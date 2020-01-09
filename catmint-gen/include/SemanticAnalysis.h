#ifndef SEMANTIC_ANALYSIS_H
#define SEMANTIC_ANALYSIS_H

#include <map>
#include <ASTVisitor.h>
#include <Program.h>
#include <SymbolTable.h>
#include <Type.h>
#include <TypeTable.h>
#include <TypeVisitor.h>

namespace catmint {

/// \brief Performs the semantic analysis on the catmint program received in the
/// constructor
class SemanticAnalysis : public ASTVisitor {
public:
  SemanticAnalysis(Program *p);
  virtual ~SemanticAnalysis() {}

  void runAnalysis();

private:
  bool visit(Program *p) override;
  bool visit(Class *c) override;
  bool visit(Feature *f) override;

  bool visit(Attribute *a) override;

  bool visit(Method *m) override;
  bool visit(FormalParam *f) override;

  bool visit(Expression *e) override;

  bool visit(IntConstant *ic) override;
  bool visit(StringConstant *sc) override;
  bool visit(NullConstant *nc) override;
  bool visit(Symbol *s) override;

  bool visit(Block *b) override;
  bool visit(Assignment *a) override;
  bool visit(BinaryOperator *bo) override;
  bool visit(UnaryOperator *uo) override;
  bool visit(Cast *c) override;
  bool visit(Substring *s) override;
  bool visit(Dispatch *d) override;
  bool visit(StaticDispatch *sd) override;
  bool visit(NewObject *n) override;
  bool visit(IfStatement *i) override;
  bool visit(WhileStatement *w) override;
  bool visit(LocalDefinition *local) override;

public:
  TypeTable typeTable;
  SymbolTable symbolTable;
  TypeVisitor typeVisitor;

private:
  Program *program;

  void checkMainClassAndMethod();
  void checkInheritanceGraph();

  void checkFeatures(Class *c);

  template <typename DispatchT> bool checkDispatchArgs(DispatchT *d, Method *m);
};
}

// Templates can't be defined in the implementation file, so in order to
// keep things clean(er) it is common practice to separate their implementations
// into another header file
#include "SemanticAnalysisImpl.h"

#endif /* __SEMANTIC_ANALYSIS__ */
