
%code requires {
	#include <iostream>
	#include <fstream>
	#include <string>
	#include <sstream>
	#include <regex>
	#include <vector>
	#include <ASTNodes.h>
}

%code {
	#include <ASTSerialization.h>

	typedef std::unique_ptr<catmint::Expression> Expression;
	typedef catmint::BinaryOperator::BinOpKind   BinOp;
	typedef catmint::UnaryOperator::UnaryOpKind  UnOp;

	extern FILE* yyin;

	static catmint::Program* gCatmintProgram = nullptr;
	char* gInputFileName = NULL;

	int  yylex ();
	void yyerror(const char *error)
	{
		std::cout << gInputFileName << " | Line : " << yylloc.first_line << " | Column : " << yylloc.first_column << " | Error: " << error << std::endl;
	}
}

// Verbosity on syntax errors
%define parse.error verbose

%locations

%union {
	std::string* stringValue;
	int intValue;
	double floatValue;

	catmint::Class* catmintClass;
	std::vector<catmint::Class*>* catmintClasses;

	catmint::Expression* expression;
	std::vector<catmint::Expression*>* expressions;

	catmint::Feature* feature;
	std::vector<catmint::Feature*>* features;

	catmint::FormalParam* formal;
	std::vector<catmint::FormalParam*>* formals;

	catmint::Block* block;
	std::vector<std::string>* vecstr;
}

%start catmint_program

%token KW_WHILE KW_FOR KW_RETURN
%token KW_CLASS KW_SELF KW_FROM KW_END KW_VAR KW_NULL KW_DO KW_IN
%token KW_CONSTRUCTOR
%token KW_IF KW_THEN KW_ELSE KW_LOOP

%token OP_LT OP_GT OP_LTE OP_GTE OP_ISE OP_ISNE OP_NOT OP_AND OP_OR OP_XOR OP_LSHIFT OP_RSHIFT
%token OP_ATTRIB OP_DIV OP_PLUS OP_MINUS OP_MUL
%token OP_OPAREN OP_CPAREN OP_COLON OP_STATIC_ACCESS

%token KW_CONSTEXPR KW_DEF

%token <stringValue> IDENTIFIER
%token <stringValue> STRING_CONSTANT
%token <floatValue> FLOAT_CONSTANT
%token <intValue> INTEGER_CONSTANT

// Expressions
%type <expression> 
expression 
  value_expression
    local
      local_expr
    return_expression
    additive_expression
      multiplicative_expression
        pow_expression
          logic_expression
            shift_expression
              unary_expression
                increment_expression
                basic_expression
                  parenthesis_expression 
                  identifier_expression 
                    constant_expression
                    lvalue_identifier_expression
                      vector_var_access
                    rvalue_identifier_expression
                      vector_access
                  negative_expression
                  if_expression
    conditional_expression
    dispatch_expression
	void_expression
	  while_expression
	  for_expression
	    for_iterator_expression

%type <vecstr> id_list
%type <expressions> dispatch_arguments vector_arguments
%type <block> block

%type <features> features attributes attribute_definitions
%type <feature> attribute method
%type <catmintClass> catmint_class
%type <catmintClasses> catmint_classes
%type <stringValue> 		inherits_class

// Precedence increases downward
//%right '[' ']'
%left OP_MOD OP_PLUS OP_MINUS 
%left OP_MUL OP_DIV OP_POW OP_AND OP_OR OP_XOR OP_LSHIFT OP_RHIFT
%right OP_NOT
%left PREC_NEG
%nonassoc <operator> PREC_REL
%left '[' ']'
%left OP_ATTRIB
%left OP_INCR OP_DECR
//%left '[' ']' '{' '}' KW_IF KW_WHILE
//%left OP_NOT

%%

// Program can consist of blocks of code and classes
catmint_program : block catmint_classes block {
    auto base_before = new catmint::Block(@1.first_line);
		base_before->addExpression(Expression($1));

    auto base_after = new catmint::Block(@1.first_line);
		base_after->addExpression(Expression($3));

		//gCatmintProgram = new catmint::Program(@1.first_line, *$2, Expression(b));
		gCatmintProgram = new catmint::Program(@1.first_line, *$2, Expression(base_before), Expression(base_after));
	}
	| block {
    auto base = new catmint::Block(@1.first_line);
		base->addExpression(Expression($1));

    auto class_vector = new std::vector<catmint::Class*>();
		
    gCatmintProgram = new catmint::Program(@1.first_line, *class_vector, Expression(base), nullptr);
	}
	;

catmint_classes : catmint_class {
		$$ = new std::vector<catmint::Class*>();
		$$->push_back($1);
	}
	| catmint_classes catmint_class {
		$$ = $1;
		$$->push_back($2);
	}
	;

// Class definition
catmint_class : KW_CLASS IDENTIFIER features KW_END {
			$$ = new catmint::Class(@1.first_line, *$2, "", *$3);
		}
		// Inherits from other classes
		| KW_CLASS IDENTIFIER inherits_class features KW_END {
		  $$ = new catmint::Class(@1.first_line, *$2, *$3, *$4);

		  delete $2; delete $3; delete $4;
		}
		// Inherits from other classes but is empty
		| KW_CLASS IDENTIFIER inherits_class KW_END {
		  $$ = new catmint::Class(@1.first_line, *$2, *$3, std::vector<catmint::Feature*>());

		  delete $2; delete $3;
		}
		// Empty class
		| KW_CLASS IDENTIFIER KW_END {
			$$ = new catmint::Class(@1.first_line, *$2, "", std::vector<catmint::Feature*>());

			delete $2;
		}
		;

inherits_class
	: %empty {
		// no inheritance (the default parent Object is not inserted in AST)
		$$ = new std::string("");
	}
	| KW_FROM IDENTIFIER {
		// found parent class
		$$ = $2;
	}
	;

// Class features can be variable declarations or method declarations or accessors
features
    : %empty {
		  $$ = new std::vector<catmint::Feature*>();
	  }
	  | features method {
	    $$ = $1;
	    $$->push_back($2);
		  //$$->insert($1->end(), $2->begin(), $2->end());
	  }
		| features attributes {
		  $$ = $1;
			$$->insert($1->end(), $2->begin(), $2->end());
		}
		;

attributes
			: attribute_definitions {
				$$ = $1;
			}
			;

attribute_definitions : attribute {
		$$ = new std::vector<catmint::Feature*>();
		$$->push_back($1);
	}
	| attribute_definitions attribute {
		$$ = $1;
		$$->push_back($2);
	}
	;

attribute : IDENTIFIER IDENTIFIER {
		$$ = new catmint::Attribute(@1.first_line, *$2, *$1);
	}
	| IDENTIFIER IDENTIFIER OP_ATTRIB value_expression {
		// initialized attribute
		$$ = new catmint::Attribute(@1.first_line, *$2, *$1, Expression($4));

		delete $1; delete $2;
	}
	| IDENTIFIER OP_ATTRIB value_expression {
		// initialized attribute but type must be deduced from rhs
		$$ = new catmint::Attribute(@1.first_line, *$1, std::string("auto"), Expression($3));

		delete $1;
	}
	;

method
  // No return type given, must be deducible, like auto
	: KW_DEF IDENTIFIER OP_COLON block KW_END {
    auto& name  	   = *$2;
    //auto& params 	   = *$4;
		auto params 	   = new std::vector<catmint::Attribute*>();
		auto  returnType = std::string("auto");
		auto  body       = $4;

		// Void method
		$$ = new catmint::Method(@1.first_line,
							 name,
							 returnType,
	   					 Expression(body),
							 *params);

		delete $2; //delete $4;
	}
	//| KW_DEF IDENTIFIER IDENTIFIER OP_COLON formals block KW_END {
	
	| KW_DEF IDENTIFIER IDENTIFIER OP_COLON block KW_END {
    auto& name  	   = *$3;
    //auto& params 	   = *$5;
		auto params 	   = new std::vector<catmint::Attribute*>();
		auto& returnType = *$2;
		auto  body       = $5;

		// Void method
		$$ = new catmint::Method(@1.first_line,
							 name,
							 returnType,
	   					 Expression(body),
							 *params);

		delete $2; delete $3; //delete $5;
	}
	;

// ------------------------------------------------------------------------------------------------------------------
//
// Blocks of expressions and expressions
//
// ------------------------------------------------------------------------------------------------------------------

block
  : block expression {
		$$ = $1;
		if ($$ == nullptr) {
			$$ = new catmint::Block(@2.first_line);
		}

		$$->addExpression(Expression($2));
	}
	| %empty {
		$$ = nullptr;
	}
	;

local
  : local_expr
  ;
  
local_expr
  :
  // Int a
  IDENTIFIER IDENTIFIER {
	  std::cout << "local: ID ID\n";
	  fflush(stdout);
    auto ld_name = new std::vector<std::string>();
    ld_name->push_back(*$2);
    auto ld_type = *$1;
    auto base = new catmint::LocalDefinition(@1.first_line, *ld_name, ld_type);
    $$ = base;
	}
	|
	// Int a, b, c
	IDENTIFIER IDENTIFIER id_list {
	  std::cout << "local: ID ID id_list\n";
	  fflush(stdout);
    auto ld_name = new std::vector<std::string>();
    auto ld_type = *$1;
    ld_name->push_back(*$2);
    for(auto n : *$3)
      ld_name->push_back(n);
    auto base = new catmint::LocalDefinition(@1.first_line, *ld_name, ld_type);

    $$ = base;

	}
	// Int a = 3
	| IDENTIFIER IDENTIFIER OP_ATTRIB value_expression {
	  std::cout << "local: ID ID = value_expression\n";
	  fflush(stdout);
		// initialized attribute
    auto ld_name = new std::vector<std::string>();
    auto ld_type = *$1;
    ld_name->push_back(*$2);
    auto init = Expression($4);
    auto base = new catmint::LocalDefinition(@1.first_line, *ld_name, ld_type, std::move(init));
    
    $$ = base;

		delete $1; delete $2;
	}
	// a = 3
	| vector_var_access OP_ATTRIB value_expression {
	  std::cout << "vector var access\n";
	  fflush(stdout);

	  /* construct a LocalDefinition from a slicevector */
		// Get vector_var_access Slicevector object
		auto ld_name = new std::vector<std::string>();
		
		// Ugly hack - should add name to Slicevector
		auto var_access = dynamic_cast<catmint::Slicevector*>($1);
		auto var_access_name = dynamic_cast<catmint::Symbol*>(var_access->getObject())->getName();
    ld_name->push_back(var_access_name);
    
    // Don't forget to record edges...
    auto base_init = Expression($3);
    
    // Construct a new init that contains a dispatch of type set on the object, if need be
    // So basically have a local definition with a set as initializer
		auto args = std::vector<catmint::Expression *>();
		//catmint::TreeNode* copy_val = ($3)->clone();
		//args.push_back(dynamic_cast<catmint::Expression *>(copy_val));
    auto dispatch_init = Expression(new catmint::Dispatch(@1.first_line, std::string("set"), Expression(var_access), args));
    
    // Add both expressions to it
    auto new_block = new catmint::Block(@1.first_line);
    new_block->addExpression(std::move(base_init)); // std::move here
    new_block->addExpression(std::move(dispatch_init));
    
    auto base = new catmint::LocalDefinition(@1.first_line, *ld_name, std::string("auto_vect"), Expression(new_block));
    
    $$ = base;

			
		//$$ = dispatch;
	}
	| IDENTIFIER OP_ATTRIB value_expression {
		// initialized attribute but type must be deduced from rhs
    auto ld_name = new std::vector<std::string>();
		std::cout << "-- LocalDefinition : " << *$1 << std::endl;
    ld_name->push_back(*$1);
    auto init = Expression($3);
    auto base = new catmint::LocalDefinition(@1.first_line, *ld_name, std::string("auto"), std::move(init));
    
    $$ = base;

		delete $1;
	}
	// a[3] = 3
	// a = [0, 1, b] // must also add a[1] = [0,1,b]
	/*| IDENTIFIER OP_ATTRIB '[' dispatch_arguments ']' {
	
	  // Set name
	  auto ld_name = new std::vector<std::string>();
    ld_name->push_back(*$1);

    // Set partial type
    auto ld_type = std::string("_uuid_generic_0001_list");  // Semantic analyzer will add complete type

    // Get initializers
    auto& args = *$4;
      
    //this should be a dispatch with list.insert!
    auto obj = new catmint::Symbol(@1.first_line, *$1);
		//auto  obj  = $1;

		// Dispatch on list with .insert method
	  auto init = Expression(new catmint::Dispatch(@1.first_line, std::string("insert"), Expression(obj), args));
      
    // Create argument list expression
   // auto init = Expression($3);
    
    // Create actual local definition
		if (args.size() != 0)
      $$ = new catmint::LocalDefinition(@1.first_line, *ld_name, ld_type, std::move(init)); 
		else
		  $$ = new catmint::LocalDefinition(@1.first_line, *ld_name, ld_type); 

    //$$ = base;
	}
	// a = {}
	| IDENTIFIER OP_ATTRIB '{' '}' {
	
	  auto ld_name = new std::vector<std::string>();
    ld_name->push_back(*$1);
    
   
    auto ld_type = std::string("_uuid_generic_0002_dictionary"); // Semantic analyzer will add complete type
    auto base = new catmint::LocalDefinition(@1.first_line, *ld_name, ld_type);
    $$ = base;
	
	}*/
	;

id_list 
: ',' IDENTIFIER {
    $$ = new std::vector<std::string>();
    $$->push_back(*$2);
  }
  | ',' IDENTIFIER id_list {
    $$ = $3;
    $$->push_back(*$2);
  }
  ;

expression 
// Ambiguity should have been solves
  : local
  | return_expression//value_expression
  | dispatch_expression
  | void_expression
  | if_expression
  | increment_expression
	;

return_expression
  :
  KW_RETURN value_expression {
    // Create a new AST node type of type returnexpression
    $$ = new catmint::ReturnExpression(@1.first_line, Expression($2));
  }
  ;
  
value_expression
  : conditional_expression
  | additive_expression
  ;

conditional_expression 
  : additive_expression OP_LT additive_expression %prec PREC_REL {
		$$ = new catmint::BinaryOperator(@1.first_line, BinOp::LessThan, Expression($1), Expression($3));
	}
	| additive_expression OP_GT additive_expression %prec PREC_REL {
		$$ = new catmint::BinaryOperator(@1.first_line, BinOp::GreaterThan, Expression($1), Expression($3));
	}
	| additive_expression OP_GTE additive_expression %prec PREC_REL {
		$$ = new catmint::BinaryOperator(@1.first_line, BinOp::GreaterThanEqual, Expression($1), Expression($3));
	}
	| additive_expression OP_LTE additive_expression %prec PREC_REL {
		$$ = new catmint::BinaryOperator(@1.first_line, BinOp::LessThanEqual, Expression($1), Expression($3));
	}
	| additive_expression OP_ISE additive_expression %prec PREC_REL {
		$$ = new catmint::BinaryOperator(@1.first_line, BinOp::Equal, Expression($1), Expression($3));
	}
	| additive_expression OP_ISNE additive_expression %prec PREC_REL {
		$$ = new catmint::BinaryOperator(@1.first_line, BinOp::NotEqual, Expression($1), Expression($3));
	}
	;

additive_expression : multiplicative_expression
  | additive_expression OP_PLUS multiplicative_expression {
		auto type = BinOp::Add;
		auto lhr  = $1;
		auto rhr  = $3;

		// addition
        $$ = new catmint::BinaryOperator(@1.first_line, type,	Expression(lhr), Expression(rhr));
	}
	| additive_expression OP_MINUS multiplicative_expression {
		auto type = BinOp::Sub;
		auto lhr  = $1;
		auto rhr  = $3;

		// subtraction
        $$ = new catmint::BinaryOperator(@1.first_line, type,	Expression(lhr), Expression(rhr));
  }
  | additive_expression OP_MOD multiplicative_expression {
		auto type = BinOp::Mod;
		auto lhr  = $1;
		auto rhr  = $3;

		// modulus
        $$ = new catmint::BinaryOperator(@1.first_line, type,	Expression(lhr), Expression(rhr));
  }
	;

multiplicative_expression 
  : pow_expression
  | multiplicative_expression OP_MUL pow_expression {
    auto type = BinOp::Mul;
    auto lhr  = $1;
    auto rhr  = $3;

    // multiplication
    $$ = new catmint::BinaryOperator(@1.first_line, type,	Expression(lhr), Expression(rhr));
  }
  | multiplicative_expression OP_DIV pow_expression  {
    auto type = BinOp::Div;
    auto lhr  = $1;
    auto rhr  = $3;

    // division
    $$ = new catmint::BinaryOperator(@1.first_line, type,	Expression(lhr), Expression(rhr));
  }
	;
	
pow_expression
  : logic_expression
  | pow_expression OP_POW basic_expression {
    auto type = BinOp::Pow;
    auto lhr  = $1;
    auto rhr  = $3;

    // power of
    $$ = new catmint::BinaryOperator(@1.first_line, type,	Expression(lhr), Expression(rhr));
  }
  ;

logic_expression
  : shift_expression
  | logic_expression OP_XOR basic_expression {
    auto type = BinOp::Xor;
    auto lhr  = $1;
    auto rhr  = $3;

    // power of
    $$ = new catmint::BinaryOperator(@1.first_line, type,	Expression(lhr), Expression(rhr));
  }
  | logic_expression OP_AND basic_expression {
    auto type = BinOp::And;
    auto lhr  = $1;
    auto rhr  = $3;

    // power of
    $$ = new catmint::BinaryOperator(@1.first_line, type,	Expression(lhr), Expression(rhr));
  }
  | logic_expression OP_OR basic_expression {
    auto type = BinOp::Or;
    auto lhr  = $1;
    auto rhr  = $3;

    // power of
    $$ = new catmint::BinaryOperator(@1.first_line, type,	Expression(lhr), Expression(rhr));
  }
  ;

shift_expression
  : unary_expression
  | logic_expression OP_LSHIFT basic_expression {
    auto type = BinOp::LShift;
    auto lhr  = $1;
    auto rhr  = $3;

    // power of
    $$ = new catmint::BinaryOperator(@1.first_line, type,	Expression(lhr), Expression(rhr));
  }
  | logic_expression OP_RSHIFT basic_expression {
    auto type = BinOp::RShift;
    auto lhr  = $1;
    auto rhr  = $3;

    // power of
    $$ = new catmint::BinaryOperator(@1.first_line, type,	Expression(lhr), Expression(rhr));
  }
  ;

unary_expression 
  : basic_expression
  | OP_NOT basic_expression {
		// logic negation						
		$$ = new catmint::UnaryOperator(@1.first_line, UnOp::Not, Expression($2));
	}
	| increment_expression
	;
	
increment_expression
  :// prefix increment
	OP_INCR basic_expression {
	  $$ = new catmint::UnaryOperator(@1.first_line, UnOp::Increment, Expression($2));
	}
	// prefix decrement
	| OP_DECR basic_expression {
	  $$ = new catmint::UnaryOperator(@1.first_line, UnOp::Decrement, Expression($2));
	}
  ;

basic_expression
  : identifier_expression
	| negative_expression
	| parenthesis_expression
	| if_expression
	| dispatch_expression
	;

if_expression
	: 
	KW_IF value_expression OP_COLON block KW_END {
		auto cond 		= $2;		
		auto block_then = ($4 != nullptr) ? $4 : new catmint::Block(@3.first_line); 
        
		// if WITHOUT else		
		$$ = new catmint::IfStatement(@1.first_line,
								   Expression(cond),
								   Expression(block_then));
	}
	| 
	KW_IF value_expression OP_COLON block KW_ELSE block KW_END {
		auto cond	 	= $2;
		auto block_then = ($4 != nullptr) ? $4 : new catmint::Block(@3.first_line); 		
		auto block_else = ($6 != nullptr) ? $6 : new catmint::Block(@3.first_line); 		
        
		// if WITH else		
		$$ = new catmint::IfStatement(@1.first_line,
								   Expression(cond),
								   Expression(block_then),
								   Expression(block_else));
    }
  ;

dispatch_expression
	: IDENTIFIER OP_OPAREN dispatch_arguments OP_CPAREN {
		auto  obj  = nullptr;		// Will be main or any parent like obj
		auto& name = *$1;
		auto& args = *$3;

		// simple dispatch
		$$ = new catmint::Dispatch(@1.first_line, name, obj, args);
		
		delete $1; delete $3;						
	}
	| basic_expression '.' IDENTIFIER OP_OPAREN dispatch_arguments OP_CPAREN {
		auto  obj  = $1;
		auto& name = *$3;
		auto& args = *$5;

		// dispatch using object		
		$$ = new catmint::Dispatch(@1.first_line, name, Expression(obj), args);

		delete $3; delete $5;						
	}
	| basic_expression OP_STATIC_ACCESS IDENTIFIER '.' IDENTIFIER OP_OPAREN dispatch_arguments OP_CPAREN {
		auto  obj  = $1;
		auto& type = *$3;
		auto& name = *$5;
		auto& args = *$7;

		// static dispatch
		$$ = new catmint::StaticDispatch(@1.first_line, Expression(obj), type, name, args);

		delete $3; delete $5; delete $7;										
	}
	;
	
dispatch_arguments
  : %empty {
      $$ = new std::vector<catmint::Expression*>();
  }
  | value_expression {
      $$ = new std::vector<catmint::Expression*>();
      $$->push_back($1);
  }
  | dispatch_arguments ',' value_expression {
      $$ = $1;		
    $$->push_back($3);
  }
  ;

identifier_expression
  : constant_expression
  | KW_SELF {
		$$ = new catmint::Symbol(@1.first_line, "self");
	}
	| rvalue_identifier_expression
	;

rvalue_identifier_expression
	// Break this into new lvalue identifier_expression and Add dispatch symbol from class
	: IDENTIFIER {
		$$ = new catmint::Symbol(@1.first_line, *$1);
	}
	| vector_access {
	  std::cout<<"vector access from rvalue_identifier_expression\n";
	  fflush(stdout);
  	$$ = $1;
	}
	;

// Used in for - change this significantly
//lvalue_identifier_expression
	// Break this into new lvalue identifier_expression and Add dispatch symbol from class
/*	: IDENTIFIER {
		$$ = new catmint::Symbol(@1.first_line, *$1);
	}
	| vector_var_access {
  	$$ = $1;
	}*/
	//;

constant_expression
  : KW_NULL {
		$$ = new catmint::NullConstant(@1.first_line);
	}
	| INTEGER_CONSTANT {
		$$ = new catmint::IntConstant(@1.first_line, $1);
	}
	| STRING_CONSTANT {
    $$ = new catmint::StringConstant(@1.first_line, *$1);
	}
	| FLOAT_CONSTANT {
    $$ = new catmint::FloatConstant(@1.first_line, $1);
	}
	;

parenthesis_expression : OP_OPAREN value_expression OP_CPAREN {
		$$ = $2;
	}
	;

negative_expression
	: OP_MINUS basic_expression %prec PREC_NEG {
		auto type  = UnOp::Minus;
		auto value = $2;

		$$ = new catmint::UnaryOperator(@1.first_line, type, Expression(value));
	}
	;

void_expression
  : while_expression
  | for_expression
  ;
  
while_expression
    : KW_WHILE value_expression OP_COLON block KW_END {
		auto cond 		 = $2;
		auto block_while = ($4 != nullptr) ? $4 : new catmint::Block(@4.first_line);
		
		$$ = new catmint::WhileStatement(@1.first_line,
									  Expression(cond),
									  Expression(block_while));
    }
    ;

// Allow a = 1, a[1] = 1, a(1), etc
for_iterator_expression
    : rvalue_identifier_expression
    | dispatch_expression
    //| local
    ;
    
for_expression
    // Define the variable
    // for int iter in container:
    // for auto iter in container: should also be allowed, as deduction!
    // for iter = 0 in container:
    : KW_FOR for_iterator_expression KW_IN value_expression OP_COLON block KW_END {
		  auto iter   	 = $2;
		  auto cont      = $4;
		  auto block_for = ($6 != nullptr) ? $6 : new catmint::Block(@6.first_line);
		  
		  $$ = new catmint::ForStatement(@1.first_line,
									    Expression(iter),
									    Expression(cont),
									    Expression(block_for));
    }
    ;

vector_access  // More precisely rvalue ... and let arguments be longer --<< this should be for "for" and others, needs an object, disallow dispatch here
	: rvalue_identifier_expression '[' vector_arguments ']' {
	  std::cout << "rvalue vector_access\n";
    fflush(stdout);
		auto obj   = $1;
		auto name  = std::string("get");
		//auto args  = std::vector<catmint::Expression*>{$3};
		auto args  = *$3;
		
		// Crude checks here
    if (args.size() == 0) {
      // we have a vector [:] which means all
		  auto  start  = new catmint::StringConstant(@1.first_line,  "0"); // Make more checks here!
		  auto  stop   = new catmint::StringConstant(@1.first_line, "-1");
		  auto  step   = new catmint::StringConstant(@1.first_line,  "1");

		  // special syntax for String: access a substring
		  auto slice = new catmint::Slicevector(@1.first_line,
								   Expression(obj),
								   Expression(start),
								   Expression(step),								   
								   Expression(stop));	

      $$ = new catmint::Dispatch(@1.first_line,
								name,
								Expression(obj),
								args);		
    } 
    else if (args.size() == 1) {
      // a[1] - get element 1 in vector
      // we have a vector [:] which means all
		  auto  start  = args[0]; // Make more checks here!
		  auto  stop   = args[0];
		  auto  step   = new catmint::StringConstant(@1.first_line,  "1");

		  // special syntax for String: access a substring
		  auto slice = new catmint::Slicevector(@1.first_line,
								   Expression(obj),
								   Expression(start),
								   Expression(step),								   
								   Expression(stop));	

      $$ = new catmint::Dispatch(@1.first_line,
								name,
								Expression(obj),
								args);		
    }
    else if (args.size() == 2) {
      // a[begin:stop:step]
		  auto  start  = args[0]; // Make more checks here!
		  auto  stop   = args[1];
		  auto  step   = new catmint::StringConstant(@1.first_line,  "1");

		  // special syntax for String: access a substring
		  auto slice = new catmint::Slicevector(@1.first_line,
								   Expression(obj),
								   Expression(start),
								   Expression(step),								   
								   Expression(stop));	
	  
      $$ = new catmint::Dispatch(@1.first_line,
								name,
								Expression(obj),
								args);		
    }
    else if (args.size() == 3) {
      // a[begin:stop:step]
		  auto  start  = args[0]; // Make more checks here!
		  auto  stop   = args[1];
		  auto  step   = args[2];

		  // special syntax for String: access a substring
		  auto slice = new catmint::Slicevector(@1.first_line,
								   Expression(obj),
								   Expression(start),
								   Expression(step),								   
								   Expression(stop));	

      $$ = new catmint::Dispatch(@1.first_line,
								name,
								Expression(obj),
								args);		
		}
		
		
		// get access for an elementh from a Vector
		//$$ = new catmint::Dispatch(@1.first_line,
		//						name,
	//							Expression(obj),
//								args);
	}
	;

vector_arguments
  : %empty {
      $$ = new std::vector<catmint::Expression*>();
  }
  | OP_COLON {
      $$ = new std::vector<catmint::Expression*>();
  }
  | value_expression {
    std::cout<<"vector_arguments" << std::endl;
    fflush(stdout);
  
      $$ = new std::vector<catmint::Expression*>();
      $$->push_back($1);
  }
  | vector_arguments OP_COLON value_expression  {
    $$ = $1;		
    $$->push_back($3);
  }
  ;
  
vector_var_access 
  //: lvalue_identifier_expression '[' vector_arguments ']' {
  : IDENTIFIER '[' vector_arguments ']' {  
    std::cout<<"good, l_value vector_var_access" << std::endl;
    fflush(stdout);
     // Should at some point allow class member acces! maybe in identifier expr allow a "dispatch"
		auto  obj    =  new catmint::Symbol(@1.first_line, *$1); // $1
		auto& args   = *$3;

    // Crude checks here
    if (args.size() == 0) {
      // we have a vector [:] which means all
		  auto  start  = new catmint::StringConstant(@1.first_line,  "0"); // Make more checks here!
		  auto  stop   = new catmint::StringConstant(@1.first_line, "-1");
		  auto  step   = new catmint::StringConstant(@1.first_line,  "1");

		  // special syntax for String: access a substring
		  $$ = new catmint::Slicevector(@1.first_line,
								   Expression(obj),
								   Expression(start),
								   Expression(step),								   
								   Expression(stop));	
    } 
    else if (args.size() == 1) {
      // a[1] - get element 1 in vector
      // we have a vector [:] which means all
		  auto  start  = args[0]; // Make more checks here!
		  auto  stop   = args[0];
		  auto  step   = new catmint::StringConstant(@1.first_line,  "1");

		  // special syntax for String: access a substring
		  $$ = new catmint::Slicevector(@1.first_line,
								   Expression(obj),
								   Expression(start),
								   Expression(step),								   
								   Expression(stop));	
    }
    else if (args.size() == 2) {
      // a[begin:stop:step]
		  auto  start  = args[0]; // Make more checks here!
		  auto  stop   = args[1];
		  auto  step   = new catmint::StringConstant(@1.first_line,  "1");

		  // special syntax for String: access a substring
		  $$ = new catmint::Slicevector(@1.first_line,
								   Expression(obj),
								   Expression(start),
								   Expression(step),								   
								   Expression(stop));	
	  
    }
    else if (args.size() == 3) {
      // a[begin:stop:step]
		  auto  start  = args[0]; // Make more checks here!
		  auto  stop   = args[1];
		  auto  step   = args[2];

		  // special syntax for String: access a substring
		  $$ = new catmint::Slicevector(@1.first_line,
								   Expression(obj),
								   Expression(start),
								   Expression(step),								   
								   Expression(stop));	
	  
    }
    else {
      std::cout << "[ ERROR ] : Line " << @1.first_line << " : Too many rguments in container access." << std::endl;
  	  fflush(stdout);
      exit(1);
    }
		delete $3;
  }
  ;
	
%%

// ----------------------------------------------------------------------------
//
// Main processing
//
// ----------------------------------------------------------------------------

void printUsage() {
	std::cout << "Usage: ./catmint-parser <inputFile> <outputFile>" << std::endl;
}

int main(int argc, char** argv) {

	if(argc != 3) {
		printUsage();
		return 0;
	}

	gInputFileName = strdup(argv[1]);
	
	// Preprocess file for module inclusion
	std::ifstream in;
	std::string target = "target.~tmp";
	std::ofstream out(target, std::ofstream::out | std::ofstream::trunc);
	
	// Open and read initial file
	std::stringstream buffer;	
	std::ifstream initial;
	initial.open(gInputFileName);
	buffer << initial.rdbuf();
	initial.close();
	
	// Vector of modules
	std::vector<std::string> matches;
	
	// Try to match module constructions
  std::string result = "";
	try 
	{
	  std::regex re("using (.*)\n");
	  std::string text = buffer.str();
	  std::smatch match;
	  std::sregex_iterator next(text.begin(), text.end(), re);
	  std::sregex_iterator end;
	  
	  while (next != end) {
	    std::smatch match = *next;
	    std::string match_string = match.str();
	    match_string = match_string.substr(0, strlen(match.str().c_str()) - 1);
	    std::cout << "Found module inclusion: " << match_string << "\n";
	    matches.insert(matches.end(), match_string);
	    next++;
	  }
	  
    // Now eliminate module inclusions
    result = regex_replace(buffer.str(), re, "");
	}
	catch (std::regex_error& e) {
	  std::cout << "Syntax error in regular expression." << std::endl;
	}

  // Now open each module and add it to the buffer
	std::stringstream Sbuffer;	

  for(auto inclusion : matches) {
    auto module_name = inclusion.substr(strlen("using "), strlen(inclusion.c_str()));
	  std::string full_path_to_module = module_name + ".cmm";
	  std::string full_path_to_module2 = "./test/" + module_name + ".cmm";
    std::cout << "[ LOG ] Opening and adding module << " << full_path_to_module << " >>" << std::endl;
	  in.open(full_path_to_module.c_str());
	  
	  // Test alternate paths
	  if (in.fail()) {
  	  in.open(full_path_to_module2.c_str());
	    if (in.fail()) {
	      std::cout << "[ ERROR ] Could not find module!" <<std::endl;
	      fflush(stdout);
	      exit(1);
	    }
	  }
	  
	  Sbuffer << "# Included from module << " << full_path_to_module << " >> \n"; // Add a newline
	  Sbuffer << in.rdbuf();
	  Sbuffer << "\n"; // Add a newline
	  in.close();
  }
  
  // Now add the original file
	Sbuffer << result;
	out << Sbuffer.str();
	out.close();
	
	/* Open actual merged file */
	yyin = fopen("target.~tmp", "r");

	if(yyparse()) {
		return 1;
	}

	catmint::ASTSerializer serializer(argv[2]);
	serializer.visit(gCatmintProgram);

	return 0;
}
