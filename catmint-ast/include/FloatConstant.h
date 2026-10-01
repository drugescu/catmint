#ifndef FLOATCONSTANT_H
#define FLOATCONSTANT_H

#include "Expression.h"

namespace catmint {
/// \brief AST node for a float constant
///
/// A double, because a Float is one and a literal is a Float until it is
/// converted. This was a `float`, which rounded every literal in every program
/// to seven significant digits before the generator ever saw it.
class FloatConstant : public Expression {
public:
  explicit FloatConstant(int lineNumber, double value)
      : Expression(lineNumber), value(value) {}

  double getValue() const { return value; }

private:
  double value;
};
}
#endif /* FLOATCONSTANT_H */
