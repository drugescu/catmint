#ifndef IFSTATEMENT_H
#define IFSTATEMENT_H

#include <memory>
#include <utility>

#include "Expression.h"

namespace catmint {
/// \brief AST node for an if statement
class IfStatement : public Expression {
public:
  /// \brief Create a node for an if statement
  /// \note Will take ownership of \p condExpr, \p thenExpr and \p elseExpr if
  ///       provided
  explicit IfStatement(int lineNumber,
                       std::unique_ptr<Expression> condExpr = nullptr,
                       std::unique_ptr<Expression> thenExpr = nullptr,
                       std::unique_ptr<Expression> elseExpr = nullptr)
      : Expression(lineNumber), condExpr(std::move(condExpr)),
        thenExpr(std::move(thenExpr)), elseExpr(std::move(elseExpr)) {}

  /// \brief Set if condition and take ownership of it
  void setCond(std::unique_ptr<Expression> C) { condExpr = std::move(C); }

  /// \brief Set then branch and take ownership of it
  void setThen(std::unique_ptr<Expression> T) { thenExpr = std::move(T); }

  /// \brief Set else branch and take ownership of it
  void setElse(std::unique_ptr<Expression> E) { elseExpr = std::move(E); }

  Expression *getCond() const { return condExpr.get(); }
  Expression *getThen() const { return thenExpr.get(); }
  Expression *getElse() const { return elseExpr.get(); }

private:
  std::unique_ptr<Expression> condExpr;
  std::unique_ptr<Expression> thenExpr;
  std::unique_ptr<Expression> elseExpr;
};
}
#endif /* IFSTATEMENT_H */
