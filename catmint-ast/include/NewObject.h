#ifndef NEWOBJECT_H
#define NEWOBJECT_H

#include <memory>
#include <string>
#include <utility>
#include <vector>

#include "Expression.h"
#include "support/iterator.h"

namespace catmint {
/// \brief AST node for creating a new object, with the arguments its
///        constructor takes.
class NewObject : public Expression {
  typedef std::vector<std::unique_ptr<Expression>> ArgumentsType;

  struct iterator
      : public llvm::iterator_adaptor_base<iterator,
                                           ArgumentsType::const_iterator> {
    explicit iterator(ArgumentsType::const_iterator &&wrapped)
        : iterator_adaptor_base(wrapped) {}
    Expression *operator*() const { return I->get(); }
  };

public:
  /// \note This takes ownership of \p arguments if provided
  explicit NewObject(int lineNumber, std::string type,
                     const std::vector<Expression *> &arguments = {})
      : Expression(lineNumber), type(type), arguments() {
    for (auto arg : arguments) {
      this->arguments.emplace_back(arg);
    }
  }

  std::string getType() const { return type; }

  void addArgument(std::unique_ptr<Expression> arg) {
    arguments.push_back(std::move(arg));
  }

  /// @{
  /// \brief Support for iterating through the constructor arguments
  iterator begin() const { return iterator(arguments.begin()); }
  iterator end() const { return iterator(arguments.end()); }
  /// @}

private:
  std::string type;
  ArgumentsType arguments;
};
}
#endif /* NEWOBJECT_H */
