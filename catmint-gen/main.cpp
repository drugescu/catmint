
#include <iostream>

#include <SemanticAnalysis.h>
#include <SemanticException.h>
#include <PrintAnalysis.h>
#include <ASTSerialization.h>
//#include "ASTCodeGen.h"*/

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
  
  try {
    catmint::SemanticAnalysis semanticAnalysis(program.get());
    semanticAnalysis.runAnalysis();
  }  catch (catmint::SemanticException &e) {
    std::cout << e.what() << std::endl;
  }

  return 0;
}
