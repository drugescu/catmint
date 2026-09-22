
#include <iostream>
#include <set>
#include <string>
#include <vector>

#include <SemanticAnalysis.h>
#include <SemanticException.h>
#include <PrintAnalysis.h>
#include <ASTSerialization.h>

#include "llvm/IR/Verifier.h"
#include "llvm/Support/FileSystem.h"
#include "llvm/Support/Path.h"
#include "llvm/Support/raw_ostream.h"

#include "IRGenerator.h"

void printUsage() {
  std::cerr << "Usage: catmint-gen [--import <module.ast>]... [--module] "
               "[--verbose] <inputFile> <outputFile>"
            << std::endl;
  std::cerr << "  --import <ast>  bring in a separately compiled module's "
               "declarations"
            << std::endl;
  std::cerr << "  --module        compile a library: no Main required, no "
               "entry point emitted"
            << std::endl;
  std::cerr << "  --verbose       print the AST, type and symbol tables"
            << std::endl;
}

namespace {

/// Swallows everything written to it. The compiler's running commentary --
/// the AST dump, the type table, the symbol table -- goes to std::cout from
/// a dozen places, so the cheapest way to make the compiler quiet is to send
/// that stream nowhere unless --verbose is given. Errors go to std::cerr and
/// are unaffected.
class NullBuffer : public std::streambuf {
public:
  int overflow(int c) override { return c; }
};

} // namespace

int main(int argc, char **argv) {

  std::vector<std::string> imports;
  std::vector<std::string> positional;
  bool libraryOnly = false;
  bool verbose = false;

  for (int i = 1; i < argc; ++i) {
    std::string arg(argv[i]);
    if (arg == "--import") {
      if (i + 1 >= argc) {
        std::cerr << "[ ERROR ] --import needs a .ast file" << std::endl;
        return 1;
      }
      imports.push_back(argv[++i]);
    } else if (arg == "--module") {
      libraryOnly = true;
    } else if (arg == "--verbose" || arg == "-v") {
      verbose = true;
    } else {
      positional.push_back(arg);
    }
  }

  NullBuffer nullBuffer;
  std::streambuf *chatter = std::cout.rdbuf();
  if (!verbose) {
    std::cout.rdbuf(&nullBuffer);
  }

  if (positional.size() < 2) {
    std::cout.rdbuf(chatter);
    printUsage();
    return 0;
  }

  // Deserialize from ".ast" file
  catmint::ASTDeserializer deserializer(positional[0].c_str());
  std::unique_ptr<catmint::Program> program = deserializer.getRootNode();

  // Bring in the declarations of every imported module. Their classes join
  // this program's tree so that semantic analysis can resolve them and the
  // generator can lay them out, but they are recorded as external so that no
  // code is emitted for them here -- their bodies live in their own object.
  std::set<std::string> externalClasses;
  std::vector<std::unique_ptr<catmint::ASTDeserializer>> importDeserializers;
  for (const auto &importPath : imports) {
    importDeserializers.push_back(
        std::unique_ptr<catmint::ASTDeserializer>(
            new catmint::ASTDeserializer(importPath.c_str())));
    auto imported = importDeserializers.back()->getRootNode();
    if (!imported) {
      std::cerr << "[ ERROR ] could not read module " << importPath
                << std::endl;
      return 1;
    }
    for (auto &cls : imported->takeClasses()) {
      // A module reached along two import paths is listed twice; keep the
      // first copy so the class is defined once in this unit's tables.
      if (externalClasses.count(cls->getName())) {
        continue;
      }
      externalClasses.insert(cls->getName());
      program->addClass(std::move(cls));
    }
  }

  // Print what has been deserialized for debugging purposes
  catmint::PrintAnalysis printAnalysis(program.get());
  printAnalysis.runAnalysis();

  try {
    catmint::SemanticAnalysis semanticAnalysis(program.get(), libraryOnly);
    semanticAnalysis.runAnalysis();

    // Print outputs
    semanticAnalysis.typeTable.printTypeTable();
    semanticAnalysis.symbolTable.print(std::cout);

    try {
          std::string OutputFile = llvm::sys::path::filename(positional[0]).str();
          catmint::IRGenerator Generator(OutputFile, program.get(),
                                      semanticAnalysis.getTypeTable(),
                                      semanticAnalysis.getSymbolDefinitions(),
                                      externalClasses, libraryOnly);
          auto Module = Generator.runGenerator();
          if (!Module) {
            llvm::report_fatal_error(llvm::Twine("Couldn't generate module"));
          }

          std::string filename(Module->getName().str() + ".ll");
          std::error_code err;
          llvm::raw_fd_ostream output(filename, err, llvm::sys::fs::OF_Text);

          if (err) {
            llvm::report_fatal_error(llvm::Twine("Couldn't open output file: ") + filename + "\n");
          }

          if (llvm::verifyModule(*Module, &llvm::errs())) {
            return -3;
          }

          // No optimisation passes run here. They were tried, and once
          // catmintc compiles the linked bitcode at -O2 they made no
          // measurable difference -- the win was entirely in the driver,
          // which used to invoke clang at -O0 and so threw away register
          // allocation. Unoptimised IR is also much easier to read when
          // working on the generator.
          std::cout << "---------- Code Generation & Execution ----------" << std::endl;
          Module->print(output, nullptr);
    }
    catch (const std::exception &e) {
      std::cerr << e.what() << std::endl;
      return -4;
    }
  }  catch (catmint::SemanticException &e) {
    std::cerr << e.what() << std::endl;
    return -2;
  }

  std::cout << "[ LOG ] : Semantic analysis complete.\n";

  return 0;
}
