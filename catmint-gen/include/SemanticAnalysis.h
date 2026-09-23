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
  /// \param libraryOnly  true when analysing a .cmm module on its own; such a
  ///                     unit has no entry point, so the Main check is skipped.
  SemanticAnalysis(Program *p, bool libraryOnly = false);
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
  bool visit(FieldAccess *fa) override;
  bool visit(TryStatement *t) override;
  bool visit(ThrowStatement *t) override;
  bool visit(DeferStatement *d) override;

  /// The class named by a static call's receiver, or null for a normal call.
  Class *staticReceiverClass(Dispatch *d);
  bool visit(IfStatement *i) override;
  bool visit(WhileStatement *w) override;
  bool visit(LocalDefinition *local) override;
  bool visit(ReturnExpression *r) override;
  bool visit(ForStatement *f) override;

public:
  TypeTable typeTable;
  SymbolTable symbolTable;
  TypeVisitor typeVisitor;
  SymbolMap definitionsMap;

  /// \brief Get the type table
  /// \warning  This should only be called after runAnalysis(), otherwise the
  ///           table will be empty
  TypeTable getTypeTable() { return typeTable; }

  /// \brief Get a map from symbols to their definitions
  SymbolMap getSymbolDefinitions() const { return definitionsMap; }


private:
  Program *program;
  bool libraryOnly;
  /// The class currently being analysed, so that a bare call can be resolved
  /// against its static methods, which have no receiver to look at.
  Class *currentClass = nullptr;
  /// A `for` binds its loop variable, which has no definition node of its own
  /// in the tree. The synthesised definitions are owned here so that they
  /// outlive the symbol table entries pointing at them.
  std::vector<std::unique_ptr<LocalDefinition>> syntheticDefinitions;

  void checkMainClassAndMethod();
  void checkInheritanceGraph();

  void checkFeatures(Class *c);
  void checkImplementedInterfaces(Class *c);

  template <typename DispatchT> bool checkDispatchArgs(DispatchT *d, Method *m);

};
}

// Templates can't be defined in the implementation file, so in order to
// keep things clean(er) it is common practice to separate their implementations
// into another header file
#include "SemanticAnalysisImpl.h"

#endif /* __SEMANTIC_ANALYSIS__ */
