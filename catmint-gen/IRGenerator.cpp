#include "IRGenerator.h"
#include "StringConstants.h"

#include <cassert>

using namespace catmint;

RuntimeInterface::RuntimeInterface(llvm::Module &M) {
  auto &Context = M.getContext();

  RTTIType = llvm::StructType::create(Context, "struct.__catmint_rtti");
  StringType = llvm::StructType::create(Context, "struct.TString");
  ObjectType = llvm::StructType::create(Context, "struct.TObject");
  IOType = llvm::StructType::create(Context, "struct.TIO");

  auto RTTIPtrType = RTTIType->getPointerTo();
  auto StrPtrType = StringType->getPointerTo();
  auto ObjPtrType = ObjectType->getPointerTo();
  auto IOPtrType = IOType->getPointerTo();

  auto IntType = llvm::IntegerType::getInt32Ty(Context);
  auto VoidPtrType = llvm::IntegerType::getInt8PtrTy(Context);

  /* __catmint_rtti =
      struct TString* name;
      int size;
      struct __catmint_rtti *parent;
      void* vtable[]; */
  RTTIType->setBody({StrPtrType, IntType, RTTIPtrType,
                    llvm::ArrayType::get(VoidPtrType, 0) });

  /*   struct TString { struct __catmint_rtti *rtti; int length; char *string; }; */
  StringType->setBody({RTTIPtrType, IntType, llvm::Type::getInt8PtrTy(Context) });

  /*   struct TIO { struct __catmint_rtti *rtti; } */
  llvm::Type *IOTypeFields[] = { RTTIPtrType };
  IOType->setBody(IOTypeFields);

  /*   struct TObject { struct __catmint_rtti *rtti; } */
  ObjectType->setBody({ RTTIPtrType });

  RString = M.getOrInsertGlobal("RString", RTTIType);
  RIO = M.getOrInsertGlobal("RIO", RTTIType);

  llvm::Type *IOOutParamTypes[] = { IOPtrType, StrPtrType };
  llvm::Type *IOInParamTypes[] = { IOPtrType };
  IO_out = llvm::cast<llvm::Function>(M.getOrInsertFunction(
      "M2_IO_out", llvm::FunctionType::get(IOPtrType, IOOutParamTypes, false)).getCallee());
  IO_in = llvm::cast<llvm::Function>(M.getOrInsertFunction(
      "M2_IO_in", llvm::FunctionType::get(IOPtrType, IOInParamTypes, false)).getCallee());
  CatmintNew = llvm::cast<llvm::Function>(M.getOrInsertFunction(
      "__catmint_new", llvm::FunctionType::get(VoidPtrType, RTTIPtrType, false)).getCallee());
}

IRGenerator::IRGenerator(llvm::StringRef ModuleName, Program *P,
                         const TypeTable &ASTTypes, SymbolMap DefinitionsMap)
    : Context(), Module(ModuleName, Context), Builder(Context), Runtime(Module),
      AST(P), ASTTypes(ASTTypes), DefinitionsMap(std::move(DefinitionsMap)) {}

llvm::Module *IRGenerator::runGenerator() {

  firstPass = true;

  if (!visit(AST))
    return nullptr;

  return &Module;
}

///\ return a global variable
llvm::GlobalVariable* IRGenerator::getGlobal(std::string globalName)
{
    llvm::Module::global_iterator globals_iter;
    llvm::GlobalVariable *gv;
    
    for(globals_iter = Module.global_begin(); globals_iter != Module.global_end(); globals_iter++)
    {
        gv = &(*globals_iter);
        if (globalName.compare(gv->getName()) == 0)
            return gv;
    }
    return NULL;
}

bool IRGenerator::visit(Program *P) {
  for (auto C : *P) {
    if (!visit(C)) {
      return false;
    }
  }

  // Generate the startup code: a main function which should instantiate a
  // 'Main' object and invoke its 'main' method
  std::string FunctionName("main");
  assert(!Module.getFunction(FunctionName) && "Function already exists!");

  auto FunctionType =
      llvm::FunctionType::get(llvm::IntegerType::getInt32Ty(Context), false);
  CurrentFunction = llvm::cast<llvm::Function>(
      Module.getOrInsertFunction(FunctionName, FunctionType).getCallee());
  assert(CurrentFunction && "Failed to create function");

  auto CurrentBlock = llvm::BasicBlock::Create(Context, "", CurrentFunction);
  assert(CurrentBlock && "Failed to create basic block");

  Builder.SetInsertPoint(CurrentBlock);

  // TODO: We're abusively declaring Main::main as void(void) - it should take a
  // parameter representing 'self'
  // Declare struct TMAIN and make the main module be that type
  /*llvm::StructType *struct_TMain = llvm::StructType::create(Context, "struct.TMain");
  llvm::StructType * struct_TString = Module.getTypeByName("struct.TString");
  std::vector<llvm::Type*> struct_TMain_fields;
  llvm::StructType * struct_catmint_rtti = Module.getTypeByName("struct.__lcpl_rtti");
  llvm::GlobalVariable* var_NMain = new llvm::GlobalVariable(Module, struct_TString, false,
                              llvm::GlobalValue::ExternalLinkage, 0, "NMain");
  var_NMain->setAlignment(8);
  llvm::Constant *const_name = llvm::ConstantDataArray::getString(Context, "Main", true);
  llvm::ArrayType* main_array = llvm::ArrayType::get(llvm::IntegerType::get(Context, 8), 5);
  llvm::GlobalVariable* main_str = new llvm::GlobalVariable(Module, main_array, true,
                            llvm::GlobalValue::ExternalLinkage, 0, "Main_str");
  main_str->setAlignment(1);
  std::vector<llvm::Constant*> const_nmain_fields;
  llvm::GlobalVariable* grString = new llvm::GlobalVariable(Module, struct_catmint_rtti, false,
                                llvm::GlobalValue::CommonLinkage, 0, "RString");
  grString->setAlignment(8);
  llvm::GlobalVariable *rString = (llvm::GlobalVariable*)getGlobal("RString");
  const_nmain_fields.push_back(rString);
  llvm::ConstantInt* const_length = llvm::ConstantInt::get(Context, llvm::APInt(32, llvm::StringRef("4"), 10));
  const_nmain_fields.push_back(const_length);
  std::vector<llvm::Constant*> name_indices;
  llvm::ConstantInt  *ct_idx = llvm::ConstantInt::get(Context, llvm::APInt(32, llvm::StringRef("0"), 10));
  llvm::ConstantInt  *ct_idx2 = llvm::ConstantInt::get(Context, llvm::APInt(32, llvm::StringRef("0"), 10));
  name_indices.push_back(ct_idx);
  name_indices.push_back(ct_idx2);
  llvm::Constant* const_ptr_name = llvm::ConstantExpr::getGetElementPtr(main_array, main_str, name_indices); // modded - unsure
  const_nmain_fields.push_back(const_ptr_name);
  llvm::Constant* init_nmain = llvm::ConstantStruct::get(struct_TString, const_nmain_fields);
  main_str->setInitializer(const_name);
  var_NMain->setInitializer(init_nmain);*/

  //llvm::StructType * type_struct = Module.getTypeByName("struct.TMain");
  //auto* self = llvm::PointerType::get(type_struct, 0);
  //auto* func_type = llvm::FunctionType::get(llvm::Type::getVoidTy(Context), self, false);
  auto MainMethod = llvm::cast<llvm::Function>(Module.getOrInsertFunction(
          "M4_Main_main",
          //func_type).getCallee());
          llvm::FunctionType::get(llvm::Type::getVoidTy(Context), false)).getCallee());
  (void)Builder.CreateCall(MainMethod);
  (void)Builder.CreateRet(Builder.getInt32(0));
  return true;
}

bool IRGenerator::visit(Class *C) {
  // TODO: For now we're only processing the 'Main' class; remove this check
  // when you're ready to process other classes in the program
  if (C->getName() != strings::MainClass) {
    return true;
  }

  return ASTVisitor::visit(C);
}

bool IRGenerator::visit(Method *M) {
  // TODO: For now we're only processing the 'main' method; remove this check
  // when you're ready to process other methods
  if (M->getName() != strings::MainMethod) {
    return true;
  }

  // TODO: Generalize this piece of code to handle other methods
  std::string FunctionName("M4_Main_main");
  assert(!Module.getFunction(FunctionName) && "Function already exists");

  // TODO: We're abusively declaring Main::main as void(void) - it should take a
  // parameter representing 'self'
  CurrentFunction = llvm::Function::Create(
      llvm::FunctionType::get(llvm::Type::getVoidTy(Context), false),
      llvm::GlobalValue::ExternalLinkage, "M4_Main_main", &Module);
  assert(CurrentFunction && "Failed to create function");

  if (!visit(M->getBody())) {
    return false;
  }

  (void)Builder.CreateRetVoid();

  return true;
}

bool IRGenerator::visit(Block *B) {

  auto CurrentBlock = llvm::BasicBlock::Create(Context, "entry_block", CurrentFunction); // add insert before here
  assert(CurrentBlock && "Failed to create basic block");

  if (!firstPass) {
    llvm::BranchInst *end = Builder.CreateBr(CurrentBlock);
  }
  else {
    firstPass = false;
  }

  Builder.SetInsertPoint(CurrentBlock);

  // Create string
  auto StringType = Runtime.stringType();
  auto RString = Runtime.stringRTTI();
  auto New = Runtime.catmintNew();
  auto NewString = Builder.CreateBitCast(Builder.CreateCall(New, {RString}),
                                         StringType->getPointerTo());
  std::string StringValue("Hello World!\n");
  auto LengthField =
      Builder.CreateGEP(NewString, {Builder.getInt32(0), Builder.getInt32(1)});
  (void)Builder.CreateStore(Builder.getInt32(StringValue.length()),
                            LengthField);
  auto StringField =
      Builder.CreateGEP(NewString, {Builder.getInt32(0), Builder.getInt32(2)});
  (void)Builder.CreateStore(Builder.CreateGlobalStringPtr(StringValue),
                            StringField);
  // Create a new IO object and bitcast from void* to IO*
  auto RIO = Runtime.ioRTTI();
  //auto New = Runtime.catmintNew();
  auto IOType = Runtime.ioType();
  auto NewIO = Builder.CreateBitCast(Builder.CreateCall(New, RIO),
                                     IOType->getPointerTo());
  auto IO_out = Runtime.ioOut();
  //auto hello = Builder.CreateGlobalStringPtr(llvm::StringRef("Hello, world!\n"));
  /* Create String */
  llvm::Value *OutArgs[] = { NewIO, NewString };
  (void)Builder.CreateCall(IO_out, OutArgs);
    // Create a string and add it to the arguments of a future puts function
  

  /*llvm::Value *helloWorld = Builder.CreateGlobalStringPtr("hello world!\n");
  std::vector<llvm::Type *> putsArgs;
  putsArgs.push_back(Builder.getInt8Ty()->getPointerTo());
  llvm::ArrayRef<llvm::Type*>  argsRef(putsArgs);
 
  // We find the puts function, should already be defined
  llvm::FunctionType *putsType = 
  llvm::FunctionType::get(Builder.getInt32Ty(), argsRef, false);
  auto funcCallee = Module.getOrInsertFunction("puts", putsType);
  llvm::Value *putsFunc = funcCallee.getCallee();
  // Create a call to puts with the aforementioned string
  Builder.CreateCall(putsFunc, helloWorld);*/

  //(void)Builder.CreateRetVoid(); // exterraneous
  //llvm::BranchInst *end = Builder.CreateBr(CurrentBlock);

  if (!ASTVisitor::visit(B)) {
    return false;
  }

  return true;
}

bool IRGenerator::visit(Dispatch *D) {
  // TODO: We're only handling dispatches into the 'out' method, which we
  // hardcode to IO::out; remove this check when you're ready to handle other
  // dynamic dispatches
  if (D->getName() != "out") {
    //return true;
  }

  for (auto Arg : *D) {
    if (!visit(Arg)) {
      return false;
    }
  }

  // TODO: Because we're not taking a 'self' object as parameter yet, we'll have
  // to create a new IO object here to pass into the IO::out method. You should
  // update this after implementing 'self'.
  if (D->getName() == "out") {
    // Get the Value generated for the first (and only) argument
    // TODO: Generalize this to handle more than one argument
    auto OutputString = NodeMap[*D->begin()];
    if (!OutputString) {
      return true;
    }

    auto IOType = Runtime.ioType();
    auto RIO = Runtime.ioRTTI();
    auto New = Runtime.catmintNew();

    // Create a new IO object and bitcast from void* to IO*
    auto NewIO = Builder.CreateBitCast(Builder.CreateCall(New, RIO),
                                      IOType->getPointerTo());

    auto IO_out = Runtime.ioOut();
    llvm::Value *OutArgs[] = { NewIO, OutputString };

    (void)Builder.CreateCall(IO_out, OutArgs);
  }
  else if (D->getName() == "input") {
    auto IOType = Runtime.ioType();
    auto RIO = Runtime.ioRTTI();
    auto New = Runtime.catmintNew();

    // Create a new IO object and bitcast from void* to IO*
    auto NewIO = Builder.CreateBitCast(Builder.CreateCall(New, RIO),
                                      IOType->getPointerTo());

    auto IO_in = Runtime.ioIn();
    llvm::Value *OutArgs[] = { NewIO };

    (void)Builder.CreateCall(IO_in, OutArgs);
    
  }

  return true;
}

bool IRGenerator::visit(StringConstant *SC) {
  // Create a new String object and bitcast from void* to String*, then write
  // the value of the StringConstant into it in several steps:
  // * Write the length of the string into the new String object
  // * Create the storage for the string
  // * Write the pointer to the storage into the new String object
  auto StringType = Runtime.stringType();
  auto RString = Runtime.stringRTTI();
  auto New = Runtime.catmintNew();

  auto NewString = Builder.CreateBitCast(Builder.CreateCall(New, {RString}),
                                         StringType->getPointerTo());
  std::string StringValue(SC->getValue());

  auto LengthField =
      Builder.CreateGEP(NewString, {Builder.getInt32(0), Builder.getInt32(1)});
  (void)Builder.CreateStore(Builder.getInt32(StringValue.length()),
                            LengthField);

  auto StringField =
      Builder.CreateGEP(NewString, {Builder.getInt32(0), Builder.getInt32(2)});
  (void)Builder.CreateStore(Builder.CreateGlobalStringPtr(StringValue),
                            StringField);

  NodeMap[SC] = NewString;

  return true;
}
