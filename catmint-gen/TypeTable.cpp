
#include <TypeTable.h>
#include <Type.h>
#include <Class.h>
#include <StringConstants.h>
#include <SemanticException.h>

#include <algorithm>
#include <cassert>
#include <iostream>

using namespace catmint;

TypeTable::TypeTable(Program *p) {
  addTypes(p);
  buildInheritanceGraph(p);
}

TypeTable::~TypeTable() { typeTable.clear(); }

int TypeTable::printTypeTable() {
  std::cout << "-------------------------------------------\n";
  std::cout << "[Type Table]\n";
  for (auto it = typeTable.begin(); it != typeTable.end(); it++) {
    std::cout << "Key: " << it->first << ", Value: " << (dynamic_cast<catmint::Type*>(it->second))->getName() << "\n";
  }

  return true;
}

void TypeTable::addTypes(Program *p) {
  for (auto c : *p) {
    (void)createNewType(c);
  }
  addBuiltinTypes(p);
}

int TypeTable::integerWidth(const std::string &name) {
  if (name == strings::Int8)  return 8;
  if (name == strings::Int16) return 16;
  if (name == strings::Int || name == strings::Int32) return 32;
  if (name == strings::Int64) return 64;
  return 0;
}

void TypeTable::addBuiltinTypes(Program *p) {
  typeTable[strings::Int] = new Type(strings::Int);
  typeTable[strings::Null] = new Type(strings::Null);
  typeTable[strings::Void] = new Type(strings::Void);
  typeTable[strings::Float] = new Type(strings::Float);

  // `def name:` with no declared return type parses as the type "auto". Until
  // real return-type inference exists, such a method returns nothing, so the
  // spelling is an alias for Void. A method that returns a value must declare
  // its type: `def Int square(Int n):`.
  typeTable["auto"] = typeTable[strings::Void];

  // The sized integers. Int32 is registered as an alias of Int rather than as
  // a type of its own; the parser already folds the spelling away, and this
  // keeps a .ast written by an older parser working.
  typeTable[strings::Int8] = new Type(strings::Int8);
  typeTable[strings::Int16] = new Type(strings::Int16);
  typeTable[strings::Int64] = new Type(strings::Int64);
  typeTable[strings::Int32] = typeTable[strings::Int];

  // Add additional types
  addBuiltinClasses(p);
}

bool TypeTable::isBuiltinType(Type *t) const {
  const std::string &name = t->getName();
  return integerWidth(name) != 0 || name == strings::Null ||
         name == strings::Void || name == strings::Float ||
         isBuiltinClass(t->getClass());
}

// Add 'Object', 'IO', 'String' classes
namespace {

/// One parameter of a built-in method: its name and its type.
using Param = std::pair<const char *, const char *>;

/// Declare a built-in method, in slot order.
///
/// Every call allocates its own parameters. That is the point of this
/// helper: `Method` takes ownership of the `Attribute`s it is given, so
/// sharing one vector between two methods handed the same object to two
/// owners and double-freed it at startup. Declaring them here means it
/// cannot happen again.
Method *declare(std::vector<Feature *> &methods, const char *name,
                const char *returnType,
                std::initializer_list<Param> params = {}) {
  std::vector<Attribute *> own;
  own.reserve(params.size());
  for (const auto &param : params) {
    own.push_back(new Attribute(0, param.first, param.second));
  }

  auto *method = new Method(0, name, returnType, nullptr, own);
  methods.push_back(method);
  return method;
}

/// The same, for a method with no receiver: it takes no virtual table slot,
/// so it is declared after every method that does.
Method *declareStatic(std::vector<Feature *> &methods, const char *name,
                      const char *returnType,
                      std::initializer_list<Param> params = {}) {
  auto *method = declare(methods, name, returnType, params);
  method->setStatic(true);
  return method;
}

} // namespace

/// Register a built-in class and hand its features over to the program,
/// which owns them from here.
Type *TypeTable::addBuiltinClass(Program *p, const char *name,
                                 const char *parent,
                                 std::vector<Feature *> &methods) {
  std::unique_ptr<Class> declared(new Class(0, name, parent, methods));
  declared->setBuiltin(true);
  Type *type = createNewType(declared.get());
  p->addClass(std::move(declared));
  methods.clear();
  return type;
}

// Add the classes the compiler supplies. Declaration order here is virtual
// table slot order in runtime.c, and the two must agree exactly: test 42
// calls every one of these methods so that a disagreement is a failing test
// rather than a call to the wrong function.
void TypeTable::addBuiltinClasses(Program *p) {
  std::vector<Feature *> methods;

  // --- Object ---------------------------------------------------------
  declare(methods, strings::Abort, strings::Void);
  declare(methods, strings::TypeName, strings::String);
  declare(methods, strings::Copy, strings::Object);
  // Slots 3 to 5: reference counting. These sit on Object, so every class
  // has them, and every subclass's own methods start at slot 6. There is no
  // unconditional "free it now": the compiler counts references, so one
  // would leave counted references pointing at freed memory.
  declare(methods, "retain", strings::Object);
  declare(methods, "release", strings::Void);
  declare(methods, "refs", strings::Int);
  addBuiltinClass(p, strings::Object, "", methods);

  // --- IO -------------------------------------------------------------
  declare(methods, strings::In, strings::String);
  declare(methods, strings::Out, strings::Io, {{strings::Message, strings::String}});
  declare(methods, strings::ReadLine, strings::String);
  declare(methods, strings::Eof, strings::Int);
  // A seed for a random number generator: the only unpredictable thing the
  // runtime supplies, since the generator itself is in lib/random.cmm.
  declare(methods, strings::Entropy, strings::Int);
  // Time. Only these three readings come from the runtime; turning a
  // timestamp into a date is arithmetic and lives in lib/time.cmm.
  declare(methods, strings::Ticks, strings::Int);
  declare(methods, strings::Epoch, strings::Int64); // 64-bit, so past 2038
  declare(methods, strings::LocalOffset, strings::Int);
  declare(methods, strings::Sleep, strings::Io, {{"milliseconds", strings::Int}});
  declare(methods, "args", strings::Int);
  declare(methods, "arg", strings::String, {{"index", strings::Int}});
  declare(methods, "err", strings::Io, {{strings::Message, strings::String}});
  declare(methods, "exit", strings::Void, {{"code", strings::Int}});
  declare(methods, "allocated", strings::Int);
  addBuiltinClass(p, strings::Io, strings::Object, methods);

  // --- String ---------------------------------------------------------
  declare(methods, strings::Length, strings::Int);
  declare(methods, strings::ToInt, strings::Int);
  declare(methods, strings::Substr, strings::String,
          {{"start", strings::Int}, {"end", strings::Int}});
  declare(methods, strings::Concat, strings::String, {{"other", strings::String}});
  declare(methods, strings::Equals, strings::Int, {{"other", strings::String}});
  // The character code at an index, which is what a hash needs.
  declare(methods, strings::At, strings::Int, {{"index", strings::Int}});
  declare(methods, "indexOf", strings::Int, {{"needle", strings::String}});
  declare(methods, "trim", strings::String);
  declare(methods, "upper", strings::String);
  declare(methods, "lower", strings::String);
  declare(methods, "split", strings::List, {{"separator", strings::String}});
  declare(methods, "replace", strings::String,
          {{"from", strings::String}, {"to", strings::String}});
  declare(methods, "toFloat", strings::Float);
  // Static, and so after every slot-taking method: a character code does not
  // belong to a particular String. Written String.chr(65).
  declareStatic(methods, "chr", strings::String, {{"code", strings::Int}});
  addBuiltinClass(p, strings::String, strings::Object, methods);

  // --- List, the one container the runtime provides -------------------
  declare(methods, strings::Length, strings::Int);
  declare(methods, strings::Get, strings::Object, {{"index", strings::Int}});
  declare(methods, strings::Set, strings::Object,
          {{"index", strings::Int}, {"value", strings::Object}});
  declare(methods, strings::Append, strings::List, {{"value", strings::Object}});
  declare(methods, strings::Slice, strings::List,
          {{"start", strings::Int}, {"end", strings::Int}});
  addBuiltinClass(p, strings::List, strings::Object, methods);

  // --- Integer, the box that lets a number live in a List -------------
  // No setter: small values are shared boxes, so changing one in place
  // would change that number for everyone holding it.
  declare(methods, strings::Get, strings::Int);
  declare(methods, strings::GetLong, strings::Int64);
  addBuiltinClass(p, strings::Integer, strings::Object, methods);

  // --- File -----------------------------------------------------------
  declare(methods, "open", strings::Int,
          {{"path", strings::String}, {"mode", strings::String}});
  declare(methods, strings::ReadLine, strings::String);
  declare(methods, "readAll", strings::String);
  declare(methods, "write", strings::File, {{"text", strings::String}});
  declare(methods, strings::Eof, strings::Int);
  declare(methods, "close", strings::File);
  declare(methods, "isOpen", strings::Int);
  // These two are about a path, not about an open file.
  declareStatic(methods, "exists", strings::Int, {{"path", strings::String}});
  declareStatic(methods, "remove", strings::Int, {{"path", strings::String}});
  addBuiltinClass(p, strings::File, strings::Object, methods);

  // --- Math -----------------------------------------------------------
  // A shell over libm, with no state. Every method is static, so the class
  // takes no virtual table slots at all and exists to name the functions.
  for (const char *name : {"sqrt"}) declareStatic(methods, name, strings::Float, {{"x", strings::Float}});
  declareStatic(methods, "pow", strings::Float, {{"x", strings::Float}, {"y", strings::Float}});
  for (const char *name : {"exp", "log", "log10", "sin", "cos", "tan"})
    declareStatic(methods, name, strings::Float, {{"x", strings::Float}});
  declareStatic(methods, "atan2", strings::Float, {{"y", strings::Float}, {"x", strings::Float}});
  for (const char *name : {"floor", "ceil", "round", "absf"})
    declareStatic(methods, name, strings::Float, {{"x", strings::Float}});
  declareStatic(methods, "abs", strings::Int, {{"x", strings::Int}});
  for (const char *name : {"min", "max"})
    declareStatic(methods, name, strings::Int, {{"a", strings::Int}, {"b", strings::Int}});
  declareStatic(methods, "pi", strings::Float);
  declareStatic(methods, "e", strings::Float);
  addBuiltinClass(p, strings::Math, strings::Object, methods);

  // --- Process, another program running beside this one ---------------
  declare(methods, "open", strings::Int,
          {{"command", strings::String}, {"mode", strings::String}});
  declare(methods, strings::ReadLine, strings::String);
  declare(methods, "write", strings::Process, {{"text", strings::String}});
  declare(methods, strings::Eof, strings::Int);
  declare(methods, "finish", strings::Int);
  declareStatic(methods, "run", strings::Int, {{"command", strings::String}});
  declareStatic(methods, "start", strings::Int, {{"command", strings::String}});
  declareStatic(methods, "wait", strings::Int, {{"pid", strings::Int}});
  declareStatic(methods, "pid", strings::Int);
  addBuiltinClass(p, strings::Process, strings::Object, methods);

  // --- Bytes, Ints, Floats: numbers stored as numbers -----------------
  //
  // Three concrete classes rather than one generic one, because catmint has
  // no generics. Each has the same four slot-taking methods in the same
  // order, and a constructor, which takes no slot.
  struct { const char *name; const char *element; } arrays[] = {
      {strings::Bytes, strings::Int},
      {strings::Ints, strings::Int64},
      {strings::Floats, strings::Float},
  };
  for (const auto &array : arrays) {
    declare(methods, strings::Init, strings::Void, {{"count", strings::Int}});
    declare(methods, strings::Length, strings::Int);
    declare(methods, strings::Get, array.element, {{"index", strings::Int}});
    declare(methods, strings::Set, array.element,
            {{"index", strings::Int}, {"value", array.element}});
    declare(methods, strings::Fill, array.name, {{"value", array.element}});
    addBuiltinClass(p, array.name, strings::Object, methods);
  }

  // --- Worker, a thread reached only through `spawn` ------------------
  declareStatic(methods, "wait", strings::Int64, {{"handle", strings::Int}});
  declareStatic(methods, "count", strings::Int);
  addBuiltinClass(p, strings::Worker, strings::Object, methods);
}

bool TypeTable::isBuiltinClass(Class *c) const {
  // The class says so itself, set where it was declared. This used to be a
  // list of names here, and a new built-in missing from it went down the
  // user-class path, where its body-less methods were rejected with a
  // confusing type error.
  return c && c->isBuiltin();
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

Type *TypeTable::getFloatType() const {
  assert(typeTable.count(strings::Float) && "Float type not defined");
  return typeTable.at(strings::Float);
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

// Should transfer from one to another here if Main class
Type *TypeTable::createNewType(Class *cls) {
  if (typeTable.count(cls->getName())) {
    std::cout << "Duplicate!!!\n";
    throw DuplicateClassException(cls);
  }
  assert(!nodeTypeTable.count(cls) && "Class already associated with type");

  auto NewType = new Type(cls);
  typeTable[cls->getName()] = NewType;
  nodeTypeTable[cls] = NewType;

  buildFeatureTable(cls);

  return NewType;
}

// This is incomplete
Type *TypeTable::getCommonType(Type *T, Type *U) const {

  auto TN = T->getName();
  auto UN = U->getName();

  if (TN == UN) {
    return T;
  }

  // Two integer types meet at the wider of the two.
  const int widthT = integerWidth(TN);
  const int widthU = integerWidth(UN);
  if (widthT && widthU) {
    return widthT >= widthU ? T : U;
  }
  if (widthT && widthT != 32) TN = strings::Int;
  if (widthU && widthU != 32) UN = strings::Int;

  // Implicit potential conversions
  if (TN == strings::Int) {
    // Promotion to float if any are float
    if (UN == strings::Float) return getFloatType();
    // 2 * "t" = "tt"
    if (UN == strings::String) return getStringType();
  }

  if (TN == strings::Float) {
    // Promotion to float if any are float
    if (UN == strings::Int) return getFloatType();
  }

  if (TN == strings::String && (UN == strings::Int || UN == strings::Float)) {
    return getStringType();
  }

  // null belongs to every reference type, so a branch returning null and one
  // returning an object agree on the object's type rather than on nothing.
  if (TN == strings::Null && isReferenceType(UN)) return U;
  if (UN == strings::Null && isReferenceType(TN)) return T;

  // Two classes meet at their nearest shared ancestor. Object is the root, so
  // any two classes have one.
  if (isReferenceType(TN) && isReferenceType(UN)) {
    for (auto *c = getType(TN)->getClass(); c;) {
      if (isDerivedFrom(UN, c->getName())) {
        return getType(c->getName());
      }
      auto parent = parentTable.find(c);
      c = parent == parentTable.end() ? nullptr : parent->second;
    }
  }

  return getVoidType();
}

// Try to do more stuff here - no semantic analysis, just do what is feasible
std::string TypeTable::getCommonTypeStr(std::string T, std::string U) const {
  // Any object - try to walk hierarchy here as well
  if (T == U)
    return T;

  // Two integer types meet at the wider of the two, so mixing an Int with an
  // Int64 gives an Int64 and the narrower operand is sign-extended.
  const int widthT = integerWidth(T);
  const int widthU = integerWidth(U);
  if (widthT && widthU) {
    return widthT >= widthU ? T : U;
  }
  // Every integer type converts to a Float and prints as a String, and the
  // rules below are written for Int, so widen the question to it.
  if (widthT && widthT != 32) T = strings::Int;
  if (widthU && widthU != 32) U = strings::Int;
  if (T == U)
    return T;

  // Implicit potential conversions
  if (T == strings::Int) {
    // Promotion to float if any are float
    if (U == strings::Float) return strings::Float;
    // 2 * "t" = "tt"
    if (U == strings::String) return strings::String;
  }

  if (T == strings::Float) {
    if (U == strings::Int) return strings::Float;
    // Printing a Float goes through the same conversion as printing an Int;
    // the generator inserts __cm_floatToString.
    if (U == strings::String) return strings::String;
  }

  // The numeric-to-String rules were only written one way round, so
  // '1 + "a"' was allowed and '"a" + 1' was not.
  if (T == strings::String &&
      (U == strings::Int || U == strings::Float)) {
    return strings::String;
  }

  if (T == strings::Null && isReferenceType(U)) return U;
  if (U == strings::Null && isReferenceType(T)) return T;

  return strings::Void;
}

// Careful here
bool TypeTable::isDerivedFrom(const std::string &derived,
                              const std::string &base) const {
  if (derived == base) {
    return true;
  }
  auto it = typeTable.find(derived);
  if (it == typeTable.end()) {
    return false;
  }
  for (Class *c = it->second->getClass(); c;) {
    if (c->getName() == base) {
      return true;
    }
    // An interface is not in the parent chain, so a class reaches one by
    // having said `does`. Checking at every step means a subclass inherits
    // what its parent promised.
    for (const auto &implemented : c->getInterfaces()) {
      if (implemented == base) {
        return true;
      }
    }
    auto parent = parentTable.find(c);
    c = parent == parentTable.end() ? nullptr : parent->second;
  }
  return false;
}

bool TypeTable::isInterface(const std::string &name) const {
  auto it = typeTable.find(name);
  if (it == typeTable.end() || !it->second->getClass()) {
    return false;
  }
  return it->second->getClass()->isInterface();
}

bool TypeTable::isReferenceType(const std::string &name) const {
  if (integerWidth(name) != 0 || name == strings::Float ||
      name == strings::Void) {
    return false;
  }
  auto it = typeTable.find(name);
  return it != typeTable.end() && it->second->getClass() != nullptr;
}

bool TypeTable::isEqualOrImplicitlyConvertibleTo(Type *fromType, Type *toType) {
  
  // Cover case of void and void, though why this would happen beats me
  auto from = fromType->getName();
  auto to = toType->getName();
  if (from == to) return true;
  
  if (getCommonTypeStr(fromType->getName(), toType->getName()) != strings::Void)
    return true;

  // Null stands in for any object.
  if (from == strings::Null && isReferenceType(to)) {
    return true;
  }

  // An Int boxes into an Integer wherever object references are held, and
  // unboxes on the way back out. This is what lets a List hold numbers in a
  // language with no generics; the generator inserts the conversion.
  if (integerWidth(from) && isReferenceType(to)) {
    return true;
  }
  if (isReferenceType(from) && integerWidth(to)) {
    return true;
  }

  // Up the hierarchy is free. Down it is allowed too, and checked at run time
  // by the generated cast, so that a value taken out of an Object-typed
  // container can be assigned to a variable of its real type without cast
  // syntax.
  if (isReferenceType(from) && isReferenceType(to)) {
    return isDerivedFrom(from, to) || isDerivedFrom(to, from);
  }

  return false;
}

bool TypeTable::isEqualOrImplicitlyConvertibleToStr(std::string from, std::string to) {
  if (from == to)
    return true;

  // Now explain all conversions 
  if (getCommonTypeStr(from, to) != strings::Void)
    return true;

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
