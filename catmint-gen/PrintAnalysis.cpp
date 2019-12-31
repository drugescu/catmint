
#include <cassert>
#include <iostream>
#include <unordered_set>

#include <ASTNodes.h>
#include <PrintAnalysis.h>
#include <StringConstants.h>

using namespace catmint;

static int indent = 0;

/* Debug functions */

void printIndent() {
    for (auto i = 0; i < indent; i++) {
        std::cout << " ";
    }
}

/* Main Visitor */

PrintAnalysis::PrintAnalysis(Program *p)
    : program(p) {
  assert(program && "Expected non-null program");
}

void PrintAnalysis::runAnalysis() {
  assert(program && "Expected non-null program");
  visit(program);
}

bool PrintAnalysis::visit(Program *p) {
    std::cout << "\n\n ---------- Print Analysis ---------- \nVisiting program.\n";

    for (auto c : *p) {
        if (!visit(c)) {
            return false;
        }
    }

    std::cout << " ---------- End Print Analysis ---------- \n\n";

    return true;
}

bool PrintAnalysis::visit(Class *c) {
    std::cout << "\nClass: " << c->getName() << "\n";
    std::cout << "  Parent: " << c->getParent() << "\n";
    indent += 2;
    for (auto f : *c) {
        if (!visit(f)) {
            return false;
        }
    }
    indent -= 2;

    return true;
}

bool PrintAnalysis::visit(Feature *f) {

    if (f->isAttribute()) {
      auto attr = static_cast<Attribute *>(f);
      
      if (!visit(attr)) {
        return false;
      }
    } else if (f->isMethod()) {
      auto meth = static_cast<Method *>(f);

      if (!visit(meth)) {
        return false;
      }
    } else {
      std::cout << "  Not a method or an attribute: " << f->getName() << "\n";
      return false;
    }

    return true;
}

bool PrintAnalysis::visit(Attribute *a) {
    printIndent(); std::cout << "Attribute - Name: " << a->getName() << "\n";
    printIndent(); std::cout << "            Type: " << a->getType() << "\n";

    auto init = a->getInit();
    if (!init) {
        return true;
    }

    if (!visit(init)) {
        return false;
    }

    return true;
}

bool PrintAnalysis::visit(Method *m) {
    std::cout << "  Method - Name: " << m->getName() << "\n";
    std::cout << "           Return Type: " << m->getReturnType() << "\n";
    std::cout << "           Parameters: \n";

    indent += 15;
    for (auto param : *m) {
        if (!visit(param)) {
            return false;
        }
    }
    indent -= 15;

    std::cout << "           Body: \n";
    indent += 12;
    auto body = m->getBody();
    if (body) {
        if (!visit(body)) {
          return false;
        }
    }
    indent -= 12;

    return true;
}

bool PrintAnalysis::visit(Expression *e) { return ASTVisitor::visit(e); }

bool PrintAnalysis::visit(Block *b) {
  
  printIndent(); std::cout << "Block: " << "\n";
  indent += 2;

  // visit all expressions first
  if (!ASTVisitor::visit(b)) {
    return false;
  }

  indent -= 2;

  return true;
}

bool PrintAnalysis::visit(IntConstant *ic) {
  printIndent(); std::cout << "Int Constant: " << ic->getValue() << "\n";
  return true;
}

bool PrintAnalysis::visit(StringConstant *sc) {
  printIndent(); std::cout << "String Constant: " << sc->getValue() << "\n";
  return true;
}

bool PrintAnalysis::visit(NullConstant *nc) {
  printIndent(); std::cout << "Null Constant. " << "\n";
  return true;
}

bool PrintAnalysis::visit(Symbol *s) {
  printIndent(); std::cout << "Symbol: " << s->getName() << "\n";
  return true;
}

bool PrintAnalysis::visit(BinaryOperator *bo) {
  printIndent(); std::cout << "Binop: Kind: " << bo->getOperatorKind() << "\n";

  indent += 6;
  auto LHS = bo->getLHS();
  auto RHS = bo->getRHS();
  if (!visit(LHS))
    return false;
  if (!visit(RHS))
    return false;

  indent -= 6;
  return true;
}

bool PrintAnalysis::visit(Dispatch *d) {
  auto obj = d->getObject();

  printIndent(); std::cout << "Dispatch: Name: " << d->getName() << "\n";

  if (obj) {
    printIndent(); std::cout << "        : Obj:\n";
    indent += 7;
    if (!visit(obj)) {
      return false;
    }
    indent -= 7;
  }

  printIndent(); std::cout << "        : Arguments: \n";
  indent += 15;
  for (auto arg : *d) {
    if (!visit(arg)) {
      return false;
    }
  }

  indent -= 15;
  return true;
}

bool PrintAnalysis::visit(IfStatement *If) {
  printIndent(); std::cout << "If: Cond: \n";
  indent += 10;
  if (!visit(If->getCond())) {
    return false;
  }
  indent -= 10;

  printIndent(); std::cout << "    Then: \n";
  indent += 10;
  if (!visit(If->getThen())) {
    return false;
  }
  indent -= 10;

  printIndent(); std::cout << "    Else: \n";
  indent += 10;
  if (If->getElse()) {
    if (!visit(If->getElse()))
      return false;
  }
  indent -= 10;

  return true;
}

bool PrintAnalysis::visit(WhileStatement *While) {
  printIndent(); std::cout << "While: Cond: \n";
  indent += 13;
  if (!visit(While->getCond())) {
    return false;
  }
  indent -= 13;

  printIndent(); std::cout << "       Body: \n";
  indent += 13;
  if (!visit(While->getBody()))
    return false;
  indent -= 13;
  return true;
}

bool PrintAnalysis::visit(ForStatement *For) {
  printIndent(); std::cout << "For: Cond: \n";
  indent += 11;
  if (!visit(For->getIter())) {
    return false;
  }
  indent -= 11;

  printIndent(); std::cout << "        Cont: \n";
  indent += 11;
  if (!visit(For->getCont())) {
    return false;
  }
  indent -= 11;

  printIndent(); std::cout << "        Body: \n";
  indent += 11;
  if (!visit(For->getBody())) {
    return false;
  }
  indent -= 11;

  return true;
}

bool PrintAnalysis::visit(LocalDefinition *Local) {
  
  auto ns = Local->getName();

  printIndent(); std::cout << "Def: Type: " << Local->getType() << " \n";

  for (auto n : ns) {
    printIndent(); std::cout << "     Name: " << n << " \n";
  }
  
  printIndent(); std::cout << "     Init:\n";
  indent += 11;
  if (auto Init = Local->getInit()) {
    return visit(Init);
  }

  return true;
}

bool PrintAnalysis::visit(ReturnExpression *Ret) {
  printIndent(); std::cout << "Ret: \n";

  indent += 5;
  if (!visit(Ret->getRet()))
    return false;
  indent -= 5;

  return true;
}