
#ifndef INCLUDE_SYMBOLTABLE_H_
#define INCLUDE_SYMBOLTABLE_H_

#include <cassert>
#include <iostream>
#include <fstream>
#include <vector>
#include <string>
#include <unordered_map>

namespace catmint {

class TreeNode;

typedef std::unordered_map<std::string, TreeNode *> UnnamedSymbolTableScope;

// Scopes should be names so instead of a vect<unordered_map<string, TreeNode>>
//   we should have vect<string,unordered_map<string, TreeNode>>
class NamedSymbolTableScope {
  
public:
  std::string name;
  std::unordered_map<std::string, TreeNode *> *uscope;

  NamedSymbolTableScope() { uscope = new UnnamedSymbolTableScope(); name = ""; };
  NamedSymbolTableScope(const std::string n) { uscope = new UnnamedSymbolTableScope(); name = n; };
  ~NamedSymbolTableScope() { uscope->clear(); delete uscope; };

};

// Symbol table class
class SymbolTable {
  //typedef std::unordered_map<std::string, TreeNode *> SymbolTableScope;
  typedef NamedSymbolTableScope SymbolTableScope;

public:
  SymbolTable() {}
  ~SymbolTable() {}

  // RAII class for scope management
  struct Scope {
    Scope(SymbolTable &s, std::string name) : symbolTable(s) { symbolTable.pushScope(name); }
    ~Scope() { }

    // We should not destroy the symbol table without outputting it
    // ~Scope() { symbolTable.popScope(); }

  private:
    SymbolTable &symbolTable;
  };

  // Print the symbol table
  void print(std::ostream& f);

  template <typename NamedNode> void insert(NamedNode *v) {

    std::cout << "Attempting insert of node " << v->getName()[0] << std::endl;

    assert(!symbolTable.empty() && "insert on an empty symbol table");
    
    // Go through all names and insert them if LocalDefinition
    insert(v, v->getName());

    std::cout << "Inserted node " << v->getName()[0] << std::endl;
  }

  TreeNode *lookup(const std::string &name) const;

private:
  void insert(TreeNode *v, const std::string &name);
  void insert(TreeNode *v, const std::vector<std::string> &name);

  void pushScope(const std::string name);
  void popScope();

  SymbolTableScope *getScope(const std::string &name) const;

  std::vector<SymbolTableScope *> symbolTable;
};
}

#endif /* INCLUDE_SYMBOLTABLE_H_ */
