#ifndef METHOD_H_
#define METHOD_H_

#include <memory>
#include <string>
#include <utility>
#include <vector>

#include "Expression.h"
#include "Feature.h"
#include "FormalParam.h"
#include "support/iterator.h"

namespace catmint {

class FormalParam;

/// \brief AST node for a method declaration
class Method : public Feature {
  //typedef std::vector<std::unique_ptr<FormalParam>> FormalParamsType;
  typedef std::vector<std::unique_ptr<Attribute>> FormalParamsType;

  struct iterator
      : public llvm::iterator_adaptor_base<iterator,
                                           FormalParamsType::const_iterator> {
    explicit iterator(FormalParamsType::const_iterator &&wrapped)
        : iterator_adaptor_base(wrapped) {}
    //FormalParam *operator*() const { return I->get(); }
    Attribute *operator*() const { return I->get(); }
  };

public:
  /// \brief Create a node for a method declaration
  /// \note This will take ownership of \p body and of the \p formalParameters
  ///       if provided
  explicit Method(int lineNumber, const std::string &name,
                  const std::string &returnType,
                  std::unique_ptr<Expression> body = nullptr,
                  //const std::vector<FormalParam *> &formalParameters = {})
                  const std::vector<Attribute *> &formalParameters = {})
      : Feature(lineNumber, name), returnType(returnType),
        body(std::move(body)), parameters() {
    for (auto formalParameter : formalParameters) {
      parameters.emplace_back(formalParameter);
    }
  }

  /// \brief Add formal parameter and take ownership of it
  //void addParameter(std::unique_ptr<FormalParam> param) {
  void addParameter(std::unique_ptr<Attribute> param) {
    parameters.push_back(std::move(param));
  }

  std::string getName() { return name; }
  bool isMethod() const override { return true; }

  /// A static method takes no receiver and gets no virtual table slot, so it
  /// is called on the class rather than on an object.
  bool isStatic() const { return staticMethod; }
  void setStatic(bool value) { staticMethod = value; }

  /// True for `abstract def`: a signature a subclass must supply. It takes a
  /// virtual table slot like any other method, so a call through the base
  /// type reaches the subclass's implementation; what it has no body of.
  bool isAbstract() const { return abstractMethod; }
  void setAbstract(bool value) { abstractMethod = value; }

  /// @{
  /// \brief Iterate through the parameters
  iterator begin() const { return iterator(parameters.begin()); }
  iterator end() const { return iterator(parameters.end()); }
  /// @}

  std::string getReturnType() const { return returnType; }

  Expression *getBody() const { return body.get(); }
  
  std::unique_ptr<Expression> getBodyFull() { return std::move(body); }

  void setBody(std::unique_ptr<Block> newBody) { body = std::move(newBody); }

private:
  std::string returnType;
  FormalParamsType parameters;
  bool staticMethod = false;
  bool abstractMethod = false;
  
public:
  std::unique_ptr<Expression> body;
  
};
}
#endif /* METHOD_H_ */
