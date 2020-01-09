// TypeVisitor

#include <cassert>
#include <iostream>
#include <unordered_set>

/*#include <ASTNodes.h>
#include <TypeVisitor.h>
#include <StringConstants.h>
#include <TypeTable.h>*/
#include <TypeVisitor.h>
#include <ASTNodes.h>

using namespace catmint;

int indentB = 0;

void printIndentB() {
    for (auto i = 0; i < indentB; i++) {
        std::cout << " ";
    }
}

/* Main Visitor */

TypeVisitor::TypeVisitor(TypeTable *t)
    : typeTable(t) {
  assert(t && "Expected non-null Type Table");
}

std::string TypeVisitor::visitStr(Attribute *a) {
    printIndentB(); std::cout << "Attribute - Name: " << a->getName() << "\n";
    printIndentB(); std::cout << "            Type: " << a->getType() << "\n";

    return a->getType();
}

std::string TypeVisitor::visitStr(Class *c) {
    return c->getName();
}

std::string TypeVisitor::visitStr(Expression *e) {

  if (auto IntCt = dynamic_cast<IntConstant *>(e)) {
    return visitStr(IntCt);
  } else if (auto FloatCt = dynamic_cast<FloatConstant *>(e)) {
    return visitStr(FloatCt);
  } else if (auto StringCt = dynamic_cast<StringConstant *>(e)) {
    return visitStr(StringCt);
  } else if (auto NullCt = dynamic_cast<NullConstant *>(e)) {
    return visitStr(NullCt);
  } else if (auto Sym = dynamic_cast<Symbol *>(e)) {
    return visitStr(Sym);
  } else if (auto Blk = dynamic_cast<Block *>(e)) {
    return visitStr(Blk);
  } else if (auto BinOp = dynamic_cast<BinaryOperator *>(e)) {
    return visitStr(BinOp);
  } else if (auto UnaryOp = dynamic_cast<UnaryOperator *>(e)) {
    return visitStr(UnaryOp);
  } /*else if (auto C = dynamic_cast<Cast *>(E)) {
    return visit(C);
  } else if (auto Substr = dynamic_cast<Substring *>(E)) {
    return visit(Substr);
  } else if (auto Slice = dynamic_cast<Slicevector *>(E)) {
    return visit(Slice);
  }*/ else if (auto Disp = dynamic_cast<Dispatch *>(e)) {
    return visitStr(Disp);
  } /*else if (auto SDispatch = dynamic_cast<StaticDispatch *>(E)) {
    return visit(SDispatch);
  } else if (auto New = dynamic_cast<NewObject *>(E)) {
    return visit(New);
  } else if (auto If = dynamic_cast<IfStatement *>(E)) {
    return visit(If);
  } else if (auto While = dynamic_cast<WhileStatement *>(E)) {
    return visit(While);
  } else if (auto For = dynamic_cast<ForStatement *>(E)) {
    return visit(For);
  } else if (auto Local = dynamic_cast<LocalDefinition *>(E)) {
    return visit(Local);
  } else if (auto Assign = dynamic_cast<Assignment *>(E)) {
    return visit(Assign);
  } else if (auto Ret = dynamic_cast<ReturnExpression *>(E)) {
    return visit(Ret);
  }*/

  assert(false && "Unknown expression kind");
  return std::string("Unknown");
    
}


std::string TypeVisitor::visitStr(Block *b) {
  
  printIndentB(); std::cout << "Block: " << "\n";
  indentB += 2;

  // visit all expressions first
  for (auto E : *b) {
    if (visitStr(E) == std::string("Unknown")) {
      return std::string("Unknown");
    }
  }

  indentB -= 2;

  return std::string("Unknown");
}

std::string TypeVisitor::visitStr(IntConstant *ic) {
  printIndentB(); std::cout << "TypeVisit: Int Constant: " << ic->getValue() << "\n";
  return strings::Int;
}

std::string TypeVisitor::visitStr(StringConstant *sc) {
  printIndentB(); std::cout << "TypeVisit: String Constant: " << sc->getValue() << "\n";
  return strings::String;
}

std::string TypeVisitor::visitStr(NullConstant *nc) {
  printIndentB(); std::cout << "TypeVisit: Null Constant. " << "\n";
  return strings::Null;
}

std::string TypeVisitor::visitStr(Symbol *s) {
  printIndentB(); std::cout << "TypeVisit: Symbol: " << s->getName() << "\n";
  printIndentB(); std::cout << "         : Type: " << typeTable->peekTypeString(s) << "\n";

  /*auto who = symbolTable.lookup(s->getName());
  printIndentB(); std::cout << "         : Real Type: " >> typeTable->getType(who);*/
  // typeTable.setType(s, typeTable.getType(who));

  return typeTable->peekTypeString(s); // Return type of symbol
}

std::string TypeVisitor::visitStr(UnaryOperator *uo) {
    return  visitStr(uo->getOperand()); // Type of operand
}

std::string TypeVisitor::visitStr(BinaryOperator *bo) {
  printIndentB(); std::cout << "TypeVisit: Binop: Kind: " << bo->getOperatorKind() << "\n";

  indentB += 14;
  auto LHS = bo->getLHS();
  auto RHS = bo->getRHS();

  printIndentB(); std::cout << "             LHS: \n";
  auto LHStype = visitStr(LHS);
  printIndentB(); std::cout << "             RHS: \n";
  auto RHStype = visitStr(RHS);
  if (LHStype == std::string("Unknown"))
    return std::string("Unknown");

  if (RHStype == std::string("Unknown"))
    return std::string("Unknown");

  /* Boolean operator has some implicit conversions - not good to do semantic stuff here, but hack this for now*/
  if (typeTable->isEqualOrImplicitlyConvertibleToStr(LHStype, RHStype))
    return typeTable->getCommonTypeStr(LHStype, RHStype);

  indentB -= 14;
  return std::string("Unknown");
}

std::string TypeVisitor::visitStr(Dispatch *d) {
  auto obj = d->getObject();

  printIndentB(); std::cout << "TypeVisit: Dispatch: Name: " << d->getName() << "\n";

  auto objVisit = visitStr(obj);

  if (obj) {
    printIndentB(); std::cout << "        : Obj:\n";
    indentB += 7;
    if (visitStr(obj) == strings::Unknown) {
      return strings::Unknown;
    }
    indentB -= 7;
  }

  indentB -= 15;
  return objVisit;
}