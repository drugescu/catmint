#ifndef __catmint_PROGRAM__
#define __catmint_PROGRAM__

#include <map>
#include <memory>
#include <string>
#include <utility>
#include <vector>
#include <iostream>

#include "Class.h"
#include "TreeNode.h"
#include "support/iterator.h"

namespace catmint {
/// \brief AST node for an entire catmint program
///
/// This should be the root of the AST
class Program : public TreeNode {
  typedef std::vector<std::unique_ptr<Class>> ClassesType;
  typedef std::unique_ptr<Expression> ExprType;

  struct iterator
      : public llvm::iterator_adaptor_base<iterator,
                                           ClassesType::const_iterator> {
    explicit iterator(const ClassesType::const_iterator &&wrapped)
        : iterator_adaptor_base(wrapped) {}
    Class *operator*() const { return I->get(); }
  };

public:
  /// \brief Create a node for an entire program
  /// \note This takes ownership of \p classes if provided
  /*explicit Program(int lineNumber, const std::vector<Class *> &classes = {})
      : TreeNode(lineNumber), classes() {
    for (auto cls : classes) {
      this->classes.emplace_back(std::move(cls));
    }
    
    // If Main doesn't exist as a class, add it
    bool found = false;
    for (auto cls : classes) {
      if (cls->getName() == "Main") {
        found = true;
        std::cout << "Found Main.";
      }
    }
    
    if (found == false) {
      // Generate a new, empty main class with line number 0
      auto feats = new std::vector<Feature *> ();
      auto main = new Class(0, "Main", "", *feats);
      
      this->classes.emplace_back(main);
    }
  }*/
  
  explicit Program(int lineNumber, const std::vector<Class*> &classes = {}, std::unique_ptr<Expression> body1 = nullptr)
    : TreeNode(lineNumber), classes() {
    for (auto cls : classes) {
      this->classes.emplace_back(std::move(cls));
    }
    
    // If Main doesn't exist as a class, add it
    bool found = false;
    for (auto cls : classes) {
      if (cls->getName() == "Main") {
        found = true;
        std::cout << "Found Main.";
      }
    }
    
    if (found == false) {
      // Generate a new feature of type method, called main, which is by default executed, and add the expressions to it, line 0 by default
      auto feats = new std::vector<Feature *> ();
      const auto& formal_parms = new std::vector<FormalParam *> ();
      auto emptyExpr = new std::unique_ptr<Expression> ();
      
      //Method main_method;
      
      //if (body1 != nullptr)
        auto main_method = new Method(0, std::string("main"), std::string("Void"), std::move(body1), *formal_parms);
      //else
        //main_method = new Method(0, std::string("main"), std::string("Void"), emptyExpr, *formal_parms);
    
      feats->emplace_back(main_method);  
//      feats->emplace_back(body1);
  //    feats->emplace_back(body2);
      
      // Generate a new, empty main class with line number 0
      auto main = new Class(0, "Main", "", *feats);
      
      this->classes.emplace_back(main);
    }
  }

  /// \brief Add a class and take ownership of it - don't add a class that already exist, or merge them - not rgiht now
  void addClass(std::unique_ptr<Class> c) { classes.push_back(std::move(c)); }
  
  /// \brief Add an outlying block of code to the Main class, to the main method, Python-styles

  /// @{
  /// \brief Iterate through the program's classes
  iterator begin() const { return iterator(classes.begin()); }
  iterator end() const { return iterator(classes.end()); }
  /// @}

private:
  ClassesType classes;
  ExprType exprs1;
};
}
#endif // __catmint_PROGRAM__
