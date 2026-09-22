# Catmint lexer + parser.
#
# LLVM is discovered through llvm-config so the build works on Homebrew
# (keg-only) as well as on a system-wide Linux install. Override with:
#   make LLVM_CONFIG=/path/to/llvm-config
LLVM_CONFIG ?= $(shell command -v llvm-config 2>/dev/null || echo /opt/homebrew/opt/llvm@22/bin/llvm-config)

# Homebrew's bison is keg-only; the system bison (2.3) is too old for the
# %define / %code directives this grammar uses, so prefer the brew one.
BISON ?= $(shell test -x /opt/homebrew/opt/bison/bin/bison && echo /opt/homebrew/opt/bison/bin/bison || echo bison)
FLEX  ?= flex
CXX   ?= c++

LLVM_CXXFLAGS := $(shell $(LLVM_CONFIG) --cxxflags)
LLVM_LDFLAGS  := $(shell $(LLVM_CONFIG) --ldflags)
LLVM_LIBS     := $(shell $(LLVM_CONFIG) --libs support core) $(shell $(LLVM_CONFIG) --system-libs)

# llvm-config hands back -std=, -fno-exceptions and -fno-rtti. Catmint's parser
# uses try/catch and the AST relies on dynamic_cast, so strip those three and
# pin our own.
LLVM_CXXFLAGS_CLEAN = $(filter-out -std=% -fno-exceptions -fno-rtti,$(LLVM_CXXFLAGS))
CXXFLAGS = -std=c++17 -fexceptions -frtti -w $(LLVM_CXXFLAGS_CLEAN)
# Relink when the AST library changes: it is built by the 'ast' target
# above, and without this dependency a stale binary silently survives a
# change to a shared header or to ASTVisitor.cpp.
AST_LIB = ../catmint-ast/build/libcatmint-ast.a

INCLUDES = -I../catmint-ast/include
LFLAGS   = -L../catmint-ast/build $(LLVM_LDFLAGS)
LIBS     = -lcatmint-ast $(LLVM_LIBS)
MAIN     = ./bin/catmint-parser

.PHONY: all clean ast parser test

all: ast parser $(MAIN)
	@echo "The Catmint Parser has been compiled -> $(MAIN)"

$(MAIN): lex.yy.o catmint.tab.o $(AST_LIB) | bin
	$(CXX) -o $(MAIN) lex.yy.o catmint.tab.o $(LFLAGS) $(LIBS)

bin:
	mkdir -p bin

parser: catmint.tab.o lex.yy.o

catmint.tab.c catmint.tab.h: catmint.y
	$(BISON) -d catmint.y

lex.yy.c: catmint.l catmint.tab.h
	$(FLEX) catmint.l

catmint.tab.o: catmint.tab.c
	$(CXX) $(CXXFLAGS) $(INCLUDES) -c catmint.tab.c -o catmint.tab.o

lex.yy.o: lex.yy.c
	$(CXX) $(CXXFLAGS) $(INCLUDES) -c lex.yy.c -o lex.yy.o

ast:
	$(MAKE) -C ../catmint-ast -f GNUmakefile build

test: all
	./wtest.sh

clean:
	$(RM) *.o *~ $(MAIN) catmint.tab.* lex.yy.*
