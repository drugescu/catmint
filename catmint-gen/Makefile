LLVMCXX = clang++

LXXFLAGS = -std=c++14 -frtti -fexceptions -w
OLDFLAGS = -stdlib=libc++ 
INCLUDES = -I../catmint-ast/include -I. -I./include
LFLAGS = -L../catmint-ast 
LIBS = -lcatmint-ast -lLLVM-10
MAIN = ./bin/catmint-gen
LLVMFLAGS = `llvm-config --system-libs --libs all --cxxflags --ldflags`

.PHONY: clean

all: clean ast gen $(MAIN)
	@echo  The Catmint Generator has been compiled

gen: 
	$(LLVMCXX) -o $(MAIN)  $(LLVMFLAGS) $(LXXFLAGS) $(INCLUDES) *.cpp ../catmint-ast/src/*.cpp $(LFLAGS) $(LIBS) 

ast:
	cd ../catmint-ast && cmake . && make && cd ../catmint-gen

clean:
	$(RM) *.o *~ $(MAIN)
