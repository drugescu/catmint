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
  void setType(const std::string &t) { type = t; }
  Expression *getInit() const { return init.get(); }

  bool isAttribute() const override { return true; }

  /// In an extern declaration, the C type as written -- `UInt8`, `Int32`, a
  /// struct -- when it differs from getType(), which is what catmint code
  /// sees. Empty everywhere else.
  std::string getCType() const { return cType.empty() ? type : cType; }
  void setCType(const std::string &t) { cType = t; }
  bool hasCType() const { return !cType.empty(); }
  /// A field of an extern struct declared `T name[n]`: n, or 0.
  int getArrayLength() const { return arrayLength; }
  void setArrayLength(int n) { arrayLength = n; }
  /// The offset `@ n` after an extern struct field asserts, or -1.
  int getAssertedOffset() const { return assertedOffset; }
  void setAssertedOffset(int n) { assertedOffset = n; }

private:
  std::string type;
  std::string cType;
  int arrayLength = 0;
  int assertedOffset = -1;
  std::unique_ptr<Expression> init;
};
}
#endif /* ATTRIBUTE_H_ */
