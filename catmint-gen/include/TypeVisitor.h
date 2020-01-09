// TypeVisitor
#ifndef TYPEVISITOR_H
#define TYPEVISITOR_H

#include <ASTNodes.h>
#include <StringConstants.h>
#include <TypeTable.h>
#include "Debug.h"

namespace catmint {

/// \brief Performs the debug print analysis on the catmint program received in the
/// constructor
//class TypeVisitor : public ASTVisitor {
class TypeVisitor {
public:

  TypeVisitor(TypeTable *t);
  virtual ~TypeVisitor() {}

public:
  //std::string visit(Attribute *a) override;
  std::string visitStr(Attribute *a);
  std::string visitStr(Expression *e);
  std::string visitStr(Block *b);

  std::string visitStr(IntConstant *ic);
  std::string visitStr(StringConstant *sc);
  std::string visitStr(NullConstant *nc);
  std::string visitStr(Symbol *s);

  std::string visitStr(BinaryOperator *bo);
  std::string visitStr(UnaryOperator *uo);

  std::string visitStr(Dispatch *d);
  std::string visitStr(Class *c);

  // LocalDefinition for attribution if neede,d and if if permitted by grammar

private:
  // Program *program;
  TypeTable *typeTable;

};
}

#endif /* TYPE_VISITOR_H */