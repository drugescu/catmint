#include "ASTVisitor.h"

#include <cassert>

using namespace catmint;

bool ASTVisitor::visit(Program *P) {
  for (auto Class : *P) {
    if (!visit(Class)) {
      return false;
    }
  }

  return true;
}

bool ASTVisitor::visit(Class *C) {
  for (auto Feature : *C) {
    if (!visit(Feature)) {
      return false;
    }
  }

  return true;
}

bool ASTVisitor::visit(Feature *F) {
  if (auto A = dynamic_cast<Attribute *>(F)) {
    return visit(A);
  } else if (auto M = dynamic_cast<Method *>(F)) {
    return visit(M);
  }

  assert(false && "Unexpected feature kind");
  return false;
}

bool ASTVisitor::visit(Attribute *A) {
  if (auto Init = A->getInit()) {
    return visit(Init);
  }

  return true;
}

bool ASTVisitor::visit(Method *M) {
  for (auto Param : *M) {
    if (!visit(Param)) {
      return false;
    }
  }

  return visit(M->getBody());
}

bool ASTVisitor::visit(FormalParam *F) { return true; }

bool ASTVisitor::visit(Expression *E) {
  if (auto IntCt = dynamic_cast<IntConstant *>(E)) {
    return visit(IntCt);
  } else if (auto FloatCt = dynamic_cast<FloatConstant *>(E)) {
    return visit(FloatCt);
  } else if (auto StringCt = dynamic_cast<StringConstant *>(E)) {
    return visit(StringCt);
  } else if (auto NullCt = dynamic_cast<NullConstant *>(E)) {
    return visit(NullCt);
  } else if (auto Sym = dynamic_cast<Symbol *>(E)) {
    return visit(Sym);
  } else if (auto Blk = dynamic_cast<Block *>(E)) {
    return visit(Blk);
  } else if (auto BinOp = dynamic_cast<BinaryOperator *>(E)) {
    return visit(BinOp);
  } else if (auto UnaryOp = dynamic_cast<UnaryOperator *>(E)) {
    return visit(UnaryOp);
  } else if (auto C = dynamic_cast<Cast *>(E)) {
    return visit(C);
  } else if (auto Substr = dynamic_cast<Substring *>(E)) {
    return visit(Substr);
  } else if (auto Disp = dynamic_cast<Dispatch *>(E)) {
    return visit(Disp);
  } else if (auto SDispatch = dynamic_cast<StaticDispatch *>(E)) {
    return visit(SDispatch);
  } else if (auto New = dynamic_cast<NewObject *>(E)) {
    return visit(New);
  } else if (auto If = dynamic_cast<IfStatement *>(E)) {
    return visit(If);
  } else if (auto While = dynamic_cast<WhileStatement *>(E)) {
    return visit(While);
  } else if (auto Local = dynamic_cast<LocalDefinition *>(E)) {
    return visit(Local);
  } else if (auto Assign = dynamic_cast<Assignment *>(E)) {
    return visit(Assign);
  }

  assert(false && "Unknown expression kind");
  return false;
}

bool ASTVisitor::visit(IntConstant *IC) { return true; }
bool ASTVisitor::visit(FloatConstant *FC) { return true; }
bool ASTVisitor::visit(StringConstant *SC) { return true; }
bool ASTVisitor::visit(NullConstant *NC) { return true; }
bool ASTVisitor::visit(Symbol *S) { return true; }

bool ASTVisitor::visit(Block *B) {
  for (auto E : *B) {
    if (!visit(E)) {
      return false;
    }
  }

  return true;
}

bool ASTVisitor::visit(Assignment *A) { return visit(A->getExpression()); }

bool ASTVisitor::visit(BinaryOperator *BO) {
  return visit(BO->getLHS()) && visit(BO->getRHS());
}

bool ASTVisitor::visit(UnaryOperator *UO) { return visit(UO->getOperand()); }

bool ASTVisitor::visit(Cast *C) { return visit(C->getExpressionToCast()); }

bool ASTVisitor::visit(Substring *S) {
  return visit(S->getString()) && visit(S->getStart()) && visit(S->getEnd());
}

bool ASTVisitor::visit(Dispatch *D) {
  for (auto Arg : *D) {
    if (!visit(Arg)) {
      return false;
    }
  }

  return visit(D->getObject());
}

bool ASTVisitor::visit(StaticDispatch *SD) {
  for (auto Arg : *SD) {
    if (!visit(Arg)) {
      return false;
    }
  }
  return visit(SD->getObject());
}

bool ASTVisitor::visit(NewObject *NO) { return true; }

bool ASTVisitor::visit(IfStatement *If) {
  if (!visit(If->getCond())) {
    return false;
  }

  if (!visit(If->getThen())) {
    return false;
  }

  if (If->getElse()) {
    return visit(If->getElse());
  }

  return true;
}

bool ASTVisitor::visit(WhileStatement *While) {
  if (!visit(While->getCond())) {
    return false;
  }

  return visit(While->getBody());
}

bool ASTVisitor::visit(LocalDefinition *Local) {
  if (auto Init = Local->getInit()) {
    return visit(Init);
  }

  return true;
}
