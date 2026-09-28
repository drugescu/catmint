#ifndef FIELDACCESS_H
#define FIELDACCESS_H

#include <memory>
#include <string>

#include "Expression.h"

namespace catmint {
/// \brief AST node for a field of an object: `a.b` to read it, and the same
///        node carrying a value for `a.b = v`.
///
/// Read and write share one node for the same reason indexing does: the
/// grammar reduces `a.b` before it can see whether an `=` follows, so the
/// assignment rule attaches the value to the node it already has instead of
/// needing a second, conflicting rule.
class FieldAccess : public Expression {
public:
  FieldAccess(int lineNumber, std::unique_ptr<Expression> object,
              const std::string &field,
              std::unique_ptr<Expression> value = nullptr)
      : Expression(lineNumber), object(std::move(object)), field(field),
        value(std::move(value)) {}

  Expression *getObject() const { return object.get(); }
  std::string getField() const { return field; }

  /// Non-null when this is an assignment rather than a read.
  Expression *getValue() const { return value.get(); }
  void setValue(std::unique_ptr<Expression> v) { value = std::move(v); }

private:
  std::unique_ptr<Expression> object;
  std::string field;
  std::unique_ptr<Expression> value;
};
}
#endif /* FIELDACCESS_H */
