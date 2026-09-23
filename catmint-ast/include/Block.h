#ifndef BLOCK_H
#define BLOCK_H

#include <memory>
#include <utility>
#include <vector>

#include "Expression.h"

#include "support/iterator.h"

namespace catmint {
/// \brief AST node for a block of statements
class Block : public Expression {
  typedef std::vector<std::unique_ptr<Expression>> ExpressionsType;

  struct iterator
      : public llvm::iterator_adaptor_base<iterator,
                                           ExpressionsType::const_iterator> {
    explicit iterator(ExpressionsType::const_iterator &&wrapped)
        : iterator_adaptor_base(wrapped) {}
    Expression *operator*() const { return I->get(); }
  };

public:
  /// \brief Create a block node
  /// \note This will take ownership of all the nodes in \p expressions, if
  ///       provided
  explicit Block(int lineNumber,
                 const std::vector<Expression *> &expressions = {})
      : Expression(lineNumber), expressions() {
    for (auto expr : expressions) {
      this->expressions.emplace_back(expr);
    }
  }

  /// True for the block of an `unsafe:` statement. A flag rather than a node
  /// of its own: the block is the only thing it carries, and a new node would
  /// mean the same six registrations for nothing.
  bool isUnsafe() const { return unsafeBlock; }
  void setUnsafe(bool value) { unsafeBlock = value; }

  /// \brief Add expression and take ownership of it
  void addExpression(std::unique_ptr<Expression> E) {
    if (E != nullptr)
      expressions.push_back(std::move(E));
  }
  
  /// \brief Add expression and take ownership of it
  void addExpressions(std::vector<Expression *> &Es) {
    for (auto &E : Es) {
      addExpression(std::unique_ptr<Expression>(E));
    }
  }

  /// @{
  /// \brief Support for iterating through the expressions in this block
  iterator begin() const { return iterator(expressions.begin()); }
  iterator end() const { return iterator(expressions.end()); }
  /// @}

  Expression *back() const { return expressions.back().get(); }

private:
  bool unsafeBlock = false;
  ExpressionsType expressions;
};
}
#endif /* BLOCK_H */
