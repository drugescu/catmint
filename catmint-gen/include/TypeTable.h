
#ifndef INCLUDE_TYPETABLE_H_
#define INCLUDE_TYPETABLE_H_

#include <cassert>
#include <unordered_map>
#include <iostream>
#include <map>

#include <NullConstant.h>
#include <StringConstants.h>
#include <IntConstant.h>
#include <FloatConstant.h>
#include <StringConstant.h>
#include <Attribute.h>
#include <Block.h>
#include <Method.h>
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
  /// \p at is the node that named the type, so that "not found" can say where.
  Type *getType(const std::string &name, TreeNode *at = nullptr) const;

  Type *getIntType() const;
  /// \brief Width in bits of an integer type, or 0 when \p name is not one.
  ///        Int and Int32 are the same 32-bit type.
  static int integerWidth(const std::string &name);
  Type *getVoidType() const;
  Type *getNullType() const;
  Type *getFloatType() const;

  Type *getObjectType() const;
  Type *getStringType() const;
  Type *getIOType() const;

  Type *createNewType(Class *cls);
  bool isBuiltinClass(Class *cls) const;
  bool isBuiltinType(Type *t) const; // returns true for classes too

  /// \brief Return the lowest common ancestor of \p T and \p U or the void type
  ///        if they don't have a common ancestor
  Type *getCommonType(Type *T, Type *U) const;
  // Don't forget this should walk the type hierarchy
  std::string getCommonTypeStr(std::string T, std::string U) const;

  bool isEqualOrImplicitlyConvertibleTo(Type *fromType, Type *toType);
  /// \brief True when \p derived is \p base, inherits from it, or declares
  ///        that it implements it.
  bool isDerivedFrom(const std::string &derived, const std::string &base) const;
  /// \brief True for a type declared with `interface`.
  bool isInterface(const std::string &name) const;
  /// \brief True for a type held as an object reference rather than a value.
  bool isReferenceType(const std::string &name) const;
  bool isEqualOrImplicitlyConvertibleToStr(std::string from, std::string to);

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
    // Constants are typed by their kind. These must be the registered types,
    // not fresh ones: a fresh Type carries no Class, so anything inferred from
    // a literal -- `s = ""` and then `s.len()` -- would be rejected as a call
    // on a non-class object. Returning fresh ones also leaked.
    if(auto intConstant = dynamic_cast<catmint::IntConstant *>(node)) {
      // A literal too large for an Int is an Int64; everything else is an Int.
      return getType(std::string(intConstant->fitsInInt() ? strings::Int
                                                          : strings::Int64));
    }
    if(dynamic_cast<catmint::StringConstant *>(node)) {
      return getType(std::string(strings::String));
    }
    if(dynamic_cast<catmint::FloatConstant *>(node)) {
      return getType(std::string(strings::Float));
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

      // Try and return derived type here
    }

    assert(nodeTypeTable.count(node) && "Couldn't get type for node.\n");
    // Derive type here!
    // Or simply inside the isEqualOrImplicitylConvertibleTo (fromType, toType)

    return nodeTypeTable.at(node);
  }

  /// \brief Get the type of \p node or return error - useful to see if arguments are basic or composed
  /*Type *peekType(TreeNode *node) {
    if(dynamic_cast<catmint::IntConstant *>(node)) {
      return new catmint::Type(strings::Int);
    }
    if(dynamic_cast<catmint::StringConstant *>(node)) {
      return new catmint::Type(strings::String);
    }
    if(dynamic_cast<catmint::FloatConstant *>(node)) {
      return new catmint::Type(strings::Float);
    }
    if(dynamic_cast<catmint::Symbol *>(node)) {
      return new catmint::Type(strings::Symbol);
    }
    if(dynamic_cast<catmint::NullConstant *>(node)) {
      return new catmint::Type(strings::Null);
    }
    if (nodeTypeTable.count(node) == 0)
      return new catmint::Type(strings::ComplexType);
  }*/

  std::string peekTypeString(TreeNode *node) {
    if(dynamic_cast<catmint::IntConstant *>(node)) {
      return std::string(strings::Int);
    }
    if(dynamic_cast<catmint::StringConstant *>(node)) {
      return std::string(strings::String);
    }
    if(dynamic_cast<catmint::FloatConstant *>(node)) {
      return std::string(strings::Float);
    }
    if(dynamic_cast<catmint::Symbol *>(node)) {
      return std::string(strings::Symbol);
    }
    if(dynamic_cast<catmint::NullConstant *>(node)) {
      return std::string(strings::Null);
    }
    if (nodeTypeTable.count(node) == 0)
      return std::string(strings::ComplexType);

    return std::string(strings::Unknown);
  }

  /// \brief Get the parent class corresponding to \p c
  Class *getParentClass(Class *c) const;

  Attribute *getAttribute(Class *c, const std::string &name) const;
  Method *getMethod(Class *c, const std::string &name) const;

  int printTypeTable();
  
private:
  void addTypes(Program *p);
  void addBuiltinTypes(Program *p);
  void addBuiltinClasses(Program *p);
  /// Register one built-in class and hand its features to the program.
  Type *addBuiltinClass(Program *p, const char *name, const char *parent,
                        std::vector<Feature *> &methods);
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


};
}
#endif /* INCLUDE_TYPETABLE_H_ */
