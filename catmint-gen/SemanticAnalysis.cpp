
#include <cassert>
#include <iostream>
#include <unordered_set>

#include <ASTNodes.h>
#include <SemanticAnalysis.h>
#include <SemanticException.h>
#include <StringConstants.h>

using namespace catmint;

SemanticAnalysis::SemanticAnalysis(Program *p)
    : program(p), typeTable(p), symbolTable() {
  assert(program && "Expected non-null program");
}

void SemanticAnalysis::runAnalysis() {
  assert(program && "Expected non-null program");
  visit(program);
}

bool SemanticAnalysis::visit(Program *p) {

  // Check that main exists (we have inserted it manually) and inheritance graph
  checkMainClassAndMethod();
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

// Visit lass by visiting attributes and adding symbols/types to tables
bool SemanticAnalysis::visit(Class *c) {
  if (typeTable.isBuiltinClass(c)) {
    return true;
  }

  // create a scope and add all attributes to it
  SymbolTable::Scope classScope(symbolTable);
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

  // add self to symbol table
  std::vector<std::string> def_names;
  def_names.push_back("self");
  std::unique_ptr<LocalDefinition> self(
      // line of code, name, type
      new LocalDefinition(0, def_names, c->getName()));
  symbolTable.insert(self.get());
  typeTable.setType(self.get(), typeTable.getType(c));

  // Verify features
  checkFeatures(c);

  return ASTVisitor::visit(c);
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
  auto attrType = typeTable.getType(a->getType());

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

  SymbolTable::Scope methodScope(symbolTable);
  for (auto param : *m) {
    if (paramNames.count(param->getName())) {
      throw DuplicateParamException(param, m);
    }

    paramNames.insert(param->getName());

    if (!visit(param)) {
      return false;
    }
  }

  auto returnType = typeTable.getType(m->getReturnType());
  auto body = m->getBody();
  if (body) {
    if (!visit(body)) {
      return false;
    }

    auto bodyType = typeTable.getType(body);
    if (returnType != typeTable.getVoidType() &&
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
  typeTable.setType(param, typeTable.getType(param->getType()));
  return true;
}

bool SemanticAnalysis::visit(Expression *e) { return ASTVisitor::visit(e); }

bool SemanticAnalysis::visit(IntConstant *ic) {
  typeTable.setType(ic, typeTable.getIntType());
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
  auto who = symbolTable.lookup(s->getName());
  typeTable.setType(s, typeTable.getType(who));

  return true;
}

bool SemanticAnalysis::visit(Block *b) {
  SymbolTable::Scope blockScope(symbolTable);

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

  auto lhs = symbolTable.lookup(a->getSymbol());

  auto lhsType = typeTable.getType(lhs);
  auto rhsType = typeTable.getType(rhs);

  if (!typeTable.isEqualOrImplicitlyConvertibleTo(rhsType, lhsType)) {
    throw IncompatibleOperandsException(a, lhsType, rhsType);
  }

  typeTable.setType(a, lhsType);

  return true;
}

bool SemanticAnalysis::visit(BinaryOperator *bo) {
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

  if (typeTable.getType(operand) != typeTable.getIntType()) {
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

bool SemanticAnalysis::visit(Dispatch *d) {
  auto obj = d->getObject();

  std::cout << "Visiting dispatch " << d->getName() << "\n";

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

  std::cout << "Getting class of object at " << obj->getLineNumber() << "\n";
  auto objClass = objType->getClass();
  if (!objClass) {
    throw DispatchOnInvalidObjException(d->getName(), objType);
  }

  std::cout << "  Getting method... \n";
  auto method = typeTable.getMethod(objClass, d->getName());
  if (!method) {
    throw MethodNotFoundException(d->getName(), objClass);
  }

  std::cout << "  Checking dispatch args... \n";
  if (!checkDispatchArgs(d, method)) {
    return false;
  }

  std::cout << "  Set type to return type of method, " << method->getReturnType() << "\n";
  typeTable.setType(d, typeTable.getType(method->getReturnType()));

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
    throw DispatchOnInvalidObjException(d->getName(), castedType);
  }

  if (!typeTable.isEqualOrImplicitlyConvertibleTo(objType, castedType)) {
    throw DispatchOnInvalidObjException(d->getName(), objType, castedType);
  }

  auto method = typeTable.getMethod(castedClass, d->getName());
  if (!method) {
    throw MethodNotFoundException(d->getName(), castedClass);
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

  typeTable.setType(n, type);
  return true;
}

bool SemanticAnalysis::visit(IfStatement *i) {
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

  if (typeTable.getType(cond) != typeTable.getIntType()) {
    throw WrongTypeException(typeTable.getType(cond), typeTable.getIntType(),
                             cond);
  }

  auto body = w->getBody();
  if (body) {
    SymbolTable::Scope whileScope(symbolTable);
    if (!visit(body)) {
      return false;
    }
  }

  typeTable.setType(w, typeTable.getVoidType());

  return true;
}

bool SemanticAnalysis::visit(LocalDefinition *local) {
  symbolTable.insert(local);
  typeTable.setType(local, typeTable.getType(local->getType()));

  if (local->getInit()) {
    if (!visit(local->getInit())) {
      return false;
    }
  }

  return true;
}
