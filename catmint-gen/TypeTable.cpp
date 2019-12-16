
#include <TypeTable.h>
#include <Type.h>
#include <Class.h>
#include <StringConstants.h>
#include <SemanticException.h>

#include <algorithm>
#include <cassert>

using namespace lcpl;

TypeTable::TypeTable(Program *p) {
  addTypes(p);
  buildInheritanceGraph(p);
}

TypeTable::~TypeTable() { typeTable.clear(); }

void TypeTable::addTypes(Program *p) {
  for (auto c : *p) {
    (void)createNewType(c);
  }
  addBuiltinTypes(p);
}

void TypeTable::addBuiltinTypes(Program *p) {
  typeTable[strings::Int] = new Type(strings::Int);
  typeTable[strings::Null] = new Type(strings::Null);
  typeTable[strings::Void] = new Type(strings::Void);

  addBuiltinClasses(p);
}

bool TypeTable::isBuiltinType(Type *t) const {
  return t == getIntType() || t == getNullType() || t == getVoidType() ||
         isBuiltinClass(t->getClass());
}

void TypeTable::addBuiltinClasses(Program *p) {
  std::vector<Feature *> builtinMethods;
  std::vector<FormalParam *> builtinMethodsParams;

  // Object
  builtinMethods.push_back(new Method(0, strings::Abort, strings::Void, nullptr,
                                      builtinMethodsParams));
  builtinMethods.push_back(new Method(0, strings::TypeName, strings::String,
                                      nullptr, builtinMethodsParams));
  builtinMethods.push_back(new Method(0, strings::Copy, strings::Object,
                                      nullptr, builtinMethodsParams));
  std::unique_ptr<Class> objectClass(
      new Class(0, strings::Object, "", builtinMethods));
  (void)createNewType(objectClass.get());
  p->addClass(std::move(objectClass)); // we're parking this in the program, so
                                       // someone will have ownership of it, but
                                       // it's not very nice of us...

  builtinMethods.clear();
  builtinMethodsParams.clear();

  // IO
  builtinMethods.push_back(new Method(0, strings::In, strings::String, nullptr,
                                      builtinMethodsParams));
  builtinMethodsParams.push_back(
      new FormalParam(0, strings::Message, strings::String));
  builtinMethods.push_back(
      new Method(0, strings::Out, strings::Io, nullptr, builtinMethodsParams));
  std::unique_ptr<Class> ioClass(
      new Class(0, strings::Io, strings::Object, builtinMethods));
  (void)createNewType(ioClass.get());
  p->addClass(std::move(ioClass));

  builtinMethods.clear();
  builtinMethodsParams.clear();

  // String
  builtinMethods.push_back(new Method(0, strings::Length, strings::Int, nullptr,
                                      builtinMethodsParams));
  builtinMethods.push_back(new Method(0, strings::ToInt, strings::Int, nullptr,
                                      builtinMethodsParams));
  std::unique_ptr<Class> stringClass(
      new Class(0, strings::String, strings::Object, builtinMethods));
  (void)createNewType(stringClass.get());
  p->addClass(std::move(stringClass));
}

bool TypeTable::isBuiltinClass(Class *c) const {
  return c == getObjectType()->getClass() || c == getStringType()->getClass() ||
         c == getIOType()->getClass();
}

Type *TypeTable::getType(const std::string &name) const {
  if (!typeTable.count(name)) {
    throw TypeNotFoundException(name);
  }
  return typeTable.at(name);
}

Type *TypeTable::getIntType() const {
  assert(typeTable.count(strings::Int) && "Int type not defined");
  return typeTable.at(strings::Int);
}

Type *TypeTable::getVoidType() const {
  assert(typeTable.count(strings::Void) && "Void type not defined");
  return typeTable.at(strings::Void);
}

Type *TypeTable::getNullType() const {
  assert(typeTable.count(strings::Null) && "Null type not defined");
  return typeTable.at(strings::Null);
}

Type *TypeTable::getObjectType() const {
  assert(typeTable.count(strings::Object) && "Object type not defined");
  return typeTable.at(strings::Object);
}

Type *TypeTable::getStringType() const {
  assert(typeTable.count(strings::String) && "String type not defined");
  return typeTable.at(strings::String);
}

Type *TypeTable::getIOType() const {
  assert(typeTable.count(strings::Io) && "IO type not defined");
  return typeTable.at(strings::Io);
}

Type *TypeTable::createNewType(Class *cls) {
  if (typeTable.count(cls->getName())) {
    throw DuplicateClassException(cls);
  }
  assert(!nodeTypeTable.count(cls) && "Class already associated with type");

  auto NewType = new Type(cls);
  typeTable[cls->getName()] = NewType;
  nodeTypeTable[cls] = NewType;

  buildFeatureTable(cls);

  return NewType;
}

Type *TypeTable::getCommonType(Type *T, Type *U) const {
  return getVoidType();
}

bool TypeTable::isEqualOrImplicitlyConvertibleTo(Type *fromType, Type *toType) {
  return false;
}

Class *TypeTable::getParentClass(Class *c) const {
  assert(parentTable.count(c) && "Couldn't get parent");
  return parentTable.at(c);
}

Attribute *TypeTable::getAttribute(Class *c, const std::string &name) const {
  Class *currentClass = c;
  while (currentClass != nullptr) {
    assert(attributeTable.count(currentClass) && "Couldn't get attribute");
    auto it = attributeTable.at(currentClass).find(name);
    if (it == attributeTable.at(currentClass).end()) {
      currentClass = getParentClass(currentClass);
    } else {
      return it->second;
    }
  }

  return nullptr;
}

Method *TypeTable::getMethod(Class *c, const std::string &name) const {
  Class *currentClass = c;
  while (currentClass != nullptr) {
    assert(attributeTable.count(currentClass) && "Couldn't get method");
    auto it = methodTable.at(currentClass).find(name);
    if (it == methodTable.at(currentClass).end()) {
      currentClass = getParentClass(currentClass);
    } else {
      return it->second;
    }
  }

  return nullptr;
}

void TypeTable::buildInheritanceGraph(Program *p) {
  for (auto c : *p) {
    if (getType(c) == getObjectType()) {
      parentTable[c] = nullptr;
      continue;
    }

    std::string parentClassName = c->getParent();
    if (parentClassName == "") {
      parentTable[c] = getObjectType()->getClass();
    } else {
      auto parent = getType(parentClassName)->getClass();
      if (!parent) {
        throw BadInheritanceException(c, parentClassName);
      }

      parentTable[c] = parent;
    }
  }
}

void TypeTable::buildFeatureTable(Class *c) {
  auto &attributes = attributeTable[c];
  auto &methods = methodTable[c];

  for (auto f : *c) {
    if (auto a = dynamic_cast<Attribute *>(f)) {
      if (attributes.count(f->getName())) {
        throw DuplicateAttrException(a, c);
      }
      attributes[f->getName()] = a;
    } else {
      auto m = dynamic_cast<Method *>(f);
      assert(m && "Unknown feature kind");
      if (methods.count(f->getName())) {
        throw DuplicateMethodException(m, c);
      }
      methods[m->getName()] = m;
    }
  }
}
