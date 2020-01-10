#ifndef EXPRESSION_H_
#define EXPRESSION_H_

#include "TreeNode.h"
#include <string>

///\ code generation
#include <llvm/IR/Instructions.h>

namespace catmint {
/// \brief AST node for an expression
///
/// This is the base class for all expressions in catmint
class Expression : public TreeNode {
private:
    llvm::Value *LLVMop;            ///\ code generation

public:
  explicit Expression(int lineNumber) : TreeNode(lineNumber) {}

  void setLLVMop(llvm::Value * op) { LLVMop = op; }
  llvm::Value* getLLVMop() { return LLVMop; }
  
  //TreeNode* clone() const { return new TreeNode(*this); };
};
}
#endif /* EXPRESSION_H_ */
