
#include <cassert>
#include <iostream>
#include <unordered_set>

#include <ASTNodes.h>
#include <SemanticAnalysis.h>
#include <SemanticException.h>
#include <StringConstants.h>
//#include <TypeVisitor.h>

using namespace catmint;

namespace {
/// Whether an expression tree contains a `return`. A method whose body ends
/// in a statement rather than a value -- a try, a loop -- has the type Void,
/// but it can still produce its result by returning from inside, so the
/// block's type says nothing in that case.
class ReturnFinder : public ASTVisitor {
public:
  using ASTVisitor::visit;

  bool Found = false;
  bool visit(ReturnExpression *R) override {
    Found = true;
    return ASTVisitor::visit(R);
  }
};
} // namespace

SemanticAnalysis::SemanticAnalysis(Program *p, bool libraryOnly)
    : program(p), libraryOnly(libraryOnly), typeTable(p), symbolTable(),
      typeVisitor(TypeVisitor(&typeTable)) {

  //typeVisitor = TypeVisitor(&typeTable);

  assert(program && "Expected non-null program");
}

void SemanticAnalysis::runAnalysis() {
  assert(program && "Expected non-null program");
  visit(program);
}

bool SemanticAnalysis::visit(Program *p) {

  std::cout << "Starting Semantic Analysis..." << std::endl;

  // Check that main exists (we have inserted it manually) and inheritance graph.
  // A library compiled on its own has no entry point, so only the inheritance
  // graph is checked there.
  if (!libraryOnly) {
    checkMainClassAndMethod();
  }
  checkInheritanceGraph();
  
  auto mainVisits = 0;

  std::map<Class *, bool> processed;
  for (auto c : *p) {
    std::cout << "Class : " << c->getName() << "\n";
    fflush(stdout);
    if (processed[c]) {
      if (static_cast<Class *>(c)) {
        // There is one main auto-inserted, and another in your code
        if (c->getName() == "Main") {
          std::cout << "Main here.\n";
          fflush(stdout);
          //if (mainVisits >= 2)
          //     throw DuplicateClassException(c);
        }
      }
      else {
        std::cout << "Duplicated.\n";
        fflush(stdout);
        //throw DuplicateClassException(c);
      }
    }

    processed[c] = true;
    /*if (dynamic_cast<Class *>(c)) {
      if (c->getName() == "Main") {
        mainVisits++;
      }
    }*/

    if (!visit(c)) {
      return false;
    }
  }

  return true;
}

// Visit class by visiting attributes and adding symbols/types to tables
bool SemanticAnalysis::visit(Class *c) {
  // An interface is a list of signatures. Its methods have no bodies, so
  // there is nothing to walk, and nothing may be declared in it but methods.
  if (c->isInterface()) {
    for (auto f : *c) {
      if (!f->isMethod()) {
        throw SemanticException("an interface may declare only methods, and '" +
                                c->getName() + "' declares '" + f->getName() +
                                "'");
      }
    }
    return true;
  }

  checkImplementedInterfaces(c);

  if (typeTable.isBuiltinClass(c)) {// visiting builtin classes is a lot simpler than user classes, because we
    // don't need to check anything, we just need to add method parameters to
    // the type table
    SymbolTable::Scope BuiltinScope(symbolTable, c->getName());
    for (auto f : *c) {
      if (f->isMethod()) {
        auto method = static_cast<Method *>(f);
        for (auto param : *method) {
          if (!visit(param)) {
            return false;
          }
        }
      }
    }

    return true;
  }

  // Remembered so that a bare call can be resolved against this class's own
  // static methods, which have no receiver to look at.
  currentClass = c;

  // Create a scope and add all attributes to it
  SymbolTable::Scope classScope(symbolTable, c->getName());
  for (auto currentClass = c; currentClass;
       currentClass = typeTable.getParentClass(currentClass)) {
    for (auto f : *currentClass) {
      if (f->isAttribute()) {

        auto attr = static_cast<Attribute *>(f);
        symbolTable.insert(attr);

        auto attrType = typeTable.getType(attr->getType());
        typeTable.setType(attr, attrType);
      }
    }
  }

  // Add self to symbol table
  std::vector<std::string> def_names;
  def_names.push_back("self");
  std::unique_ptr<LocalDefinition> self(
      // line of code, name, type
      new LocalDefinition(0, def_names, c->getName())
  );
  
  symbolTable.insert(self.get());
  typeTable.setType(self.get(), typeTable.getType(c));

  // Verify class features
  checkFeatures(c);

  return ASTVisitor::visit(c);
}

/// Every method an interface names has to exist on the class that promised
/// it, with the same signature. Checked here rather than at the call site,
/// so a class that does not keep its promise is reported where the promise
/// is made.
void SemanticAnalysis::checkImplementedInterfaces(Class *c) {
  for (const auto &name : c->getInterfaces()) {
    auto interfaceType = typeTable.getType(name, c);
    auto interfaceClass = interfaceType->getClass();
    if (!interfaceClass || !interfaceClass->isInterface()) {
      throw SemanticException("'" + c->getName() + "' says it does '" + name +
                              "', which is not an interface");
    }

    for (auto f : *interfaceClass) {
      auto required = static_cast<Method *>(f);
      auto provided = typeTable.getMethod(c, required->getName());
      if (!provided) {
        throw SemanticException("'" + c->getName() + "' says it does '" + name +
                                "' but has no method '" + required->getName() +
                                "'");
      }
      if (provided->getReturnType() != required->getReturnType()) {
        throw SemanticException("'" + c->getName() + "." +
                                required->getName() + "' returns '" +
                                provided->getReturnType() + "' where '" + name +
                                "' asks for '" + required->getReturnType() +
                                "'");
      }

      auto givenIt = provided->begin(), givenEnd = provided->end();
      auto wantIt = required->begin(), wantEnd = required->end();
      for (; givenIt != givenEnd && wantIt != wantEnd; ++givenIt, ++wantIt) {
        if ((*givenIt)->getType() != (*wantIt)->getType()) {
          throw SemanticException("'" + c->getName() + "." +
                                  required->getName() +
                                  "' does not take the arguments '" + name +
                                  "' asks for");
        }
      }
      if (givenIt != givenEnd || wantIt != wantEnd) {
        throw SemanticException("'" + c->getName() + "." +
                                required->getName() +
                                "' does not take the arguments '" + name +
                                "' asks for");
      }
    }
  }
}

void SemanticAnalysis::checkFeatures(Class *c) {
  for (auto f : *c) {
    if (f->isAttribute()) {
      auto attr = static_cast<Attribute *>(f);
      if (typeTable.getAttribute(typeTable.getParentClass(c), f->getName())) {
        throw DuplicateAttrException(attr, c);
      }
    } else {
      assert(f->isMethod() && "Unknown feature kind");
      auto method = static_cast<Method *>(f);
      auto hidden =
          typeTable.getMethod(typeTable.getParentClass(c), f->getName());

      // A constructor is not an override: a subclass takes whatever arguments
      // it needs, and the signature of the one it inherits says nothing about
      // them. It is never dispatched virtually either, so there is no slot to
      // keep compatible. A static method has no slot either, for the same
      // reason, so neither is checked against what it hides.
      if (method->getName() == strings::Init || method->isStatic()) {
        continue;
      }

      if (hidden) {
        // check that the signatures match
        if (method->getReturnType() != hidden->getReturnType()) {
          throw InvalidMethodSignatureException(c, method);
        }

        auto methodB = method->begin(), methodE = method->end();
        auto hiddenB = hidden->begin(), hiddenE = hidden->end();

        for (; methodB != methodE && hiddenB != hiddenE; ++methodB, ++hiddenB) {
          auto paramType = typeTable.getType((*methodB)->getType());
          auto hiddenParamType = typeTable.getType((*hiddenB)->getType());

          if (paramType != hiddenParamType) {
            throw InvalidMethodSignatureException(c, method);
          }
        }

        if (methodB != methodE || hiddenB != hiddenE) {
          throw InvalidMethodSignatureException(c, method);
        }
      }
    }
  }
}

bool SemanticAnalysis::visit(Feature *f) { return ASTVisitor::visit(f); }

bool SemanticAnalysis::visit(Attribute *a) {
  auto attrType = typeTable.getType(a->getType(), a);
  // Record the type on the node: a Symbol that resolves to this attribute (or
  // to this method parameter) asks the type table for the definition's type.
  typeTable.setType(a, attrType);

  auto init = a->getInit();
  if (!init) {
    return true;
  }

  if (!visit(init)) {
    return false;
  }

  auto initType = typeTable.getType(init);
  if (!typeTable.isEqualOrImplicitlyConvertibleTo(initType, attrType)) {
    throw WrongTypeException(initType, attrType, a);
  }

  return true;
}

void SemanticAnalysis::checkMainClassAndMethod() {
  auto mainClass = typeTable.getType(strings::MainClass);
  auto mainMethod =
      typeTable.getMethod(mainClass->getClass(), strings::MainMethod);

  if (!mainMethod) {
    throw MethodNotFoundException(strings::MainMethod, mainClass->getClass());
  }
}

void SemanticAnalysis::checkInheritanceGraph() {
  std::map<Class *, int> marker;
  for (auto c : *program) {
    marker[c] = 0;

    if (c->getParent() == strings::Int || c->getParent() == strings::String) {
      throw BadInheritanceException(c, c->getParent());
    }
  }

  int currentMarker = 1;
  for (auto c : *program) {
    while (c != nullptr) {
      if (marker[c] == 0) {
        marker[c] = currentMarker;
        c = typeTable.getParentClass(c);
      } else if (marker[c] == currentMarker) {
        throw BadInheritanceException(c, c->getName());
      } else
        break;
    }
    currentMarker++;
  }
}

bool SemanticAnalysis::visit(Method *m) {
  std::unordered_set<std::string> paramNames;

  SymbolTable::Scope methodScope(symbolTable, m->getName());
  for (auto param : *m) {
    if (paramNames.count(param->getName())) {
      throw DuplicateParamException(param, m);
    }

    paramNames.insert(param->getName());

    if (!visit(param)) {
      return false;
    }

    // Bind the parameter in the method's scope so the body can refer to it.
    symbolTable.insert(param);
  }

  auto returnType = typeTable.getType(m->getReturnType(), m);
  auto body = m->getBody();
  if (body) {
    if (!visit(body)) {
      return false;
    }

    auto bodyType = typeTable.getType(body);
    ReturnFinder returns;
    returns.visit(body);
    if (returnType != typeTable.getVoidType() && !returns.Found &&
        !typeTable.isEqualOrImplicitlyConvertibleTo(bodyType, returnType)) {
      throw WrongTypeException(bodyType, returnType, m);
    }
  } else {
    if (returnType != typeTable.getVoidType()) {
      throw WrongTypeException(returnType, typeTable.getVoidType(), m);
    }
  }

  return true;
}

bool SemanticAnalysis::visit(FormalParam *param) {
  symbolTable.insert(param);
  typeTable.setType(param, typeTable.getType(param->getType(), param));
  return true;
}

bool SemanticAnalysis::visit(Expression *e) { return ASTVisitor::visit(e); }

bool SemanticAnalysis::visit(IntConstant *ic) {
  typeTable.setType(ic, typeTable.getType(static_cast<TreeNode *>(ic)));
  return true;
}

bool SemanticAnalysis::visit(StringConstant *sc) {
  typeTable.setType(sc, typeTable.getStringType());
  return true;
}

bool SemanticAnalysis::visit(NullConstant *nc) {
  typeTable.setType(nc, typeTable.getNullType());
  return true;
}

bool SemanticAnalysis::visit(Symbol *s) {
  auto who = symbolTable.lookup(s->getName(), s);
  typeTable.setType(s, typeTable.getType(who));
  definitionsMap[s] = who;

  return true;
}

bool SemanticAnalysis::visit(Block *b) {
  // Since blocks don't have names/aliases, our named scope will be annonymous as well
  SymbolTable::Scope blockScope(symbolTable, "anonymous_block");

  // visit all expressions first
  if (!ASTVisitor::visit(b)) {
    return false;
  }

  // set the type to match the type of the last expression
  if (b->begin() != b->end()) {
    typeTable.setType(b, typeTable.getType(b->back()));
  } else {
    typeTable.setType(b, typeTable.getVoidType());
  }

  return true;
}

bool SemanticAnalysis::visit(Assignment *a) {
  auto rhs = a->getExpression();

  if (!rhs) {
    throw MissingOperandException(a);
  }

  if (!visit(rhs)) {
    return false;
  }

  auto lhs = symbolTable.lookup(a->getSymbol(), a);

  auto lhsType = typeTable.getType(lhs);
  auto rhsType = typeTable.getType(rhs);

  if (!typeTable.isEqualOrImplicitlyConvertibleTo(rhsType, lhsType)) {
    throw IncompatibleOperandsException(a, lhsType, rhsType);
  }

  typeTable.setType(a, lhsType);

  return true;
}

bool SemanticAnalysis::visit(BinaryOperator *bo) {
  auto LHS = bo->getLHS();
  auto RHS = bo->getRHS();

  std::cout << "  SemanticAnalysis BinaryOperator, kind = " << bo->getOperatorKind() << "\n";

  if (!visit(LHS))
    return false;
  
  if (!visit(RHS))
    return false;

  auto lhsType = typeTable.getType(LHS);
  auto rhsType = typeTable.getType(RHS);

  // 'and' and 'or' ask each side for a truth value rather than combining
  // them, so the two need nothing in common: 'p != null and p.size() > 0'
  // has an Int on both sides, but 'p and p.size() > 0' has an object on the
  // left, and both are meant to work.
  if (bo->isShortCircuit()) {
    typeTable.setType(bo, typeTable.getIntType());
    return true;
  }

  if (!typeTable.isEqualOrImplicitlyConvertibleTo(rhsType, lhsType)) {
    throw IncompatibleOperandsException(bo, lhsType, rhsType);
  }

  // A comparison yields a truth value, which catmint represents as an Int.
  // Without this it took the common type of its operands, so comparing two
  // objects produced an Object and could not be used as a condition.
  if (bo->isComparison()) {
    typeTable.setType(bo, typeTable.getIntType());
  } else {
    typeTable.setType(bo, typeTable.getCommonType(lhsType, rhsType));
  }

  return true;
}

bool SemanticAnalysis::visit(UnaryOperator *uo) {
  auto operand = uo->getOperand();

  if (!operand) {
    throw MissingOperandException(uo);
  }

  assert(uo->getOperatorKind() != UnaryOperator::Invalid &&
         "Can't have invalid unary operators");

  if (!visit(operand)) {
    return false;
  }

  if (!TypeTable::integerWidth(typeTable.getType(operand)->getName())) {
    throw WrongTypeException(typeTable.getType(operand), typeTable.getIntType(),
                             uo);
  }

  typeTable.setType(uo, typeTable.getIntType());

  return true;
}

bool SemanticAnalysis::visit(Cast *c) {
  auto toCast = c->getExpressionToCast();

  if (!toCast) {
    throw MissingOperandException(c);
  }

  if (!visit(toCast)) {
    return false;
  }

  typeTable.setType(c, typeTable.getType(c->getType()));

  return true;
}

bool SemanticAnalysis::visit(Substring *s) {
  auto str = s->getString();
  auto start = s->getStart();
  auto end = s->getEnd();

  if (!str || !start || !end) {
    throw MissingOperandException(s);
  }

  if (!visit(str) || !visit(start) || !visit(end)) {
    return false;
  }

  if (typeTable.getType(str) != typeTable.getStringType()) {
    throw WrongTypeException(typeTable.getType(str), typeTable.getStringType(),
                             s);
  }

  if (typeTable.getType(start) != typeTable.getIntType()) {
    throw WrongTypeException(typeTable.getType(start), typeTable.getIntType(),
                             s);
  }

  if (typeTable.getType(end) != typeTable.getIntType()) {
    throw WrongTypeException(typeTable.getType(end), typeTable.getIntType(), s);
  }

  typeTable.setType(s, typeTable.getStringType());

  return true;
}

/// The class a static call names, or null when this dispatch is an ordinary
/// call. `Math.sqrt(2.0)` reaches the parser as a dispatch whose object is a
/// Symbol; it is a static call when that name is a class rather than a
/// variable, so a variable of the same name still wins.
Class *SemanticAnalysis::staticReceiverClass(Dispatch *d) {
  auto sym = dynamic_cast<Symbol *>(d->getObject());
  if (!sym || symbolTable.contains(sym->getName())) {
    return nullptr;
  }
  try {
    auto type = typeTable.getType(sym->getName());
    return type ? type->getClass() : nullptr;
  } catch (const SemanticException &) {
    return nullptr;
  }
}

bool SemanticAnalysis::visit(Dispatch *d) {
  auto obj = d->getObject();

  std::cout << "Visiting dispatch " << d->getName() << "\n";

  // A call on a class name rather than on an object.
  if (auto staticClass = staticReceiverClass(d)) {
    auto method = typeTable.getMethod(staticClass, d->getName());
    if (!method || !method->isStatic()) {
      throw MethodNotFoundException(d->getName(), staticClass, d);
    }
    if (!checkDispatchArgs(d, method)) {
      return false;
    }
    typeTable.setType(d, typeTable.getType(method->getReturnType()));
    return true;
  }

  // A bare call inside a class may name one of its own static methods, which
  // has no receiver to visit.
  if (!obj) {
    auto enclosing = currentClass;
    auto method = enclosing ? typeTable.getMethod(enclosing, d->getName())
                            : nullptr;
    if (method && method->isStatic()) {
      if (!checkDispatchArgs(d, method)) {
        return false;
      }
      typeTable.setType(d, typeTable.getType(method->getReturnType()));
      return true;
    }
  }

  if (obj) {
    std::cout << "  Object exists in dispatch and visiting.\n";
    if (!visit(obj)) {
      return false;
    }
  } else {
    std::cout << "  Object does not exist, supposing it is 'self'.\n";
    auto self = symbolTable.lookup("self");
    obj = dynamic_cast<Expression *>(self);
    assert(obj && "Invalid lookup");
  }

  std::cout << "Getting type of object at " << obj->getLineNumber() << "\n";
  auto objType = typeTable.getType(obj);
  std::cout << ">> Type is : " << objType->getName() << "\n";

  std::cout << "Getting class of object at " << obj->getLineNumber() << "\n";
  auto objClass = objType->getClass();
  if (!objClass) {
    throw DispatchOnInvalidObjException(d->getName(), objType, d);
  }
  std::cout << ">> Class is : " << objClass->getName() << "\n";

  std::cout << "  Getting method... " << d->getName() << "\n";
  auto method = typeTable.getMethod(objClass, d->getName());
  if (!method) {
    if (typeTable.isBuiltinClass(objClass))
    {
      std::cout << d->getName() << " is a built-in class.\n";
      if ((d->getName() == strings::Out) ||
          (d->getName() == strings::In))
      {}
      else
      {
        throw MethodNotFoundException(d->getName(), objClass, d);
      }
      
    }
    else
      throw MethodNotFoundException(d->getName(), objClass, d);
  }

  std::cout << "  Checking dispatch args... \n";
  if (!checkDispatchArgs(d, method)) {
    return false;
  }

  if (method)
  {
    std::cout << "  Set type to return type of method, " << method->getReturnType() << "\n";
    typeTable.setType(d, typeTable.getType(method->getReturnType()));
  }
  else { // Temporary hack
    if (d->getName() == "out") {
      typeTable.setType(d, typeTable.getStringType());
    }
  }

  std::cout << "  Done dispatch visit.\n";
  return true;
}

bool SemanticAnalysis::visit(StaticDispatch *d) {
  auto obj = d->getObject();

  if (obj) {
    if (!visit(obj)) {
      return false;
    }
  } else {
    auto self = symbolTable.lookup("self");
    obj = dynamic_cast<Expression *>(self);
    assert(obj && "Invalid lookup");
  }

  auto objType = typeTable.getType(obj);
  auto castedType = typeTable.getType(d->getType());
  auto castedClass = castedType->getClass();
  if (!castedClass) {
    throw DispatchOnInvalidObjException(d->getName(), castedType, d);
  }

  // 'expr is Type' is a type test, not a call: any object may be asked about
  // any class, and the answer is an Int.
  if (d->getName() == "is") {
    typeTable.setType(d, typeTable.getIntType());
    return true;
  }

  if (!typeTable.isEqualOrImplicitlyConvertibleTo(objType, castedType)) {
    throw DispatchOnInvalidObjException(d->getName(), objType, castedType, d);
  }

  auto method = typeTable.getMethod(castedClass, d->getName());
  if (!method) {
    throw MethodNotFoundException(d->getName(), castedClass, d);
  }

  if (!checkDispatchArgs(d, method)) {
    return false;
  }

  typeTable.setType(d, typeTable.getType(method->getReturnType()));
  return true;
}

bool SemanticAnalysis::visit(NewObject *n) {
  auto type = typeTable.getType(n->getType());

  if (!type->getClass()) {
    throw WrongTypeException(type, n);
  }

  // The arguments are the constructor's, and a constructor is just a method
  // named 'init'. Checking them here rather than in checkDispatchArgs keeps
  // NewObject free of the name a dispatch carries.
  auto constructor = typeTable.getMethod(type->getClass(), strings::Init);

  if (!constructor) {
    for (auto arg : *n) {
      if (!visit(arg)) {
        return false;
      }
      throw MethodNotFoundException(strings::Init, type->getClass());
    }
  } else {
    auto paramIt = constructor->begin();
    for (auto arg : *n) {
      if (!visit(arg)) {
        return false;
      }
      if (paramIt == constructor->end()) {
        throw TooManyArgsException(strings::Init, n);
      }

      auto paramType = typeTable.getType((*paramIt)->getType());
      if (!typeTable.isEqualOrImplicitlyConvertibleTo(typeTable.getType(arg),
                                                      paramType)) {
        throw WrongTypeException(typeTable.getType(arg), paramType, n);
      }
      ++paramIt;
    }
    if (paramIt != constructor->end()) {
      throw NotEnoughArgsException(strings::Init, n);
    }
  }

  typeTable.setType(n, type);
  return true;
}

/// `a.b`, and `a.b = v` when the node carries a value. The field is looked up
/// on the object's class, walking up the hierarchy, so an inherited field is
/// reached exactly like an own one.
bool SemanticAnalysis::visit(FieldAccess *fa) {
  auto object = fa->getObject();
  if (!object) {
    throw MissingOperandException(fa);
  }
  if (!visit(object)) {
    return false;
  }

  auto objType = typeTable.getType(object);
  auto objClass = objType->getClass();
  if (!objClass) {
    throw DispatchOnInvalidObjException(fa->getField(), objType, fa);
  }

  auto attribute = typeTable.getAttribute(objClass, fa->getField());
  if (!attribute) {
    throw AttributeNotFoundException(fa->getField(), objClass, fa);
  }

  auto fieldType = typeTable.getType(attribute->getType());

  if (auto value = fa->getValue()) {
    if (!visit(value)) {
      return false;
    }
    auto valueType = typeTable.getType(value);
    if (!typeTable.isEqualOrImplicitlyConvertibleTo(valueType, fieldType)) {
      throw WrongTypeException(valueType, fieldType, fa);
    }
  }

  typeTable.setType(fa, fieldType);
  return true;
}

bool SemanticAnalysis::visit(IfStatement *i) {
  auto condExpr = i->getCond();
  auto thenExpr = i->getThen();
  auto elseExpr = i->getElse();

  if (!condExpr) {
    throw MissingIfCondException(i);
  }

  if (!visit(condExpr)) {
    return false;
  }

  if (!TypeTable::integerWidth(typeTable.getType(condExpr)->getName())) {
    throw WrongTypeException(typeTable.getType(condExpr),
                             typeTable.getIntType(), condExpr);
  }

  if (!thenExpr) {
    throw MissingIfThenException(i);
  }

  {
    SymbolTable::Scope thenScope(symbolTable, "then_expr_anon");
    if (!visit(thenExpr)) {
      return false;
    }
  }

  if (elseExpr) {
    SymbolTable::Scope elseScope(symbolTable, "else_expr_anon");
    if (!visit(elseExpr)) {
      return false;
    }
  }

  auto thenType = typeTable.getType(thenExpr);
  auto elseType = elseExpr != nullptr ? typeTable.getType(elseExpr)
                                      : typeTable.getVoidType();

  typeTable.setType(i, typeTable.getCommonType(thenType, elseType));

  return true;
}

bool SemanticAnalysis::visit(WhileStatement *w) {
  auto cond = w->getCond();

  if (!cond) {
    throw MissingWhileCondException(w);
  }

  if (!visit(cond)) {
    return false;
  }

  if (!TypeTable::integerWidth(typeTable.getType(cond)->getName())) {
    throw WrongTypeException(typeTable.getType(cond), typeTable.getIntType(),
                             cond);
  }

  auto body = w->getBody();
  if (body) {
    SymbolTable::Scope whileScope(symbolTable, "anonymous_while");
    ++loopDepth;
    const bool ok = visit(body);
    --loopDepth;
    if (!ok) {
      return false;
    }
  }

  typeTable.setType(w, typeTable.getVoidType());

  return true;
}

bool SemanticAnalysis::visit(ForStatement *f) {
  // `for <var> in <container>:` iterates either a count (an Int, giving
  // 0..n-1) or a String (giving its characters, one-character Strings).
  // There is no list type in the runtime yet, so nothing else can be iterated.
  auto cont = f->getCont();
  if (!cont) {
    throw SemanticException("'for' without a container");
  }
  if (!visit(cont)) {
    return false;
  }

  // Compare by name: getType(TreeNode *) hands back a freshly allocated Type
  // for constants, so the pointers are not interchangeable.
  auto contType = typeTable.getType(cont);
  Type *elementType = nullptr;
  if (TypeTable::integerWidth(contType->getName())) {
    elementType = typeTable.getIntType();
  } else if (contType->getName() == strings::String) {
    elementType = typeTable.getStringType();
  } else if (contType->getName() == strings::List) {
    // A List holds object references, so the loop variable is an Object;
    // assigning it to a typed variable gets the element back out.
    elementType = typeTable.getObjectType();
  } else {
    throw SemanticException("cannot iterate over a value of type '" +
                            contType->getName() +
                            "'; 'for' takes an Int count, a String or a List");
  }

  SymbolTable::Scope forScope(symbolTable, "for");

  auto iter = f->getIter();
  if (auto sym = dynamic_cast<Symbol *>(iter)) {
    // The loop variable is just a name in the tree; give it a definition so
    // that references to it inside the body resolve like any other local.
    std::vector<std::string> names{sym->getName()};
    std::unique_ptr<LocalDefinition> def(new LocalDefinition(
        f->getLineNumber(), names, elementType->getName()));
    symbolTable.insert(def.get());
    typeTable.setType(def.get(), elementType);
    typeTable.setType(sym, elementType);
    definitionsMap[sym] = def.get();
    syntheticDefinitions.push_back(std::move(def));
  } else if (!visit(iter)) {
    return false;
  }

  ++loopDepth;
  const bool bodyOk = visit(f->getBody());
  --loopDepth;
  if (!bodyOk) {
    return false;
  }

  typeTable.setType(f, typeTable.getVoidType());
  return true;
}

/// `break` and `continue` need a loop to act on. A method called from inside
/// a loop does not count: its own body is a separate function, and the
/// generator has no way to branch out of the caller's loop from it.
bool SemanticAnalysis::visit(LoopControl *lc) {
  if (loopDepth == 0) {
    throw SemanticException(
        std::string(lc->isBreak() ? "'break'" : "'continue'") +
            " is only meaningful inside a 'while' or a 'for'",
        lc);
  }

  typeTable.setType(lc, typeTable.getVoidType());
  return true;
}

/// The handler binds one name, typed Object because anything can be thrown.
/// A handler that wants something more specific says so with an assignment,
/// which inserts the checked downcast, or asks with `is`.
bool SemanticAnalysis::visit(TryStatement *t) {
  {
    SymbolTable::Scope tryScope(symbolTable, "try");
    if (!visit(t->getBody())) {
      return false;
    }
  }

  {
    SymbolTable::Scope catchScope(symbolTable, "catch");
    std::vector<std::string> names{t->getCatchName()};
    std::unique_ptr<LocalDefinition> caught(
        new LocalDefinition(t->getLineNumber(), names, strings::Object));
    symbolTable.insert(caught.get());
    typeTable.setType(caught.get(), typeTable.getObjectType());
    syntheticDefinitions.push_back(std::move(caught));

    if (!visit(t->getHandler())) {
      return false;
    }
  }

  typeTable.setType(t, typeTable.getVoidType());
  return true;
}

bool SemanticAnalysis::visit(ThrowStatement *t) {
  auto value = t->getValue();
  if (!value) {
    throw MissingOperandException(t);
  }
  if (!visit(value)) {
    return false;
  }

  // A throw never produces a value: it leaves through the nearest handler.
  typeTable.setType(t, typeTable.getVoidType());
  return true;
}

/// The action is checked where it is written, and emitted where the block
/// ends. Nothing about the type matters: its value is discarded.
bool SemanticAnalysis::visit(DeferStatement *d) {
  auto action = d->getAction();
  if (!action) {
    throw MissingOperandException(d);
  }
  if (!visit(action)) {
    return false;
  }
  typeTable.setType(d, typeTable.getVoidType());
  return true;
}

namespace {
/// Finds the first thing in a method body that a worker must not do. A
/// worker runs on a thread while the rest of the program runs on another,
/// and nothing in the runtime is prepared for that except plain arithmetic:
/// a reference count, the temporary pool and the handler stack are all
/// shared and none is locked. So the rule is arithmetic and control flow
/// only, checked here rather than trusted.
class WorkerHazard : public ASTVisitor {
public:
  using ASTVisitor::visit;

  std::string Why;
  std::vector<Dispatch *> Calls; ///< to follow into, if everything else is fine

  bool stop(const std::string &what) {
    if (Why.empty()) {
      Why = what;
    }
    return false;
  }

  bool visit(NewObject *n) override { return stop("makes an object"); }
  bool visit(StringConstant *s) override { return stop("uses a string"); }
  bool visit(FieldAccess *f) override { return stop("reads a field"); }
  bool visit(StaticDispatch *d) override {
    return stop(d->getName() == "is" ? "asks a type question"
                                     : "calls a method on an object");
  }
  bool visit(TryStatement *t) override { return stop("uses try"); }
  bool visit(ThrowStatement *t) override { return stop("throws"); }
  bool visit(DeferStatement *d) override { return stop("uses defer"); }
  bool visit(SpawnStatement *s) override { return stop("spawns"); }

  bool visit(LocalDefinition *local) override {
    const std::string &type = local->getType();
    if (type != "auto" && !TypeTable::integerWidth(type) &&
        type != strings::Float) {
      return stop("declares '" + local->getName().front() + "' of type '" +
                  type + "'");
    }
    return ASTVisitor::visit(local);
  }

  bool visit(Dispatch *d) override {
    Calls.push_back(d);
    return ASTVisitor::visit(d);
  }
};
} // namespace

bool SemanticAnalysis::workerSafe(Class *c, Method *m, std::set<Method *> &seen,
                                  std::string &why) {
  if (seen.count(m)) {
    return true; // already being checked: recursion is fine
  }
  seen.insert(m);

  if (!m->isStatic()) {
    why = "'" + c->getName() + "." + m->getName() + "' is not static";
    return false;
  }
  for (auto param : *m) {
    if (!TypeTable::integerWidth(param->getType()) &&
        param->getType() != strings::Float) {
      why = "'" + c->getName() + "." + m->getName() + "' takes '" +
            param->getType() + "', and a worker takes only numbers";
      return false;
    }
  }
  if (!TypeTable::integerWidth(m->getReturnType()) &&
      m->getReturnType() != strings::Float) {
    why = "'" + c->getName() + "." + m->getName() + "' returns '" +
          m->getReturnType() + "', and a worker returns only a number";
    return false;
  }

  WorkerHazard hazard;
  if (m->getBody()) {
    hazard.visit(m->getBody());
  }
  if (!hazard.Why.empty()) {
    why = "'" + c->getName() + "." + m->getName() + "' " + hazard.Why;
    return false;
  }

  // Every call it makes has to be safe too, or the restriction would be one
  // level deep and mean nothing.
  for (auto call : hazard.Calls) {
    Class *target = c;
    if (auto named = staticReceiverClass(call)) {
      target = named;
    } else if (call->getObject()) {
      why = "'" + c->getName() + "." + m->getName() +
            "' calls a method on an object";
      return false;
    }

    auto callee = typeTable.getMethod(target, call->getName());
    if (!callee) {
      why = "'" + c->getName() + "." + m->getName() + "' calls '" +
            call->getName() + "', which is not there";
      return false;
    }
    if (!workerSafe(target, callee, seen, why)) {
      return false;
    }
  }

  return true;
}

/// `spawn Class.method(argument)`: the call is not made, its address and its
/// argument are handed to a thread. The method has to be one a thread can
/// safely run, and that is checked here, where it can be explained.
bool SemanticAnalysis::visit(SpawnStatement *s) {
  auto call = dynamic_cast<Dispatch *>(s->getCall());
  if (!call) {
    throw SemanticException("'spawn' needs a call to a static method");
  }

  auto target = staticReceiverClass(call);
  if (!target) {
    throw SemanticException("'spawn' needs a static method named on its "
                            "class, as in 'spawn Work.chunk(i)'");
  }

  auto method = typeTable.getMethod(target, call->getName());
  if (!method) {
    throw MethodNotFoundException(call->getName(), target, call);
  }

  auto parameters = std::distance(method->begin(), method->end());
  if (parameters != 1) {
    throw SemanticException("a worker takes exactly one number, and '" +
                            target->getName() + "." + method->getName() +
                            "' takes " + std::to_string(parameters));
  }

  std::set<Method *> seen;
  std::string why;
  if (!workerSafe(target, method, seen, why)) {
    throw SemanticException(
        "a worker may only do arithmetic, because it runs beside the rest of "
        "the program and nothing else in the runtime is shared safely: " +
        why);
  }

  if (!checkDispatchArgs(call, method)) {
    return false;
  }

  // The value is a handle to wait for.
  typeTable.setType(call, typeTable.getType(method->getReturnType()));
  typeTable.setType(s, typeTable.getIntType());
  return true;
}

bool SemanticAnalysis::visit(ReturnExpression *r) {
  // A return carries the type of the expression it returns, so that the
  // enclosing block -- and through it the method's return-type check -- sees
  // a type rather than asserting on an unannotated node.
  auto ret = r->getRet();
  if (!ret) {
    typeTable.setType(r, typeTable.getVoidType());
    return true;
  }

  if (!visit(ret)) {
    return false;
  }

  typeTable.setType(r, typeTable.getType(ret));
  return true;
}

bool SemanticAnalysis::visit(LocalDefinition *local) {
  // The initialiser is analysed before the name is bound. `x = expr` parses as
  // a definition with the type "auto", so binding first would make `a = a + 1`
  // resolve the right-hand `a` to the new, still-untyped definition instead of
  // the existing variable.
  if (local->getInit()) {
    if (!visit(local->getInit())) {
      return false;
    }
  }

  symbolTable.insert(local);

  if (local->getType() == "auto") {
    // Inferred from the initialiser; with no initialiser there is nothing to
    // infer from and the definition carries no value.
    typeTable.setType(local, local->getInit()
                                 ? typeTable.getType(local->getInit())
                                 : typeTable.getVoidType());
  } else {
    typeTable.setType(local, typeTable.getType(local->getType(), local));
  }

  return true;
}
