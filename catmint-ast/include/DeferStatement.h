#ifndef DEFERSTATEMENT_H
#define DEFERSTATEMENT_H

#include <memory>

#include "Expression.h"

namespace catmint {
/// \brief AST node for `defer <expression>`
///
/// The expression is emitted where the enclosing block ends, on every path
/// out of it, rather than where it is written. That is the whole of the
/// feature: there is no record kept at run time, and nothing to unwind.
class DeferStatement : public Expression {
public:
  DeferStatement(int lineNumber, std::unique_ptr<Expression> action)
      : Expression(lineNumber), action(std::move(action)) {}

  Expression *getAction() const { return action.get(); }

private:
  std::unique_ptr<Expression> action;
};
}
#endif /* DEFERSTATEMENT_H */
