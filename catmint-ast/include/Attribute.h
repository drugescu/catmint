#ifndef ATTRIBUTE_H_
#define ATTRIBUTE_H_

#include <memory>
#include <utility>

#include "Expression.h"
#include "Feature.h"

namespace catmint {

/// \brief AST node for a class attribute
class Attribute : public Feature {
public:
  /// \brief Create an Attribute node
  /// \note This will take ownership of \p init, if provided
  explicit Attribute(int lineNumber, const std::string &name,
                     const std::string &type,
                     std::unique_ptr<Expression> init = nullptr)
      : Feature(lineNumber, name), type(type), init(std::move(init)) {}

  void setInit(std::unique_ptr<Expression> E) { init = std::move(E); }

  std::string getName() const { return name; }
  std::string getType() const { return type; }
  Expression *getInit() const { return init.get(); }

  bool isAttribute() const override { return true; }

private:
  std::string type;
  std::unique_ptr<Expression> init;
};
}
#endif /* ATTRIBUTE_H_ */
