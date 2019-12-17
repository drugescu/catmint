
#include "SymbolTable.h"
#include "SemanticException.h"

#include <cassert>

using namespace catmint;

void SymbolTable::pushScope() {
  SymbolTableScope *scope = new SymbolTableScope();
  symbolTable.push_back(scope);
}

void SymbolTable::popScope() {
  assert(!symbolTable.empty() && "popScope on an empty symbol table");

  SymbolTableScope *scope = symbolTable.back();
  symbolTable.pop_back();
  scope->clear();
  delete scope;
}

void SymbolTable::insert(TreeNode *v, const std::string &name) {
  SymbolTableScope *scope = symbolTable.back();
  (*scope)[name] = v;
}

void SymbolTable::insert(TreeNode *v, const std::vector<std::string> &name) {
  SymbolTableScope *scope = symbolTable.back();
  // for all
  for (auto& n : name)
    (*scope)[n] = v;
  //(*scope)[name] = v;
}

TreeNode *SymbolTable::lookup(const std::string &name) const {
  assert(!symbolTable.empty() && "lookup on an empty symbol table");

  // do a bit of parsing in case we have self.x
  std::string self("self.");
  auto startsWithSelf = (name.find(self) == 0);
  auto varName = startsWithSelf ? name.substr(self.size()) : name;
  auto scope = startsWithSelf ? getScope("self") : getScope(varName);

  if (scope) {
    auto it = scope->find(varName);
    if (it != scope->end()) {
      return it->second;
    }
  }

  throw UnknownVariableException(name);
}

auto SymbolTable::getScope(const std::string &name) const -> SymbolTableScope
    * {
  for (int i = symbolTable.size() - 1; i >= 0; i--) {
    SymbolTableScope *scope = symbolTable[i];
    SymbolTableScope::iterator it = scope->find(name);
    if (it != scope->end()) {
      return scope;
    }
  }

  return nullptr;
}
