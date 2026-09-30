#ifndef CLASS_H_
#define CLASS_H_

#include <memory>
#include <string>
#include <utility>
#include <vector>
#include <algorithm>

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

  /// The source file this class was written in. A module spliced in by the
  /// preprocessor keeps its own name here, so debug information points at the
  /// file the programmer wrote rather than at the concatenated text.
  std::string getFile() const { return fileName; }
  void setFile(const std::string &file) { fileName = file; }

  /// The interfaces this class declares it implements, with `does`. An
  /// interface itself implements none.
  const std::vector<std::string> &getInterfaces() const { return interfaces; }
  void setInterfaces(const std::vector<std::string> &names) {
    interfaces = names;
  }

  /// True for a class declared with `interface`: a set of method signatures
  /// with no bodies, no attributes and no instances.
  bool isInterface() const { return interfaceDeclaration; }
  void setInterface(bool value) { interfaceDeclaration = value; }

  /// True for a class the compiler supplies rather than one the program
  /// wrote: Object, IO, String and the rest. Set where they are declared, so
  /// that nothing has to keep a list of their names in step.
  bool isBuiltin() const { return builtinDeclaration; }
  void setBuiltin(bool value) { builtinDeclaration = value; }

  /// True for `extern class`: a list of C functions, with no bodies, no
  /// fields and no instances. Its methods keep their names unmangled,
  /// because the symbol already exists in some library.
  bool isExtern() const { return externDeclaration; }
  void setExtern(bool value) { externDeclaration = value; }

  /// `extern struct` and `extern union`: a C layout, fields only. Instances
  /// are counted catmint objects whose payload is the C bytes -- owned and
  /// inline, or a view of bytes C owns.
  bool isCStruct() const { return cKind != 0; }
  bool isCUnion() const { return cKind == 2; }
  void setCKind(int kind) { cKind = kind; }
  int getCKind() const { return cKind; }
  /// The size `@ n` after the name asserts, or -1 when there is none.
  int getAssertedSize() const { return assertedSize; }
  void setAssertedSize(int size) { assertedSize = size; }
  /// No fields and no asserted size: known only by pointer, never made here.
  bool isOpaque() const {
    return isCStruct() && assertedSize < 0 && features.empty();
  }

  /// \brief Add a feature and take ownership of it
  void addFeature(std::unique_ptr<Feature> F) {
    features.push_back(std::move(F));
  }

  /// \brief Remove a feature by name
  void removeFeature(std::string name) {

    this->features.erase(
      std::remove_if(
          this->features.begin(),
          this->features.end(),
          [name](const std::unique_ptr<Feature> &current_feature) -> bool {
              // Do "some stuff", then return true if element should be removed.
              return current_feature.get()->getName() == name;
          }
      ),
      this->features.end()
    );
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
  std::string fileName;
  std::vector<std::string> interfaces;
  bool interfaceDeclaration = false;
  bool builtinDeclaration = false;
  bool externDeclaration = false;
  int cKind = 0; // 0 a class, 1 an extern struct, 2 an extern union
  int assertedSize = -1;
  FeaturesType features;
  Symbol self;
};
}
#endif /* CLASS_H_ */
