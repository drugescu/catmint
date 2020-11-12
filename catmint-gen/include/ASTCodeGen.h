#ifndef ASTCODEGEN_H
#define ASTCODEGEN_H


#include <llvm/IR/Type.h>
#include <llvm/IR/DerivedTypes.h>
#include <llvm/IR/Function.h>
#include <llvm/IR/LLVMContext.h>
#include <llvm/IR/PassManager.h>
#include <llvm/IR/Instructions.h>
#include <llvm/IR/CallingConv.h>
//#include <llvm/Bitcode/ReaderWriter.h>
#include <llvm/Bitcode/BitcodeReader.h>
#include <llvm/Bitcode/BitcodeWriter.h>
#include <llvm/IR/Verifier.h>
#include <llvm/IR/IRPrintingPasses.h>
#include <llvm/Support/FormattedStream.h>
#include <llvm/IR/IRBuilder.h>
#include <llvm/IR/Module.h>
#include <llvm/Support/TargetSelect.h>
#include <llvm/ExecutionEngine/GenericValue.h>
#include <llvm/ExecutionEngine/MCJIT.h>
#include <llvm/Support/raw_ostream.h>
#include <llvm/Target/TargetMachine.h>

#include "ASTVisitor.h"
#include "Program.h"
#include "SemanticAnalysis.h"

//using namespace llvm;


namespace catmint
{

class RuntimeInterface {
public:
  RuntimeInterface(llvm::Module &M);

  llvm::StructType *rttiType() const { return RTTIType; }
  llvm::StructType *stringType() const { return StringType; }
  llvm::StructType *ioType() const { return IOType; }

  llvm::Value *stringRTTI() const { return RString; }
  llvm::Value *ioRTTI() const { return RIO; }

  llvm::Function *ioOut() const { return IO_out; }
  llvm::Function *lcplNew() const { return LCPLNew; }

private:
  llvm::StructType *RTTIType;
  llvm::StructType *StringType;
  llvm::StructType *IOType;

  llvm::Value *RString;
  llvm::Value *RIO;

  llvm::Function *IO_out;

  llvm::Function *LCPLNew;
};

class ASTCodeGen : public ASTVisitor
{
public:
    ASTCodeGen(const char* module_name, Program* Prog, SemanticAnalysis * const Sema);
    virtual ~ASTCodeGen(){}
    
    void runCodeGeneration(const std::string &filename);

    
    
private:
  llvm::Module *module;
  llvm::LLVMContext TheContext;
  Program *program;
  
  ///\ aux
  int BlockID;
  llvm::BasicBlock    *crtBasicBlock;
  llvm::Function      *crtFunction;
  llvm::AllocaInst    *crtSelf;
  catmint::Class         *crtClass;

  bool visit(Program *P) override;
  bool visit(Class *C) override;
  bool visit(Feature * f) override;
  bool visit(Attribute *F) override;
	bool visit(Method *M) override;
	bool visit(FormalParam *F) override;

	bool visit(Expression *E) override;

	bool visit(IntConstant *IC) override;
	bool visit(StringConstant *SC) override;
	bool visit(NullConstant *NC) override;
	bool visit(Symbol *Sym) override;

	bool visit(Block *B) override;
	bool visit(Assignment* A) override;
	bool visit(BinaryOperator *BO) override;
	bool visit(UnaryOperator *UO) override;
	bool visit(Cast *C) override;
	bool visit(Substring *S) override;
	bool visit(Dispatch *D) override;
	bool visit(StaticDispatch *SD) override;
	bool visit(NewObject *NO) override;
	bool visit(IfStatement *If) override;
	bool visit(WhileStatement *While) override;
	bool visit(LocalDefinition *Local) override;

  void generateTypes ();
  void generateRuntimeTypes();
  void generateRuntimeGlobalVars();
  void generateFunctionPrototype(Method * m);
  void generateStartupPrototype();
  void generateStartup();
  void generate_catmint_new();
  void generateRuntimeFunctionPrototype();
  void generateFunctionPrototype(Class *c, Method *method);
  
  void generateConstructor(std::string class_name);
  llvm::GlobalVariable* DeclareGlobalRttiVar(std::string name);
  llvm::GlobalVariable* DefineGlobalStringConst(std::string name);
  llvm::GlobalVariable* getGlobal(std::string globalName);
  std::string getLLVMmethodName(std::string, std::string);
  std::string setLLVMmethodName(Method *m);
  
  void generateMain_Name_Type();
  void generateMain_RTTI();
  
  RuntimeInterface Runtime;

  std::string getBlockLabel() { BlockID++; return std::string("block" + std::to_string(BlockID)); }
  
  llvm::BasicBlock* getBasicBlock() {return crtBasicBlock; }
  void setBasicBlock(llvm::BasicBlock * bb) { crtBasicBlock = bb; }

  llvm::Function  * getFunction() { return crtFunction; }
  void setFunction(llvm::Function * func) { crtFunction = func; }

  void setLLVMself(llvm::AllocaInst* alloc_inst) {crtSelf = alloc_inst; }
  llvm::AllocaInst * getLLVMself() {return crtSelf; }
  
  catmint::Class* getClass() {return crtClass; }
  void setClass(catmint::Class * cls) { crtClass = cls; }

    
};

} ///\ end namespace

#endif
