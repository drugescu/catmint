#ifndef WHILESTATEMENT_H
#define WHILESTATEMENT_H

#include <memory>
#include <utility>

#include "Expression.h"

namespace catmint {
/// \brief AST node for the while statement
class WhileStatement : public Expression {
public:
  /// \brief Create a node for a while statement
  /// \note This will take ownership of \p condExpr and \p bodyExpr if provided
  explicit WhileStatement(int lineNumber,
                          std::unique_ptr<Expression> condExpr = nullptr,
                          std::unique_ptr<Expression> bodyExpr = nullptr)
      : Expression(lineNumber), condExpr(std::move(condExpr)),
        bodyExpr(std::move(bodyExpr)) {}

  /// \brief Set and take ownership of the loop condition
  void setCond(std::unique_ptr<Expression> C) { condExpr = std::move(C); }

  /// \brief Set and take ownership of the loop body
  void setBody(std::unique_ptr<Expression> B) { bodyExpr = std::move(B); }

  Expression *getCond() const { return condExpr.get(); }
  Expression *getBody() const { return bodyExpr.get(); }

private:
  std::unique_ptr<Expression> condExpr;
  std::unique_ptr<Expression> bodyExpr;
};
}
#endif /* WHILESTATEMENT_H */
