
#include <iostream>

#include <ASTSerialization.h>
/*#include <SemanticAnalysis.h>
#include <SemanticException.h>
#include "ASTCodeGen.h"*/

void printUsage() {
  std::cout << "./lcpl-codegen <inputFile> <outputFile> " << std::endl;
}

int main(int argc, char **argv) {

  if (argc < 3) {
    printUsage();
    return 0;
  }

  catmint::ASTDeserializer deserializer(argv[1]);
  std::unique_ptr<catmint::Program> program = deserializer.getRootNode();

  /*try {
    lcpl::SemanticAnalysis semanticAnalysis(program.get());
    //semanticAnalysis.runAnalysis();
      
    lcpl::ASTCodeGen codeGenerator(argv[1], program.get(), &semanticAnalysis);
    codeGenerator.runCodeGeneration(argv[2]);
   

    if ((argc == 4) && (strcmp(argv[3], "--run") == 0)) {
      std::cout << "Running interpreter" << std::endl;
//      semanticAnalysis.runInterpreter();
    }
  } catch (lcpl::SemanticException &e) {
    std::cout << e.what() << std::endl;
  }*/

  return 0;
}
