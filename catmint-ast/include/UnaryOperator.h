#ifndef UNARYOPERATOR_H
#define UNARYOPERATOR_H

#include <memory>
#include <utility>

#include "Expression.h"

namespace catmint {
/// \brief AST node for a unary operator
class UnaryOperator : public Expression {
public:
  /// \brief The kinds of unary operators in catmint
  enum UnaryOpKind { Minus, Not, Invalid };

  /// \brief Create a node for a unary operator
  /// \note This takes ownership of \p operand if provided
  explicit UnaryOperator(int lineNumber, UnaryOpKind operatorKind,
                         std::unique_ptr<Expression> operand = nullptr)
      : Expression(lineNumber), operatorKind(operatorKind),
        operand(std::move(operand)) {}

  /// \brief Set and take ownership of the operand to this unary operator
  void setOperand(std::unique_ptr<Expression> op) { operand = std::move(op); }

  UnaryOpKind getOperatorKind() const { return operatorKind; }
  Expression *getOperand() const { return operand.get(); }

private:
  UnaryOpKind operatorKind;
  std::unique_ptr<Expression> operand;
};
}
#endif /* UNARYOPERATOR_H */
