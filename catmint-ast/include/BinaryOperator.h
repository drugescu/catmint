#ifndef BINARYOPERATOR_H
#define BINARYOPERATOR_H

#include <memory>
#include <utility>

#include "Expression.h"

namespace catmint {
/// \brief AST node for a binary operator
class BinaryOperator : public Expression {
public:
  /// \brief The kinds of binary operators in catmint
  enum BinOpKind {
    Add,
    Sub,
    Mul,
    Div,
    FirstArithmetic = Add,
    LastArithmetic = Div,

    LessThan,
    LessThanEqual,
    Equal,
    FirstComparison = LessThan,
    LastComparison = Equal,

    Invalid
  };

  /// \brief Create a binary operator node
  /// \note This will take ownership of \p LHS and \p RHS if provided.
  explicit BinaryOperator(int lineNumber, BinOpKind operatorKind,
                          std::unique_ptr<Expression> LHS = nullptr,
                          std::unique_ptr<Expression> RHS = nullptr)
      : Expression(lineNumber), operatorKind(operatorKind), LHS(std::move(LHS)),
        RHS(std::move(RHS)) {}

  /// \brief Set and take ownership of the left-hand side of the operator
  void setLHS(std::unique_ptr<Expression> E) { LHS = std::move(E); }

  /// \brief Set and take ownership of the right-hand side of the operator
  void setRHS(std::unique_ptr<Expression> E) { RHS = std::move(E); }

  BinOpKind getOperatorKind() const { return operatorKind; }
  Expression *getLHS() const { return LHS.get(); }
  Expression *getRHS() const { return RHS.get(); }

  bool isArithmetic() const {
    return operatorKind >= FirstArithmetic && operatorKind <= LastArithmetic;
  }

  bool isComparison() const {
    return operatorKind >= FirstComparison && operatorKind <= LastComparison;
  }

private:
  BinOpKind operatorKind;
  std::unique_ptr<Expression> LHS;
  std::unique_ptr<Expression> RHS;
};
}
#endif /* BINARYOPERATOR_H */
