#ifndef IR_GENERATOR_H
#define IR_GENERATOR_H

#include "ASTVisitor.h"
#include "SymbolTable.h"
#include "TypeTable.h"

#include "llvm/ADT/ArrayRef.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"
#include "llvm/ADT/APInt.h"

namespace llvm {
  class Function;
  class StructType;
  class Value;
}

namespace catmint {

/// Helper class for dealing with the types and functions in the catmint runtime
class RuntimeInterface {
public:
  RuntimeInterface(llvm::Module &M);

  llvm::StructType *rttiType() const { return RTTIType; }
  llvm::StructType *stringType() const { return StringType; }
  llvm::StructType *objectType() const { return ObjectType; }
  llvm::StructType *ioType() const { return IOType; }

  llvm::Value *stringRTTI() const { return RString; }
  llvm::Value *ioRTTI() const { return RIO; }

  llvm::Function *ioOut() const { return IO_out; }
  llvm::Function *lcplNew() const { return LCPLNew; }

private:
  llvm::StructType *RTTIType;
  llvm::StructType *StringType;
  llvm::StructType *ObjectType;
  llvm::StructType *IOType;

  llvm::Value *RString;
  llvm::Value *RIO;

  llvm::Function *IO_out;

  llvm::Function *LCPLNew;
};

class IRGenerator : public ASTVisitor {
public:
  IRGenerator(llvm::StringRef ModuleName, Program *P, const TypeTable &ASTTypes,
              SymbolMap DefinitionsMap);
  virtual ~IRGenerator() {}

  llvm::Module *runGenerator();
  llvm::GlobalVariable* getGlobal(std::string globalName);

private:
  llvm::LLVMContext Context;
  llvm::Module Module;

  llvm::Function *CurrentFunction;

  llvm::IRBuilder<> Builder;

  /// AST to IR mapping
  llvm::DenseMap<TreeNode *, llvm::Value *> NodeMap;

  const RuntimeInterface Runtime;

  Program *AST;
  const TypeTable ASTTypes;
  const SymbolMap DefinitionsMap;

  using ASTVisitor::visit;

  int firstPass = true;

  bool visit(Program *P) override;
  bool visit(Class *C) override;

  bool visit(Method *M) override;

  bool visit(Block *B) override;

  bool visit(Dispatch *D) override;

  bool visit(StringConstant *SC) override;
};
} // namespace catmint

#endif
