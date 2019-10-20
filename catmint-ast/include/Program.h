#ifndef __catmint_PROGRAM__
#define __catmint_PROGRAM__

#include <map>
#include <memory>
#include <string>
#include <utility>
#include <vector>

#include "Class.h"
#include "TreeNode.h"
#include "support/iterator.h"

namespace catmint {
/// \brief AST node for an entire catmint program
///
/// This should be the root of the AST
class Program : public TreeNode {
  typedef std::vector<std::unique_ptr<Class>> ClassesType;

  struct iterator
      : public llvm::iterator_adaptor_base<iterator,
                                           ClassesType::const_iterator> {
    explicit iterator(const ClassesType::const_iterator &&wrapped)
        : iterator_adaptor_base(wrapped) {}
    Class *operator*() const { return I->get(); }
  };

public:
  /// \brief Create a node for an entire program
  /// \note This takes ownership of \p classes if provided
  explicit Program(int lineNumber, const std::vector<Class *> &classes = {})
      : TreeNode(lineNumber), classes() {
    for (auto cls : classes) {
      this->classes.emplace_back(std::move(cls));
    }
  }

  /// \brief Add a class and take ownership of it
  void addClass(std::unique_ptr<Class> c) { classes.push_back(std::move(c)); }

  /// @{
  /// \brief Iterate through the program's classes
  iterator begin() const { return iterator(classes.begin()); }
  iterator end() const { return iterator(classes.end()); }
  /// @}

private:
  ClassesType classes;
};
}
#endif // __catmint_PROGRAM__
