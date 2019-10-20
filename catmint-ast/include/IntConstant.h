#ifndef INTCONSTANT_H
#define INTCONSTANT_H

#include "Expression.h"

namespace catmint {
/// \brief AST node for an integer constant
class IntConstant : public Expression {
public:
  explicit IntConstant(int lineNumber, int value)
      : Expression(lineNumber), value(value) {}

  int getValue() const { return value; }

private:
  int value;
};
}
#endif /* INTCONSTANT_H */
