#ifndef CLASSVISITOR_H
#define CLASSVISITOR_H

#include "Class.h"
#include "Program.h"
#include "TypeTable.h"

#include <unordered_set>

namespace lcpl {

/// \brief Base class for visiting the class hierarchy
///
/// This class offers support for visiting each class in the program in a
/// topological order defined by the inheritance relationship (a class' parent
/// is always visited before the class itself). It also allows different
/// treatment of builtin classes vs user classes.
class ClassVisitor {
public:
  ClassVisitor(const TypeTable &ASTTypeTable) : ASTTypes(ASTTypeTable) {}
  virtual ~ClassVisitor() {}

  /// \brief Method that starts the traversal of all classes in the program.
  /// This method invokes visitUserClass and visitBuiltinClass, always on the
  /// parent before any of the children. Only override it if you wish to change
  /// the visiting order.
  virtual bool visitProgram(Program *P);

private:
  /// \brief Method for visiting user-defined classes.
  virtual bool visitUserClass(Class *C);

  /// \brief Method for visiting builtin classes.
  virtual bool visitBuiltinClass(Class *C);

  /// \brief Helper class that dispatches to visit[User|Builtin]Class.
  bool visitClass(Class *C, std::unordered_set<Class *> &Visited);

protected:
  const TypeTable &ASTTypes;
};

} // namespace lcpl

#endif
