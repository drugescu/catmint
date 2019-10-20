#ifndef CLASS_H_
#define CLASS_H_

#include <memory>
#include <string>
#include <utility>
#include <vector>

#include "Feature.h"
#include "Symbol.h"
#include "TreeNode.h"
#include "support/iterator.h"

namespace catmint {

class Attribute;
class Method;

/// \brief AST node for a class
class Class : public TreeNode {
  typedef std::vector<std::unique_ptr<Feature>> FeaturesType;

  struct iterator
      : public llvm::iterator_adaptor_base<iterator,
                                           FeaturesType::const_iterator> {
    explicit iterator(const FeaturesType::const_iterator &&wrapped)
        : iterator_adaptor_base(wrapped) {}
    Feature *operator*() const { return I->get(); }
  };

public:
  /// \brief Create a node for a class
  /// \note This will take ownership of the \p features, if provided
  explicit Class(int lineNumber, const std::string &name,
                 const std::string &parentClassName,
                 const std::vector<Feature *> &features = {})
      : TreeNode(lineNumber), name(name), parentClassName(parentClassName),
        features(), self(lineNumber, "self") {
    for (auto feature : features) {
      this->features.emplace_back(feature);
    }
  }

  std::string getName() const { return name; }
  std::string getParent() const { return parentClassName; }

  /// \brief Add a feature and take ownership of it
  void addFeature(std::unique_ptr<Feature> F) {
    features.push_back(std::move(F));
  }

  /// @{
  /// \brief Support for iterating through the features
  iterator begin() const { return iterator(features.begin()); }
  iterator end() const { return iterator(features.end()); }
  /// @}

  bool isSelf(Symbol *S) const { return S == &self; }
  Symbol *getSelf() { return &self; }

private:
  std::string name;
  std::string parentClassName;
  FeaturesType features;
  Symbol self;
};
}
#endif /* CLASS_H_ */
