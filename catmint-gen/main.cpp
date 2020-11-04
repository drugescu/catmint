
#include <iostream>

#include <SemanticAnalysis.h>
#include <SemanticException.h>
#include <PrintAnalysis.h>
#include <ASTSerialization.h>
#include "ASTCodeGen.h"

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
      catmint::ASTCodeGen codeGenerator(argv[1], program.get(), &semanticAnalysis);
      codeGenerator.runCodeGeneration("");
    }
    catch (std::exception e) {
      std::cout << e.what() << std::endl;
    }
  }  catch (catmint::SemanticException &e) {
    std::cout << e.what() << std::endl;
  }

  std::cout << "[ LOG ] : Semantic analysis complete. No errors.\n";



  return 0;
}
