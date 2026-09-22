#include "IRGenerator.h"
#include "SemanticException.h"
#include "StringConstants.h"

#include "llvm/IR/Constants.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/Verifier.h"

#include <functional>
#include <iostream>
#include <sstream>

using namespace catmint;

// ---------------------------------------------------------------------------
// RuntimeInterface
// ---------------------------------------------------------------------------

RuntimeInterface::RuntimeInterface(llvm::Module &M) {
  auto &Context = M.getContext();
  auto Ptr = llvm::PointerType::getUnqual(Context);
  auto I32 = llvm::Type::getInt32Ty(Context);
  auto Void = llvm::Type::getVoidTy(Context);
  (void)Void;

  RTTIType = llvm::StructType::create(Context, "struct.__catmint_rtti");
  StringType = llvm::StructType::create(Context, "struct.TString");
  ObjectType = llvm::StructType::create(Context, "struct.TObject");
  IOType = llvm::StructType::create(Context, "struct.TIO");

  // { TString *name; int size; __catmint_rtti *parent; void *vtable[]; }
  RTTIType->setBody({Ptr, I32, Ptr, llvm::ArrayType::get(Ptr, 0)});
  // { rtti; int length; char *chars; }
  StringType->setBody({Ptr, I32, Ptr});
  ObjectType->setBody({Ptr});
  IOType->setBody({Ptr});

  RObject = llvm::cast<llvm::GlobalVariable>(
      M.getOrInsertGlobal("RObject", RTTIType));
  RString = llvm::cast<llvm::GlobalVariable>(
      M.getOrInsertGlobal("RString", RTTIType));
  RIO = llvm::cast<llvm::GlobalVariable>(M.getOrInsertGlobal("RIO", RTTIType));

  CatmintNew =
      M.getOrInsertFunction("__catmint_new", llvm::FunctionType::get(Ptr, {Ptr}, false));
  IntToString = M.getOrInsertFunction(
      "__lcpl_intToString", llvm::FunctionType::get(Ptr, {I32}, false));
  FloatToString = M.getOrInsertFunction(
      "__lcpl_floatToString",
      llvm::FunctionType::get(Ptr, {llvm::Type::getDoubleTy(Context)}, false));
  CheckNull = M.getOrInsertFunction(
      "__lcpl_checkNull", llvm::FunctionType::get(Void, {Ptr}, false));
  DynamicCast = M.getOrInsertFunction(
      "__lcpl_cast", llvm::FunctionType::get(Ptr, {Ptr, Ptr}, false));
  StringSubstring = M.getOrInsertFunction(
      "M6_String_substring", llvm::FunctionType::get(Ptr, {Ptr, I32, I32}, false));
  StringConcat = M.getOrInsertFunction(
      "M6_String_concat", llvm::FunctionType::get(Ptr, {Ptr, Ptr}, false));
  StringEqual = M.getOrInsertFunction(
      "M6_String_equal", llvm::FunctionType::get(I32, {Ptr, Ptr}, false));
}

// ---------------------------------------------------------------------------
// Construction
// ---------------------------------------------------------------------------

IRGenerator::IRGenerator(llvm::StringRef ModuleName, Program *P,
                         const TypeTable &ASTTypes, SymbolMap DefinitionsMap,
                         std::set<std::string> ExternalClasses,
                         bool LibraryOnly)
    : Context(), Module(ModuleName, Context), Builder(Context),
      // A generic little-endian 64-bit layout. Only used to size objects; the
      // module carries no datalayout of its own so lli/clang supply the host's.
      SizingLayout("e-m:e-i64:64-f80:128-n8:16:32:64-S128"), Runtime(Module),
      AST(P), ASTTypes(ASTTypes), DefinitionsMap(std::move(DefinitionsMap)),
      ExternalClasses(std::move(ExternalClasses)), LibraryOnly(LibraryOnly) {}

/// A built-in is external in the same sense an imported class is: its code
/// lives in another object (runtime.ll), so only declarations belong here.
bool IRGenerator::isExternal(const ClassInfo *CI) const {
  return CI->Builtin || ExternalClasses.count(CI->AST->getName()) != 0;
}

void IRGenerator::fail(int Line, const std::string &Message) {
  std::ostringstream OS;
  OS << "[ CODEGEN ERROR ] line " << Line << ": " << Message;
  throw std::runtime_error(OS.str());
}

// ---------------------------------------------------------------------------
// Name mangling
// ---------------------------------------------------------------------------

std::string IRGenerator::mangle(const std::string &ClassName,
                                const std::string &MethodName) {
  return "M" + std::to_string(ClassName.size()) + "_" + ClassName + "_" +
         MethodName;
}

/// Built-in methods live in runtime.ll under names that predate the catmint
/// spellings (catmint `type` is `typeName`, `len` is `length`, `input` is
/// `in`), so they cannot be derived by mangling and are mapped explicitly.
std::string IRGenerator::runtimeSymbol(ClassInfo *CI,
                                       const std::string &MethodName) {
  if (!CI->Builtin)
    return mangle(CI->AST->getName(), MethodName);

  const std::string &C = CI->AST->getName();
  if (C == strings::Object) {
    if (MethodName == strings::Abort)    return "M6_Object_abort";
    if (MethodName == strings::TypeName) return "M6_Object_typeName";
    if (MethodName == strings::Copy)     return "M6_Object_copy";
  } else if (C == strings::Io) {
    if (MethodName == strings::In)       return "M2_IO_in";
    if (MethodName == strings::Out)      return "M2_IO_out";
    if (MethodName == strings::ReadLine) return "M2_IO_readLine";
    if (MethodName == strings::Eof)      return "M2_IO_eof";
  } else if (C == strings::String) {
    if (MethodName == strings::Length) return "M6_String_length";
    if (MethodName == strings::ToInt)  return "M6_String_toInt";
  }
  return mangle(C, MethodName);
}

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

llvm::Type *IRGenerator::lowerType(const std::string &TypeName) {
  // A method declared without a return type ("auto") returns nothing; this
  // mirrors the alias registered in TypeTable::addBuiltinTypes.
  if (TypeName == "auto" || TypeName == strings::Void)
    return llvm::Type::getVoidTy(Context);
  if (TypeName == strings::Int)
    return llvm::Type::getInt32Ty(Context);
  if (TypeName == strings::Float)
    return llvm::Type::getDoubleTy(Context);
  if (TypeName == strings::Void)
    return llvm::Type::getVoidTy(Context);
  // Everything else is a reference: String, Null, user classes, Object, IO.
  return llvm::PointerType::getUnqual(Context);
}

ClassInfo *IRGenerator::lookupClass(const std::string &Name) {
  auto It = Classes.find(Name);
  return It == Classes.end() ? nullptr : &It->second;
}

bool IRGenerator::isSubclassOf(const std::string &Derived,
                               const std::string &Base) {
  if (Derived == Base)
    return true;
  for (auto *CI = lookupClass(Derived); CI; CI = CI->Parent)
    if (CI->AST->getName() == Base)
      return true;
  return false;
}

// ---------------------------------------------------------------------------
// Class collection and layout
// ---------------------------------------------------------------------------

bool IRGenerator::collectClasses() {
  // The type table parks the built-in classes in the Program, so a single walk
  // sees Object, IO and String alongside the user's classes.
  for (auto *C : *AST) {
    ClassInfo CI;
    CI.AST = C;
    const std::string Name = C->getName();
    CI.Builtin = (Name == strings::Object || Name == strings::Io ||
                  Name == strings::String);
    Classes[Name] = CI;
  }

  if (!LibraryOnly && !lookupClass(strings::MainClass)) {
    std::cerr << "[ CODEGEN ERROR ] program has no 'Main' class\n";
    return false;
  }

  // Link parents. An empty parent name means Object, except for Object itself.
  for (auto &Entry : Classes) {
    ClassInfo &CI = Entry.second;
    std::string ParentName = CI.AST->getParent();
    if (CI.AST->getName() == strings::Object)
      continue;
    if (ParentName.empty())
      ParentName = strings::Object;
    CI.Parent = lookupClass(ParentName);
    if (!CI.Parent) {
      std::cerr << "[ CODEGEN ERROR ] class '" << CI.AST->getName()
                << "' inherits unknown class '" << ParentName << "'\n";
      return false;
    }
  }

  // Order parents before children so layouts and vtables can be inherited.
  std::map<std::string, int> State; // 0 unvisited, 1 in progress, 2 done
  std::vector<ClassInfo *> Order;
  std::function<bool(ClassInfo *)> Visit = [&](ClassInfo *CI) -> bool {
    int &S = State[CI->AST->getName()];
    if (S == 2)
      return true;
    if (S == 1) {
      std::cerr << "[ CODEGEN ERROR ] inheritance cycle at '"
                << CI->AST->getName() << "'\n";
      return false;
    }
    S = 1;
    if (CI->Parent && !Visit(CI->Parent))
      return false;
    S = 2;
    Order.push_back(CI);
    return true;
  };
  for (auto &Entry : Classes)
    if (!Visit(&Entry.second))
      return false;

  ClassOrder = std::move(Order);
  return true;
}

bool IRGenerator::layoutClass(ClassInfo *CI) {
  const std::string Name = CI->AST->getName();

  // Built-in layouts are fixed by runtime.ll and must not be recomputed.
  if (CI->Builtin) {
    if (Name == strings::Object) {
      CI->Ty = Runtime.objectType();
      CI->Elements = {llvm::PointerType::getUnqual(Context)};
    } else if (Name == strings::Io) {
      CI->Ty = Runtime.ioType();
      CI->Elements = {llvm::PointerType::getUnqual(Context)};
    } else {
      CI->Ty = Runtime.stringType();
      CI->Elements = {llvm::PointerType::getUnqual(Context),
                      llvm::Type::getInt32Ty(Context),
                      llvm::PointerType::getUnqual(Context)};
    }
    return true;
  }

  // { rtti, inherited fields..., own fields... }
  if (CI->Parent) {
    CI->Elements = CI->Parent->Elements;
    CI->FieldIndex = CI->Parent->FieldIndex;
    CI->FieldType = CI->Parent->FieldType;
  } else {
    CI->Elements = {llvm::PointerType::getUnqual(Context)};
  }

  for (auto *F : *CI->AST) {
    auto *A = dynamic_cast<Attribute *>(F);
    if (!A)
      continue;
    CI->FieldIndex[A->getName()] = static_cast<unsigned>(CI->Elements.size());
    CI->FieldType[A->getName()] = A->getType();
    CI->Elements.push_back(lowerType(A->getType()));
  }

  CI->Ty = llvm::StructType::create(Context, CI->Elements, "struct.T" + Name);
  return true;
}

void IRGenerator::buildVTable(ClassInfo *CI) {
  if (CI->Parent) {
    CI->VTableOrder = CI->Parent->VTableOrder;
    CI->VTableIndex = CI->Parent->VTableIndex;
    CI->VTableImpl = CI->Parent->VTableImpl;
  }

  for (auto *F : *CI->AST) {
    auto *M = dynamic_cast<Method *>(F);
    if (!M)
      continue;
    const std::string MName = M->getName();
    if (CI->VTableIndex.count(MName)) {
      CI->VTableImpl[MName] = {CI, M}; // override reuses the parent's slot
    } else {
      CI->VTableIndex[MName] = static_cast<unsigned>(CI->VTableOrder.size());
      CI->VTableOrder.push_back(MName);
      CI->VTableImpl[MName] = {CI, M};
    }
  }
}

llvm::FunctionType *IRGenerator::methodType(ClassInfo *CI, Method *M) {
  std::vector<llvm::Type *> Params;
  Params.push_back(llvm::PointerType::getUnqual(Context)); // self
  for (auto *P : *M)
    Params.push_back(lowerType(P->getType()));
  return llvm::FunctionType::get(lowerType(M->getReturnType()), Params, false);
}

void IRGenerator::declareMethods(ClassInfo *CI) {
  if (CI->Builtin)
    return;
  // For an imported class the declaration is exactly what we want, and it is
  // created on demand by emitCall and by the vtable, so nothing to do here.
  if (isExternal(CI))
    return;
  for (auto *F : *CI->AST) {
    auto *M = dynamic_cast<Method *>(F);
    if (!M)
      continue;
    const std::string Sym = mangle(CI->AST->getName(), M->getName());
    if (!Module.getFunction(Sym))
      llvm::Function::Create(methodType(CI, M),
                             llvm::GlobalValue::ExternalLinkage, Sym, &Module);
  }
}

/// Emit @N<Class> (the class-name TString) and @R<Class> (the RTTI record with
/// the virtual table) so that __catmint_new can allocate instances.
void IRGenerator::emitClassMetadata(ClassInfo *CI) {
  const std::string Name = CI->AST->getName();

  if (CI->Builtin) {
    if (Name == strings::Object)      CI->RTTI = Runtime.objectRTTI();
    else if (Name == strings::Io)     CI->RTTI = Runtime.ioRTTI();
    else                              CI->RTTI = Runtime.stringRTTI();
    return;
  }

  auto Ptr = llvm::PointerType::getUnqual(Context);
  auto I32 = llvm::Type::getInt32Ty(Context);

  if (isExternal(CI)) {
    // The module that owns this class defines @R<Class> and @N<Class>; here
    // they are only referenced. An external declaration carries no body, so
    // the vtable length does not matter to the linker.
    CI->NameGlobal = llvm::cast<llvm::GlobalVariable>(
        Module.getOrInsertGlobal("N" + Name, Runtime.stringType()));
    CI->RTTI = llvm::cast<llvm::GlobalVariable>(
        Module.getOrInsertGlobal("R" + Name, Runtime.rttiType()));
    return;
  }

  // @N<Class> : the class name as a TString, whose own rtti is @RString.
  auto *Chars = Builder.CreateGlobalString(Name, ".name." + Name,
                                           /*AddressSpace=*/0, &Module);
  auto *NameInit = llvm::ConstantStruct::get(
      Runtime.stringType(),
      {Runtime.stringRTTI(),
       llvm::ConstantInt::get(I32, static_cast<uint64_t>(Name.size())),
       llvm::cast<llvm::Constant>(Chars)});
  CI->NameGlobal = new llvm::GlobalVariable(
      Module, Runtime.stringType(), /*isConstant=*/false,
      llvm::GlobalValue::ExternalLinkage, NameInit, "N" + Name);

  // The virtual table, as function pointers in slot order.
  std::vector<llvm::Constant *> Slots;
  for (const auto &MName : CI->VTableOrder) {
    auto It = CI->VTableImpl.find(MName);
    ClassInfo *Owner = It->second.first;
    Method *M = It->second.second;
    const std::string Sym = runtimeSymbol(Owner, MName);
    auto Callee = Module.getOrInsertFunction(Sym, methodType(Owner, M));
    Slots.push_back(llvm::cast<llvm::Constant>(Callee.getCallee()));
  }
  auto *VTableTy = llvm::ArrayType::get(Ptr, Slots.size());

  // The RTTI record is a distinct struct per class because the vtable length
  // varies; __catmint_rtti declares it as a flexible [0 x ptr] member.
  auto *RTTITy = llvm::StructType::get(Context, {Ptr, I32, Ptr, VTableTy});
  uint64_t Size = SizingLayout.getTypeAllocSize(CI->Ty);
  llvm::Constant *ParentRTTI =
      CI->Parent ? llvm::cast<llvm::Constant>(CI->Parent->RTTI)
                 : llvm::cast<llvm::Constant>(llvm::ConstantPointerNull::get(Ptr));
  auto *RTTIInit = llvm::ConstantStruct::get(
      RTTITy, {CI->NameGlobal, llvm::ConstantInt::get(I32, Size), ParentRTTI,
               llvm::ConstantArray::get(VTableTy, Slots)});
  CI->RTTI = new llvm::GlobalVariable(Module, RTTITy, /*isConstant=*/false,
                                      llvm::GlobalValue::ExternalLinkage,
                                      RTTIInit, "R" + Name);
}

/// <Class>_init runs the parent initialiser and then this class's attribute
/// initialisers against an already-allocated, zeroed object.
bool IRGenerator::emitInitFunction(ClassInfo *CI) {
  if (CI->Builtin)
    return true;

  const std::string Name = CI->AST->getName();
  auto Ptr = llvm::PointerType::getUnqual(Context);
  auto *FT = llvm::FunctionType::get(llvm::Type::getVoidTy(Context), {Ptr}, false);

  if (isExternal(CI)) {
    // Declared, not defined: the initialiser is compiled with its own module.
    CI->Init = llvm::cast<llvm::Function>(
        Module.getOrInsertFunction(Name + "_init", FT).getCallee());
    return true;
  }

  CI->Init = llvm::Function::Create(FT, llvm::GlobalValue::ExternalLinkage,
                                    Name + "_init", &Module);

  auto *Entry = llvm::BasicBlock::Create(Context, "entry", CI->Init);
  Builder.SetInsertPoint(Entry);

  CurrentClass = CI;
  CurrentFunction = CI->Init;
  CurrentReturnType = strings::Void;
  Scopes.clear();
  Scopes.emplace_back();

  auto *SelfSlot = createEntryAlloca(Ptr, "self");
  Builder.CreateStore(CI->Init->getArg(0), SelfSlot);
  Scopes.back()["self"] = {SelfSlot, Name};

  // Chain to the parent initialiser (Object_init / IO_init / String_init are
  // provided by the runtime; user parents get the one we generate).
  if (CI->Parent) {
    std::string ParentInit = CI->Parent->AST->getName() + "_init";
    auto Callee = Module.getOrInsertFunction(ParentInit, FT);
    Builder.CreateCall(Callee, {CI->Init->getArg(0)});
  }

  for (auto *F : *CI->AST) {
    auto *A = dynamic_cast<Attribute *>(F);
    if (!A || !A->getInit())
      continue;
    llvm::Value *V = emit(A->getInit());
    if (!V)
      continue;
    V = coerce(V, staticTypeOf(A->getInit()), A->getType(), A->getLineNumber());
    auto *Addr = Builder.CreateGEP(
        CI->Ty, CI->Init->getArg(0),
        {Builder.getInt32(0), Builder.getInt32(CI->FieldIndex[A->getName()])},
        A->getName() + ".addr");
    Builder.CreateStore(V, Addr);
  }

  if (!blockTerminated())
    Builder.CreateRetVoid();
  return true;
}

// ---------------------------------------------------------------------------
// Methods
// ---------------------------------------------------------------------------

bool IRGenerator::emitMethod(ClassInfo *CI, Method *M) {
  const std::string Sym = mangle(CI->AST->getName(), M->getName());
  auto *F = Module.getFunction(Sym);
  if (!F)
    return false;
  if (!F->empty())
    return true; // already emitted

  auto *Entry = llvm::BasicBlock::Create(Context, "entry", F);
  Builder.SetInsertPoint(Entry);

  CurrentClass = CI;
  CurrentFunction = F;
  CurrentReturnType = M->getReturnType();
  Scopes.clear();
  Scopes.emplace_back();

  // self, then the declared parameters, each given a stack slot so that
  // assignment to a parameter works like assignment to any other local.
  auto Ptr = llvm::PointerType::getUnqual(Context);
  auto *SelfSlot = createEntryAlloca(Ptr, "self");
  Builder.CreateStore(F->getArg(0), SelfSlot);
  Scopes.back()["self"] = {SelfSlot, CI->AST->getName()};

  unsigned Idx = 1;
  for (auto *P : *M) {
    auto *Slot = createEntryAlloca(lowerType(P->getType()), P->getName());
    Builder.CreateStore(F->getArg(Idx), Slot);
    Scopes.back()[P->getName()] = {Slot, P->getType()};
    ++Idx;
  }

  llvm::Value *Body = M->getBody() ? emit(M->getBody()) : nullptr;

  if (!blockTerminated()) {
    if (M->getReturnType() == strings::Void || M->getReturnType() == "auto") {
      Builder.CreateRetVoid();
    } else {
      // catmint allows the last expression to be the result.
      llvm::Type *RT = lowerType(M->getReturnType());
      if (Body && Body->getType() == RT) {
        Builder.CreateRet(Body);
      } else if (RT->isPointerTy()) {
        Builder.CreateRet(llvm::ConstantPointerNull::get(
            llvm::cast<llvm::PointerType>(RT)));
      } else if (RT->isIntegerTy()) {
        Builder.CreateRet(llvm::ConstantInt::get(RT, 0));
      } else {
        Builder.CreateRet(llvm::ConstantFP::get(RT, 0.0));
      }
    }
  }
  return true;
}

/// The program entry point: allocate a Main, run its initialiser, call main.
void IRGenerator::emitProgramMain() {
  ClassInfo *MainCI = lookupClass(strings::MainClass);
  auto *FT = llvm::FunctionType::get(llvm::Type::getInt32Ty(Context), false);
  auto *F = llvm::Function::Create(FT, llvm::GlobalValue::ExternalLinkage,
                                   "main", &Module);
  auto *Entry = llvm::BasicBlock::Create(Context, "entry", F);
  Builder.SetInsertPoint(Entry);

  auto *Obj = Builder.CreateCall(Runtime.catmintNew(), {MainCI->RTTI}, "main.obj");
  if (MainCI->Init)
    Builder.CreateCall(MainCI->Init, {Obj});

  auto MainMethod = MainCI->VTableImpl.find(strings::MainMethod);
  if (MainMethod != MainCI->VTableImpl.end()) {
    ClassInfo *Owner = MainMethod->second.first;
    Method *M = MainMethod->second.second;
    auto Callee = Module.getOrInsertFunction(runtimeSymbol(Owner, M->getName()),
                                             methodType(Owner, M));
    Builder.CreateCall(Callee, {Obj});
  }

  Builder.CreateRet(Builder.getInt32(0));
}

// ---------------------------------------------------------------------------
// Driver
// ---------------------------------------------------------------------------

llvm::Module *IRGenerator::runGenerator() {
  if (!collectClasses())
    return nullptr;

  for (auto *CI : ClassOrder) {
    if (!layoutClass(CI))
      return nullptr;
    buildVTable(CI);
  }
  for (auto *CI : ClassOrder)
    declareMethods(CI);
  for (auto *CI : ClassOrder)
    emitClassMetadata(CI);
  for (auto *CI : ClassOrder)
    if (!emitInitFunction(CI))
      return nullptr;

  for (auto *CI : ClassOrder) {
    if (isExternal(CI))
      continue;
    for (auto *Feat : *CI->AST) {
      auto *M = dynamic_cast<Method *>(Feat);
      if (M && !emitMethod(CI, M))
        return nullptr;
    }
  }

  if (!LibraryOnly)
    emitProgramMain();
  return &Module;
}

// ---------------------------------------------------------------------------
// Scope helpers
// ---------------------------------------------------------------------------

llvm::AllocaInst *IRGenerator::createEntryAlloca(llvm::Type *Ty,
                                                 const std::string &Name) {
  llvm::IRBuilder<> Tmp(&CurrentFunction->getEntryBlock(),
                        CurrentFunction->getEntryBlock().begin());
  return Tmp.CreateAlloca(Ty, nullptr, Name);
}

IRGenerator::Local *IRGenerator::findLocal(const std::string &Name) {
  for (auto It = Scopes.rbegin(); It != Scopes.rend(); ++It) {
    auto Found = It->find(Name);
    if (Found != It->end())
      return &Found->second;
  }
  return nullptr;
}

llvm::Value *IRGenerator::selfValue() {
  auto *L = findLocal("self");
  if (!L)
    return nullptr;
  return Builder.CreateLoad(llvm::PointerType::getUnqual(Context), L->Addr,
                            "self.val");
}

llvm::Value *IRGenerator::attributeAddress(const std::string &Name,
                                           std::string &TypeOut) {
  if (!CurrentClass)
    return nullptr;
  auto It = CurrentClass->FieldIndex.find(Name);
  if (It == CurrentClass->FieldIndex.end())
    return nullptr;
  TypeOut = CurrentClass->FieldType[Name];
  llvm::Value *Self = selfValue();
  if (!Self)
    return nullptr;
  return Builder.CreateGEP(CurrentClass->Ty, Self,
                           {Builder.getInt32(0), Builder.getInt32(It->second)},
                           Name + ".addr");
}

bool IRGenerator::blockTerminated() const {
  auto *BB = Builder.GetInsertBlock();
  return BB && BB->getTerminator() != nullptr;
}

// ---------------------------------------------------------------------------
// Static types
// ---------------------------------------------------------------------------

std::string IRGenerator::staticTypeOf(Expression *E) {
  if (!E)
    return strings::Void;

  if (dynamic_cast<IntConstant *>(E))    return strings::Int;
  if (dynamic_cast<FloatConstant *>(E))  return strings::Float;
  if (dynamic_cast<StringConstant *>(E)) return strings::String;
  if (dynamic_cast<NullConstant *>(E))   return strings::Null;

  if (auto *S = dynamic_cast<Symbol *>(E)) {
    if (auto *L = findLocal(S->getName()))
      return L->TypeName;
    if (CurrentClass) {
      auto It = CurrentClass->FieldType.find(S->getName());
      if (It != CurrentClass->FieldType.end())
        return It->second;
    }
    return strings::Object;
  }
  if (auto *B = dynamic_cast<Block *>(E)) {
    std::string Last = strings::Void;
    for (auto *Sub : *B)
      Last = staticTypeOf(Sub);
    return Last;
  }
  if (auto *BO = dynamic_cast<BinaryOperator *>(E)) {
    if (BO->isComparison())
      return strings::Int;
    std::string L = staticTypeOf(BO->getLHS());
    std::string R = staticTypeOf(BO->getRHS());
    if (L == strings::String || R == strings::String)
      return strings::String; // '+' concatenates
    if (L == strings::Float || R == strings::Float)
      return strings::Float;
    return strings::Int;
  }
  if (auto *UO = dynamic_cast<UnaryOperator *>(E))
    return UO->getOperatorKind() == UnaryOperator::Not
               ? std::string(strings::Int)
               : staticTypeOf(UO->getOperand());
  if (auto *A = dynamic_cast<Assignment *>(E))
    return staticTypeOf(A->getExpression());
  if (auto *LD = dynamic_cast<LocalDefinition *>(E))
    return LD->getType();
  if (auto *NO = dynamic_cast<NewObject *>(E))  return NO->getType();
  if (auto *C = dynamic_cast<Cast *>(E))        return C->getType();
  if (dynamic_cast<Substring *>(E))             return strings::String;
  if (auto *R = dynamic_cast<ReturnExpression *>(E))
    return staticTypeOf(R->getRet());
  if (auto *If = dynamic_cast<IfStatement *>(E)) {
    std::string T = staticTypeOf(If->getThen());
    return T;
  }
  if (dynamic_cast<WhileStatement *>(E))        return strings::Void;
  if (dynamic_cast<ForStatement *>(E))          return strings::Void;

  if (auto *D = dynamic_cast<Dispatch *>(E)) {
    std::string RecvType = D->getObject() ? staticTypeOf(D->getObject())
                                          : (CurrentClass ? CurrentClass->AST->getName()
                                                          : std::string(strings::Object));
    if (auto *CI = lookupClass(RecvType)) {
      auto It = CI->VTableImpl.find(D->getName());
      if (It != CI->VTableImpl.end())
        return It->second.second->getReturnType();
    }
    return strings::Object;
  }
  if (auto *SD = dynamic_cast<StaticDispatch *>(E)) {
    if (auto *CI = lookupClass(SD->getType())) {
      auto It = CI->VTableImpl.find(SD->getName());
      if (It != CI->VTableImpl.end())
        return It->second.second->getReturnType();
    }
    return strings::Object;
  }
  return strings::Object;
}

/// Insert the conversion needed to use a \p From value where \p To is expected.
/// Int -> String goes through the runtime's intToString, which is what makes
/// `out(someInt)` work.
llvm::Value *IRGenerator::coerce(llvm::Value *V, const std::string &From,
                                 const std::string &To, int Line) {
  if (!V || From == To)
    return V;

  if (From == strings::Int && To == strings::String)
    return Builder.CreateCall(Runtime.intToString(), {V}, "int.str");
  if (From == strings::Float && To == strings::String)
    return Builder.CreateCall(Runtime.floatToString(), {V}, "float.str");
  if (From == strings::Int && To == strings::Float)
    return Builder.CreateSIToFP(V, llvm::Type::getDoubleTy(Context), "int.fp");
  if (From == strings::Float && To == strings::Int)
    return Builder.CreateFPToSI(V, llvm::Type::getInt32Ty(Context), "fp.int");
  // Reference types are all `ptr` under opaque pointers, so widening to a base
  // class or to Object needs no instruction.
  return V;
}

// ---------------------------------------------------------------------------
// Expressions
// ---------------------------------------------------------------------------

llvm::Value *IRGenerator::emit(Expression *E) {
  if (!E || blockTerminated())
    return nullptr;

  if (auto *N = dynamic_cast<Block *>(E))            return emitBlock(N);
  if (auto *N = dynamic_cast<IntConstant *>(E))      return emitIntConstant(N);
  if (auto *N = dynamic_cast<FloatConstant *>(E))    return emitFloatConstant(N);
  if (auto *N = dynamic_cast<StringConstant *>(E))   return emitStringConstant(N);
  if (auto *N = dynamic_cast<NullConstant *>(E))     return emitNullConstant(N);
  if (auto *N = dynamic_cast<LocalDefinition *>(E))  return emitLocalDefinition(N);
  if (auto *N = dynamic_cast<Assignment *>(E))       return emitAssignment(N);
  if (auto *N = dynamic_cast<BinaryOperator *>(E))   return emitBinaryOperator(N);
  if (auto *N = dynamic_cast<UnaryOperator *>(E))    return emitUnaryOperator(N);
  if (auto *N = dynamic_cast<IfStatement *>(E))      return emitIf(N);
  if (auto *N = dynamic_cast<WhileStatement *>(E))   return emitWhile(N);
  if (auto *N = dynamic_cast<ForStatement *>(E))     return emitFor(N);
  if (auto *N = dynamic_cast<ReturnExpression *>(E)) return emitReturn(N);
  if (auto *N = dynamic_cast<StaticDispatch *>(E))   return emitStaticDispatch(N);
  if (auto *N = dynamic_cast<Dispatch *>(E))         return emitDispatch(N);
  if (auto *N = dynamic_cast<NewObject *>(E))        return emitNewObject(N);
  if (auto *N = dynamic_cast<Cast *>(E))             return emitCast(N);
  if (auto *N = dynamic_cast<Substring *>(E))        return emitSubstring(N);
  if (auto *N = dynamic_cast<Symbol *>(E))           return emitSymbol(N);

  fail(E->getLineNumber(), "unsupported expression in code generation");
}

llvm::Value *IRGenerator::emitBlock(Block *B) {
  Scopes.emplace_back();
  llvm::Value *Last = nullptr;
  for (auto *Sub : *B) {
    if (blockTerminated())
      break;
    Last = emit(Sub);
  }
  Scopes.pop_back();
  return Last;
}

llvm::Value *IRGenerator::emitIntConstant(IntConstant *IC) {
  return Builder.getInt32(IC->getValue());
}

llvm::Value *IRGenerator::emitFloatConstant(FloatConstant *FC) {
  return llvm::ConstantFP::get(llvm::Type::getDoubleTy(Context),
                               static_cast<double>(FC->getValue()));
}

/// String literals become private TString globals rather than heap objects, so
/// evaluating one costs nothing at run time.
llvm::Value *IRGenerator::makeStringLiteral(const std::string &Value) {
  auto *Chars = Builder.CreateGlobalString(Value, ".str",
                                           /*AddressSpace=*/0, &Module);
  auto *Init = llvm::ConstantStruct::get(
      Runtime.stringType(),
      {Runtime.stringRTTI(),
       llvm::ConstantInt::get(llvm::Type::getInt32Ty(Context),
                              static_cast<uint64_t>(Value.size())),
       llvm::cast<llvm::Constant>(Chars)});
  return new llvm::GlobalVariable(Module, Runtime.stringType(),
                                  /*isConstant=*/false,
                                  llvm::GlobalValue::PrivateLinkage, Init,
                                  ".strobj");
}

llvm::Value *IRGenerator::emitStringConstant(StringConstant *SC) {
  return makeStringLiteral(SC->getValue());
}

llvm::Value *IRGenerator::emitNullConstant(NullConstant *) {
  return llvm::ConstantPointerNull::get(llvm::PointerType::getUnqual(Context));
}

llvm::Value *IRGenerator::emitSymbol(Symbol *S) {
  const std::string Name = S->getName();
  if (Name == strings::Self)
    return selfValue();

  if (auto *L = findLocal(Name))
    return Builder.CreateLoad(lowerType(L->TypeName), L->Addr, Name);

  std::string FieldTy;
  if (auto *Addr = attributeAddress(Name, FieldTy))
    return Builder.CreateLoad(lowerType(FieldTy), Addr, Name);

  fail(S->getLineNumber(), "unknown identifier '" + Name + "'");
}

/// Declaring a variable of class type also constructs it, so `IO n` yields a
/// usable object without an explicit `new`. That is the style every program in
/// this repository is written in, and it matters for a second reason: the
/// grammar folds the statement that follows a bare declaration into the
/// declaration's initialiser, so `IO n` on one line and `n.out(...)` on the
/// next arrive here as one node whose initialiser already mentions `n`. The
/// variable is therefore registered and constructed before the initialiser is
/// evaluated.
llvm::Value *IRGenerator::emitLocalDefinition(LocalDefinition *LD) {
  std::string DeclaredType = LD->getType();

  // `auto x = expr` takes the type of its initialiser.
  if (DeclaredType == "auto" || DeclaredType.empty()) {
    DeclaredType = LD->getInit() ? staticTypeOf(LD->getInit())
                                 : std::string(strings::Object);
  }

  Expression *InitExpr = LD->getInit();

  // `x = expr` parses as a definition with no declared type. When the name is
  // already visible it is an assignment to that variable, not a new one --
  // otherwise `sum = sum + i` inside a loop body would bind a fresh `sum` that
  // vanishes when the body's scope ends, and the outer variable would never
  // change.
  if (LD->getType() == "auto" && InitExpr) {
    bool AllKnown = !LD->getName().empty();
    for (const auto &Name : LD->getName()) {
      std::string Unused;
      if (!findLocal(Name) &&
          !(CurrentClass && CurrentClass->FieldIndex.count(Name)))
        AllKnown = false;
    }
    if (AllKnown) {
      const std::string InitTy = staticTypeOf(InitExpr);
      llvm::Value *V = emit(InitExpr);
      if (!V)
        return nullptr;
      for (const auto &Name : LD->getName()) {
        if (auto *L = findLocal(Name)) {
          Builder.CreateStore(coerce(V, InitTy, L->TypeName, LD->getLineNumber()),
                              L->Addr);
          continue;
        }
        std::string FieldTy;
        if (auto *Addr = attributeAddress(Name, FieldTy))
          Builder.CreateStore(coerce(V, InitTy, FieldTy, LD->getLineNumber()),
                              Addr);
      }
      return V;
    }
  }

  ClassInfo *DeclClass = lookupClass(DeclaredType);
  // A self-contained initialiser supplies the whole value, so there is nothing
  // to default-construct first.
  const bool InitIsComplete =
      InitExpr && (dynamic_cast<NewObject *>(InitExpr) ||
                   dynamic_cast<StringConstant *>(InitExpr) ||
                   dynamic_cast<NullConstant *>(InitExpr));

  llvm::Type *Lowered = lowerType(DeclaredType);
  std::vector<llvm::Value *> Slots;
  for (const auto &Name : LD->getName()) {
    auto *Slot = createEntryAlloca(Lowered, Name);
    if (DeclClass && !InitIsComplete) {
      auto *Obj = Builder.CreateCall(Runtime.catmintNew(), {DeclClass->RTTI},
                                     Name + ".obj");
      if (DeclClass->Init) {
        Builder.CreateCall(DeclClass->Init, {Obj});
      } else {
        auto *FT = llvm::FunctionType::get(
            llvm::Type::getVoidTy(Context),
            {llvm::PointerType::getUnqual(Context)}, false);
        Builder.CreateCall(
            Module.getOrInsertFunction(DeclaredType + "_init", FT), {Obj});
      }
      Builder.CreateStore(Obj, Slot);
    } else if (Lowered->isPointerTy()) {
      Builder.CreateStore(llvm::ConstantPointerNull::get(
                              llvm::PointerType::getUnqual(Context)),
                          Slot);
    } else if (DeclaredType == strings::Float) {
      Builder.CreateStore(
          llvm::ConstantFP::get(llvm::Type::getDoubleTy(Context), 0.0), Slot);
    } else {
      Builder.CreateStore(Builder.getInt32(0), Slot);
    }
    Scopes.back()[Name] = {Slot, DeclaredType};
    Slots.push_back(Slot);
  }

  if (!InitExpr)
    return nullptr;

  const std::string InitType = staticTypeOf(InitExpr);
  llvm::Value *V = emit(InitExpr);
  if (!V)
    return nullptr;
  // Store only when the initialiser actually yields this type; when the
  // grammar has folded an unrelated following statement in here, it is
  // evaluated for its effect and discarded.
  if (InitType == DeclaredType || isSubclassOf(InitType, DeclaredType) ||
      InitType == strings::Int || InitType == strings::Float ||
      InitType == strings::Null) {
    llvm::Value *Stored = coerce(V, InitType, DeclaredType, LD->getLineNumber());
    if (Stored->getType() == Lowered)
      for (auto *Slot : Slots)
        Builder.CreateStore(Stored, Slot);
  }
  return V;
}

llvm::Value *IRGenerator::emitAssignment(Assignment *A) {
  llvm::Value *V = emit(A->getExpression());
  if (!V)
    return nullptr;
  const std::string Name = A->getSymbol();
  const std::string FromType = staticTypeOf(A->getExpression());

  if (auto *L = findLocal(Name)) {
    Builder.CreateStore(coerce(V, FromType, L->TypeName, A->getLineNumber()),
                        L->Addr);
    return V;
  }
  std::string FieldTy;
  if (auto *Addr = attributeAddress(Name, FieldTy)) {
    Builder.CreateStore(coerce(V, FromType, FieldTy, A->getLineNumber()), Addr);
    return V;
  }
  fail(A->getLineNumber(), "assignment to unknown identifier '" + Name + "'");
}

llvm::Value *IRGenerator::emitBinaryOperator(BinaryOperator *BO) {
  const std::string LT = staticTypeOf(BO->getLHS());
  const std::string RT = staticTypeOf(BO->getRHS());

  llvm::Value *L = emit(BO->getLHS());
  llvm::Value *R = emit(BO->getRHS());
  if (!L || !R)
    return nullptr;

  using BK = BinaryOperator::BinOpKind;
  const BK Op = BO->getOperatorKind();

  // String concatenation and comparison go through the runtime.
  if (LT == strings::String || RT == strings::String) {
    llvm::Value *LS = coerce(L, LT, strings::String, BO->getLineNumber());
    llvm::Value *RS = coerce(R, RT, strings::String, BO->getLineNumber());
    if (Op == BK::Add)
      return Builder.CreateCall(Runtime.stringConcat(), {LS, RS}, "concat");
    if (Op == BK::Equal)
      return Builder.CreateCall(Runtime.stringEqual(), {LS, RS}, "streq");
    if (Op == BK::NotEqual) {
      auto *Eq = Builder.CreateCall(Runtime.stringEqual(), {LS, RS}, "streq");
      return Builder.CreateZExt(
          Builder.CreateICmpEQ(Eq, Builder.getInt32(0)),
          llvm::Type::getInt32Ty(Context), "strne");
    }
    fail(BO->getLineNumber(), "operator '" + BO->getName() +
                                  "' is not defined for String operands");
  }

  const bool Floating = (LT == strings::Float || RT == strings::Float);
  if (Floating) {
    L = coerce(L, LT, strings::Float, BO->getLineNumber());
    R = coerce(R, RT, strings::Float, BO->getLineNumber());
    switch (Op) {
    case BK::Add: return Builder.CreateFAdd(L, R, "fadd");
    case BK::Sub: return Builder.CreateFSub(L, R, "fsub");
    case BK::Mul: return Builder.CreateFMul(L, R, "fmul");
    case BK::Div: return Builder.CreateFDiv(L, R, "fdiv");
    default: break;
    }
    llvm::CmpInst::Predicate P;
    switch (Op) {
    case BK::LessThan:         P = llvm::CmpInst::FCMP_OLT; break;
    case BK::LessThanEqual:    P = llvm::CmpInst::FCMP_OLE; break;
    case BK::GreaterThan:      P = llvm::CmpInst::FCMP_OGT; break;
    case BK::GreaterThanEqual: P = llvm::CmpInst::FCMP_OGE; break;
    case BK::Equal:            P = llvm::CmpInst::FCMP_OEQ; break;
    case BK::NotEqual:         P = llvm::CmpInst::FCMP_ONE; break;
    default:
      fail(BO->getLineNumber(),
           "operator '" + BO->getName() + "' is not defined for Float operands");
    }
    return Builder.CreateZExt(Builder.CreateFCmp(P, L, R, "fcmp"),
                              llvm::Type::getInt32Ty(Context), "fcmp.i32");
  }

  switch (Op) {
  case BK::Add:    return Builder.CreateAdd(L, R, "add");
  case BK::Sub:    return Builder.CreateSub(L, R, "sub");
  case BK::Mul:    return Builder.CreateMul(L, R, "mul");
  case BK::Div:    return Builder.CreateSDiv(L, R, "div");
  case BK::Mod:    return Builder.CreateSRem(L, R, "mod");
  case BK::And:    return Builder.CreateAnd(L, R, "and");
  case BK::Or:     return Builder.CreateOr(L, R, "or");
  case BK::Xor:    return Builder.CreateXor(L, R, "xor");
  case BK::LShift: return Builder.CreateShl(L, R, "shl");
  case BK::RShift: return Builder.CreateAShr(L, R, "shr");
  case BK::Pow: {
    // Integer exponentiation by repeated multiplication, so that '**' needs no
    // libm and stays in the integer domain.
    auto *Acc = createEntryAlloca(llvm::Type::getInt32Ty(Context), "pow.acc");
    auto *Cnt = createEntryAlloca(llvm::Type::getInt32Ty(Context), "pow.n");
    Builder.CreateStore(Builder.getInt32(1), Acc);
    Builder.CreateStore(R, Cnt);
    auto *Cond = llvm::BasicBlock::Create(Context, "pow.cond", CurrentFunction);
    auto *Body = llvm::BasicBlock::Create(Context, "pow.body", CurrentFunction);
    auto *End  = llvm::BasicBlock::Create(Context, "pow.end", CurrentFunction);
    Builder.CreateBr(Cond);
    Builder.SetInsertPoint(Cond);
    auto *N = Builder.CreateLoad(llvm::Type::getInt32Ty(Context), Cnt, "n");
    Builder.CreateCondBr(Builder.CreateICmpSGT(N, Builder.getInt32(0)), Body, End);
    Builder.SetInsertPoint(Body);
    auto *A = Builder.CreateLoad(llvm::Type::getInt32Ty(Context), Acc, "acc");
    Builder.CreateStore(Builder.CreateMul(A, L, "acc.next"), Acc);
    Builder.CreateStore(Builder.CreateSub(N, Builder.getInt32(1), "n.next"), Cnt);
    Builder.CreateBr(Cond);
    Builder.SetInsertPoint(End);
    return Builder.CreateLoad(llvm::Type::getInt32Ty(Context), Acc, "pow");
  }
  default: break;
  }

  llvm::CmpInst::Predicate P;
  switch (Op) {
  case BK::LessThan:         P = llvm::CmpInst::ICMP_SLT; break;
  case BK::LessThanEqual:    P = llvm::CmpInst::ICMP_SLE; break;
  case BK::GreaterThan:      P = llvm::CmpInst::ICMP_SGT; break;
  case BK::GreaterThanEqual: P = llvm::CmpInst::ICMP_SGE; break;
  case BK::Equal:            P = llvm::CmpInst::ICMP_EQ;  break;
  case BK::NotEqual:         P = llvm::CmpInst::ICMP_NE;  break;
  default:
    fail(BO->getLineNumber(), "unsupported binary operator '" + BO->getName() + "'");
  }
  return Builder.CreateZExt(Builder.CreateICmp(P, L, R, "cmp"),
                            llvm::Type::getInt32Ty(Context), "cmp.i32");
}

llvm::Value *IRGenerator::emitUnaryOperator(UnaryOperator *UO) {
  llvm::Value *V = emit(UO->getOperand());
  if (!V)
    return nullptr;
  if (UO->getOperatorKind() == UnaryOperator::Minus) {
    if (V->getType()->isDoubleTy())
      return Builder.CreateFNeg(V, "neg");
    return Builder.CreateNeg(V, "neg");
  }
  // Logical NOT: zero becomes 1, anything else becomes 0.
  return Builder.CreateZExt(Builder.CreateICmpEQ(V, Builder.getInt32(0), "notcmp"),
                            llvm::Type::getInt32Ty(Context), "not");
}

llvm::Value *IRGenerator::emitIf(IfStatement *If) {
  llvm::Value *Cond = emit(If->getCond());
  if (!Cond)
    return nullptr;
  if (Cond->getType()->isPointerTy())
    Cond = Builder.CreateICmpNE(
        Cond, llvm::ConstantPointerNull::get(
                  llvm::PointerType::getUnqual(Context)), "ifptr");
  else
    Cond = Builder.CreateICmpNE(Cond, Builder.getInt32(0), "ifcond");

  auto *ThenBB = llvm::BasicBlock::Create(Context, "if.then", CurrentFunction);
  auto *ElseBB = llvm::BasicBlock::Create(Context, "if.else", CurrentFunction);
  auto *EndBB  = llvm::BasicBlock::Create(Context, "if.end", CurrentFunction);
  Builder.CreateCondBr(Cond, ThenBB, ElseBB);

  Builder.SetInsertPoint(ThenBB);
  llvm::Value *ThenV = emit(If->getThen());
  bool ThenOpen = !blockTerminated();
  auto *ThenExit = Builder.GetInsertBlock();
  if (ThenOpen)
    Builder.CreateBr(EndBB);

  Builder.SetInsertPoint(ElseBB);
  llvm::Value *ElseV = If->getElse() ? emit(If->getElse()) : nullptr;
  bool ElseOpen = !blockTerminated();
  auto *ElseExit = Builder.GetInsertBlock();
  if (ElseOpen)
    Builder.CreateBr(EndBB);

  Builder.SetInsertPoint(EndBB);
  if (!ThenOpen && !ElseOpen) {
    // Both arms returned; nothing can reach the join.
    Builder.CreateUnreachable();
    return nullptr;
  }
  // Produce a value only when both arms supply one of the same type.
  if (ThenOpen && ElseOpen && ThenV && ElseV &&
      ThenV->getType() == ElseV->getType() && !ThenV->getType()->isVoidTy()) {
    auto *Phi = Builder.CreatePHI(ThenV->getType(), 2, "if.val");
    Phi->addIncoming(ThenV, ThenExit);
    Phi->addIncoming(ElseV, ElseExit);
    return Phi;
  }
  return nullptr;
}

llvm::Value *IRGenerator::emitWhile(WhileStatement *W) {
  auto *CondBB = llvm::BasicBlock::Create(Context, "while.cond", CurrentFunction);
  auto *BodyBB = llvm::BasicBlock::Create(Context, "while.body", CurrentFunction);
  auto *EndBB  = llvm::BasicBlock::Create(Context, "while.end", CurrentFunction);

  Builder.CreateBr(CondBB);
  Builder.SetInsertPoint(CondBB);
  llvm::Value *Cond = emit(W->getCond());
  if (!Cond)
    return nullptr;
  if (Cond->getType()->isPointerTy())
    Cond = Builder.CreateICmpNE(
        Cond, llvm::ConstantPointerNull::get(
                  llvm::PointerType::getUnqual(Context)), "whileptr");
  else
    Cond = Builder.CreateICmpNE(Cond, Builder.getInt32(0), "whilecond");
  Builder.CreateCondBr(Cond, BodyBB, EndBB);

  Builder.SetInsertPoint(BodyBB);
  (void)emit(W->getBody());
  if (!blockTerminated())
    Builder.CreateBr(CondBB);

  Builder.SetInsertPoint(EndBB);
  return nullptr;
}

/// `for <var> in <container>:` over an Int count (0..n-1) or over a String
/// (each character as a one-character String). Both lower to the same counted
/// loop; only what gets stored into the loop variable differs.
llvm::Value *IRGenerator::emitFor(ForStatement *F) {
  auto *IterSym = dynamic_cast<Symbol *>(F->getIter());
  if (!IterSym)
    fail(F->getLineNumber(),
         "the loop variable of a 'for' must be a plain name");

  const std::string ContType = staticTypeOf(F->getCont());
  const bool OverString = (ContType == strings::String);
  if (!OverString && ContType != strings::Int)
    fail(F->getLineNumber(), "cannot iterate over a value of type '" +
                                 ContType + "'; 'for' takes an Int or a String");

  llvm::Value *Cont = emit(F->getCont());
  if (!Cont)
    return nullptr;

  auto *I32 = llvm::Type::getInt32Ty(Context);
  auto Ptr = llvm::PointerType::getUnqual(Context);

  // The bound is the count itself, or the string's length.
  llvm::Value *Bound = Cont;
  llvm::Value *StrSlot = nullptr;
  if (OverString) {
    StrSlot = createEntryAlloca(Ptr, "for.str");
    Builder.CreateStore(Cont, StrSlot);
    auto StrLen = Module.getOrInsertFunction(
        "M6_String_length", llvm::FunctionType::get(I32, {Ptr}, false));
    Builder.CreateCall(Runtime.checkNull(), {Cont});
    Bound = Builder.CreateCall(StrLen, {Cont}, "for.len");
  }

  auto *BoundSlot = createEntryAlloca(I32, "for.bound");
  Builder.CreateStore(Bound, BoundSlot);
  auto *IdxSlot = createEntryAlloca(I32, "for.idx");
  Builder.CreateStore(Builder.getInt32(0), IdxSlot);

  // The loop variable lives in its own scope, so it does not leak out and does
  // not collide with a variable of the same name outside the loop.
  Scopes.emplace_back();
  const std::string ElemType = OverString ? strings::String : strings::Int;
  auto *VarSlot = createEntryAlloca(lowerType(ElemType), IterSym->getName());
  Scopes.back()[IterSym->getName()] = {VarSlot, ElemType};

  auto *CondBB = llvm::BasicBlock::Create(Context, "for.cond", CurrentFunction);
  auto *BodyBB = llvm::BasicBlock::Create(Context, "for.body", CurrentFunction);
  auto *StepBB = llvm::BasicBlock::Create(Context, "for.step", CurrentFunction);
  auto *EndBB = llvm::BasicBlock::Create(Context, "for.end", CurrentFunction);

  Builder.CreateBr(CondBB);

  Builder.SetInsertPoint(CondBB);
  auto *Idx = Builder.CreateLoad(I32, IdxSlot, "for.i");
  auto *Limit = Builder.CreateLoad(I32, BoundSlot, "for.n");
  Builder.CreateCondBr(Builder.CreateICmpSLT(Idx, Limit, "for.more"), BodyBB,
                       EndBB);

  Builder.SetInsertPoint(BodyBB);
  if (OverString) {
    // substring is a half-open range, so one character at i is [i, i+1).
    auto *Str = Builder.CreateLoad(Ptr, StrSlot, "for.s");
    auto *Next = Builder.CreateAdd(Idx, Builder.getInt32(1), "for.i1");
    auto *Ch = Builder.CreateCall(Runtime.stringSubstring(), {Str, Idx, Next},
                                  "for.ch");
    Builder.CreateStore(Ch, VarSlot);
  } else {
    Builder.CreateStore(Idx, VarSlot);
  }
  (void)emit(F->getBody());
  if (!blockTerminated())
    Builder.CreateBr(StepBB);

  Builder.SetInsertPoint(StepBB);
  auto *Cur = Builder.CreateLoad(I32, IdxSlot, "for.i.cur");
  Builder.CreateStore(Builder.CreateAdd(Cur, Builder.getInt32(1), "for.i.next"),
                      IdxSlot);
  Builder.CreateBr(CondBB);

  Scopes.pop_back();
  Builder.SetInsertPoint(EndBB);
  return nullptr;
}

llvm::Value *IRGenerator::emitReturn(ReturnExpression *R) {
  if (CurrentReturnType == strings::Void || CurrentReturnType == "auto" ||
      !R->getRet()) {
    Builder.CreateRetVoid();
    return nullptr;
  }
  llvm::Value *V = emit(R->getRet());
  if (!V) {
    Builder.CreateRetVoid();
    return nullptr;
  }
  V = coerce(V, staticTypeOf(R->getRet()), CurrentReturnType, R->getLineNumber());
  Builder.CreateRet(V);
  return nullptr;
}

/// Shared by dynamic and static dispatch. \p Virtual selects a vtable load;
/// otherwise the implementation is called directly.
llvm::Value *IRGenerator::emitCall(ClassInfo *RecvClass,
                                   const std::string &MethodName,
                                   llvm::Value *Receiver,
                                   const std::vector<Expression *> &Args,
                                   int Line, bool Virtual,
                                   const std::string &StaticClass) {
  auto It = RecvClass->VTableImpl.find(MethodName);
  if (It == RecvClass->VTableImpl.end())
    fail(Line, "class '" + RecvClass->AST->getName() + "' has no method '" +
                   MethodName + "'");

  ClassInfo *Owner = It->second.first;
  Method *M = It->second.second;
  auto *FT = methodType(Owner, M);

  // Evaluate and convert the arguments against the declared parameter types.
  std::vector<llvm::Value *> CallArgs;
  CallArgs.push_back(Receiver);
  auto ParamIt = M->begin();
  for (auto *Arg : Args) {
    const std::string FromTy = staticTypeOf(Arg);
    llvm::Value *V = emit(Arg);
    if (!V)
      fail(Line, "argument to '" + MethodName + "' produced no value");
    if (ParamIt != M->end()) {
      V = coerce(V, FromTy, (*ParamIt)->getType(), Line);
      ++ParamIt;
    }
    CallArgs.push_back(V);
  }
  if (CallArgs.size() != FT->getNumParams())
    fail(Line, "wrong number of arguments to '" + MethodName + "'");

  Builder.CreateCall(Runtime.checkNull(), {Receiver});

  if (!Virtual) {
    ClassInfo *Target = StaticClass.empty() ? Owner : lookupClass(StaticClass);
    if (!Target)
      Target = Owner;
    auto TIt = Target->VTableImpl.find(MethodName);
    ClassInfo *TOwner = TIt != Target->VTableImpl.end() ? TIt->second.first : Owner;
    Method *TM = TIt != Target->VTableImpl.end() ? TIt->second.second : M;
    auto Callee = Module.getOrInsertFunction(runtimeSymbol(TOwner, MethodName),
                                             methodType(TOwner, TM));
    auto *Call = Builder.CreateCall(Callee, CallArgs);
    return (TM->getReturnType() == strings::Void ||
            TM->getReturnType() == "auto") ? nullptr
                                                : static_cast<llvm::Value *>(Call);
  }

  // rtti = obj->rtti; fn = rtti->vtable[slot]; fn(obj, args...)
  unsigned Slot = RecvClass->VTableIndex[MethodName];
  auto Ptr = llvm::PointerType::getUnqual(Context);
  auto *RTTI = Builder.CreateLoad(Ptr, Receiver, "rtti");
  auto *SlotAddr = Builder.CreateGEP(
      Runtime.rttiType(), RTTI,
      {Builder.getInt32(0), Builder.getInt32(3), Builder.getInt32(Slot)},
      MethodName + ".slot");
  auto *Fn = Builder.CreateLoad(Ptr, SlotAddr, MethodName + ".fn");
  auto *Call = Builder.CreateCall(FT, Fn, CallArgs);
  return (M->getReturnType() == strings::Void ||
          M->getReturnType() == "auto") ? nullptr
                                        : static_cast<llvm::Value *>(Call);
}

llvm::Value *IRGenerator::emitDispatch(Dispatch *D) {
  std::string RecvType;
  llvm::Value *Receiver = nullptr;

  if (D->getObject()) {
    RecvType = staticTypeOf(D->getObject());
    Receiver = emit(D->getObject());
  } else {
    // A bare call is a call on self.
    if (!CurrentClass)
      fail(D->getLineNumber(), "call to '" + D->getName() + "' outside a class");
    RecvType = CurrentClass->AST->getName();
    Receiver = selfValue();
  }
  if (!Receiver)
    fail(D->getLineNumber(), "receiver of '" + D->getName() + "' produced no value");

  ClassInfo *CI = lookupClass(RecvType);
  if (!CI)
    fail(D->getLineNumber(), "unknown class '" + RecvType + "' in dispatch");

  std::vector<Expression *> Args;
  for (auto *A : *D)
    Args.push_back(A);
  return emitCall(CI, D->getName(), Receiver, Args, D->getLineNumber(),
                  /*Virtual=*/true, "");
}

llvm::Value *IRGenerator::emitStaticDispatch(StaticDispatch *SD) {
  llvm::Value *Receiver = emit(SD->getObject());
  if (!Receiver)
    fail(SD->getLineNumber(), "receiver of '" + SD->getName() + "' produced no value");
  ClassInfo *CI = lookupClass(SD->getType());
  if (!CI)
    fail(SD->getLineNumber(), "unknown class '" + SD->getType() + "'");
  std::vector<Expression *> Args;
  for (auto *A : *SD)
    Args.push_back(A);
  return emitCall(CI, SD->getName(), Receiver, Args, SD->getLineNumber(),
                  /*Virtual=*/false, SD->getType());
}

llvm::Value *IRGenerator::emitNewObject(NewObject *NO) {
  ClassInfo *CI = lookupClass(NO->getType());
  if (!CI)
    fail(NO->getLineNumber(), "cannot instantiate unknown class '" + NO->getType() + "'");
  auto *Obj = Builder.CreateCall(Runtime.catmintNew(), {CI->RTTI},
                                 "new." + NO->getType());
  if (CI->Init) {
    Builder.CreateCall(CI->Init, {Obj});
  } else if (CI->Builtin) {
    auto *FT = llvm::FunctionType::get(llvm::Type::getVoidTy(Context),
                                       {llvm::PointerType::getUnqual(Context)},
                                       false);
    Builder.CreateCall(
        Module.getOrInsertFunction(CI->AST->getName() + "_init", FT), {Obj});
  }
  return Obj;
}

llvm::Value *IRGenerator::emitCast(Cast *C) {
  llvm::Value *V = emit(C->getExpressionToCast());
  if (!V)
    return nullptr;
  ClassInfo *CI = lookupClass(C->getType());
  if (!CI)
    return V; // Int/Float casts are handled by coerce
  const std::string From = staticTypeOf(C->getExpressionToCast());
  if (From == strings::Int || From == strings::Float || C->getType() == strings::Int ||
      C->getType() == strings::Float)
    return coerce(V, From, C->getType(), C->getLineNumber());
  // Downcasts are checked at run time against the target's RTTI.
  return Builder.CreateCall(Runtime.dynamicCast(), {V, CI->RTTI}, "cast");
}

llvm::Value *IRGenerator::emitSubstring(Substring *S) {
  llvm::Value *Str = emit(S->getString());
  llvm::Value *Start = emit(S->getStart());
  llvm::Value *End = emit(S->getEnd());
  if (!Str || !Start || !End)
    return nullptr;
  return Builder.CreateCall(Runtime.stringSubstring(), {Str, Start, End}, "substr");
}
