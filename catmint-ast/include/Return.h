#ifndef RETURNEXPRESSION_H
#define RETURNEXPRESSION_H

#include <string>

#include "Expression.h"

namespace catmint {
/// \brief AST node for creating a new object
class ReturnExpression : public Expression {
public:
  explicit ReturnExpression(int lineNumber, 
                           std::unique_ptr<Expression> retExpr = nullptr)
      : Expression(lineNumber), retExpr(std::move(retExpr)) {}

  /// \brief Set and take ownership of the expression to be returned
  void setRet(std::unique_ptr<Expression> E) { retExpr = std::move(E); }
  
  Expression *getRet() const { return retExpr.get(); }

private:
  std::unique_ptr<Expression> retExpr;
};
}
#endif /* RETURNEXPRESSION_H */
