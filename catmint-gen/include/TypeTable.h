
#ifndef INCLUDE_TYPETABLE_H_
#define INCLUDE_TYPETABLE_H_

#include <cassert>
#include <unordered_map>
#include <iostream>
#include <map>

#include <StringConstants.h>
#include <IntConstant.h>
#include <FloatConstant.h>
#include <StringConstant.h>
#include <Attribute.h>
#include <BinaryOperator.h>
#include <Type.h>

using namespace catmint;

namespace catmint {

class Attribute;
class BinaryOperator;
class Class;
class Method;
class Program;
class TreeNode;
class Type;

class TypeTable {

public:
  TypeTable(Program *p);
  ~TypeTable();

  /// \brief Get the type corresponding to \p name or throw an exception
  Type *getType(const std::string &name) const;

  Type *getIntType() const;
  Type *getVoidType() const;
  Type *getNullType() const;

  Type *getObjectType() const;
  Type *getStringType() const;
  Type *getIOType() const;

  Type *createNewType(Class *cls);
  bool isBuiltinClass(Class *cls) const;
  bool isBuiltinType(Type *t) const; // returns true for classes too

  /// \brief Return the lowest common ancestor of \p T and \p U or the void type
  ///        if they don't have a common ancestor
  Type *getCommonType(Type *T, Type *U) const;

  bool isEqualOrImplicitlyConvertibleTo(Type *fromType, Type *toType);

  void setType(TreeNode *node, Type *type) { 
    nodeTypeTable[node] = type; 
    std::cout << "Set type of node at line " << node->getLineNumber() << " to " << type->getName() << "\n";
    auto attr = dynamic_cast<catmint::Attribute*>(node);
    if(attr) {
      std::cout << "Node is attribute with name '" <<  attr->getName() << "'\n";
    }
  }

  /// \brief Get the type of \p node or assert (we don't throw an exception
  ///        because we don't intend to catch semantic errors with this)
  Type *getType(TreeNode *node) {
    // For integer/float/string nodes there is no type
    if(dynamic_cast<catmint::IntConstant *>(node)) {
      return new catmint::Type(strings::Int);
    }
    if(dynamic_cast<catmint::StringConstant *>(node)) {
      return new catmint::Type(strings::String);
    }
    if(dynamic_cast<catmint::FloatConstant *>(node)) {
      return new catmint::Type(strings::Float);
    }
    

    if (nodeTypeTable.count(node) == 0) {
      std::cout << "\n\nError: Node line number: " << node->getLineNumber() << "\n";
      auto symb = dynamic_cast<catmint::Symbol*>(node);
      if(symb) {
        std::cout << "Node is symbol with name '" <<  symb->getName() << "'\n";
      }
      auto binop = dynamic_cast<catmint::BinaryOperator*>(node);
      if(binop) {
        std::cout << "Node is binary operator with kind '" <<  binop->getName() << "'\n";
      }

      printTypeTable();
    }

    assert(nodeTypeTable.count(node) && "Couldn't get type for node.\n");
    // Derive type here!
    return nodeTypeTable.at(node);
  }

  /// \brief Get the parent class corresponding to \p c
  Class *getParentClass(Class *c) const;

  Attribute *getAttribute(Class *c, const std::string &name) const;
  Method *getMethod(Class *c, const std::string &name) const;


private:
  void addTypes(Program *p);
  void addBuiltinTypes(Program *p);
  void addBuiltinClasses(Program *p);
  void buildInheritanceGraph(Program *p);
  void buildFeatureTable(Class *c);

//  std::unordered_map<std::string, Type *> typeTable;
//  std::unordered_map<TreeNode *, Type *> nodeTypeTable;
//  std::unordered_map<Class *, Class *> parentTable;
    
    std::map<std::string, Type *> typeTable;
    std::map<TreeNode *, Type *> nodeTypeTable;
    std::map<Class *, Class *> parentTable;

//  std::unordered_map<Class *, std::unordered_map<std::string, Attribute *>>
//      attributeTable;
    std::map<Class *, std::map<std::string, Attribute *>> attributeTable;

//  std::unordered_map<Class *, std::unordered_map<std::string, Method *>>
//      methodTable;
    std::map<Class *, std::map<std::string, Method *>> methodTable;

  int printTypeTable();
};
}
#endif /* INCLUDE_TYPETABLE_H_ */
