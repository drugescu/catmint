CXX = g++

CXXFLAGS = -std=c++14
INCLUDES = -I../catmint-ast/include
LFLAGS = -L../catmint-ast 
LIBS = -lcatmint-ast -lLLVM-10
MAIN = ./bin/catmint-parser

.PHONY: clean

all: clean ast parser $(MAIN)
	@echo  The Catmint Parser has been compiled

$(MAIN): lex.yy.o catmint.tab.o
	$(CXX) -o $(MAIN) lex.yy.o catmint.tab.o $(LFLAGS) $(LIBS)

parser:
	bison -d catmint.y
	flex catmint.l
	$(CXX) $(CXXFLAGS) $(INCLUDES) lex.yy.c -c
	$(CXX) $(CXXFLAGS) $(INCLUDES) catmint.tab.c -c

ast:
	cd ../catmint-ast && cmake . && make && cd ../catmint-lex

clean:
	$(RM) *.o *~ $(MAIN) catmint.tab.* lex.yy.*
