#ifndef SLICEVECTOR_H
#define SLICEVECTOR_H

#include <memory>
#include <utility>

#include "Expression.h"

namespace catmint {
/// \brief AST node for the substring operator
class Slicevector : public Expression {
public:
  /// \brief Create a node for the vector slice operator
  /// \note This will take ownership of \p object, \p start, \p step and \p end if
  ///       provided
  explicit Slicevector(int lineNumber,
                     std::unique_ptr<Expression> obj = nullptr,
                     std::unique_ptr<Expression> start = nullptr,
                     std::unique_ptr<Expression> step = nullptr,
                     std::unique_ptr<Expression> end = nullptr)
      : Expression(lineNumber), obj(std::move(obj)),
        start(std::move(start)), step(std::move(step)), end(std::move(end)) {}

  /// \brief Set and take ownership of the string object on which the operator
  ///        is invoked
  void setObject(std::unique_ptr<Expression> E) { obj = std::move(E); }

  /// \brief Set and take ownership of the start index of the substring operator
  void setStart(std::unique_ptr<Expression> E) { start = std::move(E); }

  /// \brief Set and take ownership of the start index of the substring operator
  void setStep(std::unique_ptr<Expression> E) { step = std::move(E); }

  /// \brief Set and take ownership of the end index of the substring operator
  void setEnd(std::unique_ptr<Expression> E) { end = std::move(E); }

  Expression *getObject() const { return obj.get(); }
  Expression *getStart() const { return start.get(); }
  Expression *getStep() const { return step.get(); }
  Expression *getEnd() const { return end.get(); }

private:
  std::unique_ptr<Expression> obj;
  std::unique_ptr<Expression> start;
  std::unique_ptr<Expression> step;
  std::unique_ptr<Expression> end;
};
}
#endif /* SLICEVECTOR_H */
