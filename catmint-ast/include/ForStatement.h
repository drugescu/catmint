#ifndef FORSTATEMENT_H
#define FORSTATEMENT_H

#include <memory>
#include <utility>

#include "Expression.h"

namespace catmint {
  /// \brief AST node for the while statement
  class ForStatement : public Expression {
  public:
    /// \brief Create a node for a for statement
    /// \note Will take ownership of \p iterExpr, \p containerExpr and \p bodyExpr if provided
    /// \note Default order: ID of iterator, container, body
    explicit ForStatement(int lineNumber,
                            std::unique_ptr<Expression> iterExpr = nullptr,
                            std::unique_ptr<Expression> contExpr = nullptr,
                            std::unique_ptr<Expression> bodyExpr = nullptr)
        : Expression(lineNumber), 
          iterExpr(std::move(iterExpr)),
          contExpr(std::move(contExpr)),
          bodyExpr(std::move(bodyExpr)) {}

    /// \brief Set and take ownership of the iterator declaration
    void setIter(std::unique_ptr<Expression> I) { iterExpr = std::move(I); }

    /// \brief Set and take ownership of the container expression
    void setCont(std::unique_ptr<Expression> C) { contExpr = std::move(C); }

    /// \brief Set and take ownership of the loop body
    void setBody(std::unique_ptr<Expression> B) { bodyExpr = std::move(B); }

    Expression *getIter() const { return iterExpr.get(); }
    Expression *getCont() const { return contExpr.get(); }
    Expression *getBody() const { return bodyExpr.get(); }

  private:
    std::unique_ptr<Expression> iterExpr;
    std::unique_ptr<Expression> contExpr;
    std::unique_ptr<Expression> bodyExpr;
  };
}
#endif /* FORSTATEMENT_H */
