#ifndef SPAWNSTATEMENT_H
#define SPAWNSTATEMENT_H

#include <memory>

#include "Expression.h"

namespace catmint {
/// \brief AST node for `spawn Class.method(argument)`
///
/// The call is not made here: its address and its argument are handed to a
/// thread, and the expression's value is a handle to wait for. The call is
/// held as an ordinary Dispatch so that the existing machinery resolves
/// which static method is meant.
class SpawnStatement : public Expression {
public:
  SpawnStatement(int lineNumber, std::unique_ptr<Expression> call)
      : Expression(lineNumber), call(std::move(call)) {}

  Expression *getCall() const { return call.get(); }

private:
  std::unique_ptr<Expression> call;
};
}
#endif /* SPAWNSTATEMENT_H */
