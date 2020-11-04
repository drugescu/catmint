
#include "SymbolTable.h"
#include "SemanticException.h"

#include <cassert>
#include <iostream>
#include <fstream>

using namespace catmint;

void SymbolTable::pushScope(const std::string name) {
  std::cout << "Pushing new scope '" << name << "'... " << std::endl;
  SymbolTableScope *scope = new SymbolTableScope(name);
  symbolTable.push_back(scope);
}

void SymbolTable::popScope() {
  std::cout << "Popping scope... " << std::endl;

  assert(!symbolTable.empty() && "popScope on an empty symbol table");

  SymbolTableScope *scope = symbolTable.back();
  symbolTable.pop_back();

  delete scope;
}

void SymbolTable::insert(TreeNode *v, const std::string &name) {
  SymbolTableScope *scope = symbolTable.back();

  (*(scope->uscope)) [name] = v;
}

void SymbolTable::insert(TreeNode *v, const std::vector<std::string> &name) {
  SymbolTableScope *scope = symbolTable.back();

  for (auto& n : name) {
    (*(scope->uscope))[n] = v;
  }
}

TreeNode *SymbolTable::lookup(const std::string &name) const {
  assert(!symbolTable.empty() && "lookup on an empty symbol table");

  // do a bit of parsing in case we have self.x
  std::string self("self.");
  auto startsWithSelf = (name.find(self) == 0);
  auto varName = startsWithSelf ? name.substr(self.size()) : name;
  auto scope = startsWithSelf ? getScope("self") : getScope(varName);

  if (scope) {
    auto it = (scope->uscope)->find(varName);
    if (it != (scope->uscope)->end()) {
      return it->second;
    }
  }

  throw UnknownVariableException(name);
}

auto SymbolTable::getScope(const std::string &name) const -> SymbolTableScope
    * {
  for (int i = symbolTable.size() - 1; i >= 0; i--) {
    SymbolTableScope *scope = symbolTable[i];
    UnnamedSymbolTableScope::iterator it = (scope->uscope)->find(name);
    if (it != (scope->uscope)->end()) {
      return scope;
    }
  }

  return nullptr;
}

void SymbolTable::print(std::ostream& f) {
  f << "-------------------------------------------\n";
  f << "[Symbol Table]\n";
  f << "Symbol table size " << symbolTable.size() - 1 << std::endl;
  f << "'self' refers to auto-added symbols for each class." << std::endl;

  for (int i = 0; i < symbolTable.size(); i++) {
    SymbolTableScope *scope = symbolTable[i];

    f << "Scope_" << i << " : Name '" << scope->name << "' :" << std::endl;

    UnnamedSymbolTableScope::iterator it = (scope->uscope)->begin();

    while (it != (scope->uscope)->end()) {
      f << "  Symbol: '" << it->first << "', Line " << it->second->getLineNumber() << std::endl;
      it++;
    }
  }
}
