#ifndef THROWSTATEMENT_H
#define THROWSTATEMENT_H

#include <memory>

#include "Expression.h"

namespace catmint {
/// \brief AST node for `throw <expression>`
///
/// The value is any object; an Int is boxed on the way, as it is anywhere
/// else a reference is expected. A throw never returns.
class ThrowStatement : public Expression {
public:
  ThrowStatement(int lineNumber, std::unique_ptr<Expression> value)
      : Expression(lineNumber), value(std::move(value)) {}

  Expression *getValue() const { return value.get(); }

private:
  std::unique_ptr<Expression> value;
};
}
#endif /* THROWSTATEMENT_H */
