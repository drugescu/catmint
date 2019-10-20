#ifndef EXPRESSION_H_
#define EXPRESSION_H_

#include "TreeNode.h"
#include <string>

namespace catmint {
/// \brief AST node for an expression
///
/// This is the base class for all expressions in catmint
class Expression : public TreeNode {
public:
  explicit Expression(int lineNumber) : TreeNode(lineNumber) {}
};
}
#endif /* EXPRESSION_H_ */
