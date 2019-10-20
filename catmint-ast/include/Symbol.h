#ifndef SYMBOL_H
#define SYMBOL_H

#include <string>

#include "Expression.h"

namespace catmint {
/// \brief AST node for a symbol representing a variable or attribute appearing
///        in an expression
class Symbol : public Expression {
public:
  explicit Symbol(int lineNumber, const std::string &name)
      : Expression(lineNumber), name(name) {}

  std::string getName() const { return name; }

private:
  std::string name;
};
}
#endif /* SYMBOL_H */
