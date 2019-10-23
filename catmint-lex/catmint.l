%{

#include "catmint.tab.h"
#include <string>

void countColumns();

static int gColumnNumber = 1; 

#define YY_USER_ACTION { \
		yylloc.first_line = yylloc.last_line = yylineno;\
		yylloc.first_column = gColumnNumber;\
		yylloc.last_column = gColumnNumber+yyleng;\
	}
%}

%option yylineno

%%

"class" 	{ countColumns(); return KW_CLASS; }
"from" 		{ countColumns(); return KW_FROM; }
"inherits"  { countColumns(); return KW_INHERITS;	}
"constructor"	{ countColumns(); return KW_CONSTRUCTOR; }
"var"		{ countColumns(); return KW_VAR; }
"if"		{ countColumns(); return KW_IF; }
"then"		{ countColumns(); return KW_THEN; }
"else"		{ countColumns();  return KW_ELSE; }
"end"		{ countColumns();  return KW_END; }
"<"			{ countColumns(); return OP_LT;  }
">"			{ countColumns(); return OP_GT;  }
"<="			{ countColumns(); return OP_LTE; }
">="			{ countColumns(); return OP_GTE; }
"=="			{ countColumns(); return OP_ISE; }
"="			{ countColumns(); return OP_ATTRIB; }

"#"[^\r\n]*	{}


[a-zA-Z]([0-9a-zA-Z_])* {
	countColumns(); 
	yylval.stringValue = new std::string(yytext);
    return IDENTIFIER;
}

[0]|([1-9][0-9]*)	{ 
	countColumns(); 
	yylval.intValue = atoi(yytext);
	return INTEGER_CONSTANT; 
}

[0-9]*(\.[0-9]+) {
	countColumns();
	yylval.floatValue = atof(yytext);
	return FLOAT_CONSTANT;
}

["]([^"]|(\\\"))*["] {
	std::string s = std::string(yytext);
	s = s.substr(1, s.size() - 2);
	
	yylval.stringValue = new std::string(s);
	return STRING_CONSTANT;
}

[ \t\r\n]					{ countColumns(); }				
. {
	countColumns(); 
	return yytext[0];
}

%%

int yywrap(void) {
	return 1;
}

void countColumns() {
	for(int i = 0; yytext[i]; i++) {
		if(yytext[i] == '\n') {
			gColumnNumber = 1;
		} else if(yytext[i] == '\t') {
			gColumnNumber += 8 - (gColumnNumber % 8);
		} else {
			gColumnNumber ++;
		}
	}
}
