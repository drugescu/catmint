#ifndef LOCALDEFINITION_H
#define LOCALDEFINITION_H

#include <memory>
#include <iostream>
#include <string>
#include <vector>
#include <utility>

#include "Expression.h"

namespace catmint {
/// \brief AST node for a local variable definition
class LocalDefinition : public Expression {
public:
  /// \brief Create a node for a local variable definition
  /// \note This will take ownership of \p init if provided. It will _not_ take
  ///       ownership of \p scope. You should make sure \p scope's lifetime is
  ///       longer
  ///       than that of the created node.
  explicit LocalDefinition(int lineNumber, const std::vector<std::string> &name,
                           const std::string &type,
                           std::unique_ptr<Expression> init = nullptr,
                           Expression *scope = nullptr)
      : Expression(lineNumber), name(name), type(type), scope(scope),
        init(std::move(init)) { 
          //std::cout<<"Generated LocalDefinition.\n"; 
          //for (auto n : name) {
            //std::cout << "Name " << n << "\n";
          //}
        }

  /// \brief Set the scope of the local variable
  /// \note This does not take ownership of \p E. You should ensure that \E's
  ///       lifetime is longer than that of the current node
  void setScope(Expression *E) { scope = E; }

  /// \brief Set the initializer for the variable and take ownership of it
  void setInit(std::unique_ptr<Expression> E) { init = std::move(E); }

  std::vector<std::string> getName() const { return name; }
  std::string getType() const { return type; }
  Expression *getScope() const { return scope; }
  Expression *getInit() const { return init.get(); }

private:
  std::vector<std::string> name;
  std::string type;
  Expression *scope;
  std::unique_ptr<Expression> init;
};
}
#endif /* LOCALDEFINITION_H */
