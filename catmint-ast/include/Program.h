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

// Forward declarations of classes
#include "StringConstant.h"
#include "UnaryOperator.h"
#include "Substring.h"
#include "StaticDispatch.h"
#include "WhileStatement.h"

namespace catmint {


enum exps {
  INT = 0,
  FLOAT,
  STRING,
  NULLCT,
  SYMBOL,
  BLOCK,
  BINOP,
  UNARYOP,
  CCC,
  SUBSTR,
  DISP,
  SDISP,
  NEW,
  IF,
  WHILE,
  LOCAL,
  ASSIGN
};

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


int type_of_expr(Expression *E) {
  if (auto IntCt = dynamic_cast<IntConstant *>(E)) {
    return INT;
  } else if (auto FloatCt = dynamic_cast<FloatConstant *>(E)) {
    return FLOAT;
  } else if (auto StringCt = dynamic_cast<StringConstant *>(E)) {
    return STRING;
  } else if (auto NullCt = dynamic_cast<NullConstant *>(E)) {
    return NULLCT;
  } else if (auto Sym = dynamic_cast<Symbol *>(E)) {
    return SYMBOL;
  } else if (auto Blk = dynamic_cast<Block *>(E)) {
    return BLOCK;
  } else if (auto BinOp = dynamic_cast<BinaryOperator *>(E)) {
    return BINOP;
  } else if (auto UnaryOp = dynamic_cast<UnaryOperator *>(E)) {
    return UNARYOP;
  }  else if (auto C = dynamic_cast<Cast *>(E)) {
    return CCC;
  } else if (auto Substr = dynamic_cast<Substring *>(E)) {
    return SUBSTR;
  } else if (auto Disp = dynamic_cast<Dispatch *>(E)) {
    return DISP;
  } else if (auto SDispatch = dynamic_cast<StaticDispatch *>(E)) {
    return SDISP;
  } else if (auto New = dynamic_cast<NewObject *>(E)) {
    return NEW;
  } else if (auto If = dynamic_cast<IfStatement *>(E)) {
    return IF;
  } else if (auto While = dynamic_cast<WhileStatement *>(E)) {
    return WHILE;
  } else if (auto Local = dynamic_cast<LocalDefinition *>(E)) {
    return LOCAL;
  } else if (auto Assign = dynamic_cast<Assignment *>(E)) {
    return ASSIGN;
  }

  return -1;
}

  /// \brief Create a node for an entire program
  /// \note This takes ownership of \p classes if provided
  /* Constructor */
  explicit Program(int lineNumber, const std::vector<Class*> &classes = {}, std::unique_ptr<Expression> body1 = nullptr, std::unique_ptr<Expression> body2 = nullptr, bool createMain = false)
    : TreeNode(lineNumber), classes() {
    for (auto cls : classes) {
      this->classes.emplace_back(std::move(cls));
    }

    /* If we have been asked to not generate a main method, for good reason (semantic check) so don't do it. */
    if (!createMain) {
      std::cout << "[ LOG ] No 'Main' will be generated - explicitely set this way (semantic analysis or codegen)." << std::endl;
      return;
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
        break;
      }
    }

    // If found, insert blocks
    if (found == true) {
      // Now add stuff to it - whats before, before the first block, what's after, after the last block
      // find main, which is by default executed, and add the expressions to it
      for (auto met = found_class->begin(); met != found_class->end(); met++) {
        //std::cout << "  Class Main has feature : " << (*met)->getName() << std::endl;
        if ((*met)->getName() == "main") {
           found_method = dynamic_cast<Method*>(*met);
           //std::cout << "    Class Main has a \"main\" method, here we must insert our stuff : " << found_method->getName() << std::endl;
        }
      }

      // If there is a main method, insert into it, if not, create it
      if (found_method != nullptr) {
        std::cout << "[ LOG ] Inserting your out-of-class code into Main.main" << std::endl;
        // Class will have 1 feature, the main method
        // The main method will have a block of expressions starting with the one given to this constructor

        auto startingExpr = std::move(body1);
        auto endingExpr   = std::move(body2);
        
        if (found_method->isMethod()) {
          //std::cout << "    'main' is indeed a method!" << std::endl;
        }
        else {
          std::cout << "[ Error ] 'main' of 'Main' is not a method!" << std::endl;
          exit(1);
        }

        std::vector<Expression*> expressions;
        
        // Create a new block, add the received block and the currently existing blocks of expressions to it
        // Place new block
        auto new_body = new catmint::Block(lineNumber);

        // Add pre- and post- block
        new_body->addExpression(std::unique_ptr<Expression>(std::move(startingExpr))); // Starting expression added successfully - but empty

        // Current content of main method
        auto body_full = std::move(dynamic_cast<Method*>(found_method)->getBodyFull());
        new_body->addExpression(std::unique_ptr<Expression>(std::move(body_full)));        
        
        // Add post block
        new_body->addExpression(std::unique_ptr<Expression>(std::move(endingExpr))); // Starting expression added successfully - but empty

        // Replace body of main with the new body
        std::unique_ptr<Block> new_body_ptr(new_body);
        dynamic_cast<Method*>(found_method)->setBody(std::move(new_body_ptr));
      }
      else { // Not found 'main' method of 'Main' class - must add it
        std::cout << "[ LOG ] 'main' method of 'Main' class does not exist, generating it from your code." << std::endl;
        fflush(stdout);
        auto feats = new std::vector<Feature *> ();
        const auto& formal_parms = new std::vector<Attribute *> ();
        
        // Get surrounding expressions
        auto startingExpr = std::move(body1);
        auto endingExpr = std::move(body2);

        auto main_method = new Method(0, std::string("main"), std::string("Void"), nullptr, *formal_parms);
        auto main_method_ptr = std::unique_ptr<Feature>(main_method);

        // Also add ending expression
        auto new_body = new catmint::Block(lineNumber);
        new_body->addExpression(std::unique_ptr<Expression>(std::move(startingExpr))); // Starting expression added successfully - but empty
        new_body->addExpression(std::unique_ptr<Expression>(std::move(endingExpr))); // Starting expression added successfully - but empty

        // Now set new body
        std::unique_ptr<Block> new_body_ptr(new_body);
        main_method->setBody(std::move(new_body_ptr));

        // Place the main_method into the list of features
        feats->emplace_back(std::move(main_method));

        // Place into main class
        found_class->addFeature(std::move(main_method_ptr));
      }

    }
    else if (found == false) {
      // Generate a new feature of type method, called main, which is by default executed, and add the expressions to it, line 0 by default
      // Class will have 1 feature, the main method
      // The main method will have a block of expressions starting with the one given to this constructor

      std::cout << "[ LOG ] 'Main.main' class and method do not exist, generating them from your code." << std::endl;

      auto feats = new std::vector<Feature *> ();
      const auto& formal_parms = new std::vector<Attribute *> ();
      
      // Get surrounding expressions
      auto startingExpr = std::move(body1);
      auto endingExpr = std::move(body2);

      // Generate empty method body
      auto main_method = new Method(0, std::string("main"), std::string("Void"), nullptr, *formal_parms);

      // Also add ending expression
      auto starting_body = new catmint::Block(lineNumber);
      starting_body->addExpression(std::unique_ptr<Expression>(std::move(startingExpr))); // Starting expression added successfully - but empty
      starting_body->addExpression(std::unique_ptr<Expression>(std::move(endingExpr))); // Starting expression added successfully - but empty

      // Now set new body
      std::unique_ptr<Block> starting_body_ptr(starting_body);
      main_method->setBody(std::move(starting_body_ptr));
      
      // Place the main_method into the list of features
      feats->emplace_back(std::move(main_method));

      // Generate a new, empty main class with line number 0
      auto main = new Class(0, "Main", "", *feats);

      // Place Main class in the classes list
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
