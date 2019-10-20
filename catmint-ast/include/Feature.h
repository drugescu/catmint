#ifndef FEATURE_H_
#define FEATURE_H_

#include <string>

#include "TreeNode.h"

namespace catmint {
/// \brief AST node for a class feature
///
/// Base class for class features (methods and attributes)
class Feature : public TreeNode {
public:
  explicit Feature(int lineNumber, const std::string &name)
      : TreeNode(lineNumber), name(name) {}
  virtual ~Feature() {}

  std::string getName() const { return name; }

  virtual bool isMethod() const { return false; }
  virtual bool isAttribute() const { return false; }

protected:
  std::string name;
};
}
#endif /* FEATURE_H_ */
