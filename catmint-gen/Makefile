LLVMCXX = clang++

LXXFLAGS = -std=c++11 -stdlib=libc++ -frtti -fexceptions -w
INCLUDES = -I../catmint-ast/include -I. -I./include
LFLAGS = -L../catmint-ast 
LIBS = -lcatmint-ast
MAIN = ./bin/catmint-gen
LLVMFLAGS = `llvm-config --system-libs --libs executionengine core mcjit analysis native --cxxflags --ldflags `

.PHONY: clean

all: clean ast gen $(MAIN)
	@echo  The Catmint Generator has been compiled

gen: 
	$(LLVMCXX) -o $(MAIN)  $(LLVMFLAGS) $(LXXFLAGS) $(INCLUDES) $(LFLAGS) $(LIBS) *.cpp ../catmint-ast/src/*.cpp

ast:
	cd ../catmint-ast && cmake . && make && cd ../catmint-gen

clean:
	$(RM) *.o *~ $(MAIN)
