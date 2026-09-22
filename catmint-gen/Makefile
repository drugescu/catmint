# Catmint semantic analysis + LLVM IR generation.
#
# LLVM is discovered through llvm-config so the build works on Homebrew
# (keg-only) as well as a system-wide Linux install. Override with:
#   make LLVM_CONFIG=/path/to/llvm-config
LLVM_CONFIG ?= $(shell command -v llvm-config 2>/dev/null || echo /opt/homebrew/opt/llvm@22/bin/llvm-config)
CXX ?= c++

LLVM_CXXFLAGS := $(shell $(LLVM_CONFIG) --cxxflags)
LLVM_LDFLAGS  := $(shell $(LLVM_CONFIG) --ldflags)
LLVM_LIBS     := $(shell $(LLVM_CONFIG) --libs core support irreader bitwriter) \
                 $(shell $(LLVM_CONFIG) --system-libs)

# llvm-config hands back -std=, -fno-exceptions and -fno-rtti. The generator
# uses try/catch (SemanticException) and dynamic_cast, so strip those.
LLVM_CXXFLAGS_CLEAN = $(filter-out -std=% -fno-exceptions -fno-rtti,$(LLVM_CXXFLAGS))
CXXFLAGS = -std=c++17 -fexceptions -frtti -w $(LLVM_CXXFLAGS_CLEAN)

INCLUDES = -I../catmint-ast/include -I. -I./include
LFLAGS   = -L../catmint-ast/build $(LLVM_LDFLAGS)
LIBS     = -lcatmint-ast $(LLVM_LIBS)
MAIN     = ./bin/catmint-gen

SOURCES = IRGenerator.cpp PrintAnalysis.cpp SemanticAnalysis.cpp \
          SemanticException.cpp SymbolTable.cpp TypeTable.cpp \
          TypeVisitor.cpp main.cpp

.PHONY: all clean ast gen test

all: ast $(MAIN)
	@echo "The Catmint Generator has been compiled -> $(MAIN)"

$(MAIN): $(SOURCES) | bin
	$(CXX) $(CXXFLAGS) $(INCLUDES) -o $(MAIN) $(SOURCES) $(LFLAGS) $(LIBS)

bin:
	mkdir -p bin

gen: $(MAIN)

ast:
	$(MAKE) -C ../catmint-ast -f GNUmakefile build

test: all
	./qtest.sh

clean:
	$(RM) *.o *~ $(MAIN)
