#ifndef CAST_H
#define CAST_H

#include <memory>
#include <string>
#include <utility>

#include "Expression.h"

namespace catmint {
/// \brief AST node for an explicit cast expression
class Cast : public Expression {
public:
  /// \brief Create an explicit cast node
  /// \note This will take ownership of \p toCast if provided
  explicit Cast(int lineNumber, std::string type,
                std::unique_ptr<Expression> toCast = nullptr)
      : Expression(lineNumber), type(type), toCast(std::move(toCast)) {}

  /// \brief Set the expression to cast and take ownership of it
  void setExpressionToCast(std::unique_ptr<Expression> E) {
    toCast = std::move(E);
  }

  std::string getType() const { return type; }
  Expression *getExpressionToCast() const { return toCast.get(); }

private:
  std::string type;
  std::unique_ptr<Expression> toCast;
};
}
#endif /* CAST_H */
