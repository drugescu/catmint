CXX = g++

CXXFLAGS = -std=c++11
INCLUDES = -I../catmint-ast/include -I. -I./include
LFLAGS = -L../catmint-ast 
LIBS = -lcatmint-ast
MAIN = ./bin/catmint-gen

.PHONY: clean

all: clean ast gen $(MAIN)
	@echo  The Catmint Generator has been compiled

$(MAIN): gen
	$(CXX) -o $(MAIN) $(LFLAGS) $(LIBS)

gen:
#	$(CXX) $(CXXFLAGS) $(INCLUDES) ASTCodeGen.cpp main.cpp -c
	$(CXX) $(CXXFLAGS) $(INCLUDES) *.cpp -c

ast:
	cd ../catmint-ast && cmake . && make && cd ../catmint-gen

clean:
	$(RM) *.o *~ $(MAIN)
