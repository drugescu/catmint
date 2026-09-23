#ifndef LOOPCONTROL_H
#define LOOPCONTROL_H

#include "Expression.h"

namespace catmint {
/// \brief AST node for `break` and `continue`
///
/// One node for both. They are the same shape -- no children, no value --
/// and differ only in which block the generator branches to, so keeping them
/// apart would mean the same six registrations twice for a one-line
/// difference. They serialize under separate node types all the same, so an
/// AST dump still reads as what was written.
class LoopControl : public Expression {
public:
  enum Kind { Break, Continue };

  LoopControl(int lineNumber, Kind kind)
      : Expression(lineNumber), kind(kind) {}

  Kind getKind() const { return kind; }
  bool isBreak() const { return kind == Break; }

private:
  Kind kind;
};
}
#endif /* LOOPCONTROL_H */
