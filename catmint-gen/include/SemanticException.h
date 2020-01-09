#ifndef SEMANTICEXCEPTION_H
#define SEMANTICEXCEPTION_H

#include <exception>
#include <sstream>
#include <string>

#include "ASTNodes.h"
#include "Type.h"

namespace catmint {
/// \brief Exception thrown during semantic analysis
class SemanticException : public std::exception {
public:
  SemanticException(std::string message = "Catmint generic semantic error!",
                    TreeNode *node = nullptr)
      : message(""), node(node) {
    stringStream.str("");
    if (node == nullptr) {
      stringStream << "[ ERROR ] : " << message;
    } else {
      stringStream << "[ ERROR ] : Line " << node->getLineNumber()
                   << " : " + message;
    }
    this->message = stringStream.str();
  }

  const char *what() const noexcept override { return message.c_str(); }

private:
  std::string message;
  TreeNode *node;

  static std::ostringstream stringStream;
};

/// \brief Exception thrown when a class has two or more attributes with the
///        same name (either inherited or not)
class DuplicateAttrException : public SemanticException {
public:
  DuplicateAttrException(Attribute *a, Class *c)
      : SemanticException(
            "An attribute with the same name already exists in class '" +
                c->getName() + "' : '" + a->getName() + "'.",
            a),
        attribute(a), containingClass(c) {}

  Attribute *attribute;
  Class *containingClass;
};

class DuplicateMethodException : public SemanticException {
public:
  DuplicateMethodException(Method *m, Class *c)
      : SemanticException(
            "A method with the same name already exists in class '" +
                c->getName() + "' : '" + m->getName() + "'.",
            m),
        method(m), containingClass(c) {}

  Method *method;
  Class *containingClass;
};

/// \brief Exception thrown when a method has two or more parameters with the
///        same name
class DuplicateParamException : public SemanticException {
public:
  //DuplicateParamException(FormalParam *p, Method *m)
  DuplicateParamException(Attribute *p, Method *m)
      : SemanticException("Method '" + m->getName() +
                              "' has more than one parameter named '" +
                              p->getName() + "'.",
                          p),
        param(p), method(m) {}

  //FormalParam *param;
  Attribute *param;
  Method *method;
};

class DuplicateClassException : public SemanticException {
public:
  DuplicateClassException(Class *c)
      : SemanticException(
            "A class with the same name already exists: '" + c->getName() + "'.", c),
        cls(c) {}

  Class *cls;
};

class BadInheritanceException : public SemanticException {
public:
  BadInheritanceException(Class *c, const std::string &ancestor)
      : SemanticException(
            "Class '" + c->getName() + "' inherits from '" + ancestor + "'.", c),
        cls(c), ancestor(ancestor) {}

  Class *cls;
  std::string ancestor;
};

class InvalidMethodSignatureException : public SemanticException {
public:
  InvalidMethodSignatureException(Class *c, Method *m)
      : SemanticException("Signature of method '" + m->getName() + "' in class '" +
                          c->getName() +
                          "' doesn't match that of overriden method."),
        cls(c), method(m) {}

  Class *cls;
  Method *method;
};

class MissingOperandException : public SemanticException {
public:
  MissingOperandException(Expression *e)
      : SemanticException("Missing value for operand.", e), expr(e) {}

  Expression *expr;
};

class MissingIfCondException : public SemanticException {
public:
  MissingIfCondException(IfStatement *i)
      : SemanticException("Missing 'if' condition.", i), expr(i) {}

  IfStatement *expr;
};

class MissingIfThenException : public SemanticException {
public:
  MissingIfThenException(IfStatement *i)
      : SemanticException("Missing 'then' branch.", i), expr(i) {}

  IfStatement *expr;
};

class MissingWhileCondException : public SemanticException {
public:
  MissingWhileCondException(WhileStatement *w)
      : SemanticException("Missing 'while' condition.", w), expr(w) {}

  WhileStatement *expr;
};

class IncompatibleOperandsException : public SemanticException {
public:
  IncompatibleOperandsException(Expression *e, Type *lhs, Type *rhs)
      : SemanticException("Incompatible types '" + lhs->getName() + "' and '" +
                              rhs->getName() + "'.",
                          e),
        expr(e), lhsType(lhs), rhsType(rhs) {}

  Expression *expr;
  Type *lhsType;
  Type *rhsType;
};

class UnknownVariableException : public SemanticException {
public:
  UnknownVariableException(const std::string &name)
      : SemanticException("Variable '" + name + "' not found in symbol table, has it been declared?"),
        name(name) {}

  std::string name;
};

/// \brief Thrown when a dispatch or static dispatch is made on a non-class
///        object
class DispatchOnInvalidObjException : public SemanticException {
public:
  DispatchOnInvalidObjException(const std::string &name, Type *obj)
      : SemanticException("Trying to call method '" + name +
                          "' on a non-class object of type '" + obj->getName() + "'."),
        methodName(name), objType(obj), castedType(nullptr) {}

  DispatchOnInvalidObjException(const std::string &name, Type *obj,
                                Type *castedObj)
      : SemanticException("Trying to call method '" + castedObj->getName() +
                          "::" + name + "' on object of type '" + obj->getName() + "'."),
        methodName(name), objType(obj), castedType(castedObj) {}

  std::string methodName;
  Type *objType;
  Type *castedType;
};

class AttributeNotFoundException : public SemanticException {
public:
  AttributeNotFoundException(const std::string &name, Class *c)
      : SemanticException("Attribute '" + name + "' not found in class '" +
                          c->getName() + "'."),
        name(name), cls(c) {}

  std::string name;
  Class *cls;
};

class MethodNotFoundException : public SemanticException {
public:
  MethodNotFoundException(const std::string &name, Class *c)
      : SemanticException("Method '" + name + "' not found in class '" +
                          c->getName() + "'"),
        name(name), cls(c) {}

  std::string name;
  Class *cls;
};

class TypeNotFoundException : public SemanticException {
public:
  TypeNotFoundException(const std::string &name)
      : SemanticException("Type '" + name + "' not found in Type Table."),
        name(name) {}

  std::string name;
};

class WrongTypeException : public SemanticException {
public:
  WrongTypeException(Type *actual, Type *expected, TreeNode *e)
      : SemanticException("Wrong type '" + actual->getName() + "' (expected '" +
                              expected->getName() + "')",
                          e),
        actual(actual), expected(expected), expr(e) {}

  WrongTypeException(Type *actual, Expression *e)
      : SemanticException("Wrong type '" + actual->getName() + "'.", e), actual(actual),
        expected(nullptr), expr(e) {}

  Type *actual;
  Type *expected;
  TreeNode *expr;
};

class TooManyArgsException : public SemanticException {
public:
  TooManyArgsException(const std::string &name, Expression *d)
      : SemanticException("Too many args in call to '" + name + "'.", d), name(name),
        expr(d) {}

  std::string name;
  Expression *expr;
};

class NotEnoughArgsException : public SemanticException {
public:
  NotEnoughArgsException(const std::string &name, Expression *d)
      : SemanticException("Not enough args in call to '" + name + "'.", d), name(name),
        expr(d) {}

  std::string name;
  Expression *expr;
};
}
#endif /* SEMANTICEXCEPTION_H */
