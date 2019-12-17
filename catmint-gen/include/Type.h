
#ifndef __TYPE__
#define __TYPE__

#include <string>

#include "Class.h"

namespace catmint {

class Type {
public:
  Type(const std::string &name) : name(name), cls(nullptr) {}
  Type(Class *cls) : name(cls->getName()), cls(cls) {}
  ~Type() {}

  const std::string &getName() const { return name; }

  Class *getClass() const { return cls; }

private:
  std::string name;
  Class *cls;
};
}

#endif /* __TYPE__ */
