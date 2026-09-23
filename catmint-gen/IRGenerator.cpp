#include "ASTVisitor.h"
#include "IRGenerator.h"
#include "SemanticException.h"
#include "StringConstants.h"

#include "llvm/IR/Constants.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/Verifier.h"

#include <algorithm>
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
  auto I64 = llvm::Type::getInt64Ty(Context);
  auto Void = llvm::Type::getVoidTy(Context);
  (void)Void;

  RTTIType = llvm::StructType::create(Context, "struct.__catmint_rtti");
  StringType = llvm::StructType::create(Context, "struct.TString");
  ObjectType = llvm::StructType::create(Context, "struct.TObject");
  IOType = llvm::StructType::create(Context, "struct.TIO");

  // { TString *name; int size; __catmint_rtti *parent; void *interfaces;
  //   void *vtable[]; }
  RTTIType->setBody({Ptr, I32, Ptr, Ptr, llvm::ArrayType::get(Ptr, 0)});
  // Every object is { rtti, int refs, ... }; refs is 0 for a static object,
  // which is how free() knows not to touch a string literal.
  // { rtti; int refs; int length; char *chars; }
  StringType->setBody({Ptr, I32, I32, Ptr});
  ObjectType->setBody({Ptr, I32});
  IOType->setBody({Ptr, I32});

  RObject = llvm::cast<llvm::GlobalVariable>(
      M.getOrInsertGlobal("RObject", RTTIType));
  RString = llvm::cast<llvm::GlobalVariable>(
      M.getOrInsertGlobal("RString", RTTIType));
  RIO = llvm::cast<llvm::GlobalVariable>(M.getOrInsertGlobal("RIO", RTTIType));

  CatmintNew =
      M.getOrInsertFunction("__catmint_new", llvm::FunctionType::get(Ptr, {Ptr}, false));
  IntToString = M.getOrInsertFunction(
      "__cm_intToString", llvm::FunctionType::get(Ptr, {I32}, false));
  FloatToString = M.getOrInsertFunction(
      "__cm_floatToString",
      llvm::FunctionType::get(Ptr, {llvm::Type::getDoubleTy(Context)}, false));
  LongToString = M.getOrInsertFunction(
      "__cm_longToString", llvm::FunctionType::get(Ptr, {I64}, false));
  // The box holds 64 bits, so an Int8 and an Int64 survive a trip through a
  // container equally well.
  BoxLong = M.getOrInsertFunction("__cm_boxLong",
                                  llvm::FunctionType::get(Ptr, {I64}, false));
  UnboxLong = M.getOrInsertFunction("__cm_unboxLong",
                                    llvm::FunctionType::get(I64, {Ptr}, false));
  ObjectEquals = M.getOrInsertFunction(
      "__cm_equals", llvm::FunctionType::get(I32, {Ptr, Ptr}, false));
  IsType = M.getOrInsertFunction(
      "__cm_isType", llvm::FunctionType::get(I32, {Ptr, Ptr}, false));
  CheckNull = M.getOrInsertFunction(
      "__cm_checkNull", llvm::FunctionType::get(Void, {Ptr}, false));
  DynamicCast = M.getOrInsertFunction(
      "__cm_cast", llvm::FunctionType::get(Ptr, {Ptr, Ptr}, false));
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
                         bool LibraryOnly, bool EmitDebugInfo)
    : Context(), Module(ModuleName, Context), Builder(Context),
      // A generic little-endian 64-bit layout. Only used to size objects; the
      // module carries no datalayout of its own so lli/clang supply the host's.
      SizingLayout("e-m:e-i64:64-f80:128-n8:16:32:64-S128"), Runtime(Module),
      AST(P), ASTTypes(ASTTypes), DefinitionsMap(std::move(DefinitionsMap)),
      ExternalClasses(std::move(ExternalClasses)), LibraryOnly(LibraryOnly),
      EmitDebugInfo(EmitDebugInfo) {}

// ---------------------------------------------------------------------------
// Debug information
//
// Line numbers and nothing else: a subprogram per function and a location per
// expression. That is enough for a debugger to say where it is and for a
// crash to name a file and a line, which is what was missing. Describing
// types and variables would be a much larger piece of work and is not done.
// ---------------------------------------------------------------------------

void IRGenerator::startDebugInfo() {
  if (!EmitDebugInfo)
    return;

  DI.reset(new llvm::DIBuilder(Module));

  // The compile unit's file is the file Main was written in, falling back to
  // the first class that names one.
  std::string MainPath;
  if (auto *MainCI = lookupClass(strings::MainClass))
    MainPath = MainCI->AST->getFile();
  if (MainPath.empty()) {
    for (auto *CI : ClassOrder) {
      if (!CI->AST->getFile().empty()) {
        MainPath = CI->AST->getFile();
        break;
      }
    }
  }
  if (MainPath.empty())
    MainPath = Module.getName().str();

  DIMainFile = debugFileFor(nullptr);
  auto Slash = MainPath.find_last_of('/');
  const std::string Dir = Slash == std::string::npos ? std::string(".")
                                                     : MainPath.substr(0, Slash);
  const std::string Name =
      Slash == std::string::npos ? MainPath : MainPath.substr(Slash + 1);
  DIMainFile = DI->createFile(Name, Dir);
  DIFiles[MainPath] = DIMainFile;

  DICU = DI->createCompileUnit(llvm::dwarf::DW_LANG_C, DIMainFile, "catmint",
                               /*isOptimized=*/false, /*Flags=*/"",
                               /*RuntimeVersion=*/0);

  Module.addModuleFlag(llvm::Module::Warning, "Debug Info Version",
                       llvm::DEBUG_METADATA_VERSION);
  Module.addModuleFlag(llvm::Module::Warning, "Dwarf Version", 4);
}

llvm::DIFile *IRGenerator::debugFileFor(ClassInfo *CI) {
  if (!DI)
    return nullptr;
  const std::string Path = CI ? CI->AST->getFile() : std::string();
  if (Path.empty())
    return DIMainFile;

  auto Found = DIFiles.find(Path);
  if (Found != DIFiles.end())
    return Found->second;

  auto Slash = Path.find_last_of('/');
  const std::string Dir =
      Slash == std::string::npos ? std::string(".") : Path.substr(0, Slash);
  const std::string Name =
      Slash == std::string::npos ? Path : Path.substr(Slash + 1);
  auto *File = DI->createFile(Name, Dir);
  DIFiles[Path] = File;
  return File;
}

void IRGenerator::beginDebugScope(llvm::Function *F, ClassInfo *CI,
                                  const std::string &Name, int Line) {
  if (!DI) {
    Builder.SetCurrentDebugLocation(llvm::DebugLoc());
    return;
  }

  auto *File = debugFileFor(CI);
  // An empty type list: the signature is not described, only the location.
  auto *Type = DI->createSubroutineType(DI->getOrCreateTypeArray({}));
  const unsigned At = Line > 0 ? static_cast<unsigned>(Line) : 1u;
  CurrentSubprogram = DI->createFunction(
      File, Name, F->getName(), File, At, Type, At,
      llvm::DINode::FlagPrototyped, llvm::DISubprogram::SPFlagDefinition);
  F->setSubprogram(CurrentSubprogram);
  setDebugLine(Line);
}

void IRGenerator::endDebugScope() {
  CurrentSubprogram = nullptr;
  Builder.SetCurrentDebugLocation(llvm::DebugLoc());
}

void IRGenerator::setDebugLine(int Line) {
  if (!DI || !CurrentSubprogram)
    return;
  const unsigned At = Line > 0 ? static_cast<unsigned>(Line) : 1u;
  Builder.SetCurrentDebugLocation(
      llvm::DILocation::get(Context, At, 0, CurrentSubprogram));
}

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

/// '::' is not valid in an unquoted LLVM symbol, so a namespaced class
/// contributes '$' instead. '$' cannot appear in a catmint identifier, so no
/// global class can collide with a namespaced one.
static std::string symbolName(const std::string &ClassName) {
  std::string result = ClassName;
  for (size_t at = result.find("::"); at != std::string::npos;
       at = result.find("::", at + 1)) {
    result.replace(at, 2, "$");
  }
  return result;
}

std::string IRGenerator::mangle(const std::string &ClassName,
                                const std::string &MethodName) {
  const std::string symbol = symbolName(ClassName);
  return "M" + std::to_string(symbol.size()) + "_" + symbol + "_" + MethodName;
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
    if (MethodName == strings::Entropy)     return "M2_IO_entropy";
    if (MethodName == strings::Ticks)       return "M2_IO_ticks";
    if (MethodName == strings::Epoch)       return "M2_IO_epoch";
    if (MethodName == strings::LocalOffset) return "M2_IO_localOffset";
    if (MethodName == strings::Sleep)       return "M2_IO_sleep";
  } else if (C == strings::String) {
    if (MethodName == strings::Length) return "M6_String_length";
    if (MethodName == strings::ToInt)  return "M6_String_toInt";
    if (MethodName == strings::Substr) return "M6_String_substring";
    if (MethodName == strings::Concat) return "M6_String_concat";
    if (MethodName == strings::Equals) return "M6_String_equal";
    if (MethodName == strings::At)     return "M6_String_at";
  } else if (C == strings::List) {
    if (MethodName == strings::Length) return "M4_List_len";
    if (MethodName == strings::Get)    return "M4_List_get";
    if (MethodName == strings::Set)    return "M4_List_set";
    if (MethodName == strings::Append) return "M4_List_append";
    if (MethodName == strings::Slice)  return "M4_List_slice";
  } else if (C == strings::Integer) {
    if (MethodName == strings::Get)     return "M7_Integer_get";
    if (MethodName == strings::GetLong) return "M7_Integer_getLong";
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
  if (int Width = TypeTable::integerWidth(TypeName))
    return llvm::Type::getIntNTy(Context, static_cast<unsigned>(Width));
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
  for (auto *CI = lookupClass(Derived); CI; CI = CI->Parent) {
    if (CI->AST->getName() == Base)
      return true;
    // An interface is not in the parent chain; a class reaches one by
    // having promised it, and a subclass inherits that promise.
    for (const auto &Promise : CI->AST->getInterfaces())
      if (Promise == Base)
        return true;
  }
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
    CI.IsInterface = C->isInterface();
    // The class says whether it is one the compiler supplies; this used to
    // be a second list of names here, which is one more place to forget.
    CI.Builtin = C->isBuiltin();
    const std::string Name = C->getName();
    // Two definitions of one name used to overwrite each other here, so a
    // program importing two modules that both define a Point silently got
    // whichever came last. Until there are namespaces, say so instead.
    auto existing = Classes.find(Name);
    if (existing != Classes.end() && existing->second.AST != C) {
      std::cerr << "[ CODEGEN ERROR ] class '" << Name
                << "' is defined more than once; all classes share one global "
                   "namespace\n";
      return false;
    }
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
    auto Ptr = llvm::PointerType::getUnqual(Context);
    auto I32 = llvm::Type::getInt32Ty(Context);
    if (Name == strings::Object) {
      CI->Ty = Runtime.objectType();
      CI->Elements = {Ptr, I32};
    } else if (Name == strings::Io) {
      CI->Ty = Runtime.ioType();
      CI->Elements = {Ptr, I32};
    } else if (Name == strings::List) {
      // { rtti, int refs, int length, int capacity, void **items }
      CI->Elements = {Ptr, I32, I32, I32, Ptr};
      CI->Ty = llvm::StructType::create(Context, CI->Elements, "struct.TList");
    } else if (Name == strings::File) {
      // { rtti, int refs, FILE *handle }
      CI->Elements = {Ptr, I32, Ptr};
      CI->Ty = llvm::StructType::create(Context, CI->Elements, "struct.TFile");
    } else if (Name == strings::Math) {
      // { rtti, int refs } -- Math has no state of its own.
      CI->Elements = {Ptr, I32};
      CI->Ty = llvm::StructType::create(Context, CI->Elements, "struct.TMath");
    } else if (Name == strings::Process) {
      // { rtti, int refs, FILE *pipe, int pid }
      CI->Elements = {Ptr, I32, Ptr, I32};
      CI->Ty = llvm::StructType::create(Context, CI->Elements, "struct.TProcess");
    } else if (Name == strings::Worker) {
      // { rtti, int refs } -- Worker has no state of its own.
      CI->Elements = {Ptr, I32};
      CI->Ty = llvm::StructType::create(Context, CI->Elements, "struct.TWorker");
    } else if (Name == strings::Bytes || Name == strings::Ints ||
               Name == strings::Floats) {
      // { rtti, int refs, int length, T *data } -- the same shape for all
      // three, since the element type only matters to the runtime.
      CI->Elements = {Ptr, I32, I32, Ptr};
      CI->Ty = llvm::StructType::create(Context, CI->Elements,
                                        "struct.T" + Name);
    } else if (Name == strings::Integer) {
      // { rtti, int refs, long long value }
      CI->Elements = {Ptr, I32, llvm::Type::getInt64Ty(Context)};
      CI->Ty = llvm::StructType::create(Context, CI->Elements, "struct.TInteger");
    } else {
      CI->Ty = Runtime.stringType();
      CI->Elements = {Ptr, I32, I32, Ptr};
    }
    return true;
  }

  // An interface has no instances, so its layout is only what Object needs
  // for the metadata to be well formed.
  if (CI->IsInterface) {
    CI->Elements = {llvm::PointerType::getUnqual(Context),
                    llvm::Type::getInt32Ty(Context)};
    CI->Ty = llvm::StructType::create(Context, CI->Elements,
                                      "struct.I" + symbolName(Name));
    return true;
  }

  // { rtti, refs, inherited fields..., own fields... }
  if (CI->Parent) {
    CI->Elements = CI->Parent->Elements;
    CI->FieldIndex = CI->Parent->FieldIndex;
    CI->FieldType = CI->Parent->FieldType;
  } else {
    CI->Elements = {llvm::PointerType::getUnqual(Context),
                    llvm::Type::getInt32Ty(Context)};
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
    CI->StaticImpl = CI->Parent->StaticImpl;
    CI->AllInterfaces = CI->Parent->AllInterfaces;
  }
  for (const auto &Name : CI->AST->getInterfaces()) {
    if (std::find(CI->AllInterfaces.begin(), CI->AllInterfaces.end(), Name) ==
        CI->AllInterfaces.end())
      CI->AllInterfaces.push_back(Name);
  }

  for (auto *F : *CI->AST) {
    auto *M = dynamic_cast<Method *>(F);
    if (!M)
      continue;
    const std::string MName = M->getName();
    // A static method gets no slot: there is no receiver to load one from.
    if (M->isStatic()) {
      CI->StaticImpl[MName] = {CI, M};
      continue;
    }
    // A constructor gets no slot either. It is always called on a known
    // class, and a subclass's constructor takes its own arguments, so a
    // shared slot would hold function pointers of two different types.
    if (MName == strings::Init) {
      CI->VTableImpl[MName] = {CI, M};
      continue;
    }
    if (CI->VTableIndex.count(MName)) {
      CI->VTableImpl[MName] = {CI, M}; // override reuses the parent's slot
    } else {
      CI->VTableIndex[MName] = static_cast<unsigned>(CI->VTableOrder.size());
      CI->VTableOrder.push_back(MName);
      CI->VTableImpl[MName] = {CI, M};
    }
  }

  // Each interface gets a run of slots at the end, holding this class's
  // implementations in the interface's own declaration order. A subclass
  // repeats its parent's runs rather than sharing them, so that a method it
  // overrides is the one the interface reaches.
  for (const auto &Name : CI->AllInterfaces) {
    ClassInfo *Iface = lookupClass(Name);
    if (!Iface)
      continue;
    CI->InterfaceBases.push_back(
        {Name, static_cast<unsigned>(CI->VTableOrder.size())});
    for (auto *F : *Iface->AST) {
      if (auto *M = dynamic_cast<Method *>(F))
        CI->VTableOrder.push_back(M->getName());
    }
  }
}

llvm::FunctionType *IRGenerator::methodType(ClassInfo *CI, Method *M) {
  std::vector<llvm::Type *> Params;
  // A static method has no receiver, so its parameters start at zero.
  if (!M->isStatic())
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
    else if (Name == strings::String) CI->RTTI = Runtime.stringRTTI();
    else
      // List and Integer are defined in runtime.c like the rest, so their
      // metadata is simply referenced here.
      CI->RTTI = llvm::cast<llvm::GlobalVariable>(
          Module.getOrInsertGlobal("R" + symbolName(Name), Runtime.rttiType()));
    return;
  }

  auto Ptr = llvm::PointerType::getUnqual(Context);
  auto I32 = llvm::Type::getInt32Ty(Context);

  if (isExternal(CI)) {
    // The module that owns this class defines @R<Class> and @N<Class>; here
    // they are only referenced. An external declaration carries no body, so
    // the vtable length does not matter to the linker.
    CI->NameGlobal = llvm::cast<llvm::GlobalVariable>(
        Module.getOrInsertGlobal("N" + symbolName(Name), Runtime.stringType()));
    CI->RTTI = llvm::cast<llvm::GlobalVariable>(
        Module.getOrInsertGlobal("R" + symbolName(Name), Runtime.rttiType()));
    return;
  }

  // @N<Class> : the class name as a TString, whose own rtti is @RString.
  auto *Chars = Builder.CreateGlobalString(Name, ".name." + Name,
                                           /*AddressSpace=*/0, &Module);
  // A reference count of zero: the class name is static, so free() on it is
  // a no-op rather than a call to free() on something malloc never returned.
  auto *NameInit = llvm::ConstantStruct::get(
      Runtime.stringType(),
      {Runtime.stringRTTI(), llvm::ConstantInt::get(I32, 0),
       llvm::ConstantInt::get(I32, static_cast<uint64_t>(Name.size())),
       llvm::cast<llvm::Constant>(Chars)});
  CI->NameGlobal = new llvm::GlobalVariable(
      Module, Runtime.stringType(), /*isConstant=*/false,
      llvm::GlobalValue::ExternalLinkage, NameInit, "N" + symbolName(Name));

  // The virtual table, as function pointers in slot order. An interface's
  // own methods have no implementation anywhere, so its table stops after
  // the slots it inherits from Object; nothing dispatches through it.
  size_t SlotCount = CI->VTableOrder.size();
  if (CI->IsInterface) {
    ClassInfo *ObjectCI = lookupClass(strings::Object);
    SlotCount = ObjectCI ? ObjectCI->VTableOrder.size() : 0;
  }

  std::vector<llvm::Constant *> Slots;
  for (size_t N = 0; N < SlotCount; ++N) {
    const std::string &MName = CI->VTableOrder[N];
    auto It = CI->VTableImpl.find(MName);
    ClassInfo *Owner = It->second.first;
    Method *M = It->second.second;
    const std::string Sym = runtimeSymbol(Owner, MName);
    auto Callee = Module.getOrInsertFunction(Sym, methodType(Owner, M));
    Slots.push_back(llvm::cast<llvm::Constant>(Callee.getCallee()));
  }

  // The interface table: one { interface rtti, base slot } per promise, with
  // a null entry to end it. A class that promises nothing has none.
  llvm::Constant *Interfaces = llvm::ConstantPointerNull::get(Ptr);
  if (!CI->InterfaceBases.empty()) {
    auto *EntryTy = llvm::StructType::get(Context, {Ptr, I32});
    std::vector<llvm::Constant *> Entries;
    for (const auto &Promise : CI->InterfaceBases) {
      ClassInfo *Iface = lookupClass(Promise.first);
      if (!Iface || !Iface->RTTI)
        fail(CI->AST->getLineNumber(),
             "interface '" + Promise.first + "' has no metadata yet; "
             "interfaces must be emitted first");
      Entries.push_back(llvm::ConstantStruct::get(
          EntryTy, {Iface->RTTI, llvm::ConstantInt::get(I32, Promise.second)}));
    }
    Entries.push_back(llvm::ConstantStruct::get(
        EntryTy, {llvm::ConstantPointerNull::get(Ptr),
                  llvm::ConstantInt::get(I32, 0)}));
    auto *TableTy = llvm::ArrayType::get(EntryTy, Entries.size());
    CI->IfaceTable = new llvm::GlobalVariable(
        Module, TableTy, /*isConstant=*/true, llvm::GlobalValue::PrivateLinkage,
        llvm::ConstantArray::get(TableTy, Entries), "F" + symbolName(Name));
    Interfaces = CI->IfaceTable;
  }
  auto *VTableTy = llvm::ArrayType::get(Ptr, Slots.size());

  // The RTTI record is a distinct struct per class because the vtable length
  // varies; __catmint_rtti declares it as a flexible [0 x ptr] member.
  auto *RTTITy = llvm::StructType::get(Context, {Ptr, I32, Ptr, Ptr, VTableTy});
  uint64_t Size = SizingLayout.getTypeAllocSize(CI->Ty);
  llvm::Constant *ParentRTTI =
      CI->Parent ? llvm::cast<llvm::Constant>(CI->Parent->RTTI)
                 : llvm::cast<llvm::Constant>(llvm::ConstantPointerNull::get(Ptr));
  auto *RTTIInit = llvm::ConstantStruct::get(
      RTTITy, {CI->NameGlobal, llvm::ConstantInt::get(I32, Size), ParentRTTI,
               Interfaces, llvm::ConstantArray::get(VTableTy, Slots)});
  CI->RTTI = new llvm::GlobalVariable(Module, RTTITy, /*isConstant=*/false,
                                      llvm::GlobalValue::ExternalLinkage,
                                      RTTIInit, "R" + symbolName(Name));
}

/// <Class>_init runs the parent initialiser and then this class's attribute
/// initialisers against an already-allocated, zeroed object.
bool IRGenerator::emitInitFunction(ClassInfo *CI) {
  if (CI->Builtin || CI->IsInterface)
    return true;

  const std::string Name = CI->AST->getName();
  auto Ptr = llvm::PointerType::getUnqual(Context);
  auto *FT = llvm::FunctionType::get(llvm::Type::getVoidTy(Context), {Ptr}, false);
  const std::string InitName = symbolName(Name) + "_init";

  if (isExternal(CI)) {
    // Declared, not defined: the initialiser is compiled with its own module.
    CI->Init = llvm::cast<llvm::Function>(
        Module.getOrInsertFunction(InitName, FT).getCallee());
    return true;
  }

  CI->Init = llvm::Function::Create(FT, llvm::GlobalValue::ExternalLinkage,
                                    InitName, &Module);

  auto *Entry = llvm::BasicBlock::Create(Context, "entry", CI->Init);
  Builder.SetInsertPoint(Entry);
  beginDebugScope(CI->Init, CI, InitName, CI->AST->getLineNumber());

  CurrentClass = CI;
  CurrentFunction = CI->Init;
  CurrentReturnType = strings::Void;
  OpenHandlers = 0;
  FunctionHasTry = false;
  Scopes.clear();
  Scopes.emplace_back();
  Pools.clear();
  beginPool();

  auto *SelfSlot = createEntryAlloca(Ptr, "self");
  Builder.CreateStore(CI->Init->getArg(0), SelfSlot);
  Scopes.back().Locals["self"] = {SelfSlot, Name};

  // Chain to the parent initialiser (Object_init / IO_init / String_init are
  // provided by the runtime; user parents get the one we generate).
  if (CI->Parent) {
    std::string ParentInit = symbolName(CI->Parent->AST->getName()) + "_init";
    auto Callee = Module.getOrInsertFunction(ParentInit, FT);
    Builder.CreateCall(Callee, {CI->Init->getArg(0)});
  }

  for (auto *F : *CI->AST) {
    auto *A = dynamic_cast<Attribute *>(F);
    if (!A)
      continue;

    if (!A->getInit()) {
      // An attribute of class type is constructed, exactly as a local of that
      // type is. There is no `new` in the grammar, so without this an
      // attribute could never hold an object and calling a method on it would
      // fail with a null receiver.
      //
      // The exception is an attribute whose type is the enclosing class or an
      // ancestor of it: constructing that would recurse forever. Such an
      // attribute starts null, which is what a linked structure wants anyway.
      ClassInfo *FieldClass = lookupClass(A->getType());
      if (!FieldClass || FieldClass->IsInterface ||
          isSubclassOf(CI->AST->getName(), A->getType()))
        continue;

      auto *Obj = constructObject(FieldClass, {}, A->getLineNumber(),
                                  A->getName() + ".obj");
      auto *Slot = Builder.CreateGEP(
          CI->Ty, CI->Init->getArg(0),
          {Builder.getInt32(0), Builder.getInt32(CI->FieldIndex[A->getName()])},
          A->getName() + ".addr");
      // The object was zeroed by __catmint_new, so there is nothing to
      // release; the field takes a reference of its own.
      storeReference(Obj, Slot, /*SlotIsLive=*/false);
      continue;
    }

    llvm::Value *V = emit(A->getInit());
    if (!V)
      continue;
    V = coerce(V, staticTypeOf(A->getInit()), A->getType(), A->getLineNumber());
    auto *Addr = Builder.CreateGEP(
        CI->Ty, CI->Init->getArg(0),
        {Builder.getInt32(0), Builder.getInt32(CI->FieldIndex[A->getName()])},
        A->getName() + ".addr");
    if (isReferenceTypeName(A->getType()))
      storeReference(V, Addr, /*SlotIsLive=*/false);
    else
      Builder.CreateStore(V, Addr);
  }

  if (!blockTerminated())
    emitCleanupAndReturn(nullptr);
  endPool(/*Reachable=*/false);
  endDebugScope();
  return true;
}

// ---------------------------------------------------------------------------
// Methods
// ---------------------------------------------------------------------------

namespace {
/// Whether a method body contains a try, which decides whether its locals
/// have to be read and written volatilely.
class TryFinder : public ASTVisitor {
public:
  // Overriding one visit would otherwise hide every other overload.
  using ASTVisitor::visit;

  bool Found = false;
  bool visit(TryStatement *T) override {
    Found = true;
    return ASTVisitor::visit(T);
  }
};
} // namespace

bool IRGenerator::emitMethod(ClassInfo *CI, Method *M) {
  const std::string Sym = mangle(CI->AST->getName(), M->getName());
  auto *F = Module.getFunction(Sym);
  if (!F)
    return false;
  if (!F->empty())
    return true; // already emitted

  auto *Entry = llvm::BasicBlock::Create(Context, "entry", F);
  Builder.SetInsertPoint(Entry);
  beginDebugScope(F, CI, CI->AST->getName() + "." + M->getName(),
                  M->getLineNumber());

  CurrentClass = CI;
  CurrentFunction = F;
  CurrentReturnType = M->getReturnType();
  OpenHandlers = 0;
  Scopes.clear();
  Scopes.emplace_back();

  TryFinder Finder;
  if (M->getBody())
    Finder.visit(M->getBody());
  FunctionHasTry = Finder.Found;

  // Everything this method allocates and does not keep is released when it
  // returns. A loop body opens a pool of its own so that a long loop does
  // not hold every temporary it ever made. Both are taken away again if
  // nothing inside them allocates.
  Pools.clear();
  beginPool();

  // self, then the declared parameters, each given a stack slot so that
  // assignment to a parameter works like assignment to any other local. A
  // static method has no self, and its parameters start at argument zero.
  auto Ptr = llvm::PointerType::getUnqual(Context);
  unsigned Idx = 0;
  if (!M->isStatic()) {
    auto *SelfSlot = createEntryAlloca(Ptr, "self");
    Builder.CreateStore(F->getArg(0), SelfSlot);
    Scopes.back().Locals["self"] = {SelfSlot, CI->AST->getName()};
    Idx = 1;
  }

  for (auto *P : *M) {
    auto *Slot = createEntryAlloca(lowerType(P->getType()), P->getName());
    // A parameter is an ordinary local from here on, so it is counted like
    // one: retained on the way in and released when the method ends. The
    // caller's own reference keeps it alive across the call either way, but
    // counting it means reassigning a parameter behaves like reassigning
    // anything else.
    if (isReferenceTypeName(P->getType()))
      storeReference(F->getArg(Idx), Slot, /*SlotIsLive=*/false);
    else
      Builder.CreateStore(F->getArg(Idx), Slot);
    Scopes.back().Locals[P->getName()] = {Slot, P->getType()};
    ++Idx;
  }

  llvm::Value *Body = M->getBody() ? emit(M->getBody()) : nullptr;

  if (!blockTerminated()) {
    if (M->getReturnType() == strings::Void || M->getReturnType() == "auto") {
      emitCleanupAndReturn(nullptr);
    } else {
      // catmint allows the last expression to be the result.
      llvm::Type *RT = lowerType(M->getReturnType());
      llvm::Value *RV = nullptr;
      if (Body && Body->getType() == RT) {
        RV = Body;
      } else if (RT->isPointerTy()) {
        RV = llvm::ConstantPointerNull::get(llvm::cast<llvm::PointerType>(RT));
      } else if (RT->isIntegerTy()) {
        RV = llvm::ConstantInt::get(RT, 0);
      } else {
        RV = llvm::ConstantFP::get(RT, 0.0);
      }
      emitCleanupAndReturn(RV);
    }
  }
  endPool(/*Reachable=*/false);
  if (FunctionHasTry) {
    makeLocalsVolatile(F);
    FunctionHasTry = false;
  }
  endDebugScope();
  return true;
}

/// The program entry point: hand the command line to the runtime, allocate a
/// Main, run its initialiser, call main.
void IRGenerator::emitProgramMain() {
  ClassInfo *MainCI = lookupClass(strings::MainClass);
  auto *I32 = llvm::Type::getInt32Ty(Context);
  auto Ptr = llvm::PointerType::getUnqual(Context);
  // main(int argc, char **argv), so that IO.args() and IO.arg(i) have
  // something to report. A program that never asks still pays nothing.
  auto *FT = llvm::FunctionType::get(I32, {I32, Ptr}, false);
  auto *F = llvm::Function::Create(FT, llvm::GlobalValue::ExternalLinkage,
                                   "main", &Module);
  auto *Entry = llvm::BasicBlock::Create(Context, "entry", F);
  Builder.SetInsertPoint(Entry);
  beginDebugScope(F, MainCI, "main", MainCI->AST->getLineNumber());

  auto SetArgs = Module.getOrInsertFunction(
      "__cm_setArgs",
      llvm::FunctionType::get(llvm::Type::getVoidTy(Context), {I32, Ptr},
                              false));
  Builder.CreateCall(SetArgs, {F->getArg(0), F->getArg(1)});

  Scopes.clear();
  Scopes.emplace_back();
  OpenHandlers = 0;
  Pools.clear();
  beginPool();

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

  endPool(/*Reachable=*/true);
  Builder.CreateRet(Builder.getInt32(0));
  endDebugScope();
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
  startDebugInfo();
  for (auto *CI : ClassOrder)
    declareMethods(CI);
  // Three passes, because a class's interface table points at the
  // interfaces' metadata and an interface's own points at Object's, while
  // ClassOrder only promises parents before children.
  for (auto *CI : ClassOrder)
    if (CI->Builtin)
      emitClassMetadata(CI);
  for (auto *CI : ClassOrder)
    if (CI->IsInterface && !CI->Builtin)
      emitClassMetadata(CI);
  for (auto *CI : ClassOrder)
    if (!CI->IsInterface && !CI->Builtin)
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

  // Without this the metadata is incomplete and the verifier rejects it.
  if (DI)
    DI->finalize();
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
    auto Found = It->Locals.find(Name);
    if (Found != It->Locals.end())
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

// ---------------------------------------------------------------------------
// Ownership
//
// Every allocation joins the open temporary pool and is released when that
// pool closes. What keeps an object past that is a reference of its own:
// storing into a variable, a field or a container retains, and leaving the
// scope releases. See the long note in runtime.c.
// ---------------------------------------------------------------------------

bool IRGenerator::isReferenceTypeName(const std::string &TypeName) {
  if (TypeName.empty() || TypeName == "auto" || TypeName == strings::Void ||
      TypeName == strings::Float || TypeTable::integerWidth(TypeName))
    return false;
  // Null is a reference, but a null needs no counting and no release.
  return TypeName != strings::Null;
}

void IRGenerator::emitRetain(llvm::Value *V) {
  if (!V || !V->getType()->isPointerTy())
    return;
  auto Retain = Module.getOrInsertFunction(
      "__cm_retain",
      llvm::FunctionType::get(llvm::Type::getVoidTy(Context),
                              {llvm::PointerType::getUnqual(Context)}, false));
  Builder.CreateCall(Retain, {V});
}

void IRGenerator::emitRelease(llvm::Value *V) {
  if (!V || !V->getType()->isPointerTy())
    return;
  auto Release = Module.getOrInsertFunction(
      "__cm_release",
      llvm::FunctionType::get(llvm::Type::getVoidTy(Context),
                              {llvm::PointerType::getUnqual(Context)}, false));
  Builder.CreateCall(Release, {V});
}

void IRGenerator::storeReference(llvm::Value *V, llvm::Value *Slot,
                                 bool SlotIsLive) {
  emitRetain(V);
  if (SlotIsLive) {
    auto *Old = Builder.CreateLoad(llvm::PointerType::getUnqual(Context), Slot,
                                   "old");
    emitRelease(Old);
  }
  Builder.CreateStore(V, Slot);
}

void IRGenerator::releaseScopes(unsigned Count) {
  unsigned Seen = 0;
  for (auto It = Scopes.rbegin(); It != Scopes.rend() && Seen < Count;
       ++It, ++Seen) {
    for (auto &Entry : It->Locals) {
      if (Entry.first == strings::Self)
        continue;
      if (!isReferenceTypeName(Entry.second.TypeName))
        continue;
      auto *V = Builder.CreateLoad(llvm::PointerType::getUnqual(Context),
                                   Entry.second.Addr, Entry.first + ".out");
      emitRelease(V);
    }
  }
}

void IRGenerator::emitPoolPushCall() {
  auto Push = Module.getOrInsertFunction(
      "__cm_poolPush",
      llvm::FunctionType::get(llvm::Type::getVoidTy(Context), {}, false));
  Builder.CreateCall(Push, {});
}

/// Opening a pool is speculative: the call is emitted now and taken out
/// again by endPool if nothing between the two allocated. Without this a
/// loop that only adds integers would pay two calls an iteration for a
/// mechanism it never uses, which measured as a sevenfold slowdown.
void IRGenerator::beginPool() {
  auto Push = Module.getOrInsertFunction(
      "__cm_poolPush",
      llvm::FunctionType::get(llvm::Type::getVoidTy(Context), {}, false));
  auto *Call = Builder.CreateCall(Push, {});
  Pools.push_back({Call, AllocationCount, {}});
}

void IRGenerator::endPool(bool Reachable) {
  PoolScope Scope = Pools.back();
  Pools.pop_back();

  // Nothing between the open and here could put anything in it, so both the
  // open and every close a return emitted for it come out again. An inner
  // pool that allocated has already moved the count, so an outer pool is
  // never removed while an inner one is kept.
  if (AllocationCount == Scope.AllocationsBefore) {
    for (auto *Pop : Scope.Pops)
      Pop->eraseFromParent();
    Scope.Push->eraseFromParent();
    return;
  }
  if (Reachable)
    emitPoolPopCall();
}

void IRGenerator::noteAllocation() { ++AllocationCount; }

llvm::CallInst *IRGenerator::emitPoolPopCall() {
  auto Pop = Module.getOrInsertFunction(
      "__cm_poolPop",
      llvm::FunctionType::get(llvm::Type::getVoidTy(Context), {}, false));
  return Builder.CreateCall(Pop, {});
}

/// Hand an object to the open pool, which will release it once. Paired with
/// a retain, this keeps a value alive past the scope that owned it without
/// making anything else responsible for it.
void IRGenerator::emitPoolAdd(llvm::Value *V) {
  if (!V || !V->getType()->isPointerTy())
    return;
  noteAllocation();
  auto Add = Module.getOrInsertFunction(
      "__cm_poolAdd",
      llvm::FunctionType::get(llvm::Type::getVoidTy(Context),
                              {llvm::PointerType::getUnqual(Context)}, false));
  Builder.CreateCall(Add, {V});
}

void IRGenerator::emitCleanupAndReturn(llvm::Value *RV) {
  const bool Reference = RV && RV->getType()->isPointerTy();

  // Retain first: everything below is about giving references back, and the
  // result must not be one of the things given back.
  if (Reference)
    emitRetain(RV);

  runDeferred(static_cast<unsigned>(Scopes.size()));
  releaseScopes(static_cast<unsigned>(Scopes.size()));
  popOpenHandlers();
  // Every pool open around this return is closed here. Each close is
  // remembered by its pool, so that a pool nothing used takes its closes
  // away along with its open.
  for (size_t N = Pools.size(); N-- > 0;)
    Pools[N].Pops.push_back(emitPoolPopCall());

  // The caller's pool now owns the balancing release, so the result is alive
  // for the caller's statement and nobody has to remember to free it. This
  // does not count as an allocation here: the object joins the caller's
  // pool, not this frame's.
  if (Reference) {
    auto Add = Module.getOrInsertFunction(
        "__cm_poolAdd",
        llvm::FunctionType::get(llvm::Type::getVoidTy(Context),
                                {llvm::PointerType::getUnqual(Context)},
                                false));
    Builder.CreateCall(Add, {RV});
  }

  if (RV)
    Builder.CreateRet(RV);
  else
    Builder.CreateRetVoid();
}

llvm::Value *IRGenerator::toCondition(llvm::Value *V, const std::string &Name) {
  if (V->getType()->isPointerTy())
    return Builder.CreateICmpNE(
        V, llvm::ConstantPointerNull::get(llvm::PointerType::getUnqual(Context)),
        Name);
  if (V->getType()->isDoubleTy())
    return Builder.CreateFCmpONE(
        V, llvm::ConstantFP::get(llvm::Type::getDoubleTy(Context), 0.0), Name);
  return Builder.CreateICmpNE(V, llvm::ConstantInt::get(V->getType(), 0), Name);
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

  if (auto *IC = dynamic_cast<IntConstant *>(E))
    return IC->fitsInInt() ? strings::Int : strings::Int64;
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
    if (BO->isComparison() || BO->isShortCircuit())
      return strings::Int;
    std::string L = staticTypeOf(BO->getLHS());
    std::string R = staticTypeOf(BO->getRHS());
    if (L == strings::String || R == strings::String)
      return strings::String; // '+' concatenates
    if (L == strings::Float || R == strings::Float)
      return strings::Float;
    const int LWidth = TypeTable::integerWidth(L);
    const int RWidth = TypeTable::integerWidth(R);
    if (LWidth && RWidth)
      return LWidth >= RWidth ? L : R;
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
  if (auto *FA = dynamic_cast<FieldAccess *>(E)) {
    if (auto *CI = lookupClass(staticTypeOf(FA->getObject()))) {
      auto It = CI->FieldType.find(FA->getField());
      if (It != CI->FieldType.end())
        return It->second;
    }
    return strings::Object;
  }
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
  if (dynamic_cast<TryStatement *>(E))          return strings::Void;
  if (dynamic_cast<ThrowStatement *>(E))        return strings::Void;
  if (dynamic_cast<DeferStatement *>(E))        return strings::Void;
  if (dynamic_cast<SpawnStatement *>(E))        return strings::Int;

  if (auto *D = dynamic_cast<Dispatch *>(E)) {
    if (ClassInfo *Target = staticReceiver(D)) {
      auto It = Target->StaticImpl.find(D->getName());
      if (It != Target->StaticImpl.end())
        return It->second.second->getReturnType();
    }
    if (!D->getObject() && CurrentClass &&
        !CurrentClass->VTableImpl.count(D->getName())) {
      auto It = CurrentClass->StaticImpl.find(D->getName());
      if (It != CurrentClass->StaticImpl.end())
        return It->second.second->getReturnType();
    }
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
    if (SD->getName() == "is")
      return strings::Int;
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

  const int FromWidth = TypeTable::integerWidth(From);
  const int ToWidth = TypeTable::integerWidth(To);

  // Between two integer types: sign-extend to widen, truncate to narrow. Both
  // directions are implicit, as they are in C, because the language has no
  // cast expression for numbers.
  if (FromWidth && ToWidth) {
    auto *Target = llvm::Type::getIntNTy(Context, static_cast<unsigned>(ToWidth));
    if (FromWidth == ToWidth)
      return V;
    return FromWidth < ToWidth ? Builder.CreateSExt(V, Target, "widen")
                               : Builder.CreateTrunc(V, Target, "narrow");
  }

  if (FromWidth && To == strings::String) {
    noteAllocation();
    // Int64 has its own conversion; the narrower widths go through Int.
    if (FromWidth == 64)
      return Builder.CreateCall(Runtime.longToString(), {V}, "long.str");
    V = coerce(V, From, strings::Int, Line);
    return Builder.CreateCall(Runtime.intToString(), {V}, "int.str");
  }
  if (From == strings::Float && To == strings::String) {
    noteAllocation();
    return Builder.CreateCall(Runtime.floatToString(), {V}, "float.str");
  }
  if (FromWidth && To == strings::Float)
    return Builder.CreateSIToFP(V, llvm::Type::getDoubleTy(Context), "int.fp");
  if (From == strings::Float && ToWidth)
    return Builder.CreateFPToSI(
        V, llvm::Type::getIntNTy(Context, static_cast<unsigned>(ToWidth)),
        "fp.int");
  const bool FromIsValue = (FromWidth != 0 || From == strings::Float);
  const bool ToIsValue = (ToWidth != 0 || To == strings::Float);

  // An integer put where object references live is boxed into an Integer, and
  // taken back out it is unboxed, checked. This is what lets a List hold
  // numbers when the language has no generics. The box holds 64 bits, so no
  // width loses anything on the way through.
  if (FromWidth && !ToIsValue && To != strings::Void) {
    noteAllocation();
    V = coerce(V, From, strings::Int64, Line);
    return Builder.CreateCall(Runtime.boxLong(), {V}, "box");
  }
  if (!FromIsValue && From != strings::Void && ToWidth) {
    auto *Boxed = Builder.CreateCall(Runtime.unboxLong(), {V}, "unbox");
    return coerce(Boxed, strings::Int64, To, Line);
  }

  // Reference types are all `ptr` under opaque pointers, so widening to a base
  // class needs no instruction. Narrowing does need one: assigning an Object
  // taken out of a container to a variable of a more specific type inserts a
  // checked downcast, which aborts at run time if the object is not of that
  // type. That keeps containers usable without cast syntax, at the cost of
  // the check being a run-time one.
  if (!FromIsValue && !ToIsValue) {
    ClassInfo *ToClass = lookupClass(To);
    if (ToClass && lookupClass(From) && isSubclassOf(To, From) && To != From)
      return Builder.CreateCall(Runtime.dynamicCast(), {V, ToClass->RTTI},
                                "downcast");
    // Into an interface the class does not visibly promise: the object may
    // still do it -- it may be a subclass, or have come out of a container --
    // so the runtime decides, and says so if it does not.
    if (ToClass && ToClass->IsInterface && lookupClass(From) &&
        !isSubclassOf(From, To))
      return Builder.CreateCall(Runtime.dynamicCast(), {V, ToClass->RTTI},
                                "as.iface");
  }
  return V;
}

// ---------------------------------------------------------------------------
// Expressions
// ---------------------------------------------------------------------------

llvm::Value *IRGenerator::emit(Expression *E) {
  if (!E || blockTerminated())
    return nullptr;

  // Every instruction from here on is attributed to this node's line, which
  // is what turns a crash into a file and a line.
  setDebugLine(E->getLineNumber());

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
  if (auto *N = dynamic_cast<FieldAccess *>(E))      return emitFieldAccess(N);
  if (auto *N = dynamic_cast<TryStatement *>(E))     return emitTry(N);
  if (auto *N = dynamic_cast<ThrowStatement *>(E))   return emitThrow(N);
  if (auto *N = dynamic_cast<DeferStatement *>(E))   return emitDefer(N);
  if (auto *N = dynamic_cast<SpawnStatement *>(E))   return emitSpawn(N);
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

  if (!blockTerminated()) {
    // The block's value may be one of the objects this scope is about to
    // release -- a method whose last expression names a local. Handing it to
    // the pool keeps it alive for the rest of the enclosing statement, which
    // is exactly as long as anyone can still be looking at it.
    if (Last && Last->getType()->isPointerTy()) {
      emitRetain(Last);
      emitPoolAdd(Last);
    }
    // Deferred work first: it almost always uses one of the locals that the
    // release below is about to let go of.
    runDeferred(1);
    releaseScopes(1);
  }
  Scopes.pop_back();
  return Last;
}

llvm::Value *IRGenerator::emitIntConstant(IntConstant *IC) {
  // A literal that does not fit in an Int is an Int64, which is the only way
  // to write a 64-bit value: arithmetic on two Ints stays 32 bits.
  if (!IC->fitsInInt())
    return llvm::ConstantInt::get(llvm::Type::getInt64Ty(Context),
                                  static_cast<uint64_t>(IC->getValue()), true);
  return Builder.getInt32(static_cast<int32_t>(IC->getValue()));
}

llvm::Value *IRGenerator::emitFloatConstant(FloatConstant *FC) {
  return llvm::ConstantFP::get(llvm::Type::getDoubleTy(Context),
                               static_cast<double>(FC->getValue()));
}

/// String literals become private TString globals rather than heap objects, so
/// evaluating one costs nothing at run time. Their reference count is zero,
/// which is what tells free() and release() to leave them alone.
llvm::Value *IRGenerator::makeStringLiteral(const std::string &Value) {
  auto *I32 = llvm::Type::getInt32Ty(Context);
  auto *Chars = Builder.CreateGlobalString(Value, ".str",
                                           /*AddressSpace=*/0, &Module);
  auto *Init = llvm::ConstantStruct::get(
      Runtime.stringType(),
      {Runtime.stringRTTI(), llvm::ConstantInt::get(I32, 0),
       llvm::ConstantInt::get(I32, static_cast<uint64_t>(Value.size())),
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
  if (Name == strings::Self) {
    if (auto *Self = selfValue())
      return Self;
    fail(S->getLineNumber(), "'self' is not available in a static method");
  }

  if (auto *L = findLocal(Name))
    return Builder.CreateLoad(lowerType(L->TypeName), L->Addr, Name);

  std::string FieldTy;
  if (auto *Addr = attributeAddress(Name, FieldTy))
    return Builder.CreateLoad(lowerType(FieldTy), Addr, Name);

  if (CurrentClass && CurrentClass->FieldIndex.count(Name) && !findLocal("self"))
    fail(S->getLineNumber(), "a static method cannot use the attribute '" +
                                 Name + "', which belongs to an instance");

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
          auto *Stored = coerce(V, InitTy, L->TypeName, LD->getLineNumber());
          if (isReferenceTypeName(L->TypeName))
            storeReference(Stored, L->Addr, /*SlotIsLive=*/true);
          else
            Builder.CreateStore(Stored, L->Addr);
          continue;
        }
        std::string FieldTy;
        if (auto *Addr = attributeAddress(Name, FieldTy)) {
          auto *Stored = coerce(V, InitTy, FieldTy, LD->getLineNumber());
          if (isReferenceTypeName(FieldTy))
            storeReference(Stored, Addr, /*SlotIsLive=*/true);
          else
            Builder.CreateStore(Stored, Addr);
        }
      }
      return V;
    }
  }

  ClassInfo *DeclClass = lookupClass(DeclaredType);
  // An interface names what a value can do, not what to make, so declaring
  // one produces a null reference waiting to be given an object.
  if (DeclClass && DeclClass->IsInterface)
    DeclClass = nullptr;
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
      auto *Obj = constructObject(DeclClass, {}, LD->getLineNumber(),
                                  Name + ".obj");
      storeReference(Obj, Slot, /*SlotIsLive=*/false);
    } else if (Lowered->isPointerTy()) {
      Builder.CreateStore(llvm::ConstantPointerNull::get(
                              llvm::PointerType::getUnqual(Context)),
                          Slot);
    } else if (DeclaredType == strings::Float) {
      Builder.CreateStore(
          llvm::ConstantFP::get(llvm::Type::getDoubleTy(Context), 0.0), Slot);
    } else {
      // The declared width, not Int's: an Int64 was being given a 32-bit
      // zero and then immediately overwritten.
      Builder.CreateStore(llvm::ConstantInt::get(Lowered, 0), Slot);
    }
    Scopes.back().Locals[Name] = {Slot, DeclaredType};
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
  //
  // `InitType == Object` is the container case: a value coming out of a List
  // is typed Object, and the declared type narrows it with a checked cast.
  // The last clause is the unboxing one, `Int n = list.get(i)`. Neither can be
  // confused with a folded statement, whose value is always some concrete
  // class such as IO.
  ClassInfo *DeclaredClass = lookupClass(DeclaredType);
  const bool Assignable =
      InitType == DeclaredType || isSubclassOf(InitType, DeclaredType) ||
      InitType == strings::Int || InitType == strings::Float ||
      InitType == strings::Null || InitType == strings::Object ||
      (DeclaredType == strings::Int && lookupClass(InitType) != nullptr) ||
      // An interface-typed variable takes any object; whether it really does
      // what the interface asks is settled at run time.
      (DeclaredClass && DeclaredClass->IsInterface &&
       lookupClass(InitType) != nullptr);
  if (Assignable) {
    llvm::Value *Stored = coerce(V, InitType, DeclaredType, LD->getLineNumber());
    if (Stored->getType() == Lowered) {
      // The slot already holds an object when the declaration constructed
      // one, and that one is being replaced.
      const bool SlotIsLive = (DeclClass != nullptr) && !InitIsComplete;
      for (auto *Slot : Slots) {
        if (isReferenceTypeName(DeclaredType))
          storeReference(Stored, Slot, SlotIsLive);
        else
          Builder.CreateStore(Stored, Slot);
      }
    }
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
    auto *Stored = coerce(V, FromType, L->TypeName, A->getLineNumber());
    if (isReferenceTypeName(L->TypeName))
      storeReference(Stored, L->Addr, /*SlotIsLive=*/true);
    else
      Builder.CreateStore(Stored, L->Addr);
    return V;
  }
  std::string FieldTy;
  if (auto *Addr = attributeAddress(Name, FieldTy)) {
    auto *Stored = coerce(V, FromType, FieldTy, A->getLineNumber());
    if (isReferenceTypeName(FieldTy))
      storeReference(Stored, Addr, /*SlotIsLive=*/true);
    else
      Builder.CreateStore(Stored, Addr);
    return V;
  }
  fail(A->getLineNumber(), "assignment to unknown identifier '" + Name + "'");
}

void IRGenerator::collectConcatenation(Expression *E,
                                       std::vector<Expression *> &Parts) {
  if (auto *BO = dynamic_cast<BinaryOperator *>(E)) {
    if (BO->getOperatorKind() == BinaryOperator::Add &&
        staticTypeOf(BO) == strings::String) {
      collectConcatenation(BO->getLHS(), Parts);
      collectConcatenation(BO->getRHS(), Parts);
      return;
    }
  }
  Parts.push_back(E);
}

/// `a + b + c` as one call instead of two, so the answer is allocated once
/// and the intermediate string nobody asked for is never made. Every
/// interpolated string is exactly this shape, which is why it is worth the
/// special case: it took building 400,000 strings from 0.098 s to 0.055 s.
llvm::Value *IRGenerator::emitConcatenation(BinaryOperator *BO) {
  if (BO->getOperatorKind() != BinaryOperator::Add ||
      staticTypeOf(BO) != strings::String)
    return nullptr;

  std::vector<Expression *> Parts;
  collectConcatenation(BO, Parts);
  if (Parts.size() < 3)
    return nullptr; // one concat is already one call

  auto Ptr = llvm::PointerType::getUnqual(Context);
  auto *ArrayTy = llvm::ArrayType::get(Ptr, Parts.size());
  auto *Array = createEntryAlloca(ArrayTy, "concat.parts");

  // Left to right, because that is the order the program wrote them in and
  // evaluating a part can have effects.
  for (size_t N = 0; N < Parts.size(); ++N) {
    const std::string From = staticTypeOf(Parts[N]);
    llvm::Value *V = emit(Parts[N]);
    if (!V)
      fail(BO->getLineNumber(), "a piece of a string join produced no value");
    V = coerce(V, From, strings::String, BO->getLineNumber());
    auto *Slot = Builder.CreateGEP(
        ArrayTy, Array,
        {Builder.getInt32(0), Builder.getInt32(static_cast<unsigned>(N))},
        "concat.part");
    Builder.CreateStore(V, Slot);
  }

  noteAllocation();
  auto ConcatAll = Module.getOrInsertFunction(
      "__cm_concatAll",
      llvm::FunctionType::get(Ptr, {Ptr, llvm::Type::getInt32Ty(Context)},
                              false));
  return Builder.CreateCall(
      ConcatAll,
      {Array, Builder.getInt32(static_cast<unsigned>(Parts.size()))},
      "concat");
}

llvm::Value *IRGenerator::emitBinaryOperator(BinaryOperator *BO) {
  // 'and' and 'or' come first, because the whole point of them is that the
  // right operand is not evaluated unless it has to be. Everything below
  // this evaluates both sides.
  if (BO->isShortCircuit()) {
    const bool IsAnd = BO->getOperatorKind() == BinaryOperator::AndAlso;

    llvm::Value *L = emit(BO->getLHS());
    if (!L)
      return nullptr;
    L = toCondition(L, IsAnd ? "and.lhs" : "or.lhs");

    auto *RHSBB = llvm::BasicBlock::Create(Context, IsAnd ? "and.rhs" : "or.rhs",
                                           CurrentFunction);
    auto *EndBB = llvm::BasicBlock::Create(Context, IsAnd ? "and.end" : "or.end",
                                           CurrentFunction);
    auto *EntryBB = Builder.GetInsertBlock();
    // 'and' needs the right side only when the left is true; 'or' only when
    // it is false.
    Builder.CreateCondBr(L, IsAnd ? RHSBB : EndBB, IsAnd ? EndBB : RHSBB);

    Builder.SetInsertPoint(RHSBB);
    llvm::Value *R = emit(BO->getRHS());
    if (!R)
      return nullptr;
    R = toCondition(R, IsAnd ? "and.rhs.v" : "or.rhs.v");
    auto *RHSExit = Builder.GetInsertBlock();
    Builder.CreateBr(EndBB);

    Builder.SetInsertPoint(EndBB);
    auto *Phi = Builder.CreatePHI(Builder.getInt1Ty(), 2,
                                  IsAnd ? "and.val" : "or.val");
    // Short-circuiting out of 'and' is false, out of 'or' is true.
    Phi->addIncoming(Builder.getInt1(!IsAnd), EntryBB);
    Phi->addIncoming(R, RHSExit);
    return Builder.CreateZExt(Phi, llvm::Type::getInt32Ty(Context),
                              IsAnd ? "and" : "or");
  }

  // A chain of concatenations is emitted as one call, before either side is
  // evaluated as an ordinary operand.
  if (auto *Joined = emitConcatenation(BO))
    return Joined;

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
    if (Op == BK::Add) {
      noteAllocation();
      return Builder.CreateCall(Runtime.stringConcat(), {LS, RS}, "concat");
    }
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

  // Two object references: identity would be wrong for strings and boxed
  // integers, so the runtime decides.
  if ((Op == BK::Equal || Op == BK::NotEqual) && L->getType()->isPointerTy() &&
      R->getType()->isPointerTy()) {
    auto *Eq = Builder.CreateCall(Runtime.objectEquals(), {L, R}, "objeq");
    if (Op == BK::Equal)
      return Eq;
    return Builder.CreateZExt(
        Builder.CreateICmpEQ(Eq, Builder.getInt32(0)),
        llvm::Type::getInt32Ty(Context), "objne");
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

  // Two integer operands of different widths meet at the wider of the two,
  // which LLVM requires anyway: an add of an i32 and an i64 is not typeable.
  const int LWidth = TypeTable::integerWidth(LT);
  const int RWidth = TypeTable::integerWidth(RT);
  std::string ResultType = strings::Int;
  if (LWidth && RWidth) {
    ResultType = LWidth >= RWidth ? LT : RT;
    L = coerce(L, LT, ResultType, BO->getLineNumber());
    R = coerce(R, RT, ResultType, BO->getLineNumber());
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
    // libm and stays in the integer domain. It runs at the width of the
    // promoted operands, so an Int64 base does not lose its high bits.
    llvm::Type *Wide = L->getType();
    auto *Acc = createEntryAlloca(Wide, "pow.acc");
    auto *Cnt = createEntryAlloca(Wide, "pow.n");
    Builder.CreateStore(llvm::ConstantInt::get(Wide, 1), Acc);
    Builder.CreateStore(R, Cnt);
    auto *Cond = llvm::BasicBlock::Create(Context, "pow.cond", CurrentFunction);
    auto *Body = llvm::BasicBlock::Create(Context, "pow.body", CurrentFunction);
    auto *End  = llvm::BasicBlock::Create(Context, "pow.end", CurrentFunction);
    Builder.CreateBr(Cond);
    Builder.SetInsertPoint(Cond);
    auto *N = Builder.CreateLoad(Wide, Cnt, "n");
    Builder.CreateCondBr(
        Builder.CreateICmpSGT(N, llvm::ConstantInt::get(Wide, 0)), Body, End);
    Builder.SetInsertPoint(Body);
    auto *A = Builder.CreateLoad(Wide, Acc, "acc");
    Builder.CreateStore(Builder.CreateMul(A, L, "acc.next"), Acc);
    Builder.CreateStore(
        Builder.CreateSub(N, llvm::ConstantInt::get(Wide, 1), "n.next"), Cnt);
    Builder.CreateBr(Cond);
    Builder.SetInsertPoint(End);
    return Builder.CreateLoad(Wide, Acc, "pow");
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
  return Builder.CreateZExt(Builder.CreateNot(toCondition(V, "notcmp"), "notv"),
                            llvm::Type::getInt32Ty(Context), "not");
}

llvm::Value *IRGenerator::emitIf(IfStatement *If) {
  llvm::Value *Cond = emit(If->getCond());
  if (!Cond)
    return nullptr;
  Cond = toCondition(Cond, "ifcond");

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
  Cond = toCondition(Cond, "whilecond");
  Builder.CreateCondBr(Cond, BodyBB, EndBB);

  Builder.SetInsertPoint(BodyBB);
  // One pool per iteration, so a loop that builds strings does not hold all
  // of them until the method returns.
  beginPool();
  (void)emit(W->getBody());
  const bool BodyFallsThrough = !blockTerminated();
  endPool(BodyFallsThrough);
  if (BodyFallsThrough)
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
  const bool OverList = (ContType == strings::List);
  if (!OverString && !OverList && !TypeTable::integerWidth(ContType))
    fail(F->getLineNumber(),
         "cannot iterate over a value of type '" + ContType +
             "'; 'for' takes an Int, a String or a List");

  llvm::Value *Cont = emit(F->getCont());
  if (!Cont)
    return nullptr;

  auto *I32 = llvm::Type::getInt32Ty(Context);
  auto Ptr = llvm::PointerType::getUnqual(Context);

  // The bound is the count itself, or the string's length.
  llvm::Value *Bound = Cont;
  llvm::Value *StrSlot = nullptr;
  if (OverList) {
    StrSlot = createEntryAlloca(Ptr, "for.list");
    Builder.CreateStore(Cont, StrSlot);
    auto ListLen = Module.getOrInsertFunction(
        "M4_List_len", llvm::FunctionType::get(I32, {Ptr}, false));
    Builder.CreateCall(Runtime.checkNull(), {Cont});
    Bound = Builder.CreateCall(ListLen, {Cont}, "for.count");
  } else if (OverString) {
    StrSlot = createEntryAlloca(Ptr, "for.str");
    Builder.CreateStore(Cont, StrSlot);
    auto StrLen = Module.getOrInsertFunction(
        "M6_String_length", llvm::FunctionType::get(I32, {Ptr}, false));
    Builder.CreateCall(Runtime.checkNull(), {Cont});
    Bound = Builder.CreateCall(StrLen, {Cont}, "for.len");
  } else {
    // A count of any integer width narrows to the loop counter's Int.
    Bound = coerce(Cont, ContType, strings::Int, F->getLineNumber());
  }

  auto *BoundSlot = createEntryAlloca(I32, "for.bound");
  Builder.CreateStore(Bound, BoundSlot);
  auto *IdxSlot = createEntryAlloca(I32, "for.idx");
  Builder.CreateStore(Builder.getInt32(0), IdxSlot);

  // The loop variable lives in its own scope, so it does not leak out and does
  // not collide with a variable of the same name outside the loop.
  Scopes.emplace_back();
  // A List holds object references, so the loop variable is an Object; assign
  // it to a typed variable to get the element back out.
  const std::string ElemType = OverList     ? strings::Object
                               : OverString ? strings::String
                                            : strings::Int;
  auto *VarSlot = createEntryAlloca(lowerType(ElemType), IterSym->getName());
  Scopes.back().Locals[IterSym->getName()] = {VarSlot, ElemType};
  // Cleared before the loop, so the first iteration's store has something
  // defined to release and the last iteration's value is released at the end.
  if (isReferenceTypeName(ElemType))
    Builder.CreateStore(llvm::ConstantPointerNull::get(Ptr), VarSlot);

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
  beginPool();
  if (OverList) {
    auto *List = Builder.CreateLoad(Ptr, StrSlot, "for.l");
    auto ListGet = Module.getOrInsertFunction(
        "M4_List_get", llvm::FunctionType::get(Ptr, {Ptr, I32}, false));
    storeReference(Builder.CreateCall(ListGet, {List, Idx}, "for.item"),
                   VarSlot, /*SlotIsLive=*/true);
  } else if (OverString) {
    // substring is a half-open range, so one character at i is [i, i+1).
    auto *Str = Builder.CreateLoad(Ptr, StrSlot, "for.s");
    auto *Next = Builder.CreateAdd(Idx, Builder.getInt32(1), "for.i1");
    noteAllocation();
    auto *Ch = Builder.CreateCall(Runtime.stringSubstring(), {Str, Idx, Next},
                                  "for.ch");
    storeReference(Ch, VarSlot, /*SlotIsLive=*/true);
  } else {
    Builder.CreateStore(Idx, VarSlot);
  }
  (void)emit(F->getBody());
  const bool BodyFallsThrough = !blockTerminated();
  endPool(BodyFallsThrough);
  if (BodyFallsThrough)
    Builder.CreateBr(StepBB);

  Builder.SetInsertPoint(StepBB);
  auto *Cur = Builder.CreateLoad(I32, IdxSlot, "for.i.cur");
  Builder.CreateStore(Builder.CreateAdd(Cur, Builder.getInt32(1), "for.i.next"),
                      IdxSlot);
  Builder.CreateBr(CondBB);

  Builder.SetInsertPoint(EndBB);
  runDeferred(1);
  releaseScopes(1);
  Scopes.pop_back();
  return nullptr;
}

/// Leaving a try by returning has to pop the handlers that were opened
/// around this point; otherwise the next throw jumps into a frame that has
/// already gone. The value is computed first, since computing it may itself
/// throw, and that throw should still find this try's handler.
void IRGenerator::popOpenHandlers() {
  if (OpenHandlers == 0)
    return;
  auto Pop = Module.getOrInsertFunction(
      "__cm_popHandler",
      llvm::FunctionType::get(llvm::Type::getVoidTy(Context), {}, false));
  for (unsigned N = 0; N < OpenHandlers; ++N)
    Builder.CreateCall(Pop, {});
}

llvm::Value *IRGenerator::emitReturn(ReturnExpression *R) {
  if (CurrentReturnType == strings::Void || CurrentReturnType == "auto" ||
      !R->getRet()) {
    emitCleanupAndReturn(nullptr);
    return nullptr;
  }
  llvm::Value *V = emit(R->getRet());
  if (!V) {
    emitCleanupAndReturn(nullptr);
    return nullptr;
  }
  // The conversion comes first, because it may itself allocate.
  V = coerce(V, staticTypeOf(R->getRet()), CurrentReturnType, R->getLineNumber());
  emitCleanupAndReturn(V);
  return nullptr;
}

/// Shared by dynamic and static dispatch. \p Virtual selects a vtable load;
/// otherwise the implementation is called directly.
llvm::Value *IRGenerator::emitCall(ClassInfo *RecvClass,
                                   const std::string &MethodName,
                                   llvm::Value *Receiver,
                                   const std::vector<Expression *> &Args,
                                   int Line, bool Virtual,
                                   const std::string &StaticClass,
                                   bool ReceiverKnown) {
  auto It = RecvClass->VTableImpl.find(MethodName);
  if (It == RecvClass->VTableImpl.end()) {
    if (RecvClass->StaticImpl.count(MethodName))
      fail(Line, "'" + MethodName + "' is a static method of '" +
                     RecvClass->AST->getName() + "'; call it on the class, as " +
                     RecvClass->AST->getName() + "." + MethodName + "(...)");
    fail(Line, "class '" + RecvClass->AST->getName() + "' has no method '" +
                   MethodName + "'");
  }

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

  // Every call checks its receiver, except when it is `self`: a method is
  // running, so the object it is running on exists. That is most calls in a
  // recursive or self-dispatching program, and the check was costing a call
  // and a branch each time.
  if (!ReceiverKnown)
    Builder.CreateCall(Runtime.checkNull(), {Receiver});

  // A method that returns a reference hands it to this frame's pool as it
  // leaves, so this frame needs one.
  if (isReferenceTypeName(M->getReturnType()))
    noteAllocation();

  // A method with no virtual table slot -- a constructor -- is always called
  // directly, whatever the call site asked for, and so is one that nothing
  // overrides.
  if (!Virtual || !RecvClass->VTableIndex.count(MethodName) ||
      canCallDirectly(RecvClass, MethodName)) {
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

  // Through an interface the slot is not known here: the object's class
  // decides where its run of interface slots begins, and the method's
  // position within the interface is added to that. Object's own methods are
  // at the same index in every class, so those still go straight to it.
  llvm::Value *SlotIndex = Builder.getInt32(Slot);
  ClassInfo *ObjectCI = lookupClass(strings::Object);
  const unsigned ObjectSlots =
      ObjectCI ? static_cast<unsigned>(ObjectCI->VTableOrder.size()) : 0;
  if (RecvClass->IsInterface && Slot >= ObjectSlots) {
    auto Base = Module.getOrInsertFunction(
        "__cm_ifaceBase",
        llvm::FunctionType::get(llvm::Type::getInt32Ty(Context), {Ptr, Ptr},
                                false));
    auto *Start =
        Builder.CreateCall(Base, {Receiver, RecvClass->RTTI}, "iface.base");
    SlotIndex = Builder.CreateAdd(Start, Builder.getInt32(Slot - ObjectSlots),
                                  "iface.slot");
  }

  auto *SlotAddr = Builder.CreateGEP(
      Runtime.rttiType(), RTTI,
      {Builder.getInt32(0), Builder.getInt32(4), SlotIndex},
      MethodName + ".slot");
  auto *Fn = Builder.CreateLoad(Ptr, SlotAddr, MethodName + ".fn");
  auto *Call = Builder.CreateCall(FT, Fn, CallArgs);
  return (M->getReturnType() == strings::Void ||
          M->getReturnType() == "auto") ? nullptr
                                        : static_cast<llvm::Value *>(Call);
}

/// The class a dispatch's receiver names, when the receiver is a class name
/// rather than a variable. A variable of the same name wins, so a program
/// that has both is not silently redirected.
ClassInfo *IRGenerator::staticReceiver(Dispatch *D) {
  auto *Sym = dynamic_cast<Symbol *>(D->getObject());
  if (!Sym || findLocal(Sym->getName()))
    return nullptr;
  if (CurrentClass && CurrentClass->FieldIndex.count(Sym->getName()))
    return nullptr;
  return lookupClass(Sym->getName());
}

/// A virtual table exists for the case where the answer is not known until
/// run time. When nothing overrides a method, it is known: the call goes
/// straight to the implementation, and the optimiser can then inline it,
/// which is what takes an array element access from a call to a load.
///
/// Only sound with the whole program in view. Compiling a module on its own,
/// or a program that imports separately compiled ones, leaves somewhere for
/// an override to hide, so this answers no there.
bool IRGenerator::canCallDirectly(ClassInfo *RecvClass,
                                  const std::string &MethodName) {
  if (LibraryOnly || !ExternalClasses.empty())
    return false;
  if (RecvClass->IsInterface)
    return false;

  auto It = RecvClass->VTableImpl.find(MethodName);
  if (It == RecvClass->VTableImpl.end())
    return false;
  ClassInfo *Chosen = It->second.first;

  const std::string &Base = RecvClass->AST->getName();
  for (auto &Entry : Classes) {
    ClassInfo *Candidate = &Entry.second;
    if (Candidate == RecvClass)
      continue;
    // Only classes below this one can change the answer.
    bool Below = false;
    for (auto *Up = Candidate->Parent; Up; Up = Up->Parent) {
      if (Up == RecvClass) {
        Below = true;
        break;
      }
    }
    if (!Below)
      continue;

    auto Other = Candidate->VTableImpl.find(MethodName);
    if (Other == Candidate->VTableImpl.end() || Other->second.first != Chosen)
      return false;
  }
  return true;
}

llvm::Value *IRGenerator::emitStaticCall(ClassInfo *Owner, Method *M,
                                         const std::vector<Expression *> &Args,
                                         int Line) {
  auto *FT = methodType(Owner, M);

  std::vector<llvm::Value *> CallArgs;
  auto ParamIt = M->begin();
  for (auto *Arg : Args) {
    const std::string FromTy = staticTypeOf(Arg);
    llvm::Value *V = emit(Arg);
    if (!V)
      fail(Line, "argument to '" + M->getName() + "' produced no value");
    if (ParamIt != M->end()) {
      V = coerce(V, FromTy, (*ParamIt)->getType(), Line);
      ++ParamIt;
    }
    CallArgs.push_back(V);
  }
  if (CallArgs.size() != FT->getNumParams())
    fail(Line, "wrong number of arguments to '" + M->getName() + "'");

  if (isReferenceTypeName(M->getReturnType()))
    noteAllocation();

  auto Callee =
      Module.getOrInsertFunction(runtimeSymbol(Owner, M->getName()), FT);
  auto *Call = Builder.CreateCall(Callee, CallArgs);
  return (M->getReturnType() == strings::Void || M->getReturnType() == "auto")
             ? nullptr
             : static_cast<llvm::Value *>(Call);
}

llvm::Value *IRGenerator::emitDispatch(Dispatch *D) {
  std::vector<Expression *> DispatchArgs;
  for (auto *A : *D)
    DispatchArgs.push_back(A);

  // A call on a class name: no receiver is evaluated at all.
  if (ClassInfo *Target = staticReceiver(D)) {
    auto It = Target->StaticImpl.find(D->getName());
    if (It == Target->StaticImpl.end())
      fail(D->getLineNumber(), "class '" + Target->AST->getName() +
                                   "' has no static method '" + D->getName() +
                                   "'");
    return emitStaticCall(It->second.first, It->second.second, DispatchArgs,
                          D->getLineNumber());
  }

  // A bare call may name one of this class's own static methods, which is
  // how one static calls another.
  if (!D->getObject() && CurrentClass) {
    auto It = CurrentClass->StaticImpl.find(D->getName());
    if (It != CurrentClass->StaticImpl.end() &&
        !CurrentClass->VTableImpl.count(D->getName()))
      return emitStaticCall(It->second.first, It->second.second, DispatchArgs,
                            D->getLineNumber());
  }

  std::string RecvType;
  llvm::Value *Receiver = nullptr;

  // A bare call, and a call written on `self`, both run on the object this
  // method is already running on, so there is nothing to check.
  auto *AsSymbol = dynamic_cast<Symbol *>(D->getObject());
  const bool OnSelf =
      !D->getObject() || (AsSymbol && AsSymbol->getName() == strings::Self);

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

  return emitCall(CI, D->getName(), Receiver, DispatchArgs, D->getLineNumber(),
                  /*Virtual=*/true, "", /*ReceiverKnown=*/OnSelf);
}

llvm::Value *IRGenerator::emitStaticDispatch(StaticDispatch *SD) {
  llvm::Value *Receiver = emit(SD->getObject());
  if (!Receiver)
    fail(SD->getLineNumber(), "receiver of '" + SD->getName() + "' produced no value");
  ClassInfo *CI = lookupClass(SD->getType());
  if (!CI)
    fail(SD->getLineNumber(), "unknown class '" + SD->getType() + "'");

  // 'expr is Type' walks the object's ancestry and answers 1 or 0. It never
  // aborts, which is what makes it usable as a guard before a downcast.
  if (SD->getName() == "is")
    return Builder.CreateCall(Runtime.isType(), {Receiver, CI->RTTI}, "istype");
  std::vector<Expression *> Args;
  for (auto *A : *SD)
    Args.push_back(A);
  auto *AsSymbol = dynamic_cast<Symbol *>(SD->getObject());
  const bool OnSelf = AsSymbol && AsSymbol->getName() == strings::Self;
  return emitCall(CI, SD->getName(), Receiver, Args, SD->getLineNumber(),
                  /*Virtual=*/false, SD->getType(), /*ReceiverKnown=*/OnSelf);
}

/// Three steps: allocate, run the attribute initialisers, run the constructor.
/// A constructor is an ordinary method named 'init', so it is called through
/// the same path as any other call and its arguments are converted against its
/// declared parameter types.
///
/// A plain declaration passes no arguments, and only a constructor that takes
/// none runs for it; declaring a variable of a class whose constructor needs
/// arguments leaves the object default-initialised, as it was before
/// constructors existed.
llvm::Value *IRGenerator::constructObject(ClassInfo *CI,
                                          const std::vector<Expression *> &Args,
                                          int Line, const std::string &Name) {
  noteAllocation();
  auto *Obj = Builder.CreateCall(Runtime.catmintNew(), {CI->RTTI}, Name);

  if (CI->Init) {
    Builder.CreateCall(CI->Init, {Obj});
  } else {
    auto *FT = llvm::FunctionType::get(llvm::Type::getVoidTy(Context),
                                       {llvm::PointerType::getUnqual(Context)},
                                       false);
    Builder.CreateCall(
        Module.getOrInsertFunction(symbolName(CI->AST->getName()) + "_init", FT),
        {Obj});
  }

  auto Ctor = CI->VTableImpl.find(strings::Init);
  if (Ctor == CI->VTableImpl.end()) {
    if (!Args.empty())
      fail(Line, "class '" + CI->AST->getName() + "' has no constructor");
    return Obj;
  }

  size_t Params = 0;
  for (auto *P : *Ctor->second.second) {
    (void)P;
    ++Params;
  }
  if (Args.size() != Params) {
    if (!Args.empty())
      fail(Line, "the constructor of '" + CI->AST->getName() + "' takes " +
                     std::to_string(Params) + " arguments");
    return Obj;
  }

  emitCall(CI, strings::Init, Obj, Args, Line, /*Virtual=*/false,
           CI->AST->getName());
  return Obj;
}

llvm::Value *IRGenerator::emitNewObject(NewObject *NO) {
  ClassInfo *CI = lookupClass(NO->getType());
  if (!CI)
    fail(NO->getLineNumber(), "cannot instantiate unknown class '" + NO->getType() + "'");
  if (CI->IsInterface)
    fail(NO->getLineNumber(), "'" + NO->getType() +
                                  "' is an interface and has no instances");

  std::vector<Expression *> Args;
  for (auto *A : *NO)
    Args.push_back(A);
  return constructObject(CI, Args, NO->getLineNumber(), "new." + NO->getType());
}

/// `a.b`, and `a.b = v` when the node carries a value. Both are one GEP into
/// the object's struct; the field index comes from the layout computed for the
/// object's static type, so an inherited field needs no special case -- a
/// subclass's layout starts with its parent's.
llvm::Value *IRGenerator::emitFieldAccess(FieldAccess *FA) {
  const std::string ObjType = staticTypeOf(FA->getObject());
  ClassInfo *CI = lookupClass(ObjType);
  if (!CI)
    fail(FA->getLineNumber(),
         "'" + ObjType + "' is not a class, so it has no field '" +
             FA->getField() + "'");

  auto Field = CI->FieldIndex.find(FA->getField());
  if (Field == CI->FieldIndex.end())
    fail(FA->getLineNumber(), "class '" + ObjType + "' has no field '" +
                                  FA->getField() + "'");
  const std::string FieldType = CI->FieldType[FA->getField()];

  llvm::Value *Object = emit(FA->getObject());
  if (!Object)
    fail(FA->getLineNumber(),
         "the object of '." + FA->getField() + "' produced no value");
  Builder.CreateCall(Runtime.checkNull(), {Object});

  auto *Addr = Builder.CreateGEP(
      CI->Ty, Object, {Builder.getInt32(0), Builder.getInt32(Field->second)},
      FA->getField() + ".addr");

  if (auto *Value = FA->getValue()) {
    const std::string FromType = staticTypeOf(Value);
    llvm::Value *V = emit(Value);
    if (!V)
      return nullptr;
    V = coerce(V, FromType, FieldType, FA->getLineNumber());
    if (isReferenceTypeName(FieldType))
      storeReference(V, Addr, /*SlotIsLive=*/true);
    else
      Builder.CreateStore(V, Addr);
    return V;
  }

  return Builder.CreateLoad(lowerType(FieldType), Addr, FA->getField());
}

// ---------------------------------------------------------------------------
// Errors
//
// try/catch/throw on setjmp and longjmp. There is nothing to unwind -- the
// language has no destructors -- so jumping over frames skips no work, and
// the path where nothing is thrown costs one setjmp per try.
// ---------------------------------------------------------------------------

llvm::Value *IRGenerator::emitTry(TryStatement *T) {
  auto Ptr = llvm::PointerType::getUnqual(Context);
  auto *I32 = llvm::Type::getInt32Ty(Context);
  auto *VoidTy = llvm::Type::getVoidTy(Context);

  // The jump buffer lives in this frame, because setjmp has to be called
  // from the frame it will return to. Its size is fixed by agreement with
  // CATMINT_JMPBUF_BYTES in runtime.c, which checks it at run time.
  auto *BufTy = llvm::ArrayType::get(Builder.getInt8Ty(), 512);
  auto *Buf = createEntryAlloca(BufTy, "try.buf");
  Buf->setAlignment(llvm::Align(16));

  auto Push = Module.getOrInsertFunction(
      "__cm_pushHandler", llvm::FunctionType::get(VoidTy, {Ptr}, false));
  auto Pop = Module.getOrInsertFunction(
      "__cm_popHandler", llvm::FunctionType::get(VoidTy, {}, false));
  auto CaughtFn = Module.getOrInsertFunction(
      "__cm_caught", llvm::FunctionType::get(Ptr, {}, false));

  // setjmp is called here rather than from a runtime helper, because a helper
  // would return before the longjmp ever arrived.
  auto SetJmp = Module.getOrInsertFunction(
      "setjmp", llvm::FunctionType::get(I32, {Ptr}, false));
  if (auto *SJ = llvm::dyn_cast<llvm::Function>(SetJmp.getCallee()))
    SJ->addFnAttr(llvm::Attribute::ReturnsTwice);

  // The handler's variable is cleared before the try is entered, so that the
  // store in the handler has something defined to release -- a try inside a
  // loop would otherwise see the previous iteration's value.
  auto *CaughtSlot = createEntryAlloca(Ptr, T->getCatchName());
  Builder.CreateStore(llvm::ConstantPointerNull::get(Ptr), CaughtSlot);

  Builder.CreateCall(Push, {Buf});
  auto *Code = Builder.CreateCall(SetJmp, {Buf}, "try.code");
  Code->addFnAttr(llvm::Attribute::ReturnsTwice);
  auto *Threw = Builder.CreateICmpNE(Code, Builder.getInt32(0), "try.threw");

  auto *BodyBB = llvm::BasicBlock::Create(Context, "try.body", CurrentFunction);
  auto *CatchBB = llvm::BasicBlock::Create(Context, "try.catch", CurrentFunction);
  auto *EndBB = llvm::BasicBlock::Create(Context, "try.end", CurrentFunction);
  Builder.CreateCondBr(Threw, CatchBB, BodyBB);

  Builder.SetInsertPoint(BodyBB);
  ++OpenHandlers;
  Scopes.emplace_back();
  (void)emit(T->getBody());
  Scopes.pop_back();
  --OpenHandlers;
  if (!blockTerminated()) {
    Builder.CreateCall(Pop, {});
    Builder.CreateBr(EndBB);
  }

  // Arriving here means a throw, which popped the handler on its way, so
  // there is nothing to pop and the next throw goes further out.
  Builder.SetInsertPoint(CatchBB);
  Scopes.emplace_back();
  storeReference(Builder.CreateCall(CaughtFn, {}, "caught"), CaughtSlot,
                 /*SlotIsLive=*/true);
  Scopes.back().Locals[T->getCatchName()] = {CaughtSlot, strings::Object};
  (void)emit(T->getHandler());
  Scopes.pop_back();
  if (!blockTerminated())
    Builder.CreateBr(EndBB);

  Builder.SetInsertPoint(EndBB);
  return nullptr;
}

/// Registering a defer emits nothing here: the expression is kept and
/// emitted at each point the enclosing block can be left.
llvm::Value *IRGenerator::emitDefer(DeferStatement *D) {
  if (Scopes.empty())
    fail(D->getLineNumber(), "'defer' outside any scope");
  Scopes.back().Deferred.push_back(D->getAction());
  return nullptr;
}

void IRGenerator::runDeferred(unsigned Count) {
  unsigned Seen = 0;
  for (auto It = Scopes.rbegin(); It != Scopes.rend() && Seen < Count;
       ++It, ++Seen) {
    // Last registered runs first, as everywhere else that has defer.
    for (auto Action = It->Deferred.rbegin(); Action != It->Deferred.rend();
         ++Action) {
      if (blockTerminated())
        return;
      (void)emit(*Action);
    }
  }
}

/// `spawn Class.method(argument)`: hand the method's address and the
/// argument to a thread rather than calling it. The semantic pass has
/// already made sure the method is one a thread can safely run -- static,
/// numbers in and out, and nothing in it that touches an object -- so there
/// is nothing to check here beyond finding it.
llvm::Value *IRGenerator::emitSpawn(SpawnStatement *S) {
  auto *Call = dynamic_cast<Dispatch *>(S->getCall());
  if (!Call)
    fail(S->getLineNumber(), "'spawn' needs a call to a static method");

  ClassInfo *Target = staticReceiver(Call);
  if (!Target)
    fail(S->getLineNumber(), "'spawn' needs a static method named on its class");

  auto Found = Target->StaticImpl.find(Call->getName());
  if (Found == Target->StaticImpl.end())
    fail(S->getLineNumber(), "class '" + Target->AST->getName() +
                                 "' has no static method '" + Call->getName() +
                                 "'");

  ClassInfo *Owner = Found->second.first;
  Method *M = Found->second.second;

  // The thread's entry point is long long (*)(long long), so the method's
  // own widths are adapted here rather than in the runtime.
  auto *I64 = llvm::Type::getInt64Ty(Context);
  auto Ptr = llvm::PointerType::getUnqual(Context);
  auto Entry = Module.getOrInsertFunction(runtimeSymbol(Owner, M->getName()),
                                          methodType(Owner, M));

  auto ArgIt = Call->begin();
  if (ArgIt == Call->end())
    fail(S->getLineNumber(), "a worker takes exactly one number");
  llvm::Value *Argument = emit(*ArgIt);
  if (!Argument)
    fail(S->getLineNumber(), "the argument to 'spawn' produced no value");
  Argument = coerce(Argument, staticTypeOf(*ArgIt), strings::Int64,
                    S->getLineNumber());

  auto Start = Module.getOrInsertFunction(
      "__cm_workerStart",
      llvm::FunctionType::get(llvm::Type::getInt32Ty(Context), {Ptr, I64},
                              false));
  return Builder.CreateCall(
      Start, {Entry.getCallee(), Argument}, "worker");
}

llvm::Value *IRGenerator::emitThrow(ThrowStatement *T) {
  const std::string From = staticTypeOf(T->getValue());
  llvm::Value *V = emit(T->getValue());
  if (!V)
    fail(T->getLineNumber(), "the value of a 'throw' produced nothing");
  // An Int is boxed here exactly as it is anywhere a reference is wanted.
  V = coerce(V, From, strings::Object, T->getLineNumber());

  auto Throw = Module.getOrInsertFunction(
      "__cm_throw",
      llvm::FunctionType::get(llvm::Type::getVoidTy(Context),
                              {llvm::PointerType::getUnqual(Context)}, false));
  auto *Call = Builder.CreateCall(Throw, {V});
  Call->setDoesNotReturn();
  Builder.CreateUnreachable();
  return nullptr;
}

void IRGenerator::makeLocalsVolatile(llvm::Function *F) {
  std::set<llvm::Value *> Allocas;
  for (auto &I : F->getEntryBlock())
    if (auto *A = llvm::dyn_cast<llvm::AllocaInst>(&I))
      Allocas.insert(A);

  for (auto &BB : *F) {
    for (auto &I : BB) {
      if (auto *L = llvm::dyn_cast<llvm::LoadInst>(&I)) {
        if (Allocas.count(L->getPointerOperand()))
          L->setVolatile(true);
      } else if (auto *S = llvm::dyn_cast<llvm::StoreInst>(&I)) {
        if (Allocas.count(S->getPointerOperand()))
          S->setVolatile(true);
      }
    }
  }
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
  noteAllocation();
  return Builder.CreateCall(Runtime.stringSubstring(), {Str, Start, End}, "substr");
}
