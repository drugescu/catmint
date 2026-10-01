#ifndef SEMANTICANALYSISIMPL_H
#define SEMANTICANALYSISIMPL_H

#include "SemanticException.h"
//#include "TypeVisitor.h"
#include <iostream>

template <typename DispatchT>
bool catmint::SemanticAnalysis::checkDispatchArgs(DispatchT *d, Method *m,
                                                  bool externCall) {
  // Temporary - should not matter for in and out...
  if (!m) {
    std::cout << "method is none.\n";
    return true;
  }

  auto paramIt = m->begin();
  for (auto arg : *d) {
    // A callback parameter takes a static method named as `Order.ascending`,
    // which is not an expression to be evaluated (`Order` is a class, not a
    // variable), so it is checked against the callback's signature instead.
    if (externCall && paramIt != m->end()) {
      if (auto callback = callbackClass((*paramIt)->getType())) {
        checkCallbackArgument(arg, callback, d);
        ++paramIt;
        continue;
      }
    }
    if (!visit(arg)) {
      return false;
    }

    if (paramIt == m->end()) {
      throw TooManyArgsException(d->getName(), d);
    }

    std::cout << "  checkDispatchArgs-> Getting type of argument.\n";
    std::cout << "    Type of arg in dispatch: " << typeTable.getType(arg)->getName() << "\n";
    std::cout << "    Type of arg in method: " << (*paramIt)->getType() << "\n";

    const std::string argName = typeTable.getType(arg)->getName();
    const std::string paramName = (*paramIt)->getType();
    if (externCall) {
      // C takes an integer and this is a float: almost always a mistake
      // in a call to C, so it is not converted silently here, though it
      // still is in catmint code.
      if (TypeTable::floatWidth(argName) && TypeTable::integerWidth(paramName)) {
        throw SemanticException("'" + d->getName() + "' takes an integer as '" +
                                    (*paramIt)->getName() + "' and is given a " +
                                    argName + "; convert it on purpose first",
                                d);
      }
      // A Ptr parameter is C's void *: it takes the bytes of an extern
      // struct or of an array, which is how an out-parameter is written.
      if (paramName == strings::Ptr &&
          (cStructClass(argName) || argName == strings::Bytes ||
           argName == strings::Ints || argName == strings::Floats)) {
        ++paramIt;
        continue;
      }
    }
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
