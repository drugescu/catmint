
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
void TypeTable::addBuiltinClasses(Program *p) {
  std::vector<Feature *> builtinMethods;
  //std::vector<FormalParam *> builtinMethodsParams;
  std::vector<Attribute *> builtinMethodsParams;

  // ---------------------------------------------------------------------------
  // Add built-in class - 'Object'
  // ---------------------------------------------------------------------------
  
  // Method(int, string &name, string &returnType, Expression* body, vector<...> &formalParameters
  // Method - 'Obj_object.abort()' returning 'Void'
  builtinMethods.push_back(new Method(0, strings::Abort, strings::Void, nullptr,
                                      builtinMethodsParams));

  // Method - 'Obj_object.type()' returning obj of type 'String'
  builtinMethods.push_back(new Method(0, strings::TypeName, strings::String,
                                      nullptr, builtinMethodsParams));

  // Method - 'Obj_object.copy()' returning obj of type 'Object'
  builtinMethods.push_back(new Method(0, strings::Copy, strings::Object,
                                      nullptr, builtinMethodsParams));

  // Slots 3 to 6: giving memory back. These sit on Object, so every class
  // has them, which means every subclass's own methods now start at slot 7.
  builtinMethods.push_back(
      new Method(0, "free", strings::Void, nullptr, builtinMethodsParams));
  builtinMethods.push_back(
      new Method(0, "retain", strings::Object, nullptr, builtinMethodsParams));
  builtinMethods.push_back(
      new Method(0, "release", strings::Void, nullptr, builtinMethodsParams));
  builtinMethods.push_back(
      new Method(0, "refs", strings::Int, nullptr, builtinMethodsParams));
  
  // Add these methods to class 'Object' with no parent, add class to typeTable,  park it in the program
  std::unique_ptr<Class> objectClass(
      new Class(0, strings::Object, "", builtinMethods));
  (void)createNewType(objectClass.get());
  p->addClass(std::move(objectClass)); // we're parking this in the program, so
                                       // someone will have ownership of it, but
                                       // it's not very nice of us...

  builtinMethods.clear();
  builtinMethodsParams.clear();

  // ---------------------------------------------------------------------------
  // Add built-in class - 'IO'
  // ---------------------------------------------------------------------------

  // Method - 'IO_object.in(String message)' returning obj of type 'String'
  builtinMethods.push_back(new Method(0, strings::In, strings::String, nullptr,
                                      builtinMethodsParams));
  
  // Method - 'IO_object.out(String message)' returning obj of type 'IO'
  builtinMethodsParams.push_back(
      // Attribute(int lineNum, const std::string &name, const std::string &type, catmint::Program::ExprType init = nullptr)
      new Attribute(0, strings::Message, strings::String));
  builtinMethods.push_back(
      new Method(0, strings::Out, strings::Io, nullptr, builtinMethodsParams));

  // Appended after 'out' on purpose: the virtual table slot of a built-in is
  // fixed by runtime.c, and inserting earlier would renumber 'input' and
  // 'out'. Declaration order here is slot order there.
  builtinMethodsParams.clear();
  // Method - 'IO_object.readLine()' returning obj of type 'String'
  builtinMethods.push_back(new Method(0, strings::ReadLine, strings::String,
                                      nullptr, builtinMethodsParams));
  // Method - 'IO_object.eof()' returning an 'Int'
  builtinMethods.push_back(
      new Method(0, strings::Eof, strings::Int, nullptr, builtinMethodsParams));
  // Method - 'IO_object.entropy()' returning an 'Int': a seed for a random
  // number generator, the only unpredictable thing the runtime supplies.
  builtinMethods.push_back(new Method(0, strings::Entropy, strings::Int,
                                      nullptr, builtinMethodsParams));

  // Time. Only these three readings come from the runtime; turning a
  // timestamp into a date is integer arithmetic and lives in lib/time.cmm.
  builtinMethods.push_back(
      new Method(0, strings::Ticks, strings::Int, nullptr, builtinMethodsParams));
  // Seconds since 1970 is an Int64, so it keeps working past 2038.
  builtinMethods.push_back(new Method(0, strings::Epoch, strings::Int64,
                                      nullptr, builtinMethodsParams));
  builtinMethods.push_back(new Method(0, strings::LocalOffset, strings::Int,
                                      nullptr, builtinMethodsParams));

  builtinMethodsParams.clear();
  builtinMethodsParams.push_back(new Attribute(0, "milliseconds", strings::Int));
  builtinMethods.push_back(
      new Method(0, strings::Sleep, strings::Io, nullptr, builtinMethodsParams));

  // Slots 12 to 15: the command line, standard error and the exit status.
  builtinMethodsParams.clear();
  builtinMethods.push_back(
      new Method(0, "args", strings::Int, nullptr, builtinMethodsParams));

  builtinMethodsParams.clear();
  builtinMethodsParams.push_back(new Attribute(0, "index", strings::Int));
  builtinMethods.push_back(
      new Method(0, "arg", strings::String, nullptr, builtinMethodsParams));

  builtinMethodsParams.clear();
  builtinMethodsParams.push_back(new Attribute(0, strings::Message, strings::String));
  builtinMethods.push_back(
      new Method(0, "err", strings::Io, nullptr, builtinMethodsParams));

  builtinMethodsParams.clear();
  builtinMethodsParams.push_back(new Attribute(0, "code", strings::Int));
  builtinMethods.push_back(
      new Method(0, "exit", strings::Void, nullptr, builtinMethodsParams));

  builtinMethodsParams.clear();
  builtinMethods.push_back(
      new Method(0, "allocated", strings::Int, nullptr, builtinMethodsParams));
  builtinMethodsParams.clear();
  
  // Add these methods to class 'IO' which inherits 'Object', add class to typeTable,  park it in the program
  // Class(int, const std::string &name, const std::string &parentClassName, const std::vector<...> &features = {})
  std::unique_ptr<Class> ioClass(
      new Class(0, strings::Io, strings::Object, builtinMethods));
  (void)createNewType(ioClass.get());
  p->addClass(std::move(ioClass));

  builtinMethods.clear();
  builtinMethodsParams.clear();

  // ---------------------------------------------------------------------------
  // Add built-in class - 'String'
  // ---------------------------------------------------------------------------

  // Method - 'String_object.len()' returning an 'Int'
  builtinMethods.push_back(new Method(0, strings::Length, strings::Int, nullptr,
                                      builtinMethodsParams));
  // Method - 'String_object.toInt()' returning an 'Int'
  builtinMethods.push_back(new Method(0, strings::ToInt, strings::Int, nullptr,
                                      builtinMethodsParams));

  // The next three were always in runtime.c's virtual table but were never
  // declared here, so slots 5 to 7 existed without a way to call them.
  // Declaration order is slot order, so they go in exactly this sequence.
  builtinMethodsParams.clear();
  builtinMethodsParams.push_back(new Attribute(0, "start", strings::Int));
  builtinMethodsParams.push_back(new Attribute(0, "end", strings::Int));
  builtinMethods.push_back(new Method(0, strings::Substr, strings::String,
                                      nullptr, builtinMethodsParams));

  builtinMethodsParams.clear();
  builtinMethodsParams.push_back(new Attribute(0, "other", strings::String));
  builtinMethods.push_back(new Method(0, strings::Concat, strings::String,
                                      nullptr, builtinMethodsParams));

  builtinMethodsParams.clear();
  builtinMethodsParams.push_back(new Attribute(0, "other", strings::String));
  builtinMethods.push_back(new Method(0, strings::Equals, strings::Int, nullptr,
                                      builtinMethodsParams));

  // New slot 8: the character code at an index, which is what a hash needs.
  builtinMethodsParams.clear();
  builtinMethodsParams.push_back(new Attribute(0, "index", strings::Int));
  builtinMethods.push_back(
      new Method(0, strings::At, strings::Int, nullptr, builtinMethodsParams));

  // Slots 9 to 16: the text operations a program needs on its first page.
  // These names are not remapped in IRGenerator::runtimeSymbol, so the C
  // functions are named by the ordinary mangling, M6_String_<name>.
  builtinMethodsParams.clear();
  builtinMethodsParams.push_back(new Attribute(0, "needle", strings::String));
  builtinMethods.push_back(
      new Method(0, "indexOf", strings::Int, nullptr, builtinMethodsParams));

  builtinMethodsParams.clear();
  builtinMethods.push_back(
      new Method(0, "trim", strings::String, nullptr, builtinMethodsParams));
  builtinMethods.push_back(
      new Method(0, "upper", strings::String, nullptr, builtinMethodsParams));
  builtinMethods.push_back(
      new Method(0, "lower", strings::String, nullptr, builtinMethodsParams));

  builtinMethodsParams.clear();
  builtinMethodsParams.push_back(new Attribute(0, "separator", strings::String));
  builtinMethods.push_back(
      new Method(0, "split", strings::List, nullptr, builtinMethodsParams));

  builtinMethodsParams.clear();
  builtinMethodsParams.push_back(new Attribute(0, "code", strings::Int));
  builtinMethods.push_back(
      new Method(0, "chr", strings::String, nullptr, builtinMethodsParams));

  builtinMethodsParams.clear();
  builtinMethodsParams.push_back(new Attribute(0, "from", strings::String));
  builtinMethodsParams.push_back(new Attribute(0, "to", strings::String));
  builtinMethods.push_back(
      new Method(0, "replace", strings::String, nullptr, builtinMethodsParams));

  builtinMethodsParams.clear();
  builtinMethods.push_back(
      new Method(0, "toFloat", strings::Float, nullptr, builtinMethodsParams));
  builtinMethodsParams.clear();
  
  // Add these methods to class 'String' which inherits 'Object', add class to typeTable,  park it in the program
  // Class(int, const std::string &name, const std::string &parentClassName, const std::vector<...> &features = {})
  std::unique_ptr<Class> stringClass(
      new Class(0, strings::String, strings::Object, builtinMethods));
  (void)createNewType(stringClass.get());
  p->addClass(std::move(stringClass));

  builtinMethods.clear();
  builtinMethodsParams.clear();

  // ---------------------------------------------------------------------------
  // Add built-in class - 'List'
  //
  // The one container the runtime provides: a growable array of object
  // references. Declaration order is virtual table slot order and must match
  // RList in runtime.c.
  // ---------------------------------------------------------------------------

  // 'len()' returning an 'Int'
  builtinMethods.push_back(new Method(0, strings::Length, strings::Int, nullptr,
                                      builtinMethodsParams));

  // Method takes ownership of each Attribute it is given, so every method
  // needs its own freshly allocated parameters. Reusing one vector across two
  // methods would hand the same object to two owners.

  // 'get(Int index)' returning an 'Object'
  builtinMethodsParams.clear();
  builtinMethodsParams.push_back(new Attribute(0, "index", strings::Int));
  builtinMethods.push_back(new Method(0, strings::Get, strings::Object, nullptr,
                                      builtinMethodsParams));

  // 'set(Int index, Object value)' returning the value
  builtinMethodsParams.clear();
  builtinMethodsParams.push_back(new Attribute(0, "index", strings::Int));
  builtinMethodsParams.push_back(new Attribute(0, "value", strings::Object));
  builtinMethods.push_back(new Method(0, strings::Set, strings::Object, nullptr,
                                      builtinMethodsParams));

  // 'append(Object value)' returning the list
  builtinMethodsParams.clear();
  builtinMethodsParams.push_back(new Attribute(0, "value", strings::Object));
  builtinMethods.push_back(new Method(0, strings::Append, strings::List,
                                      nullptr, builtinMethodsParams));

  // 'slice(Int start, Int end)' returning a new 'List'
  builtinMethodsParams.clear();
  builtinMethodsParams.push_back(new Attribute(0, "start", strings::Int));
  builtinMethodsParams.push_back(new Attribute(0, "end", strings::Int));
  builtinMethods.push_back(new Method(0, strings::Slice, strings::List, nullptr,
                                      builtinMethodsParams));

  std::unique_ptr<Class> listClass(
      new Class(0, strings::List, strings::Object, builtinMethods));
  (void)createNewType(listClass.get());
  p->addClass(std::move(listClass));

  builtinMethods.clear();
  builtinMethodsParams.clear();

  // ---------------------------------------------------------------------------
  // Add built-in class - 'Integer', the box that lets an Int live in a List
  // ---------------------------------------------------------------------------

  builtinMethodsParams.clear();
  builtinMethods.push_back(new Method(0, strings::Get, strings::Int, nullptr,
                                      builtinMethodsParams));
  builtinMethodsParams.clear();
  builtinMethodsParams.push_back(new Attribute(0, "value", strings::Int));
  builtinMethods.push_back(new Method(0, strings::Set, strings::Integer,
                                      nullptr, builtinMethodsParams));

  // Appended: the whole 64-bit value, where get() truncates to an Int.
  builtinMethodsParams.clear();
  builtinMethods.push_back(new Method(0, strings::GetLong, strings::Int64,
                                      nullptr, builtinMethodsParams));

  std::unique_ptr<Class> integerClass(
      new Class(0, strings::Integer, strings::Object, builtinMethods));
  (void)createNewType(integerClass.get());
  p->addClass(std::move(integerClass));

  builtinMethods.clear();
  builtinMethodsParams.clear();

  // ---------------------------------------------------------------------------
  // Add built-in class - 'File'
  //
  // The handle is the whole of the state. open() answers 1 or 0 rather than
  // aborting, because a missing file is something a program has an opinion
  // about. Declaration order is virtual table slot order and must match
  // RFile in runtime.c.
  // ---------------------------------------------------------------------------

  builtinMethodsParams.push_back(new Attribute(0, "path", strings::String));
  builtinMethodsParams.push_back(new Attribute(0, "mode", strings::String));
  builtinMethods.push_back(
      new Method(0, "open", strings::Int, nullptr, builtinMethodsParams));

  builtinMethodsParams.clear();
  builtinMethods.push_back(new Method(0, strings::ReadLine, strings::String,
                                      nullptr, builtinMethodsParams));
  builtinMethods.push_back(
      new Method(0, "readAll", strings::String, nullptr, builtinMethodsParams));

  builtinMethodsParams.clear();
  builtinMethodsParams.push_back(new Attribute(0, "text", strings::String));
  builtinMethods.push_back(
      new Method(0, "write", strings::File, nullptr, builtinMethodsParams));

  builtinMethodsParams.clear();
  builtinMethods.push_back(
      new Method(0, strings::Eof, strings::Int, nullptr, builtinMethodsParams));
  builtinMethods.push_back(
      new Method(0, "close", strings::File, nullptr, builtinMethodsParams));
  builtinMethods.push_back(
      new Method(0, "isOpen", strings::Int, nullptr, builtinMethodsParams));

  builtinMethodsParams.clear();
  builtinMethodsParams.push_back(new Attribute(0, "path", strings::String));
  builtinMethods.push_back(
      new Method(0, "exists", strings::Int, nullptr, builtinMethodsParams));

  builtinMethodsParams.clear();
  builtinMethodsParams.push_back(new Attribute(0, "path", strings::String));
  builtinMethods.push_back(
      new Method(0, "remove", strings::Int, nullptr, builtinMethodsParams));

  std::unique_ptr<Class> fileClass(
      new Class(0, strings::File, strings::Object, builtinMethods));
  (void)createNewType(fileClass.get());
  p->addClass(std::move(fileClass));

  builtinMethods.clear();
  builtinMethodsParams.clear();

  // ---------------------------------------------------------------------------
  // Add built-in class - 'Math'
  //
  // A shell over libm, with no state. The language has no free functions, so
  // this is where they live. Declaration order must match RMath in runtime.c.
  // ---------------------------------------------------------------------------

  // One entry per slot, in RMath's order. Written out rather than generated
  // from a table, because the order is the calling convention.
  auto oneFloat = [&](const char *name) {
    builtinMethodsParams.clear();
    builtinMethodsParams.push_back(new Attribute(0, "x", strings::Float));
    builtinMethods.push_back(
        new Method(0, name, strings::Float, nullptr, builtinMethodsParams));
  };
  auto twoFloats = [&](const char *name, const char *first,
                       const char *second) {
    builtinMethodsParams.clear();
    builtinMethodsParams.push_back(new Attribute(0, first, strings::Float));
    builtinMethodsParams.push_back(new Attribute(0, second, strings::Float));
    builtinMethods.push_back(
        new Method(0, name, strings::Float, nullptr, builtinMethodsParams));
  };
  auto twoInts = [&](const char *name) {
    builtinMethodsParams.clear();
    builtinMethodsParams.push_back(new Attribute(0, "a", strings::Int));
    builtinMethodsParams.push_back(new Attribute(0, "b", strings::Int));
    builtinMethods.push_back(
        new Method(0, name, strings::Int, nullptr, builtinMethodsParams));
  };

  oneFloat("sqrt");
  twoFloats("pow", "x", "y");
  oneFloat("exp");
  oneFloat("log");
  oneFloat("log10");
  oneFloat("sin");
  oneFloat("cos");
  oneFloat("tan");
  twoFloats("atan2", "y", "x");
  oneFloat("floor");
  oneFloat("ceil");
  oneFloat("round");
  oneFloat("absf");

  builtinMethodsParams.clear();
  builtinMethodsParams.push_back(new Attribute(0, "x", strings::Int));
  builtinMethods.push_back(
      new Method(0, "abs", strings::Int, nullptr, builtinMethodsParams));

  twoInts("min");
  twoInts("max");

  builtinMethodsParams.clear();
  builtinMethods.push_back(
      new Method(0, "pi", strings::Float, nullptr, builtinMethodsParams));
  builtinMethods.push_back(
      new Method(0, "e", strings::Float, nullptr, builtinMethodsParams));

  std::unique_ptr<Class> mathClass(
      new Class(0, strings::Math, strings::Object, builtinMethods));
  (void)createNewType(mathClass.get());
  p->addClass(std::move(mathClass));
}

bool TypeTable::isBuiltinClass(Class *c) const {
  if (!c) {
    return false;
  }
  // Compare by name: a built-in's methods have no body, so missing one here
  // sends it down the user-class path and the body-less methods are rejected.
  const std::string &name = c->getName();
  return name == strings::Object || name == strings::String ||
         name == strings::Io || name == strings::List ||
         name == strings::Integer || name == strings::File ||
         name == strings::Math;
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
    auto parent = parentTable.find(c);
    c = parent == parentTable.end() ? nullptr : parent->second;
  }
  return false;
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
