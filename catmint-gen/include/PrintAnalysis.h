#ifndef PRINT_ANALYSIS_H
#define PRINT_ANALYSIS_H

#include <map>
#include <ASTVisitor.h>
#include <Program.h>
#include "Debug.h"

namespace catmint {

/// \brief Performs the debug print analysis on the catmint program received in the
/// constructor
class PrintAnalysis : public ASTVisitor {
public:
  PrintAnalysis(Program *p);
  virtual ~PrintAnalysis() {}

  void runAnalysis();

private:
  bool visit(Program *p) override;
  bool visit(Class *c) override;
  bool visit(Feature *f) override;

  bool visit(Attribute *a) override;

  bool visit(Method *m) override;

  bool visit(Expression *e) override;

  bool visit(IntConstant *ic) override;
  bool visit(StringConstant *sc) override;
  bool visit(NullConstant *nc) override;
  bool visit(Symbol *s) override;

  bool visit(Block *b) override;
  bool visit(BinaryOperator *bo) override;
  bool visit(Dispatch *d) override;
  bool visit(IfStatement *i) override;
  bool visit(ForStatement *i) override;
  bool visit(WhileStatement *w) override;
  bool visit(LocalDefinition *local) override;
  bool visit(ReturnExpression *ret) override;
  /*bool visit(FormalParam *f) override;

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
  bool visit(LocalDefinition *local) override;*/

private:
  Program *program;

};
}

#endif /* PRINT_ANALYSIS_H */
