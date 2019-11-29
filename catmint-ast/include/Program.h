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
    // First emplace the classes in the Program
    for (auto cls : classes) {
      this->classes.emplace_back(std::move(cls));
    }

    // If Main doesn't exist as a class, add it
    bool found = false;

    // Raw pointers, no ownership info required, just have to modify them
    catmint::Class* found_class = nullptr;
    //catmint::Method* found_method = nullptr;
    catmint::Feature* found_method = nullptr;
    
    // Find main class
    for (auto& cls : this->classes) {
      if (cls->getName() == "Main") {
        found = true;
        found_class = cls.get();

        std::cout << "Found Main of type { " << cls->getName() << ", " << typeid(cls).name() << " }" << std::endl;

        break;
      }
    }

    // If found, insert blocks
    if (found == true) {
      // Now add stuff to it - whats before, before the first block, what's after, after the last block
      // find main, which is by default executed, and add the expressions to it
      for (auto met = found_class->begin(); met != found_class->end(); met++) {
        std::cout << "  Class Main has feature : " << (*met)->getName() << std::endl;
        if ((*met)->getName() == "main") {
           found_method = dynamic_cast<Method*>(*met);
           std::cout << "    Class Main has a \"main\" method, here we must insert our stuff : " << found_method->getName() << std::endl;
        }
      }

      // If there is a main method, insert into it, if not, create it
      if (found_method != nullptr) {
        std::cout << "    Attempting insertion in class Main and method \"main\"" << std::endl;
        // Class will have 1 feature, the main method
        // The main method will have a block of expressions starting with the one given to this constructor
        //auto feats = new std::vector<Feature *> ();
        //const auto& formal_parms = new std::vector<FormalParam *> ();
        if (body1.get() == nullptr)
          std::cout << "    Starting expression is null!" << std::endl;
        else {
          std::cout << "    Starting expression is not null!" << std::endl;
          std::cout << "    Starting expression line number: " << body1.get()->getLineNumber() << std::endl;
        }
        std::cout.flush();

        auto startingExpr = std::move(body1);
        if (startingExpr == nullptr)
          std::cout << "    Starting expression is null!" << std::endl;
        else
          std::cout << "    Starting expression is not null!" << std::endl;
        std::cout.flush();
        
        auto d = dynamic_cast<Method*>(found_method)->getBody();
        if (d == nullptr)
          std::cout << "    'main' method body is null!" << std::endl;
        else
          std::cout << "    'main' method body is not null!" << std::endl;

        std::vector<Expression*> expressions;

        // Place new block // dont forget to separate between before and after
        //if (startingExpr != nullptr)
        //  expressions.emplace_back(std::move(startingExpr.get()));

        // Place old block back
        if (d != nullptr)
          expressions.emplace_back(std::move(d));

        for (auto c : expressions)
          std::cout << "Expr : " << c << std::endl;

        // Create a new block, add the received block and the currently existing blocks of expressions to it
        //   Then assign it to the method
        auto new_body = new catmint::Block(lineNumber, expressions);
        std::cout << "New block now contains back: " << new_body->back();

        //std::unique_ptr<Block> new_body_ptr(new catmint::Block(lineNumber, expressions));
        std::unique_ptr<Block> new_body_ptr;

        //new_body_ptr.reset(std::move(new_body));
        new_body_ptr.reset(new_body);

        std::cout << "Long line -----------------------------------------------";
        std::cout.flush();

        //found_method->setBody(std::move(new_body_ptr));
        //found_method->setBody(new_body);

        auto t = dynamic_cast<Method*>(found_method)->getBody();
        std::cout << "Inserted a new body. " << t << std::endl;
        std::cout.flush();
        

        //found_method->setBody(std::move(new_body_ptr));
        //found_method->setBody(new std::unique_ptr<Block>(reinterpret_cast<Block>(startingExpr)));
        // /found_method->setBody(std::move(new_body_ptr));

      }
      else { // Not found main method of Main class
        // This part works
        auto feats = new std::vector<Feature *> ();
        //const auto& formal_parms = new std::vector<FormalParam *> ();
        const auto& formal_parms = new std::vector<Attribute *> ();
        auto startingExpr = std::move(body1);

        auto main_method = new Method(0, std::string("main"), std::string("Void"), std::move(startingExpr), *formal_parms);
        auto main_method_ptr = std::unique_ptr<Feature>(main_method);

        // Place the main_method into the list of features
        feats->emplace_back(std::move(main_method));

        // Place into main class a new features
        found_class->addFeature(std::move(main_method_ptr));//std::move(*(feats->back())));
      }

    }
    else if (found == false) {
      // Generate a new feature of type method, called main, which is by default executed, and add the expressions to it, line 0 by default
      // This part also works

      // Class will have 1 feature, the main method
      // The main method will have a block of expressions starting with the one given to this constructor
      auto feats = new std::vector<Feature *> ();
      //const auto& formal_parms = new std::vector<FormalParam *> ();
      const auto& formal_parms = new std::vector<Attribute *> ();
      auto startingExpr = std::move(body1);

      auto main_method = new Method(0, std::string("main"), std::string("Void"), std::move(startingExpr), *formal_parms);

      // Place the main_method into the list of features
      feats->emplace_back(std::move(main_method));

      // Do also place here variable declaraions FormalParams

      // Generate a new, empty main class with line number 0
      auto main = new Class(0, "Main", "", *feats);

      // Place this in the classesl
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
