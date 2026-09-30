#ifndef SEMANTIC_ANALYSIS_H
#define SEMANTIC_ANALYSIS_H

#include <map>
#include <set>
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
  bool visit(SpawnStatement *s) override;
  bool visit(LoopControl *lc) override;

  /// Whether \p name in \p c is a C function reached through `extern class`.
  Method *externMethod(Class *c, const std::string &name);
  /// The types allowed to cross the boundary, and why the others are not.
  void checkExternSignature(Class *c, Method *m);

  /// Say something when arithmetic is done at one width and then widened.
  /// `Int64 x = a * b` with two Ints multiplies in 32 bits and widens the
  /// result, so a product that does not fit is already wrong. The arithmetic
  /// is left alone -- it is what C does, and this language's integer rules
  /// are C's -- and the compiler points at it instead.
  void warnNarrowWidening(const std::string &declaredType, Expression *init,
                          int line);

  /// Whether \p m may run on a worker: it must do arithmetic and nothing
  /// else, so that it cannot touch a reference count, the temporary pool or
  /// the handler stack from another thread. \p why says what stopped it.
  bool workerSafe(Class *c, Method *m, std::set<Method *> &seen,
                  std::string &why);

  /// Work out every method's inferred return type before anything is
  /// checked, so that a caller declared above its callee sees the same type as
  /// one declared below it. Run to a fixed point, because one inferred method
  /// may return what another does.
  void inferReturnTypesEarly();
  /// \p c is the class \p m belongs to, for resolving a bare call.
  std::string earlyReturnType(Class *c, Method *m);
  /// The type of \p e worked out structurally, without the symbol table and
  /// without analysing anything: a literal, a `new`, arithmetic on those, or a
  /// call to a method that declares its type. Empty when it cannot tell, which
  /// is not an error -- the ordinary pass settles those.
  std::string earlyTypeOf(Class *c, Expression *e);

  /// The type a method returns when two of its `return`s disagree, or null
  /// when they cannot be reconciled and the programmer has to say. Stricter
  /// on purpose than isEqualOrImplicitlyConvertibleTo, which allows boxing in
  /// either direction -- under that rule a method returning an Int and a
  /// String infers Int and fails at run time, which is the error inference
  /// exists to move to compile time.
  Type *commonReturnType(Type *a, Type *b);

  /// The abstract methods \p c still has no body for: its own, and any it
  /// inherited without overriding. Empty means the class is concrete and can
  /// be made.
  std::vector<std::string> unimplementedAbstract(Class *c);

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
  /// How many loops enclose the node being visited. `break` and `continue`
  /// outside all of them have nothing to branch to, and the generator would
  /// have no target to emit -- so it is rejected here, where the message can
  /// name a line.
  unsigned loopDepth = 0;
  /// How many `unsafe` regions enclose the node being visited -- blocks, and
  /// the body of an `unsafe def`. Calling an extern function anywhere else is
  /// an error, which is the whole of what the marking buys: every place the
  /// program can reach outside itself is spelled.
  unsigned unsafeDepth = 0;
  /// The field a subscript is about to index: the one place an array field
  /// of an extern struct may be named without being an error.
  FieldAccess *cArrayContext = nullptr;
  /// A `for` binds its loop variable, which has no definition node of its own
  /// in the tree. The synthesised definitions are owned here so that they
  /// outlive the symbol table entries pointing at them.
  std::vector<std::unique_ptr<LocalDefinition>> syntheticDefinitions;

  void checkMainClassAndMethod();
  void checkInheritanceGraph();

  void checkFeatures(Class *c);
  void checkImplementedInterfaces(Class *c);

  template <typename DispatchT>
  bool checkDispatchArgs(DispatchT *d, Method *m, bool externCall = false);
  /// The extern struct or union \p typeName names, or null.
  Class *cStructClass(const std::string &typeName);
  /// Everything `extern struct` promises: fields of C-representable types,
  /// no methods, no initialisers.
  void checkCStruct(Class *c);
  /// `s.pad[i]` and `s.pad[i] = v`: the dispatch a subscript on an array
  /// field of an extern struct parses to. Handled here when \p d is one.
  bool visitCArrayAccess(Dispatch *d, bool &handled);
  /// C's unsigned types are for extern declarations only; anywhere else they
  /// are an error that says what to write instead.
  void refuseCBoundaryType(const std::string &type, TreeNode *where);

};
}

// Templates can't be defined in the implementation file, so in order to
// keep things clean(er) it is common practice to separate their implementations
// into another header file
#include "SemanticAnalysisImpl.h"

#endif /* __SEMANTIC_ANALYSIS__ */
