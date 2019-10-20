#ifndef FORMALPARAM_H_
#define FORMALPARAM_H_

#include "TreeNode.h"

namespace catmint {
/// \brief AST node for a formal parameter in a method declaration
class FormalParam : public TreeNode {
public:
  explicit FormalParam(int lineNumber, const std::string &name,
                       const std::string &type)
      : TreeNode(lineNumber), name(name), type(type) {}

  std::string getName() const { return name; }
  std::string getType() const { return type; }

private:
  std::string name;
  std::string type;
};
}
#endif /* FORMALPARAM_H_ */
