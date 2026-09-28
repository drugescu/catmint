#ifndef INTCONSTANT_H
#define INTCONSTANT_H

#include <cstdint>

#include "Expression.h"

namespace catmint {
/// \brief AST node for an integer constant
///
/// The value is held as 64 bits so that a literal too large for an Int can be
/// written at all. The generator gives such a literal the type Int64 and
/// everything else the type Int.
class IntConstant : public Expression {
public:
  explicit IntConstant(int lineNumber, long long value)
      : Expression(lineNumber), value(value) {}

  long long getValue() const { return value; }

  /// True when the value fits in an Int, which is what decides its type.
  bool fitsInInt() const {
    return value >= INT32_MIN && value <= INT32_MAX;
  }

private:
  long long value;
};
}
#endif /* INTCONSTANT_H */
