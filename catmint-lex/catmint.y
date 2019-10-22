
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
		std::cout << gInputFileName << " : " << yylloc.first_line << " : " << yylloc.first_column << " " << error << std::endl;
	}
}

%locations

%union {
	std::string* stringValue;
	int intValue;
	float floatValue;

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

%token KW_CLASS KW_INHERITS KW_FROM KW_END KW_VAR
%token KW_CONSTRUCTOR
%token KW_IF KW_THEN KW_ELSE KW_LOOP

%token OP_LT OP_GT OP_LTE OP_GTE OP_ISE OP_ATTRIB

%token <stringValue> IDENTIFIER
%token <intValue> INTEGER_CONSTANT
%token <floatValue> FLOAT_CONSTANT

%type <expression> expression conditional_expression
%type <expression> relational_expression additive_expression multiplicative_expression
%type <expression> unary_expression basic_expression
//%type <expressions> arguments
/*%type <formal> formal
%type <formals> formals */
%type <block> block
/*
%type <feature> method attribute
%type <features> features attributes attribute_definitions*/
%type <features> features attributes attribute_definitions
%type <feature> attribute
%type <catmintClass> catmint_class
%type <catmintClasses> catmint_classes
%type <stringValue> 		inherits_class

%%
catmint_program : block catmint_classes block {
    auto b = new catmint::Block(@1.first_line);
		b->addExpression(Expression($1));
		b->addExpression(Expression($3));
		gCatmintProgram = new catmint::Program(@1.first_line, *$2, Expression(b));
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
			std::vector<catmint::Feature*> a;
			$$ = new catmint::Class(@1.first_line, *$2, "", a);
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
features : attributes 
		| features attributes {
			$1->insert($1->end(), $2->begin(), $2->end());
			$$ = $1;
		}
		;

attributes : KW_VAR attribute_definitions KW_END {
				$$ = $2;
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
		//auto& type  = $1->first;
		//auto& name  = $1->second;
		//auto  value = $3;

		// initialized attribute		
		$$ = new catmint::Attribute(@1.first_line, *$2, *$1, Expression($4));

		delete $1; delete $2;	
	}
	;
/*
features : method {
			$$ = new std::vector<catmint::Feature*>();
			$$->push_back($1);
		}
		| features method {
			$1->push_back($2);
			$$ = $1;
		 }
		| attributes 
		| features attributes {
			$1->insert($1->end(), $2->begin(), $2->end());
			$$ = $1;
		}
		;

attributes : KW_VAR attribute_definitions KW_END ';' {
				$$ = $2;
			}
			;

attribute_definitions : attribute ';' {
		$$ = new std::vector<catmint::Feature*>();
		$$->push_back($1);
	}
	| attribute_definitions attribute ';' {
		$$ = $1;
		$$->push_back($2);
	}
	;

attribute : IDENTIFIER IDENTIFIER {
		$$ = new catmint::Attribute(@1.first_line, *$2, *$1);
	}
	;

method : IDENTIFIER formals '-' '>' IDENTIFIER ':' block KW_END ';' {
		$$ = new catmint::Method(@1.first_line, *$1, *$5, catmint::ExpressionPtr($7), *$2);
	}	
	;

formals : %empty {
		$$ = new std::vector<catmint::FormalParam*>();
	} 
	| formal {
		$$ = new std::vector<catmint::FormalParam*>();
		$$->push_back($1);
	}
	| formals ',' formal {
		$1->push_back($3);
		$$ = $1;
	}
	;

formal : IDENTIFIER IDENTIFIER {
		$$ = new catmint::FormalParam(@1.first_line, *$2, *$1);
	}
	;*/

block : expression {
		$$ = new catmint::Block(@1.first_line);
		$$->addExpression(Expression($1));
	}
	| block expression {
		$$ = $1;
		$$->addExpression(Expression($2));
	}
	| %empty {
		$$ = nullptr;		
	}
	;
	
expression : conditional_expression 
	;

conditional_expression : relational_expression
	;

relational_expression : additive_expression
	| relational_expression OP_LT additive_expression {
		$$ = new catmint::BinaryOperator(@1.first_line, BinOp::LessThan, Expression($1), Expression($3));
	}
	;

additive_expression : multiplicative_expression 
	;

multiplicative_expression : unary_expression 
	;

unary_expression : basic_expression 
	;

basic_expression : INTEGER_CONSTANT {
		$$ = new catmint::IntConstant(@1.first_line, $1);
	}
	| IDENTIFIER {
		$$ = new catmint::Symbol(@1.first_line, *$1);
	}
	//| dispatch_expression
	;
	
/*dispatch_expression : '[' IDENTIFIER ']' {
		$$ = new catmint::Dispatch(@1.first_line,*$2);
	}
	; */

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

