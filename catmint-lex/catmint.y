
%code requires {
	#include <iostream>
	#include <string>
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
}

%start catmint_program

%token KW_CLASS KW_SELF KW_FROM KW_END KW_VAR KW_NULL
%token KW_CONSTRUCTOR
%token KW_IF KW_THEN KW_ELSE KW_LOOP

%token OP_LT OP_GT OP_LTE OP_GTE OP_ISE
%token OP_ATTRIB OP_DIV OP_PLUS OP_MINUS OP_MUL
%token OP_OPAREN OP_CPAREN OP_COLON

%token KW_CONSTEXPR KW_DEF

%token <stringValue> IDENTIFIER
%token <stringValue> STRING_CONSTANT
%token <floatValue> FLOAT_CONSTANT
%token <intValue> INTEGER_CONSTANT

// Expressions
%type <expression> expression conditional_expression value_expression
%type <expression> relational_expression additive_expression multiplicative_expression
%type <expression> unary_expression basic_expression local //formal
%type <expression> identifier_expression parenthesis_expression negative_expression constant_expression assignment_expression
%type <expressions> locals
%type <block> block

%type <features> features attributes attribute_definitions
%type <feature> attribute method
%type <catmintClass> catmint_class
%type <catmintClasses> catmint_classes
%type <stringValue> 		inherits_class

//%type <formal> 	formal
//%type <formals> formals

%left '+' '-'
%left '*' '/'
%left PREC_NEG

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
	| IDENTIFIER IDENTIFIER OP_ATTRIB expression {
		// initialized attribute
		$$ = new catmint::Attribute(@1.first_line, *$2, *$1, Expression($4));

		delete $1; delete $2;
	}
	| IDENTIFIER OP_ATTRIB expression {
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
	/*
	| KW_DEF IDENTIFIER IDENTIFIER OP_COLON attributes block KW_END {
    auto& name  	   = *$3;
    //auto& params 	   = *$5;
		auto params 	   = new std::vector<catmint::FormalParam*>();
		auto& returnType = *$2;
		auto  body       = $5;

		// Void method
		$$ = new catmint::Method(@1.first_line,
							 name,
							 returnType,
	   					 Expression(body),
							 *params);

		delete $2; delete $3; //delete $5;
	} */
	;

// ------------------------------------------------------------------------------------------------------------------
//
// Blocks of expressions and expressions
//
// ------------------------------------------------------------------------------------------------------------------

block
  : block locals {
	  $$ = $1;
		if ($$ == nullptr) {
			$$ = new catmint::Block(@2.first_line);
		}

		$$->addExpressions(*$2);

		delete $2;
	}
	| block expression {
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

locals
  : local {
		$$ = new std::vector<catmint::Expression*>();
		$$->push_back($1);
  }
	| locals local {
		$$ = $1;
		$$->push_back($2);
	}

  ;

local
  : IDENTIFIER IDENTIFIER {
			$$ = new catmint::LocalDefinition(@1.first_line, *$2, *$1);
	}
	| IDENTIFIER IDENTIFIER OP_ATTRIB expression {
		// initialized attribute
		$$ = new catmint::LocalDefinition(@1.first_line, *$2, *$1, Expression($4));

		delete $1; delete $2;
	}
	| IDENTIFIER OP_ATTRIB expression {
		// initialized attribute but type must be deduced from rhs
		$$ = new catmint::LocalDefinition(@1.first_line, *$1, std::string("auto"), Expression($3));

		delete $1;
	}
  ;

expression : value_expression
	;

value_expression
  : additive_expression
  | assignment_expression
  | conditional_expression
  ;

conditional_expression : relational_expression
	;

relational_expression : additive_expression
	| relational_expression OP_LT additive_expression {
		$$ = new catmint::BinaryOperator(@1.first_line, BinOp::LessThan, Expression($1), Expression($3));
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
	;

multiplicative_expression : unary_expression
	;

unary_expression : basic_expression
	 | multiplicative_expression OP_MUL basic_expression {
		  auto type = BinOp::Mul;
		  auto lhr  = $1;
		  auto rhr  = $3;

		  // multiplication
      $$ = new catmint::BinaryOperator(@1.first_line, type,	Expression(lhr), Expression(rhr));
   }
	 | multiplicative_expression OP_DIV basic_expression  {
		  auto type = BinOp::Div;
		  auto lhr  = $1;
		  auto rhr  = $3;

		  // division
      $$ = new catmint::BinaryOperator(@1.first_line, type,	Expression(lhr), Expression(rhr));
    }
	;

basic_expression
  : identifier_expression
	| negative_expression
	| parenthesis_expression
	;

identifier_expression
  : constant_expression
  | KW_SELF {
		$$ = new catmint::Symbol(@1.first_line, "self");
	}
	| IDENTIFIER {
		$$ = new catmint::Symbol(@1.first_line, *$1);
	}
	;

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

assignment_expression
  : IDENTIFIER OP_ATTRIB value_expression {
	  auto& name  = *$1;
   	auto  value = $3;

	  // simple assignment
    $$ = new catmint::Assignment(@1.first_line, name, Expression(value));

	  delete $1;
  }

%%

void printUsage() {
	std::cout << "Usage: ./catmint-parser <inputFile> <outputFile>" << std::endl;
}

int main(int argc, char** argv) {

	if(argc != 3) {
		printUsage();
		return 0;
	}

	gInputFileName = strdup(argv[1]);
	yyin = fopen(argv[1], "r");

	if(yyparse()) {
		return 1;
	}

	catmint::ASTSerializer serializer(argv[2]);
	serializer.visit(gCatmintProgram);

	return 0;
}
