#ifndef SEMANTICANALYSISIMPL_H
#define SEMANTICANALYSISIMPL_H

#include "SemanticException.h"
#include <iostream>

template <typename DispatchT>
bool catmint::SemanticAnalysis::checkDispatchArgs(DispatchT *d, Method *m) {
  auto paramIt = m->begin();
  for (auto arg : *d) {
    if (!visit(arg)) {
      return false;
    }

    if (paramIt == m->end()) {
      throw TooManyArgsException(d->getName(), d);
    }

    std::cout << "  Getting type or argument.\n";
    if (!typeTable.isEqualOrImplicitlyConvertibleTo(
            typeTable.getType(arg), typeTable.getType((*paramIt)->getType()))) {
      throw WrongTypeException(typeTable.getType(arg),
                               typeTable.getType((*paramIt)->getType()), d);
    }

    ++paramIt;
  }

  if (paramIt != m->end()) {
    throw NotEnoughArgsException(d->getName(), d);
  }

  return true;
}

#endif /* SEMANTICANALYSISIMPL_H */
