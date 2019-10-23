#ifndef FLOATCONSTANT_H
#define FLOATCONSTANT_H

#include "Expression.h"

namespace catmint {
/// \brief AST node for a float constant
class FloatConstant : public Expression {
public:
  explicit FloatConstant(int lineNumber, float value)
      : Expression(lineNumber), value(value) {}

  float getValue() const { return value; }

private:
  float value;
};
}
#endif /* FLOATCONSTANT_H */
