#ifndef ASSIGNMENT_H_
#define ASSIGNMENT_H_

#include <memory>

#include "Expression.h"
#include "Symbol.h"

namespace catmint {

/// \brief AST node for an assignment expression
class Assignment : public Expression {
public:
  /// \brief Create an Assignment node
  /// \note This will take ownership of \p expression, if provided
  Assignment(int lineNumber, const std::string &name,
             std::unique_ptr<Expression> expression)
//      : Expression(lineNumber), symbol(new Symbol(lineNumber, name)),
      : Expression(lineNumber), symbol(name),
        expression(std::move(expression)) {}

  //Symbol *getSymbol() const { return symbol.get(); }
  std::string getSymbol() const { return symbol; }
  Expression *getExpression() const { return expression.get(); }

private:
  //std::unique_ptr<Symbol> symbol;
  std::string symbol;
  std::unique_ptr<Expression> expression;
};
}

#endif /* ASSIGNMENT_H_ */
