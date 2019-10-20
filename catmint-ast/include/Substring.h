#ifndef SUBSTRING_H
#define SUBSTRING_H

#include <memory>
#include <utility>

#include "Expression.h"

namespace catmint {
/// \brief AST node for the substring operator
class Substring : public Expression {
public:
  /// \brief Create a node for the substring operator
  /// \note This will take ownership of \p string, \p start and \p end if
  ///       provided
  explicit Substring(int lineNumber,
                     std::unique_ptr<Expression> string = nullptr,
                     std::unique_ptr<Expression> start = nullptr,
                     std::unique_ptr<Expression> end = nullptr)
      : Expression(lineNumber), string(std::move(string)),
        start(std::move(start)), end(std::move(end)) {}

  /// \brief Set and take ownership of the string object on which the operator
  ///        is invoked
  void setString(std::unique_ptr<Expression> E) { string = std::move(E); }

  /// \brief Set and take ownership of the start index of the substring operator
  void setStart(std::unique_ptr<Expression> E) { start = std::move(E); }

  /// \brief Set and take ownership of the end index of the substring operator
  void setEnd(std::unique_ptr<Expression> E) { end = std::move(E); }

  Expression *getString() const { return string.get(); }
  Expression *getStart() const { return start.get(); }
  Expression *getEnd() const { return end.get(); }

private:
  std::unique_ptr<Expression> string;
  std::unique_ptr<Expression> start;
  std::unique_ptr<Expression> end;
};
}
#endif /* SUBSTRING_H */
