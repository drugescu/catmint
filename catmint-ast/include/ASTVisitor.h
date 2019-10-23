#ifndef ASTVISITOR_H
#define ASTVISITOR_H

#include "ASTNodes.h"

namespace catmint {

/// \brief Base class for AST visitors.
///
/// This class offers facilities for visiting each kind of node in the AST. The
/// \c visit methods are in charge of both actually visiting the nodes and of
/// traversing the AST (i.e. invoking visit for the subtrees of the current
/// node). This means that if you override one of the methods, you will have to
/// continue the traversal yourself.
///
/// The base class offers default implementations for traversing the AST. If any
/// of the \c visit methods returns false, the traversal stops.
class ASTVisitor {
  ASTVisitor(const ASTVisitor &) = delete;
  ASTVisitor(ASTVisitor &&) = delete;
  ASTVisitor &operator=(const ASTVisitor &) = delete;
  ASTVisitor &operator=(ASTVisitor &&) = delete;

public:
  ASTVisitor() {}
  virtual ~ASTVisitor() {}

  virtual bool visit(Program *P);

  virtual bool visit(Class *C);
  virtual bool visit(Feature *F);
  virtual bool visit(Attribute *A);
  virtual bool visit(Method *M); /// Default order: parameters and then body
  virtual bool visit(FormalParam *F);

  virtual bool visit(Expression *E);

  virtual bool visit(IntConstant *IC);
  virtual bool visit(FloatConstant *IF);
  virtual bool visit(StringConstant *SC);
  virtual bool visit(NullConstant *NC);
  virtual bool visit(Symbol *S);

  virtual bool visit(Block *B);
  virtual bool visit(Assignment *A);
  virtual bool visit(BinaryOperator *BO);
  virtual bool visit(UnaryOperator *UO);
  virtual bool visit(Cast *C);
  virtual bool visit(Substring *S);       /// Default order: string, start, end
  virtual bool visit(Dispatch *D);        /// Default order: args, object
  virtual bool visit(StaticDispatch *SD); /// Default order: args, object
  virtual bool visit(NewObject *NO);
  virtual bool visit(IfStatement *If); /// Default order: condition, then, else
  virtual bool visit(WhileStatement *While);  /// Default order: condition, body
  virtual bool visit(LocalDefinition *Local); /// \note Does not visit scope!
};
} /* namespace catmint */
#endif /* ASTVISITOR_H */
