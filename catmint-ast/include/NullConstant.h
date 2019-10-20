#ifndef VOIDCONSTANT_H
#define VOIDCONSTANT_H

#include "Expression.h"

namespace catmint {
/// \brief AST node for the null constant
class NullConstant : public Expression {
public:
  NullConstant(int lineNumber) : Expression(lineNumber) {}
};
}
#endif /* VOIDCONSTANT_H */
