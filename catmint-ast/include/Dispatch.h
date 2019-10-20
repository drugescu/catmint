#ifndef DISPATCH_H
#define DISPATCH_H

#include <memory>
#include <utility>
#include <vector>

#include "Expression.h"
#include "support/iterator.h"

namespace catmint {
/// \brief AST node for a dispatch expression
class Dispatch : public Expression {
  typedef std::vector<std::unique_ptr<Expression>> ArgumentsType;

  struct iterator
      : public llvm::iterator_adaptor_base<iterator,
                                           ArgumentsType::const_iterator> {
    explicit iterator(ArgumentsType::const_iterator &&wrapped)
        : iterator_adaptor_base(wrapped) {}
    Expression *operator*() const { return I->get(); }
  };

public:
  /// \brief Create a dispatch node
  /// \note This will take ownership of \p object and \p arguments if provided
  explicit Dispatch(int lineNumber, const std::string &name,
                    std::unique_ptr<Expression> object = nullptr,
                    const std::vector<Expression *> &arguments = {})
      : Expression(lineNumber), object(std::move(object)), name(name),
        arguments() {
    for (auto arg : arguments) {
      this->arguments.emplace_back(arg);
    }
  }

  Expression *getObject() const { return object.get(); }
  std::string getName() const { return name; }

  /// \brief Add argument and take ownership of it
  void addArgument(std::unique_ptr<Expression> arg) {
    arguments.push_back(std::move(arg));
  }

  void setName(const std::string &name) { this->name = name; }

  /// @{
  /// \brief Support for iterating through the arguments
  iterator begin() const { return iterator(arguments.begin()); }
  iterator end() const { return iterator(arguments.end()); }
  /// @}

private:
  std::unique_ptr<Expression> object;
  std::string name;
  ArgumentsType arguments;
};
}
#endif /* DISPATCH_H */
