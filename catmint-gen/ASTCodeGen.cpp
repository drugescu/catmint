
#include <cassert>
#include <iostream>
#include <vector>

#include "ASTCodeGen.h"
#include "support/iterator.h"

using namespace llvm;
using namespace catmint;

LLVMContext &getMyLLVMGlobalContext() {
  static LLVMContext MyGlobalContext;
  return MyGlobalContext;
}

ASTCodeGen::ASTCodeGen(const char* module_name, Program* Prog, SemanticAnalysis * const Sema)
{
    static LLVMContext TheContext;

    //module = new Module(module_name, getGlobalContext());
    module = new Module(module_name, getMyLLVMGlobalContext());

    assert(Prog && "ASTCodeGen::Expected non-null program");

    program = Prog;
    module->setDataLayout("");
    
    ///\ Add other init
}

void ASTCodeGen::runCodeGeneration(const std::string &filename)
{
    assert(program && "runCodeGeneration::Expected non-null program");
    
    ///\ generate code
    visit(program);
    
    ///\ output pt debug -> LLVM IR
    //module->dump();
    module->print(llvm::errs(), nullptr);
    
    ///\ TODO output bytecode
}

bool ASTCodeGen::visit(Program *Prog)
{

    if (Prog->begin() == Prog->end())
        return true;

    ///\ generate types
    generateTypes();
    
    generateRuntimeFunctionPrototype();
    
    generate_catmint_new();

    ///\ startup prototype
    generateStartupPrototype();

    ///\ generate code for classes
    if (!ASTVisitor::visit(Prog))
        return false;
    
    ASTCodeGen::generateStartup();
    
    return true;
}


bool ASTCodeGen::visit(Class *c)
{
    ///\ nothing to do for IO/String/Object
    if ((c->getName().compare("IO") == 0) ||
        (c->getName().compare("String") == 0) ||
        (c->getName().compare("Object") == 0))
        return true;
    
    ///\ just Main -> trebuie sa fie generalizat pentru orice clasa
    if (c->getName().compare("Main") != 0)
        return true;

    setClass(c);
    
    ///\ types
    generateMain_Name_Type();
    
    ///\ generare constructor
    generateConstructor("Main");
    
    ///\ generare prototipuri
    for (auto Feature : *c)
    {
        if (auto M = dynamic_cast<Method *>(Feature))
        {
            generateFunctionPrototype(c, M);
        }
    }
    
    ///\ RTTI
    generateMain_RTTI();

    ///\ visit methods & attributes
    return ASTVisitor::visit(c);
}

bool ASTCodeGen::visit(Feature * f)
{
    return ASTVisitor::visit(f);
}
bool ASTCodeGen::visit(Attribute *attr)
{
    return true;
}

bool ASTCodeGen::visit(Method *m)
{
    std::string llvm_func_name = setLLVMmethodName(m);
    std::string type_name = "struct.T";
    type_name.append(getClass()->getName());
    
    
    llvm::StructType * self_type = module->getTypeByName(type_name);
    
    ///\ get Function
    llvm::Function *func = module->getFunction(llvm_func_name);
    const DataLayout &DL = func->getParent()->getDataLayout();
    llvm::Function::arg_iterator args = func->arg_begin();
    llvm::Value* ptr_self = args++;
    ptr_self->setName("self");
    
    assert(func && "Error: Nu s-a gasit prototipul functiei");
    BasicBlock* label_entry = BasicBlock::Create(module->getContext(), getBlockLabel(), func,0);
    setBasicBlock(label_entry);
    
    // self - camp adaugat clasei Method si initializat in constructor
    AllocaInst* ptr_stack = new AllocaInst(llvm::PointerType::get(self_type, 0), DL.getAllocaAddrSpace(), nullptr, "addr.self", label_entry);
    //AllocaInst* ptr_stack = new AllocaInst(self_type, ConstantInt::get(self_type, 0, true), "addr.self", label_entry);
    ptr_stack->setAlignment(8);
    
    ///\ salvam pointer la locatia de stiva care tine "self"
    setLLVMself(ptr_stack);

    ///\ store on stack - valoarea existenta in *self
    StoreInst* save_on_stack = new StoreInst(ptr_self, ptr_stack, false, label_entry);

    if (!ASTVisitor::visit(m))
    {
        printf("Error: generare de cod esuata :D\n");
        exit(1);
    }
    
    ///\ label_entry trebuie sa fie setata la current bb
    ReturnInst::Create(module->getContext(), label_entry);
    
    return true;
}

bool ASTCodeGen::visit(FormalParam *fp)
{
    return true;
}

bool ASTCodeGen::visit(Expression *e)
{
    return ASTVisitor::visit(e);
}

bool ASTCodeGen::visit(IntConstant *intConst)
{
    return true;
}

///\ conventie nume string-uri: ".str<index>"
bool ASTCodeGen::visit(StringConstant *str_const)
{
    std::string str_name = ".tstring_str1"; ///\ TODO - inlocuiti 1 cu index
    llvm::StructType *str_type = module->getTypeByName("struct.TString");
    llvm::StructType * struct_rString = module->getTypeByName("struct.RString");
    llvm::GlobalVariable *rString = getGlobal("RString");
    
    
    llvm::ArrayType* arr_type = ArrayType::get(IntegerType::get(module->getContext(), 8), (str_const->getValue()).length() + 1);
    GlobalVariable* var_array = new GlobalVariable(*module, arr_type, true, GlobalValue::PrivateLinkage,0, ".str1");
    var_array->setAlignment(1);
    GlobalVariable* var_tstring = new GlobalVariable(*module, str_type, false, GlobalValue::ExternalLinkage, 0, str_name);
    var_tstring->setAlignment(8);
    
    
    llvm::Constant *const_str = ConstantDataArray::getString(module->getContext(), str_const->getValue(), true);
    std::vector<llvm::Constant*> const_tstring_fields;
    const_tstring_fields.push_back(rString);
    ConstantInt* str_length = ConstantInt::get(module->getContext(),
                            APInt(32, StringRef(std::to_string(str_const->getValue().length())), 10));
    const_tstring_fields.push_back(str_length);
    std::vector<llvm::Constant*> str_indices;
    str_indices.push_back(ConstantInt::get(module->getContext(), APInt(32, StringRef("0"), 10)));
    str_indices.push_back(ConstantInt::get(module->getContext(), APInt(32, StringRef("0"), 10)));
    llvm::Constant* const_array = llvm::ConstantExpr::getGetElementPtr(arr_type, var_array, str_indices); // unsure
    const_tstring_fields.push_back(const_array);
    llvm::Constant* const_tstring = llvm::ConstantStruct::get(str_type, const_tstring_fields);
    

    var_array->setInitializer(const_str);
    var_tstring->setInitializer(const_tstring);

    str_const->setLLVMop(var_tstring);
    return true;
}

bool ASTCodeGen::visit(NullConstant *null_const)
{
    return true;
}

bool ASTCodeGen::visit(Block *b)
{
    ///\ create basic block
    ///\ BasicBlock* bb = BasicBlock::Create(module->getContext(), ....
    
    
    ///\ visit instructions
    return ASTVisitor::visit(b);
}

bool ASTCodeGen::visit(Assignment *a)
{

    return true;
}

bool ASTCodeGen::visit(catmint::BinaryOperator *binary_op)
{
    
	return true;
}

bool ASTCodeGen::visit(catmint::UnaryOperator *unaryOp)
{
	return true;
}

bool ASTCodeGen::visit(Cast *cast)
{
    return true;
}

bool ASTCodeGen::visit(Substring *substr)
{
    return true;
}

std::string ASTCodeGen::getLLVMmethodName(std::string func_name, std::string class_name)
{
    std::string llvm_func_name = "M";
    llvm_func_name.append(std::to_string(class_name.length()));
    llvm_func_name.append("_");
    llvm_func_name.append(class_name);
    llvm_func_name.append("_");
    llvm_func_name.append(func_name);

    return llvm_func_name;
}

bool ASTCodeGen::visit(Dispatch *dispatch)
{
    ///\ visit arguments
    if (auto object = dispatch->getObject())
    {
        ///\ TODO
        assert(object && "Dispatch doesn't have object");
        if (!visit(object))
            return false;
    }
    
    std::vector<llvm::Value*> ptr_call_params;
    llvm::Value*    param_value;

    llvm::AllocaInst * self = getLLVMself();
    assert(self && "Error: self not allocated\n");
    
    LoadInst* load_self = new LoadInst(self, "", false, getBasicBlock());
    
    // is_parent_call
    llvm::StructType * struct_TIO = module->getTypeByName("struct.TIO");
    llvm::PointerType* ptr_struct_TIO = PointerType::get(struct_TIO, 0);
    CastInst* cast_tio = new BitCastInst(load_self, ptr_struct_TIO, "", getBasicBlock());

    ptr_call_params.push_back(cast_tio);
    
    if (dispatch->begin() != dispatch->end())
    {
        for (auto arg : *dispatch)
        {
            if (!visit(arg))
                return false;
            
            param_value = arg->getLLVMop();
            LoadInst* load_param = new LoadInst(param_value, "", false, getBasicBlock());
            load_param->setAlignment(8);
            
            ptr_call_params.push_back(param_value);
        }
    }
 
    ///\ hardcodare - trebuie obtinuta din vtable
    llvm::Function * call_func = module->getFunction("M2_IO_out");
    CallInst* ptr_call = CallInst::Create(call_func, ptr_call_params, "call", getBasicBlock());
    ptr_call->setCallingConv(CallingConv::C);
    
    return true;
}

bool ASTCodeGen::visit(StaticDispatch *sdispatch)
{
    return true;
}

bool ASTCodeGen::visit(NewObject *new_object)
{
    return true;
}

bool ASTCodeGen::visit(IfStatement *if_stmt)
{
    ///\ Evaluate condition

    ///\ create if_then bb

    ///\ create if_else bb

    ///\ create exit_if_bb

    ///\ true codegen

    ///\ false codegen
    
    return true;
}

bool ASTCodeGen::visit(WhileStatement *while_stmt)
{
    ///\ create while cond BB

    ///\ create while body BB

    ///\ create while exit BB
    
    ///\ code gen condition

    ///\ code gen while body

    return true;
}

bool ASTCodeGen::visit(LocalDefinition *local_def)
{
	///\ generate alloca
    return true;
}

bool ASTCodeGen::visit(Symbol *sym)
{
    return true;
}

std::string ASTCodeGen::setLLVMmethodName(Method *m)
{
    std::string llvm_func_name = "M";
    llvm_func_name.append(std::to_string((getClass()->getName()).length()));
    llvm_func_name.append("_");
    llvm_func_name.append(getClass()->getName());
    llvm_func_name.append("_");
    llvm_func_name.append(m->getName());
    
    return llvm_func_name;

}

void ASTCodeGen::generateFunctionPrototype(Class *c, Method *method)
{
    std::string type_name = "struct.T";
    type_name.append(c->getName());
    std::string func_name = "M";
    func_name.append(std::to_string(c->getName().length()));
    func_name.append("_");
    func_name.append(c->getName());
    func_name.append("_");
    func_name.append(method->getName());
    
    StructType * type_struct = module->getTypeByName(type_name);
    assert(type_struct && "Error: tip nedefinit\n");
    
    ///\ de adaugat parametrii si tipul intors -> emite intotdeauna void func(self)
    PointerType* self = PointerType::get(type_struct, 0);
    FunctionType* func_type = FunctionType::get(llvm::Type::getVoidTy(module->getContext()),
                                                self, false);
    
    Function* func = Function::Create(func_type, GlobalValue::ExternalLinkage, func_name, module);
    func->setCallingConv(CallingConv::C);
    
}


void ASTCodeGen::generateConstructor(std::string name)
{
    ///\ declaratie
    std::string type_name = "struct.T";
    type_name.append(name);
    std::string ctor_name = name;
    ctor_name.append("_init");
    
    StructType * type_struct = module->getTypeByName(type_name);
    assert (type_struct && "Error: tip nedefinit");
    
    PointerType* self = PointerType::get(type_struct, 0);
    
    FunctionType* ctor_type = FunctionType::get(llvm::Type::getVoidTy(module->getContext()),
                                    self, false);

    Function* func_ctor = Function::Create(ctor_type, GlobalValue::ExternalLinkage, ctor_name, module);
    func_ctor->setCallingConv(CallingConv::C);
    
    const DataLayout &DL = func_ctor->getParent()->getDataLayout(); // func is the function, and getDataLayout is on a module

    ///\ definitie
    Function::arg_iterator args = func_ctor->arg_begin();
    Value* ptr_self = args++;
    ptr_self->setName("self");
    
    BasicBlock* label_entry = BasicBlock::Create(module->getContext(), "entry", func_ctor,0);
    
    // Block entry (label_entry)
    AllocaInst* ptr_self_addr = new AllocaInst(self, DL.getAllocaAddrSpace(), nullptr, "self.addr", label_entry); // modded
    ptr_self_addr->setAlignment(8);
    StoreInst* copy_self = new StoreInst(ptr_self, ptr_self_addr, false, label_entry);
    LoadInst* load_self = new LoadInst(ptr_self_addr, "", false, label_entry);
    
    ///\ cast to parent -> harcodat pt main
    StructType * struct_TIO = module->getTypeByName("struct.TIO");
    CastInst* cast_to_parent = new BitCastInst(load_self, PointerType::get(struct_TIO, 0), "", label_entry);
    CallInst* call_parent_ctor = CallInst::Create(module->getFunction("IO_init"), cast_to_parent, "", label_entry);
    call_parent_ctor->setCallingConv(CallingConv::C);
    
    ///\ de adaugat initializarea atributelor
    
    ReturnInst::Create(module->getContext(), label_entry);
    
    
}

///\ TO BE completed
///\ genereaza doar functiile care apar in tabela de runtime a clasei main
void ASTCodeGen::generateRuntimeFunctionPrototype()
{
    std::string name_TObject = "struct.TObject";
    StructType *struct_TObject = module->getTypeByName(name_TObject);
    std::string name_TString = "struct.TString";
    StructType *struct_TString = module->getTypeByName(name_TString);
    std::string name_TIO = "struct.TIO";
    StructType *struct_TIO = module->getTypeByName(name_TIO);
    
    //assert((struct_TString || struct_TObject || struct_TIO ) &&
    //       "Error: N-au fost gasite structurile de runtime\n");
    
    ///\ void func(TObject*)
    FunctionType* void_func_tobject = FunctionType::get(
                                        llvm::Type::getVoidTy(module->getContext()),
                                        PointerType::get(struct_TObject, 0),
                                        false);
    Function* func_M6_Object_abort = Function::Create(
                                        void_func_tobject,
                                        GlobalValue::ExternalLinkage,"M6_Object_abort", module);
    func_M6_Object_abort->setCallingConv(CallingConv::C);
    
    FunctionType* tstring_func_tobject = FunctionType::get(
                                          PointerType::get(struct_TString, 0),
                                          PointerType::get(struct_TObject, 0),
                                          false);
    Function* func_M6_Object_typeName = Function::Create(
                                        tstring_func_tobject,
                                        GlobalValue::ExternalLinkage,"M6_Object_typeName", module);
    func_M6_Object_typeName->setCallingConv(CallingConv::C);
    
    FunctionType* tobject_func_tobject = FunctionType::get(
                                        PointerType::get(struct_TObject, 0),
                                        PointerType::get(struct_TObject, 0),
                                        false);
    Function* func_M6_Object_copy = Function::Create(
                                        tobject_func_tobject,
                                        GlobalValue::ExternalLinkage, "M6_Object_copy", module);
    func_M6_Object_copy->setCallingConv(CallingConv::C);

    
    FunctionType* tstring_func_tio = FunctionType::get(
                                        PointerType::get(struct_TString, 0),
                                        PointerType::get(struct_TIO, 0),
                                        false);
    Function* func_M2_IO_in = Function::Create(
                                         tstring_func_tio,
                                         GlobalValue::ExternalLinkage, "M2_IO_in", module);
    func_M2_IO_in->setCallingConv(CallingConv::C);
    
    std::vector<llvm::Type*> M2_IO_out_args;
    M2_IO_out_args.push_back(llvm::PointerType::get(struct_TIO, 0));
    M2_IO_out_args.push_back(llvm::PointerType::get(struct_TString, 0));
    llvm::FunctionType* tio_func_tio_tstring = llvm::FunctionType::get(
                                        PointerType::get(struct_TIO, 0),
                                        M2_IO_out_args,
                                        false);
    llvm::Function* func_M2_IO_out = llvm::Function::Create(
                                        tio_func_tio_tstring,
                                        GlobalValue::ExternalLinkage,"M2_IO_out", module);
    func_M2_IO_out->setCallingConv(CallingConv::C);
    
    
    std::vector<llvm::Type*> func_IO_init_args;
    func_IO_init_args.push_back(llvm::PointerType::get(struct_TIO, 0));
    FunctionType* void_func_tio = FunctionType::get(
                                        llvm::Type::getVoidTy(module->getContext()),
                                        func_IO_init_args, false);
    Function* func_IO_init = Function::Create(
                                        void_func_tio,
                                        GlobalValue::ExternalLinkage, "IO_init", module);
    func_IO_init->setCallingConv(CallingConv::C);

}

void ASTCodeGen::generateMain_Name_Type()
{
    StructType * struct_TString = module->getTypeByName("struct.TString");

    ///\ TMain
    StructType *struct_TMain = StructType::create(module->getContext(), "struct.TMain");
    
    std::vector<llvm::Type*> struct_TMain_fields;
    StructType * struct_catmint_rtti = module->getTypeByName("struct.__lcpl_rtti");
    assert(struct_catmint_rtti && "ERROR Nu s-a gasit struct.__lcpl_rtti\n");
    
    struct_TMain_fields.push_back(llvm::PointerType::get(struct_catmint_rtti, 0));
    struct_TMain->setBody(struct_TMain_fields, false);
    
    ///\ generate NMain
    llvm::GlobalVariable* var_NMain = new llvm::GlobalVariable(*module, struct_TString, false,
                                GlobalValue::ExternalLinkage, 0, "NMain");
    var_NMain->setAlignment(8);
    
    
    llvm::Constant *const_name = llvm::ConstantDataArray::getString(module->getContext(), "Main", true);
    
    ArrayType* main_array = ArrayType::get(IntegerType::get(module->getContext(), 8), 5);
    GlobalVariable* main_str = new GlobalVariable(*module, main_array, true,
                            GlobalValue::ExternalLinkage, 0, "Main_str");
    main_str->setAlignment(1);
    
    std::vector<llvm::Constant*> const_nmain_fields;
    GlobalVariable *rString = (GlobalVariable*)getGlobal("RString");
    assert(rString && "Error: Nu s-a gasit variabila RString\n");
    const_nmain_fields.push_back(rString);
    
    ///\ length
    llvm::ConstantInt* const_length = llvm::ConstantInt::get(module->getContext(), APInt(32, StringRef("4"), 10));
    const_nmain_fields.push_back(const_length);
    
    std::vector<llvm::Constant*> name_indices;
    llvm::ConstantInt  *ct_idx = llvm::ConstantInt::get(module->getContext(), APInt(32, StringRef("0"), 10));
    name_indices.push_back(ct_idx);
    name_indices.push_back(ct_idx);
    

    ///\ name
    llvm::Constant* const_ptr_name = llvm::ConstantExpr::getGetElementPtr(main_array, main_str, name_indices); // modded - unsure
    const_nmain_fields.push_back(const_ptr_name);
    
    llvm::Constant* init_nmain = llvm::ConstantStruct::get(struct_TString, const_nmain_fields);
    
    main_str->setInitializer(const_name);
    var_NMain->setInitializer(init_nmain);
}
                                                           
void ASTCodeGen::generateMain_RTTI()
{
    StructType * struct_TString = module->getTypeByName("struct.TString");
    StructType * struct_catmint_rtti = module->getTypeByName("struct.__lcpl_rtti");

    llvm::PointerType* ptr_i8 = llvm::PointerType::get(IntegerType::get(module->getContext(), 8), 0);

    llvm::PointerType* ptr_struct_TString = llvm::PointerType::get(struct_TString, 0);
    llvm::PointerType* ptr_struct_lcpl_rtti = llvm::PointerType::get(struct_catmint_rtti, 0);
    
    std::vector<llvm::Type*> func_rtti_fields;
    func_rtti_fields.push_back(ptr_struct_TString);
    func_rtti_fields.push_back(IntegerType::get(module->getContext(), 32));
    func_rtti_fields.push_back(ptr_struct_lcpl_rtti);
    
    ArrayType* array_type = ArrayType::get(ptr_i8, 7);
    func_rtti_fields.push_back(array_type);
    StructType *func_rtti = StructType::get(module->getContext(), func_rtti_fields, false);
   
    ///\ R<Class> variable
    llvm::GlobalVariable* var_RMain = new GlobalVariable(*module, func_rtti,
                                    false, GlobalValue::ExternalLinkage, 0, "RMain");
    var_RMain->setAlignment(8);

    ///\ constante pentru a initializa variabila
    std::vector<llvm::Constant*> const_RMain_fields;

    GlobalVariable* var_nmain = (GlobalVariable*)getGlobal("NMain");
    GlobalVariable* var_rio = (GlobalVariable*)getGlobal("RIO");
    
    assert(var_nmain && "Eroare - variabila inexistenta\n");
    assert(var_rio && "Eroare - variabila inexistenta\n");
    
    const_RMain_fields.push_back(var_nmain);
    const_RMain_fields.push_back(llvm::ConstantInt::get(module->getContext(), APInt(32, StringRef("8"), 10)));
    const_RMain_fields.push_back(var_rio);
    
    ///\ ATENTIE: hardcodare urata, nu trebuie sa se regaseasca in tema finala
    std::vector<llvm::Constant*> Main_vtable;
    
    llvm::Function *ctor = module->getFunction("Main_init");
    llvm::Function *obj_abort = module->getFunction("M6_Object_abort");
    llvm::Function *obj_typeName = module->getFunction("M6_Object_typeName");
    llvm::Function *obj_copy = module->getFunction("M6_Object_copy");
    llvm::Function *io_in = module->getFunction("M2_IO_in");
    llvm::Function *io_out = module->getFunction("M2_IO_out");
    llvm::Function *main_main = module->getFunction("M4_Main_main");

//    assert( (ctor|| obj_abort || obj_typeName || obj_copy || io_in || io_out || main_main) &&
//           "Error: Functii nedeclarate\n");
    
    Main_vtable.push_back(llvm::ConstantExpr::getCast(Instruction::BitCast, ctor, ptr_i8));
    Main_vtable.push_back(llvm::ConstantExpr::getCast(Instruction::BitCast, obj_abort, ptr_i8));
    Main_vtable.push_back(llvm::ConstantExpr::getCast(Instruction::BitCast, obj_typeName, ptr_i8));
    Main_vtable.push_back(llvm::ConstantExpr::getCast(Instruction::BitCast, obj_copy, ptr_i8));
    Main_vtable.push_back(llvm::ConstantExpr::getCast(Instruction::BitCast, io_in, ptr_i8));
    Main_vtable.push_back(llvm::ConstantExpr::getCast(Instruction::BitCast, io_out, ptr_i8));
    Main_vtable.push_back(llvm::ConstantExpr::getCast(Instruction::BitCast, main_main, ptr_i8));
    llvm::Constant* vtable_array = llvm::ConstantArray::get(ArrayType::get(ptr_i8, 7), Main_vtable);
    
    const_RMain_fields.push_back(vtable_array);
 
    
    std::vector<llvm::Type*> rmain_fields;
    rmain_fields.push_back(llvm::PointerType::get(struct_TString, 0));
    rmain_fields.push_back(IntegerType::get(module->getContext(), 32));
    rmain_fields.push_back(llvm::PointerType::get(struct_catmint_rtti, 0));
    llvm::ArrayType* virtual_table = llvm::ArrayType::get(ptr_i8, 7);
    
    rmain_fields.push_back(virtual_table);
    llvm::StructType *rmain = StructType::get(module->getContext(), rmain_fields, false);
    
    llvm::Constant* const_RMain = llvm::ConstantStruct::get(rmain, const_RMain_fields);
    
    var_RMain->setInitializer(const_RMain);
}

///\ void func(void)
void ASTCodeGen::generateStartupPrototype()
{
    // Startup function prototype
    std::string func_name = "startup";
    llvm::Function* func_startup;

    std::vector<llvm::Type*> func_args; ///\ no arguments
    llvm::FunctionType* func_type = llvm:: FunctionType::get(llvm::Type::getVoidTy(module->getContext()),
                                func_args, false);
    
    func_startup = Function::Create(func_type, GlobalValue::ExternalLinkage, func_name, module);
    func_startup->setCallingConv(CallingConv::C);
}

void ASTCodeGen::generate_catmint_new()
{
    std::string catmint_rtti_name = "struct.__lcpl_rtti";
    StructType * catmint_rtti = module->getTypeByName(catmint_rtti_name);
    std::vector<llvm::Type*> func_args;
    func_args.push_back(llvm::PointerType::get(catmint_rtti, 0));
    
    llvm::FunctionType* func_type = llvm::FunctionType::get(
                            llvm::PointerType::get(IntegerType::get(module->getContext(), 8), 0),
                            func_args, false);
    
    llvm::Function* func___catmint_new = Function::Create(func_type,
                            GlobalValue::ExternalLinkage, "__lcpl_new", module);
    func___catmint_new->setCallingConv(CallingConv::C);
    
}

// Startup function and two structures, the RTTI and the main
void ASTCodeGen::generateStartup()
{
    llvm::Function* func_startup= module->getFunction("startup");
    llvm::StructType* struct_rtti = module->getTypeByName("struct.__lcpl_rtti");
    llvm::StructType* struct_tmain = module->getTypeByName("struct.TMain");

    assert(func_startup && "Error: No prototype for startup function\n");
    assert((struct_rtti || struct_tmain) && "Error: can't find struct defs\n");
    
    const DataLayout &DL = func_startup->getParent()->getDataLayout(); // func is the function, and getDataLayout is on a module

    BasicBlock* label_entry = BasicBlock::Create(module->getContext(), "startup_entry", func_startup,0);
    
    AllocaInst* ptr_main_obj = new AllocaInst(PointerType::get(struct_tmain, 0), DL.getAllocaAddrSpace(), nullptr, "main_obj", label_entry);
    ///\ define a void func(void) function to convert the function selected from the vtable
    llvm::FunctionType* void_func = llvm::FunctionType::get(llvm::Type::getVoidTy(module->getContext()),
                        llvm::PointerType::get(IntegerType::get(module->getContext(), 8), 0), false);
    PointerType* ptr_type_void_func = PointerType::get(void_func, 0);
    
    AllocaInst* ptr_function = new AllocaInst(ptr_type_void_func, DL.getAllocaAddrSpace(), nullptr, "function", label_entry);
    ptr_function->setAlignment(8);
    
    ///\ todo - de facut globala
    Constant* cast_RMain = ConstantExpr::getCast(llvm::Instruction::BitCast,
                        (GlobalVariable*)getGlobal("RMain"),llvm::PointerType::get(struct_rtti, 0));
    
    ///\ void* __lcpl_new(__lcpl_rtti*)
    CallInst* ptr_call = CallInst::Create(module->getFunction("__lcpl_new"), cast_RMain, "call", label_entry);
    ptr_call->setCallingConv(CallingConv::C);
    
    ///\ cast from void* to struct.TMain
    CastInst* cast_to_TMain = new BitCastInst(ptr_call, llvm::PointerType::get(struct_tmain, 0), "", label_entry);
    StoreInst* store_main_obj = new StoreInst(cast_to_TMain, ptr_main_obj, false, label_entry);
    
    
    ///\ get the index
    Constant* cast_RMain_rtti = ConstantExpr::getCast(Instruction::BitCast,
                            (GlobalVariable*)getGlobal("RMain"), PointerType::get(struct_rtti, 0));
    
    std::vector<Constant*> vtable_indices;
    vtable_indices.push_back(ConstantInt::get(module->getContext(), APInt(32, StringRef("0"), 10)));
    ///\ 3 = vtable position in rtti struct
    vtable_indices.push_back(ConstantInt::get(module->getContext(), APInt(32, StringRef("3"), 10)));
    ///\ 6 = vtable[6] = main
    vtable_indices.push_back(ConstantInt::get(module->getContext(), APInt(64, StringRef("6"), 10)));
    
    llvm::Constant* main_func = ConstantExpr::getGetElementPtr(PointerType::get(struct_rtti, 0), cast_RMain_rtti, vtable_indices); // unsure
    
    LoadInst* ptr_void_func = new LoadInst(main_func, "", false, label_entry);
    CastInst* ptr_main_func = new BitCastInst(ptr_void_func, ptr_type_void_func, "", label_entry);
    StoreInst* store_ptr_main_func = new StoreInst(ptr_main_func, ptr_function, false, label_entry);
    LoadInst* tmp_ptr = new LoadInst(ptr_function, "", false, label_entry);
    
    ///\ prepare param
    LoadInst* load_main_obj = new LoadInst(ptr_main_obj, "", false, label_entry);
    CastInst* cast_param = new BitCastInst(load_main_obj,
                            PointerType::get(IntegerType::get(module->getContext(), 8), 0), "", label_entry);
    CallInst* call_main = CallInst::Create(tmp_ptr, cast_param, "", label_entry);
    call_main->setCallingConv(CallingConv::C);
    
    ReturnInst::Create(module->getContext(), label_entry);
    
}

///\ return a global variable
llvm::GlobalVariable* ASTCodeGen::getGlobal(std::string globalName)
{
    llvm::Module::global_iterator globals_iter;
    llvm::GlobalVariable *gv;
    
    
    for(globals_iter = module->global_begin(); globals_iter != module->global_end(); globals_iter++)
    {
        //gv = (llvm::GlobalVariable*)globals_iter;
        gv = &(*globals_iter);
        if (globalName.compare(gv->getName()) == 0)
            return gv;
    }
    return NULL;
}

void ASTCodeGen::generateRuntimeTypes()
{
    ///\ __lcpl_rtti
    llvm::StructType * struct_catmint_rtti = llvm::StructType::create(module->getContext(), "struct.__lcpl_rtti");
    
    ///\ campuri __lcpl_rtti
    std::vector<llvm::Type*> struct_catmint_rtti_fields;
    
    ///\ definim structura TString
    llvm::StructType * struct_TString = module->getTypeByName("struct.TString");
    if (!struct_TString) {
        struct_TString = llvm::StructType::create(module->getContext(), "struct.TString");
    }
    
    ///\ campurile pentru TString
    std::vector<llvm::Type*>  struct_TString_fields;
    ///\ __lcpl_rtti *rtti
    llvm::PointerType* ptr_catmint_rtti = llvm::PointerType::get(struct_catmint_rtti, 0);
    struct_TString_fields.push_back(ptr_catmint_rtti);
    ///\ int length
    struct_TString_fields.push_back(IntegerType::get(module->getContext(), 32));
    ///\ char* string
    llvm::PointerType* ptr_i8 = llvm::PointerType::get(IntegerType::get(module->getContext(), 8), 0);
    struct_TString_fields.push_back(ptr_i8);
    
    if (struct_TString->isOpaque()) {
        struct_TString->setBody(struct_TString_fields, false);
    }
    
    
    ///\ campuri __lcpl_rtti
    ///\ TString * name
    llvm::PointerType* ptr_TString = llvm::PointerType::get(struct_TString, 0);
    struct_catmint_rtti_fields.push_back(ptr_TString);
    ///\ size_t size
    struct_catmint_rtti_fields.push_back(IntegerType::get(module->getContext(), 32));
    ///\ struct __lcpl_rtti *parent
    struct_catmint_rtti_fields.push_back(ptr_catmint_rtti);
    ///\ void* vtable[]
    llvm::ArrayType* array_methods = llvm::ArrayType::get(ptr_i8, 0);
    struct_catmint_rtti_fields.push_back(array_methods);
    
    if (struct_catmint_rtti->isOpaque()) {
        struct_catmint_rtti->setBody(struct_catmint_rtti_fields, false);
    }
    
    StructType * struct_TObject = StructType::create(module->getContext(), "struct.TObject");
    
    std::vector<llvm::Type*> struct_TObject_fields;
    struct_TObject_fields.push_back(ptr_catmint_rtti);
    if (struct_TObject->isOpaque()) {
        struct_TObject->setBody(struct_TObject_fields, false);
    }
    
    StructType * struct_TIO = StructType::create(module->getContext(), "struct.TIO");
    std::vector<llvm::Type*> struct_TIO_fields;
    struct_TIO_fields.push_back(ptr_catmint_rtti);
    if (struct_TIO->isOpaque()) {
        struct_TIO->setBody(struct_TIO_fields, false);
    }
    
}

void ASTCodeGen::generateRuntimeGlobalVars()
{
    StructType  * struct_catmint_rtti = module->getTypeByName("struct.__lcpl_rtti");
    
    GlobalVariable* rIO = new GlobalVariable(*module, struct_catmint_rtti, false,
                                GlobalValue::CommonLinkage, 0, "RIO");
    rIO->setAlignment(8);
    
    GlobalVariable* rString = new GlobalVariable(*module, struct_catmint_rtti, false,
                                GlobalValue::CommonLinkage, 0, "RString");
    rString->setAlignment(8);
    
    GlobalVariable* rObject = new GlobalVariable(*module, struct_catmint_rtti, false,
                                GlobalValue::CommonLinkage, 0, "RObject");
    rObject->setAlignment(8);
    
    ConstantAggregateZero* const_aggregate = ConstantAggregateZero::get(struct_catmint_rtti);
    
    rObject->setInitializer(const_aggregate);
    rString->setInitializer(const_aggregate);
    rIO->setInitializer(const_aggregate);
}


void ASTCodeGen::generateTypes ()
{
    ///\ runtime types
    generateRuntimeTypes();
    
    ///\ declaram ca variabile globale informatia de runtime pt Object, String, IO
    generateRuntimeGlobalVars();
    
    ///\ generate types for all defined classes
}
