%{

#include "catmint.tab.h"
#include <cstdio>
#include <cstdlib>
#include <string>

extern std::string gCurrentFile;
extern std::string gCurrentNamespace;

void countColumns();
static std::string decodeEscapes(const std::string &text);

static int gColumnNumber = 1;

#define YY_USER_ACTION { \
		yylloc.first_line = yylloc.last_line = yylineno;\
		yylloc.first_column = gColumnNumber;\
		yylloc.last_column = gColumnNumber+yyleng;\
	}
%}

%option yylineno

%%

  /* A #line directive from the module preprocessor: re-point the lexer at the
     original file and line so diagnostics are reported against what the
     programmer wrote, not the spliced text. */
  /* Which namespace the following text declares into. '-' means global. */
^[ \t]*"#namespace"[ \t]+[A-Za-z_0-9-]+[ \t]*\r?\n {
	char directiveNs[256] = {0};
	if (sscanf(yytext, " #namespace %255s", directiveNs) == 1) {
		gCurrentNamespace = (directiveNs[0] == '-' && directiveNs[1] == '\0')
		                        ? std::string()
		                        : std::string(directiveNs);
	}
	gColumnNumber = 1;
}

^[ \t]*"#line"[ \t]+[0-9]+[ \t]+\"[^\"]*\"[ \t]*\r?\n {
	int directiveLine = 0;
	char directiveFile[1024] = {0};
	if (sscanf(yytext, " #line %d \"%1023[^\"]\"", &directiveLine, directiveFile) == 2) {
		yylineno = directiveLine;
		gCurrentFile = directiveFile;
	}
	gColumnNumber = 1;
}


"using"       { countColumns(); return KW_USING; }
"class" 	    { countColumns(); return KW_CLASS; }
"from" 		    { countColumns(); return KW_FROM; }
"return"      { countColumns(); return KW_RETURN; }
"self"        { countColumns(); return KW_SELF;	}
"null"        { countColumns(); return KW_NULL; }
"constructor"	{ countColumns(); return KW_CONSTRUCTOR; }
"new"         { countColumns(); return KW_NEW; }
"constexpr"   { countColumns(); return KW_CONSTEXPR; }
"def"         { countColumns(); return KW_DEF; }
"var"		      { countColumns(); return KW_VAR; }
"if"		      { countColumns(); return KW_IF; }
"for"		      { countColumns(); return KW_FOR; }
"in"		      { countColumns(); return KW_IN; }
"is"          { countColumns(); return KW_IS; }
"and"         { countColumns(); return OP_ANDALSO; }
"or"          { countColumns(); return OP_ORELSE; }
"do"		      { countColumns(); return KW_DO; }
"while"	      { countColumns(); return KW_WHILE; }
"then"		    { countColumns(); return KW_THEN; }
"else"		    { countColumns(); return KW_ELSE; }
"end"		      { countColumns(); return KW_END; }
"<"			      { countColumns(); return OP_LT;  }
">"			      { countColumns(); return OP_GT;  }
"<="			    { countColumns(); return OP_LTE; }
">="			    { countColumns(); return OP_GTE; }
"=="			    { countColumns(); return OP_ISE; }
"!="			    { countColumns(); return OP_ISNE; }
"="			      { countColumns(); return OP_ATTRIB; }
"+"           { countColumns(); return OP_PLUS; }
"-"           { countColumns(); return OP_MINUS; }
"*"           { countColumns(); return OP_MUL; }
"/"           { countColumns(); return OP_DIV; }
"%"           { countColumns(); return OP_MOD; }
"**"          { countColumns(); return OP_POW; }
"^"           { countColumns(); return OP_XOR; }
"&"           { countColumns(); return OP_AND; }
"<<"          { countColumns(); return OP_LSHIFT; }
">>"          { countColumns(); return OP_RSHIFT; }
"|"           { countColumns(); return OP_OR; }
"("           { countColumns(); return OP_OPAREN; }
")"           { countColumns(); return OP_CPAREN; }
"!"           { countColumns(); return OP_NOT; }
":"						{ countColumns(); return OP_COLON; }
"::"				  { countColumns(); return OP_STATIC_ACCESS; }

"#"[^\r\n]*	{}


  /* A namespace-qualified name, 'm::Vector', is lexed as a single identifier
     so that the grammar can use it wherever a type is named without becoming
     ambiguous with static dispatch. When it turns out to be static dispatch
     after all ('Program::run.execute(...)'), the dispatch rule splits it back
     apart. */
[a-zA-Z_]([0-9a-zA-Z_])*"::"[a-zA-Z_]([0-9a-zA-Z_])* {
	countColumns();
	yylval.stringValue = new std::string(yytext);
	return IDENTIFIER;
}

[a-zA-Z_]([0-9a-zA-Z_])* {
	countColumns();
	yylval.stringValue = new std::string(yytext);
    return IDENTIFIER;
}

[0]|([1-9][0-9]*)	{
	countColumns();
	/* 64-bit, so a literal that does not fit in an Int can still be written;
	   the generator gives such a literal the type Int64. */
	yylval.intValue = strtoll(yytext, NULL, 10);
	return INTEGER_CONSTANT;
}

[0-9]*(\.[0-9]+) {
	countColumns();
	yylval.floatValue = atof(yytext);
	return FLOAT_CONSTANT;
}

["]([^"]|(\\\"))*["] {
	countColumns();
	yylval.stringValue = new std::string(decodeEscapes(
		std::string(yytext).substr(1, std::string(yytext).size() - 2)));
	return STRING_CONSTANT;
}

[']([^']|(\\\'))*['] {
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


/* Turn the escape sequences in a string literal into the characters they
 * stand for. This used to be left to the AST's JSON encoding, which happened
 * to decode \n, \t and \\ because JSON spells them the same way. That was an
 * accident, and it broke on \": the quote reached the JSON writer still
 * escaped and closed the string early, producing an AST file the compiler
 * could not read back. */
static std::string decodeEscapes(const std::string &text) {
	std::string out;
	out.reserve(text.size());

	for (size_t i = 0; i < text.size(); ++i) {
		if (text[i] != '\\' || i + 1 == text.size()) {
			out.push_back(text[i]);
			continue;
		}

		++i;
		switch (text[i]) {
		case 'n':  out.push_back('\n'); break;
		case 't':  out.push_back('\t'); break;
		case 'r':  out.push_back('\r'); break;
		case '0':  out.push_back('\0'); break;
		case '\\': out.push_back('\\'); break;
		case '"':  out.push_back('"');  break;
		case '\'': out.push_back('\''); break;
		/* An unknown escape keeps both characters, so nothing is silently lost. */
		default:
			out.push_back('\\');
			out.push_back(text[i]);
			break;
		}
	}

	return out;
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
