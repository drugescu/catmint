
%code requires {
	#include <iostream>
	#include <fstream>
	#include <string>
	#include <sstream>
	#include <regex>
	#include <set>
	#include <vector>
	#include <climits>
	#include <cstdlib>
	#include <cstring>
	#include <ASTNodes.h>
	#include <StringConstants.h>
}

%code {
	#include <ASTSerialization.h>

	typedef std::unique_ptr<catmint::Expression> Expression;
	typedef catmint::BinaryOperator::BinOpKind   BinOp;
	typedef catmint::UnaryOperator::UnaryOpKind  UnOp;

	extern FILE* yyin;

	static catmint::Program* gCatmintProgram = nullptr;
	char* gInputFileName = NULL;

	// The file the current token came from. The preprocessor emits #line
	// directives when it splices a module in, and the lexer updates this, so a
	// diagnostic names the file the programmer actually wrote rather than the
	// concatenated text the parser sees.
	std::string gCurrentFile;

	// Separate compilation: leave `using` directives unexpanded, because each
	// module is compiled to its own object and linked afterwards.
	bool gExpandModules = true;
	// A .cmm is a library: it must not get a synthesised Main class, or every
	// module in a program would define one.
	bool gCreateMain = true;

	// The namespace the text being parsed belongs to, set by the #namespace
	// directives the preprocessor emits around an aliased module. Empty means
	// the global namespace.
	std::string gCurrentNamespace;

	// Namespaces opened with `using namespace <alias>`, and every class name
	// declared so far. Together they let an unqualified name find a class in
	// an opened namespace: `using namespace m` then `Vector` rather than
	// `m::Vector`. A module is spliced in at its `using` line, so its classes
	// are always declared before the code that opens the namespace.
	std::set<std::string> gOpenNamespaces;
	std::set<std::string> gDeclaredClasses;

	// Inside a namespace, an unqualified class name means one of that module's
	// own classes. The built-in and primitive names are the exception: they are
	// global, and there is a fixed list of them.
	//
	// This list has to be written out, unlike the two the compiler used to
	// keep: the built-in classes are added by the type table long after the
	// parser has finished, so there is nothing here to ask.
	static bool isGlobalTypeName(const std::string &name) {
		return name == "Int" || name == "Int8" || name == "Int16" ||
		       name == "Int32" || name == "Int64" ||
		       name == "Float" || name == "Void" ||
		       name == "Null" || name == "Object" || name == "String" ||
		       name == "IO" || name == "List" || name == "Integer" ||
		       name == "File" || name == "Math" || name == "Process" ||
		       name == "Worker" || name == "Bytes" ||
		       name == "Ints" || name == "Floats" ||
		       name == "auto" || name.rfind("_uuid_generic_", 0) == 0;
	}

	static std::string qualifyTypeName(const std::string &name) {
		// Int32 is a second spelling of Int, folded away here so that only one
		// of the two names ever reaches the type table or the generator.
		if (name == "Int32") {
			return "Int";
		}
		if (isGlobalTypeName(name) || name.find("::") != std::string::npos) {
			return name;
		}
		if (!gCurrentNamespace.empty()) {
			return gCurrentNamespace + "::" + name;
		}

		// In the global namespace an unqualified name may belong to a
		// namespace that has been opened. A class declared globally wins, so
		// opening a namespace can never change what an existing name means.
		if (gDeclaredClasses.count(name)) {
			return name;
		}
		std::string found;
		int matches = 0;
		for (const auto &space : gOpenNamespaces) {
			const std::string candidate = space + "::" + name;
			if (gDeclaredClasses.count(candidate)) {
				found = candidate;
				++matches;
			}
		}
		if (matches == 1) {
			return found;
		}
		if (matches > 1) {
			std::cerr << "[ ERROR ] '" << name
			          << "' is declared in more than one opened namespace; "
			             "qualify it" << std::endl;
		}
		return name;
	}

	// Remembered so that `using namespace` can resolve an unqualified name.
	static catmint::Class *rememberClass(catmint::Class *c) {
		gDeclaredClasses.insert(c->getName());
		c->setFile(gCurrentFile);
		return c;
	}

	int  yylex ();
	void yyerror(const char *error)
	{
		const std::string &where = gCurrentFile.empty()
			? std::string(gInputFileName ? gInputFileName : "<input>")
			: gCurrentFile;
		std::cerr << where << " | Line : " << yylloc.first_line << " | Column : " << yylloc.first_column << " | Error: " << error << std::endl;
	}
}

// Verbosity on syntax errors
%define parse.error verbose

%locations

%union {
	std::string* stringValue;
	long long intValue;
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
%token KW_INTERFACE KW_DOES
%token KW_USING KW_IS
%token KW_CONSTRUCTOR KW_NEW
%token KW_IF KW_THEN KW_ELSE KW_ELIF KW_LOOP
%token KW_TRY KW_CATCH KW_THROW KW_DEFER KW_SPAWN

%token OP_LT OP_GT OP_LTE OP_GTE OP_ISE OP_ISNE OP_NOT OP_AND OP_OR OP_XOR OP_LSHIFT OP_RSHIFT
%token OP_ANDALSO OP_ORELSE
%token OP_ATTRIB OP_DIV OP_PLUS OP_MINUS OP_MUL
%token OP_OPAREN OP_CPAREN OP_COLON OP_STATIC_ACCESS

%token KW_CONSTEXPR KW_DEF KW_STATIC

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
                basic_expression
                  parenthesis_expression
				  new_list
                  identifier_expression 
                    constant_expression
                    rvalue_identifier_expression
                      vector_access
                  negative_expression
                  field_access
                  new_expression
                  spawn_expression
                  if_expression
                  elif_chain
    conditional_expression
    dispatch_expression
	void_expression
	  while_expression
	  for_expression
	    for_iterator_expression
	  try_expression
	  throw_expression
	  defer_expression

%type <vecstr> id_list
%type <expressions> dispatch_arguments vector_arguments
%type <block> block

%type <features> features attributes attribute_definitions interface_features
%type <features> method_arguments
%type <feature> attribute method interface_method
%type <catmintClass> catmint_class
%type <catmintClasses> catmint_classes
%type <stringValue> 		inherits_class type_name
%type <vecstr> implements_class type_name_list

// Precedence increases downward
//%right '[' ']'
// 'and' and 'or' bind looser than everything else, so
// 'a > 1 and a < 10' needs no parentheses.
%left OP_ORELSE
%left OP_ANDALSO
// A comparison binds looser than arithmetic, so 'a > b - c' means
// 'a > (b - c)'. It used to sit below the arithmetic operators, where the
// parser reduced 'a > b' as soon as it could and then had nowhere to put the
// '-': the expression was a syntax error rather than a wrong answer, which
// is why moving it here cannot change what any existing program computes.
%nonassoc <operator> PREC_REL
%left OP_MOD OP_PLUS OP_MINUS 
%left OP_MUL OP_DIV OP_POW OP_AND OP_OR OP_XOR OP_LSHIFT OP_RHIFT
%right OP_NOT
%left PREC_NEG
%left '[' ']'
%left OP_ATTRIB
//%left '[' ']' '{' '}' KW_IF KW_WHILE
//%left OP_NOT

%%

// Program can consist of blocks of code and classes
catmint_program : block catmint_classes block {
    auto base_before = new catmint::Block(@1.first_line);
		base_before->addExpression(Expression($1));

    auto base_after = new catmint::Block(@1.first_line);
		base_after->addExpression(Expression($3));

		gCatmintProgram = new catmint::Program(@1.first_line, *$2, Expression(base_before), Expression(base_after), gCreateMain);
	}
	| block {
    auto base = new catmint::Block(@1.first_line);
		base->addExpression(Expression($1));

    auto class_vector = new std::vector<catmint::Class*>();
		
    gCatmintProgram = new catmint::Program(@1.first_line, *class_vector, Expression(base), nullptr, gCreateMain);
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

// Class definition. `from` names the parent and `does` names the interfaces
// it promises to implement; both are optional, and so is the body.
catmint_class
	: KW_CLASS IDENTIFIER inherits_class implements_class features KW_END {
			$$ = rememberClass(new catmint::Class(@1.first_line, qualifyTypeName(*$2), *$3, *$5));
			$$->setInterfaces(*$4);

			delete $2; delete $3; delete $4; delete $5;
		}
	// An interface is a list of method signatures: no bodies, no attributes,
	// no instances, and no parent of its own.
	| KW_INTERFACE IDENTIFIER interface_features KW_END {
			$$ = rememberClass(new catmint::Class(@1.first_line, qualifyTypeName(*$2), "", *$3));
			$$->setInterface(true);

			delete $2; delete $3;
		}
	;

implements_class
	: %empty {
		$$ = new std::vector<std::string>();
	}
	| KW_DOES type_name_list {
		$$ = $2;
	}
	;

type_name_list
	: type_name {
		$$ = new std::vector<std::string>();
		$$->push_back(*$1);
		delete $1;
	}
	| type_name_list ',' type_name {
		$$ = $1;
		$$->push_back(*$3);
		delete $3;
	}
	;

interface_features
	: %empty {
		$$ = new std::vector<catmint::Feature*>();
	}
	| interface_features interface_method {
		$$ = $1;
		$$->push_back($2);
	}
	;

// A signature with no body. The return type is required here, unlike in a
// `def` with a body: without it `def f` and `def Int f` could not be told
// apart until the token after, and an interface is the one place where
// saying what comes back is the whole point anyway.
interface_method
	: KW_DEF type_name IDENTIFIER {
		auto params = new std::vector<catmint::Attribute*>();
		$$ = new catmint::Method(@1.first_line, *$3, *$2, nullptr, *params);
		delete $2; delete $3; delete params;
	}
	| KW_DEF type_name IDENTIFIER OP_OPAREN OP_CPAREN {
		auto params = new std::vector<catmint::Attribute*>();
		$$ = new catmint::Method(@1.first_line, *$3, *$2, nullptr, *params);
		delete $2; delete $3; delete params;
	}
	| KW_DEF type_name IDENTIFIER OP_OPAREN method_arguments OP_CPAREN {
		$$ = new catmint::Method(@1.first_line, *$3, *$2, nullptr,
		                         *reinterpret_cast<std::vector<catmint::Attribute*>*>($5));
		delete $2; delete $3;
	}
	;

inherits_class
	: %empty {
		// no inheritance (the default parent Object is not inserted in AST)
		$$ = new std::string("");
	}
	| KW_FROM type_name {
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

method_arguments : type_name IDENTIFIER {
		$$ = new std::vector<catmint::Feature*>();
		auto attrib = new catmint::Attribute(@1.first_line, *$2, *$1);
		$$->push_back(attrib);
	}
	// Recurses on itself, not on attribute_definitions. Chaining the wrong
	// nonterminal here meant a method could take at most two parameters: the
	// third comma had nothing to reduce to.
	| method_arguments ',' type_name IDENTIFIER {
		$$ = $1;
		auto attrib = new catmint::Attribute(@1.first_line, *$4, *$3);
		$$->push_back(attrib);
	}
	;

attribute : type_name IDENTIFIER {
		$$ = new catmint::Attribute(@1.first_line, *$2, *$1);
	}
	| type_name IDENTIFIER OP_ATTRIB value_expression {
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

// A method declaration. The return type is optional, and so is the parameter
// list, which gives six forms. They used to be written out ad hoc, and three
// of the six were missing: a method without a declared return type could not
// take parameters at all, and empty parentheses were rejected.
//
// A declared return type is a type_name, so it may be namespace-qualified.
method
  // def f:
  : KW_DEF IDENTIFIER OP_COLON block KW_END {
		auto params = new std::vector<catmint::Attribute*>();
		$$ = new catmint::Method(@1.first_line, *$2, std::string("auto"),
		                         Expression($4), *params);
		delete $2; delete params;
	}
  // def f():
  | KW_DEF IDENTIFIER OP_OPAREN OP_CPAREN OP_COLON block KW_END {
		auto params = new std::vector<catmint::Attribute*>();
		$$ = new catmint::Method(@1.first_line, *$2, std::string("auto"),
		                         Expression($6), *params);
		delete $2; delete params;
	}
  // def f(Int a, Int b, Int c):
  | KW_DEF IDENTIFIER OP_OPAREN method_arguments OP_CPAREN OP_COLON block KW_END {
		$$ = new catmint::Method(@1.first_line, *$2, std::string("auto"),
		                         Expression($7),
		                         *reinterpret_cast<std::vector<catmint::Attribute*>*>($4));
		delete $2;
	}
  // def Int f:
  | KW_DEF type_name IDENTIFIER OP_COLON block KW_END {
		auto params = new std::vector<catmint::Attribute*>();
		$$ = new catmint::Method(@1.first_line, *$3, *$2, Expression($5), *params);
		delete $2; delete $3; delete params;
	}
  // def Int f():
  | KW_DEF type_name IDENTIFIER OP_OPAREN OP_CPAREN OP_COLON block KW_END {
		auto params = new std::vector<catmint::Attribute*>();
		$$ = new catmint::Method(@1.first_line, *$3, *$2, Expression($7), *params);
		delete $2; delete $3; delete params;
	}
  // def Int f(Int a, Int b, Int c):
  | KW_DEF type_name IDENTIFIER OP_OPAREN method_arguments OP_CPAREN OP_COLON block KW_END {
		$$ = new catmint::Method(@1.first_line, *$3, *$2, Expression($8),
		                         *reinterpret_cast<std::vector<catmint::Attribute*>*>($5));
		delete $2; delete $3;
	}
  // A constructor is sugar for a method named 'init' returning nothing. The
  // three forms mirror the parameterless, empty-parenthesis and parameterised
  // spellings of 'def'.
  // constructor:
  | KW_CONSTRUCTOR OP_COLON block KW_END {
		auto params = new std::vector<catmint::Attribute*>();
		$$ = new catmint::Method(@1.first_line, std::string(catmint::strings::Init),
		                         std::string("Void"), Expression($3), *params);
		delete params;
	}
  // constructor():
  | KW_CONSTRUCTOR OP_OPAREN OP_CPAREN OP_COLON block KW_END {
		auto params = new std::vector<catmint::Attribute*>();
		$$ = new catmint::Method(@1.first_line, std::string(catmint::strings::Init),
		                         std::string("Void"), Expression($5), *params);
		delete params;
	}
  // A static method: no receiver, no virtual table slot, called on the class.
  // Written as a prefix on any of the six 'def' forms rather than as six more
  // rules of its own.
  | KW_STATIC method {
		if (auto m = dynamic_cast<catmint::Method*>($2)) {
			m->setStatic(true);
		}
		$$ = $2;
	}
  // constructor(Int a, Int b):
  | KW_CONSTRUCTOR OP_OPAREN method_arguments OP_CPAREN OP_COLON block KW_END {
		$$ = new catmint::Method(@1.first_line, std::string(catmint::strings::Init),
		                         std::string("Void"), Expression($6),
		                         *reinterpret_cast<std::vector<catmint::Attribute*>*>($3));
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
  type_name IDENTIFIER {
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
	type_name IDENTIFIER id_list {
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
	| type_name IDENTIFIER OP_ATTRIB value_expression {
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
	// a[i] = v  ->  a.set(i, v)
	| vector_access OP_ATTRIB value_expression {
	  // vector_access already produced 'a.get(i)'. Rewriting that node in place
	  // avoids needing a second, conflicting rule for the assignment form.
	  auto getDispatch = dynamic_cast<catmint::Dispatch*>($1);
	  if (!getDispatch) {
	    std::cerr << "[ ERROR ] : Line " << @1.first_line
	              << " : left side of '=' is not an indexable access." << std::endl;
	    fflush(stdout);
	    exit(1);
	  }
	  getDispatch->setName(std::string("set"));
	  getDispatch->addArgument(Expression($3));
	  $$ = getDispatch;
	}
	// a.b = v. field_access has already been reduced, so the value is simply
	// attached to the node that is there, exactly as a[i] = v does.
	| field_access OP_ATTRIB value_expression {
	  auto access = dynamic_cast<catmint::FieldAccess*>($1);
	  if (!access) {
	    std::cerr << "[ ERROR ] : Line " << @1.first_line
	              << " : left side of '=' is not a field." << std::endl;
	    fflush(stdout);
	    exit(1);
	  }
	  access->setValue(Expression($3));
	  $$ = access;
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
	}*/
	// b = {}  - an empty dictionary literal. The lexer has no explicit rule for
	// braces; its catch-all returns them as character tokens, which is why this
	// can match '{' and '}' directly.
	| IDENTIFIER OP_ATTRIB '{' '}' {
	  auto ld_name = new std::vector<std::string>();
      ld_name->push_back(*$1);

      auto ld_type = std::string("_uuid_generic_0002_dictionary"); // Semantic analyzer will add complete type
      $$ = new catmint::LocalDefinition(@1.first_line, *ld_name, ld_type);
	}
	;

// A type name. A qualified one such as 'm::Vector' arrives as a single
// IDENTIFIER: the lexer joins it, because letting the grammar see
// IDENTIFIER '::' IDENTIFIER here is ambiguous with static dispatch
// ('Program::run.execute(...)'), which starts the same way. An unqualified
// name inside a namespaced module is qualified with that namespace.
type_name
  : IDENTIFIER {
      $$ = new std::string(qualifyTypeName(*$1));
      delete $1;
    }
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
  : local
  | return_expression
  // A statement may be any value expression. This covers a bare dispatch and
  // a bare 'if' (both reachable through basic_expression), and additionally
  // allows an expression statement the older grammar rejected: an indexed read
  // such as 'a[3]', and an operator applied to calls such as 'f(x) * g(y)'.
  // Listing dispatch_expression or if_expression here as well would make them
  // derivable two ways and introduce reduce/reduce conflicts.
  | value_expression
  | void_expression
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
  // 'and' and 'or' evaluate their right operand only when the left has not
  // already settled the answer. They sit here, at the outermost level of an
  // expression, with the lowest precedence of any operator.
  | value_expression OP_ANDALSO value_expression {
		$$ = new catmint::BinaryOperator(@1.first_line, BinOp::AndAlso,
		                                 Expression($1), Expression($3));
	}
  | value_expression OP_ORELSE value_expression {
		$$ = new catmint::BinaryOperator(@1.first_line, BinOp::OrElse,
		                                 Expression($1), Expression($3));
	}
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
	// 'expr is Type' asks whether the object is of that type, giving 1 or 0.
	// It reuses StaticDispatch, which already carries both an object and a
	// type name, so no new AST node or serialization is needed. 'is' is a
	// keyword, so it cannot collide with a method of that name.
	| additive_expression KW_IS type_name %prec PREC_REL {
		$$ = new catmint::StaticDispatch(@1.first_line, Expression($1), *$3,
		                                 std::string("is"),
		                                 std::vector<catmint::Expression*>());
		delete $3;
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
	;

basic_expression
  : identifier_expression
	| spawn_expression
	| new_expression
	| field_access
	| negative_expression
	| parenthesis_expression
	| new_list
	// | new_dict
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
	|
	KW_IF value_expression OP_COLON block elif_chain {
		auto cond	 	= $2;
		auto block_then = ($4 != nullptr) ? $4 : new catmint::Block(@3.first_line);

		// if WITH elif: the chain is already an IfStatement, and becomes this
		// one's else branch. `elif` exists because an end-terminated language
		// cannot spell `else if` the way C does -- the inner if would need an
		// `end` of its own and the outer one another after it. Python, Ruby,
		// Lua and sh all answer this with a dedicated keyword.
		$$ = new catmint::IfStatement(@1.first_line,
								   Expression(cond),
								   Expression(block_then),
								   Expression($5));
    }
  ;

// One `elif`, plus whatever follows it. Written as a right-recursive chain so
// that each link is an ordinary if with the rest as its else branch, which is
// exactly what the tree already knows how to represent -- no new AST node, no
// change to the generator or the semantic pass.
//
// The three alternatives are told apart by the token after the block, which is
// KW_END, KW_ELSE or KW_ELIF, so this introduces no conflict.
elif_chain
	: KW_ELIF value_expression OP_COLON block KW_END {
		auto block_then = ($4 != nullptr) ? $4 : new catmint::Block(@3.first_line);
		$$ = new catmint::IfStatement(@1.first_line,
								   Expression($2),
								   Expression(block_then));
	}
	| KW_ELIF value_expression OP_COLON block KW_ELSE block KW_END {
		auto block_then = ($4 != nullptr) ? $4 : new catmint::Block(@3.first_line);
		auto block_else = ($6 != nullptr) ? $6 : new catmint::Block(@3.first_line);
		$$ = new catmint::IfStatement(@1.first_line,
								   Expression($2),
								   Expression(block_then),
								   Expression(block_else));
	}
	| KW_ELIF value_expression OP_COLON block elif_chain {
		auto block_then = ($4 != nullptr) ? $4 : new catmint::Block(@3.first_line);
		$$ = new catmint::IfStatement(@1.first_line,
								   Expression($2),
								   Expression(block_then),
								   Expression($5));
	}
	;

// `new T(a, b)` allocates an object, runs its attribute initialisers and then
// its constructor. `new T` does the first two. A constructor is an ordinary
// method named 'init', so the arguments are checked and converted by the same
// code that checks any call.
new_expression
	: KW_NEW type_name OP_OPAREN dispatch_arguments OP_CPAREN {
		$$ = new catmint::NewObject(@1.first_line, *$2, *$4);
		delete $2; delete $4;
	}
	| KW_NEW type_name {
		$$ = new catmint::NewObject(@1.first_line, *$2);
		delete $2;
	}
	;

// `spawn Class.method(argument)` runs a static method on a thread and gives
// back a handle to wait for. It is an expression so that the handle can be
// kept; the call inside is an ordinary dispatch, so the usual machinery
// works out which static method is meant.
// Spelled out rather than taking any dispatch, because `spawn a.b().c()`
// would otherwise be ambiguous about which call is the one being spawned.
// This is also exactly the form that is allowed: a static method on a
// named class.
spawn_expression
	: KW_SPAWN IDENTIFIER '.' IDENTIFIER OP_OPAREN dispatch_arguments OP_CPAREN {
		auto object = new catmint::Symbol(@2.first_line, *$2);
		auto call = new catmint::Dispatch(@1.first_line, *$4,
		                                  Expression(object), *$6);
		$$ = new catmint::SpawnStatement(@1.first_line, Expression(call));

		delete $2; delete $4; delete $6;
	}
	;

// A field of an object: `a.b`. The same node serves the assignment `a.b = v`,
// which attaches the value to it (see local_expr) rather than introducing a
// second rule that would be ambiguous with this one.
//
// `a.b(...)` is a dispatch, and the two are told apart by the token after the
// name: with '(' the parser shifts into dispatch_expression, otherwise it
// reduces here. That is a shift/reduce conflict, resolved the way bison
// resolves them by default, which is the way we want it.
field_access
	: basic_expression '.' IDENTIFIER {
		$$ = new catmint::FieldAccess(@1.first_line, Expression($1), *$3);
		delete $3;
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

		// 'A::B.m(...)' is static dispatch. The lexer joins 'A::B' into one
		// identifier so that a qualified type name can be written wherever a
		// type is named, so split it apart again here.
		auto sym = dynamic_cast<catmint::Symbol*>(obj);
		auto sep = sym ? sym->getName().find("::") : std::string::npos;
		if (sep != std::string::npos) {
			auto full     = sym->getName();
			auto objName  = full.substr(0, sep);
			auto typeName = full.substr(sep + 2);
			delete obj;
			$$ = new catmint::StaticDispatch(@1.first_line,
					Expression(new catmint::Symbol(@1.first_line, objName)),
					typeName, name, args);
		} else {
			// dispatch using object
			$$ = new catmint::Dispatch(@1.first_line, name, Expression(obj), args);
		}

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

new_list : '[' dispatch_arguments ']' {
  // Set name
  auto ld_name = new std::vector<std::string>();
  ld_name->push_back(std::string("_uuid_generic_0001_list_new_name"));

  // Set partial type
  auto ld_type = std::string("_uuid_generic_0001_list");  // Semantic analyzer will add complete type

  // Create actual local definition
  $$ = new catmint::LocalDefinition(@1.first_line, *ld_name, ld_type, Expression(new catmint::Block(@2.first_line, *$2))); 
}
;

// Dictionary syntax should be: { key: value, key: value }, etc
/*new_dict : '{' dispatch_arguments '{]}' {
  // Set name
  auto ld_name = new std::vector<std::string>();
  ld_name->push_back(std::string("_uuid_generic_0001_list_new_name"));

  // Set partial type
  auto ld_type = std::string("_uuid_generic_0001_list");  // Semantic analyzer will add complete type

  // Create actual local definition
  $$ = new catmint::LocalDefinition(@1.first_line, *ld_name, ld_type, Expression(new catmint::Block(@2.first_line, *$2))); 
}
;*/

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
  | try_expression
  | throw_expression
  | defer_expression
  ;

// `defer <expression>` runs the expression where the enclosing block ends,
// on every path out of it. It is emitted there rather than recorded, so it
// costs nothing at run time and needs nothing from the runtime.
defer_expression
    : KW_DEFER value_expression {
		$$ = new catmint::DeferStatement(@1.first_line, Expression($2));
	}
    ;

// try: <block> catch <name>: <block> end
//
// The handler binds one name and no type, because anything can be thrown and
// 'is' is how a handler decides what it caught.
try_expression
    : KW_TRY OP_COLON block KW_CATCH IDENTIFIER OP_COLON block KW_END {
		auto body    = ($3 != nullptr) ? $3 : new catmint::Block(@3.first_line);
		auto handler = ($7 != nullptr) ? $7 : new catmint::Block(@7.first_line);

		$$ = new catmint::TryStatement(@1.first_line, Expression(body), *$5,
		                               Expression(handler));
		delete $5;
	}
    ;

throw_expression
    : KW_THROW value_expression {
		$$ = new catmint::ThrowStatement(@1.first_line, Expression($2));
	}
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

// More precisely rvalue ... and let arguments be longer --<< this should be for "for" and others, needs an object, disallow dispatch here
vector_access
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
  
%%

// ----------------------------------------------------------------------------
//
// Main processing
//
// ----------------------------------------------------------------------------

void printUsage() {
  std::cerr << "Usage: catmint-parser [-I <dir>]... [--verbose] <inputFile> <outputFile>"
            << std::endl;
  std::cerr << "  -I <dir>     also look for modules in <dir>" << std::endl;
  std::cerr << "  --no-expand  leave 'using' unexpanded (separate compilation)"
            << std::endl;
  std::cerr << "  --module     compile a .cmm library: no Main is synthesised"
            << std::endl;
  std::cerr << "  --namespace <n>  declare this file's classes in namespace n"
            << std::endl;
  std::cerr << "  --verbose    print the running commentary on std::cout"
            << std::endl;
}

namespace {
/// Swallows everything written to it. The grammar actions narrate what they
/// are reducing, which is useful when working on the grammar and noise the
/// rest of the time, so std::cout goes nowhere unless --verbose is given.
/// Diagnostics go to std::cerr and are never swallowed.
class NullBuffer : public std::streambuf {
public:
  int overflow(int c) override { return c; }
};
}

// ----------------------------------------------------------------------------
//
// Module preprocessing
//
// `using <name>` splices <name>.cmm into the translation unit. It is a textual
// include, but a careful one:
//   * inclusion is recursive, so a module may itself use other modules;
//   * each module is included at most once, so a diamond does not produce
//     duplicate class definitions, and a cycle terminates instead of looping;
//   * #line directives are emitted so that a diagnostic reports the file and
//     line the programmer wrote, not an offset into the spliced text.
//
// ----------------------------------------------------------------------------

namespace {

std::vector<std::string> gSearchPaths;
std::set<std::string> gIncludedModules;

/// Absolute path when the file exists, so the same module reached by two
/// different relative paths is still recognised as one module.
std::string canonicalPath(const std::string &path) {
  char resolved[PATH_MAX];
  if (realpath(path.c_str(), resolved)) {
    return std::string(resolved);
  }
  return path;
}

std::string directoryOf(const std::string &path) {
  auto slash = path.find_last_of('/');
  return slash == std::string::npos ? std::string(".") : path.substr(0, slash);
}

/// The module named on a `using` line, and the namespace alias if the line
/// says `using <module> as <alias>`. Returns an empty name when the line is
/// not a using directive.
struct UsingDirective {
  std::string module;
  std::string alias;
};

/// The alias named by `using namespace <alias>`, or empty when the line is
/// something else.
std::string openNamespaceOn(const std::string &line) {
  static const std::regex openLine(
      R"(^[ \t]*using[ \t]+namespace[ \t]+([A-Za-z_][A-Za-z_0-9]*)[ \t\r]*$)");
  std::smatch match;
  if (!std::regex_match(line, match, openLine)) {
    return std::string();
  }
  return match[1].str();
}

UsingDirective usingDirectiveOn(const std::string &line) {
  static const std::regex usingLine(
      R"(^[ \t]*using[ \t]+([A-Za-z_][A-Za-z_0-9]*)([ \t]+as[ \t]+([A-Za-z_][A-Za-z_0-9]*))?[ \t\r]*$)");
  std::smatch match;
  UsingDirective result;
  if (!std::regex_match(line, match, usingLine)) {
    return result;
  }
  result.module = match[1].str();
  result.alias = match[3].matched ? match[3].str() : std::string();
  return result;
}

/// Search <dir of the including file>, then every -I directory, then the
/// historical default locations.
std::string findModule(const std::string &name, const std::string &fromDir) {
  std::vector<std::string> candidates;
  candidates.push_back(fromDir + "/" + name + ".cmm");
  for (const auto &dir : gSearchPaths) {
    candidates.push_back(dir + "/" + name + ".cmm");
  }
  candidates.push_back(name + ".cmm");
  candidates.push_back("./test/" + name + ".cmm");

  for (const auto &candidate : candidates) {
    std::ifstream probe(candidate);
    if (probe.good()) {
      return candidate;
    }
  }
  return std::string();
}

/// Rewrite `"a ${expr} b"` into `("a " + (expr) + " b")`.
///
/// This is a source-level rewrite, done before the lexer sees the line, so
/// what is inside the braces is ordinary catmint parsed by the ordinary
/// grammar: any expression may be written there, and the compiler needs no
/// new node, no new token and no runtime support. A string with no `${` is
/// left exactly as it was.
///
/// Only double-quoted strings interpolate. A single-quoted one is literal,
/// and `\$` is a dollar sign.
std::string interpolate(const std::string &line);

/// Given the index of the `$` in a `${`, the index just past the matching
/// `}`, or npos when the braces do not balance. Braces and quotes inside the
/// expression are skipped, so a nested string or a brace literal does not
/// end it early.
size_t endOfInterpolation(const std::string &text, size_t dollar) {
	size_t i = dollar + 2;
	int depth = 1;
	for (; i < text.size() && depth > 0; ++i) {
		if (text[i] == '\\' && i + 1 < text.size()) { ++i; continue; }
		if (text[i] == '"' || text[i] == '\'') {
			const char quote = text[i];
			for (++i; i < text.size() && text[i] != quote; ++i) {
				if (text[i] == '\\' && i + 1 < text.size()) ++i;
			}
			continue;
		}
		if (text[i] == '{') ++depth;
		else if (text[i] == '}') --depth;
	}
	return depth == 0 ? i : std::string::npos;
}

/// The index of the `"` that closes the string opened at \p quote, skipping
/// escapes and whole `${...}` groups, or npos when it is never closed.
size_t endOfString(const std::string &text, size_t quote) {
	for (size_t i = quote + 1; i < text.size(); ++i) {
		if (text[i] == '\\' && i + 1 < text.size()) { ++i; continue; }
		if (text[i] == '$' && i + 1 < text.size() && text[i + 1] == '{') {
			size_t after = endOfInterpolation(text, i);
			if (after == std::string::npos) return std::string::npos;
			i = after - 1;
			continue;
		}
		if (text[i] == '"') return i;
	}
	return std::string::npos;
}

std::string interpolate(const std::string &line) {
	std::string out;
	out.reserve(line.size() + 16);

	for (size_t i = 0; i < line.size(); ++i) {
		// Outside a string, '#' begins a comment that runs to end of line.
		if (line[i] == '#') {
			out.append(line, i, std::string::npos);
			return out;
		}
		if (line[i] == '\'') {
			// A single-quoted string is literal, escapes and all.
			size_t j = i + 1;
			while (j < line.size() && line[j] != '\'') {
				if (line[j] == '\\' && j + 1 < line.size()) ++j;
				++j;
			}
			out.append(line, i, std::min(j + 1, line.size()) - i);
			i = j;
			continue;
		}
		if (line[i] != '"') {
			out.push_back(line[i]);
			continue;
		}

		// A line whose quotes do not balance is left alone rather than
		// half-rewritten; the parser will report it.
		size_t end = endOfString(line, i);
		if (end == std::string::npos) {
			out.append(line, i, std::string::npos);
			return out;
		}

		const std::string body = line.substr(i + 1, end - i - 1);
		if (body.find("${") == std::string::npos) {
			out.append(line, i, end - i + 1);
			i = end;
			continue;
		}

		// An empty literal piece at each end costs nothing and means the
		// result is a String even when the whole content is one expression.
		std::string rewritten = "(\"";
		for (size_t j = 0; j < body.size(); ++j) {
			if (body[j] == '\\' && j + 1 < body.size()) {
				rewritten.push_back(body[j]);
				rewritten.push_back(body[j + 1]);
				++j;
				continue;
			}
			if (body[j] != '$' || j + 1 >= body.size() || body[j + 1] != '{') {
				rewritten.push_back(body[j]);
				continue;
			}

			size_t after = endOfInterpolation(body, j);
			if (after == std::string::npos) {
				rewritten.append(body, j, std::string::npos);
				break;
			}

			// Recurse, so a string inside an interpolation interpolates too.
			const std::string expression =
				interpolate(body.substr(j + 2, after - j - 3));
			rewritten += "\" + (" + expression + ") + \"";
			j = after - 1;
		}
		rewritten += "\")";

		out += rewritten;
		i = end;
	}

	return out;
}

void emitLineDirective(std::ostringstream &out, int line,
                       const std::string &file) {
  out << "#line " << line << " \"" << file << "\"\n";
}

/// Tells the parser which namespace the following text belongs to. An empty
/// name means the global namespace.
void emitNamespaceDirective(std::ostringstream &out, const std::string &ns) {
  out << "#namespace " << (ns.empty() ? "-" : ns) << "\n";
}

bool expandFile(const std::string &path, std::ostringstream &out,
                std::vector<std::string> &includeStack,
                const std::string &ns = std::string());

bool expandModule(const std::string &name, const std::string &fromDir,
                  std::ostringstream &out,
                  std::vector<std::string> &includeStack,
                  const std::string &alias, const std::string &enclosingNs) {
  std::string path = findModule(name, fromDir);
  if (path.empty()) {
    std::cerr << "[ ERROR ] Could not find module << " << name << ".cmm >>"
              << std::endl;
    return false;
  }

  std::string key = canonicalPath(path);

  // A module reached twice is included once. Without this, two modules that
  // both use a third would define its classes twice.
  if (gIncludedModules.count(key)) {
    return true;
  }

  // A cycle would otherwise recurse forever. The visited set above already
  // stops the common case, but a module is only marked included once its own
  // body has been read, so check the active stack too.
  for (const auto &active : includeStack) {
    if (active == key) {
      std::cerr << "[ ERROR ] Module cycle: << " << name
                << " >> is already being included" << std::endl;
      return false;
    }
  }

  std::cout << "[ LOG ] Opening and adding module << " << path << " >>"
            << std::endl;
  gIncludedModules.insert(key);

  // `using math as m` puts everything the module declares into namespace m.
  // Without an alias the module's classes are global, as before.
  emitNamespaceDirective(out, alias);
  bool ok = expandFile(path, out, includeStack, alias);
  emitNamespaceDirective(out, enclosingNs);
  return ok;
}

bool expandFile(const std::string &path, std::ostringstream &out,
                std::vector<std::string> &includeStack,
                const std::string &ns) {
  std::ifstream in(path);
  if (!in.good()) {
    std::cerr << "[ ERROR ] Could not open << " << path << " >>" << std::endl;
    return false;
  }

  includeStack.push_back(canonicalPath(path));
  const std::string dir = directoryOf(path);

  emitLineDirective(out, 1, path);

  std::string line;
  int lineNumber = 0;
  while (std::getline(in, line)) {
    ++lineNumber;

    const std::string opened = openNamespaceOn(line);
    if (!opened.empty()) {
      // A directive rather than a splice: nothing is included, the parser is
      // simply told that unqualified names may come from here.
      out << "#open " << opened << "\n";
      continue;
    }

    UsingDirective directive = usingDirectiveOn(line);
    if (directive.module.empty()) {
      out << interpolate(line) << "\n";
      continue;
    }

    std::cout << "Found module inclusion: using " << directive.module
              << (directive.alias.empty() ? "" : " as " + directive.alias)
              << std::endl;
    if (!gExpandModules) {
      // Separate compilation: record nothing here and splice nothing in. The
      // driver compiles the module on its own and hands its interface to this
      // unit with --import.
      out << "\n";
      continue;
    }
    if (!expandModule(directive.module, dir, out, includeStack, directive.alias,
                      ns)) {
      includeStack.pop_back();
      return false;
    }
    // Back in this file: blank line keeps the `using` line's position, and the
    // directive puts the lexer back on the right file and line.
    out << "\n";
    emitLineDirective(out, lineNumber + 1, path);
  }

  includeStack.pop_back();
  return true;
}

} // namespace

// flex lets us parse straight from a buffer, so the expanded source never has
// to be written to a temporary file.
struct yy_buffer_state;
typedef yy_buffer_state *YY_BUFFER_STATE;
extern YY_BUFFER_STATE yy_scan_string(const char *str);
extern void yy_delete_buffer(YY_BUFFER_STATE buffer);
extern int yylineno;

int main(int argc, char** argv) {

  std::vector<std::string> positional;
  bool verbose = false;
  for (int i = 1; i < argc; ++i) {
    std::string arg(argv[i]);
    if (arg == "-I") {
      if (i + 1 >= argc) {
        std::cerr << "[ ERROR ] -I needs a directory" << std::endl;
        return 1;
      }
      gSearchPaths.push_back(argv[++i]);
    } else if (arg.rfind("-I", 0) == 0 && arg.size() > 2) {
      gSearchPaths.push_back(arg.substr(2));
    } else if (arg == "--verbose" || arg == "-v") {
      verbose = true;
    } else if (arg == "--no-expand") {
      gExpandModules = false;
    } else if (arg == "--module") {
      gCreateMain = false;
    } else if (arg == "--namespace") {
      if (i + 1 >= argc) {
        std::cerr << "[ ERROR ] --namespace needs a name" << std::endl;
        return 1;
      }
      gCurrentNamespace = argv[++i];
    } else {
      positional.push_back(arg);
    }
  }

  NullBuffer nullBuffer;
  if (!verbose) {
    std::cout.rdbuf(&nullBuffer);
  }

  if (positional.size() != 2) {
    printUsage();
    return 0;
  }

  gInputFileName = strdup(positional[0].c_str());
  gCurrentFile = positional[0];

  std::ostringstream expanded;
  std::vector<std::string> includeStack;
  const std::string topNamespace = gCurrentNamespace;
  if (!expandFile(positional[0], expanded, includeStack, topNamespace)) {
    return 1;
  }

  const std::string source = expanded.str();
  yylineno = 1;
  YY_BUFFER_STATE buffer = yy_scan_string(source.c_str());

  int parseResult = yyparse();

  yy_delete_buffer(buffer);

  if (parseResult) {
    return 1;
  }

  // A Main synthesised around top-level code has no file of its own, because
  // no 'class' line produced it. It belongs to the file being compiled, and
  // saying so is what lets debug information name that file.
  for (auto cls : *gCatmintProgram) {
    if (cls->getFile().empty()) {
      cls->setFile(positional[0]);
    }
  }

  catmint::ASTSerializer serializer(positional[1].c_str());
  serializer.visit(gCatmintProgram);

  return 0;
}
