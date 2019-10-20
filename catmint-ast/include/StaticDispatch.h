#ifndef STATICDISPATCH_H_
#define STATICDISPATCH_H_

#include <memory>
#include <utility>
#include <vector>

#include "Expression.h"
#include "support/iterator.h"

namespace catmint {
/// \brief AST node for a static dispatch expression
class StaticDispatch : public Expression {
  typedef std::vector<std::unique_ptr<Expression>> ArgumentsType;

  struct iterator
      : public llvm::iterator_adaptor_base<iterator,
                                           ArgumentsType::const_iterator> {
    explicit iterator(ArgumentsType::const_iterator &&wrapped)
        : iterator_adaptor_base(wrapped) {}
    Expression *operator*() const { return I->get(); }
  };

public:
  /// \brief Create a node for a static dispatch
  /// \note This takes ownership of \p object and \p arguments if provided
  explicit StaticDispatch(int lineNumber, std::unique_ptr<Expression> object,
                          const std::string &type, const std::string &name,
                          const std::vector<Expression *> &arguments = {})
      : Expression(lineNumber), object(std::move(object)), type(type),
        name(name), arguments() {
    for (auto arg : arguments) {
      this->arguments.emplace_back(arg);
    }
  }

  Expression *getObject() const { return object.get(); }
  std::string getType() const { return type; }
  std::string getName() const { return name; }

  /// \brief Add an argument and take ownership of it
  void addArgument(std::unique_ptr<Expression> Arg) {
    arguments.push_back(std::move(Arg));
  }

  /// @{
  /// \brief Iterate through the arguments
  iterator begin() const { return iterator(arguments.begin()); }
  iterator end() const { return iterator(arguments.end()); }
  /// @}

private:
  std::unique_ptr<Expression> object;
  std::string type;
  std::string name;
  ArgumentsType arguments;
};
}
#endif /* STATICDISPATCH_H_ */
