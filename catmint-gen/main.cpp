
#include <iostream>

#include <SemanticAnalysis.h>
#include <SemanticException.h>
#include <PrintAnalysis.h>
#include <ASTSerialization.h>

#include "llvm/Support/Path.h"
#include "llvm/Support/FileSystem.h"
#include "llvm/IR/Verifier.h"
#include "llvm/Support/raw_ostream.h"

#include "IRGenerator.h"

void printUsage() {
  std::cout << "./lcpl-codegen <inputFile> <outputFile> " << std::endl;
}

int main(int argc, char **argv) {

  if (argc < 3) {
    printUsage();
    return 0;
  }

  // Deserialize from ".ast" file
  catmint::ASTDeserializer deserializer(argv[1]);
  std::unique_ptr<catmint::Program> program = deserializer.getRootNode();

  // Print what has been deserialized for debugging purposes
  catmint::PrintAnalysis printAnalysis(program.get());
  printAnalysis.runAnalysis();

  try {
    catmint::SemanticAnalysis semanticAnalysis(program.get());
    semanticAnalysis.runAnalysis();

    // Print outputs
    semanticAnalysis.typeTable.printTypeTable();
    semanticAnalysis.symbolTable.print(std::cout);

    try {
          std::string OutputFile = llvm::sys::path::filename(argv[1]).str();
          catmint::IRGenerator Generator(OutputFile, program.get(),
                                      semanticAnalysis.getTypeTable(),
                                      semanticAnalysis.getSymbolDefinitions());
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

          std::cout << "---------- Code Generation & Execution ----------" << std::endl;
          Module->print(output, nullptr);

          if (llvm::verifyModule(*Module, &llvm::errs())) {
            return -3;
    }
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
