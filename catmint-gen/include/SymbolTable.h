
#ifndef INCLUDE_SYMBOLTABLE_H_
#define INCLUDE_SYMBOLTABLE_H_

#include <cassert>
#include <iostream>
#include <fstream>
#include <vector>
#include <string>
#include <unordered_map>

namespace catmint {

class Symbol;
class TreeNode;

typedef std::unordered_map<std::string, TreeNode *> UnnamedSymbolTableScope;
typedef std::unordered_map<Symbol *, TreeNode *> SymbolMap;

// Scopes should be names so instead of a vect<unordered_map<string, TreeNode>>
//   we should have vect<string,unordered_map<string, TreeNode>>
class NamedSymbolTableScope {
  
public:
  std::string name;
  std::unordered_map<std::string, TreeNode *> *uscope;
  /// A scope the analysis has left stays in the table, so the whole thing can
  /// still be printed at the end, but nothing can see into it. Until this
  /// existed no scope was ever closed: a name declared in one block, method or
  /// class was visible in every later one, so "is this name already bound?"
  /// could not be asked.
  bool open = true;

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
    // Closed, not deleted: the table is still printed whole at the end.
    ~Scope() { symbolTable.closeScope(); }

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

  /// \p at is the node the name was written on, so that "not declared" can
  /// say where. Optional, because the lookups the compiler makes for itself
  /// -- "self", say -- have no source location and cannot fail usefully.
  TreeNode *lookup(const std::string &name, TreeNode *at = nullptr) const;

  /// \brief Whether \p name resolves to a variable, without throwing.
  ///        A class name used as the receiver of a static call does not.
  bool contains(const std::string &name) const;

private:
  void insert(TreeNode *v, const std::string &name);
  void insert(TreeNode *v, const std::vector<std::string> &name);

  void pushScope(const std::string name);
  void popScope();
  /// Mark the innermost scope that is still open as left.
  void closeScope();
  /// The innermost scope that is still open: where a new name goes.
  SymbolTableScope *innermostOpen() const;

  SymbolTableScope *getScope(const std::string &name) const;

  std::vector<SymbolTableScope *> symbolTable;
};
}

#endif /* INCLUDE_SYMBOLTABLE_H_ */
