#ifndef TRYSTATEMENT_H
#define TRYSTATEMENT_H

#include <memory>
#include <string>

#include "Expression.h"

namespace catmint {
/// \brief AST node for `try: ... catch <name>: ... end`
///
/// The handler binds one name, which holds whatever was thrown. There is no
/// type on it: anything can be thrown, and `is` is how a handler decides what
/// it has.
class TryStatement : public Expression {
public:
  TryStatement(int lineNumber, std::unique_ptr<Expression> body,
               const std::string &catchName,
               std::unique_ptr<Expression> handler)
      : Expression(lineNumber), body(std::move(body)), catchName(catchName),
        handler(std::move(handler)) {}

  Expression *getBody() const { return body.get(); }
  std::string getCatchName() const { return catchName; }
  Expression *getHandler() const { return handler.get(); }

private:
  std::unique_ptr<Expression> body;
  std::string catchName;
  std::unique_ptr<Expression> handler;
};
}
#endif /* TRYSTATEMENT_H */
