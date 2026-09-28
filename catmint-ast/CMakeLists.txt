project(catmint)
cmake_minimum_required(VERSION 3.16)

find_package(LLVM REQUIRED CONFIG)
message(STATUS "Found LLVM ${LLVM_PACKAGE_VERSION}")
message(STATUS "Using LLVMConfig.cmake in: ${LLVM_DIR}")

# Nothing to declare for zlib and zstd here, though it looks like there
# should be. LLVMSupport as Debian and Ubuntu build it names ZLIB::ZLIB and
# zstd::libzstd_shared in its link interface, and CMake refuses to generate
# without those imported targets -- but LLVMConfig.cmake defines them itself,
# from its own Findzstd.cmake, provided zlib1g-dev and libzstd-dev are
# installed. When they are not, the error names LLVMExports.cmake and says
# nothing about a missing package, and it cannot be caught here because the
# failure happens inside find_package(LLVM) above. COMPILING.md lists them.

# LLVM 16+ headers require C++17, so the whole project is built at C++17.
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

set(INCLUDE_DIR include)
include_directories(${INCLUDE_DIR})

# LLVM headers are keg-only on Homebrew and not on the default include path,
# so pull them in explicitly from the LLVMConfig.cmake that find_package found.
include_directories(SYSTEM ${LLVM_INCLUDE_DIRS})
separate_arguments(LLVM_DEFINITIONS_LIST NATIVE_COMMAND "${LLVM_DEFINITIONS}")
add_definitions(${LLVM_DEFINITIONS_LIST})

set(AST_FILES
  # Add the header files too, so they can be seen in IDE projects
  ${INCLUDE_DIR}/ASTNodes.h
  ${INCLUDE_DIR}/ASTSerialization.h
  ${INCLUDE_DIR}/ASTVisitor.h
  ${INCLUDE_DIR}/Attribute.h
  ${INCLUDE_DIR}/Assignment.h
  ${INCLUDE_DIR}/BinaryOperator.h
  ${INCLUDE_DIR}/Block.h
  ${INCLUDE_DIR}/Cast.h
  ${INCLUDE_DIR}/Class.h
  ${INCLUDE_DIR}/Dispatch.h
  ${INCLUDE_DIR}/Expression.h
  ${INCLUDE_DIR}/Feature.h
  ${INCLUDE_DIR}/FormalParam.h
  ${INCLUDE_DIR}/IfStatement.h
  ${INCLUDE_DIR}/IntConstant.h
  ${INCLUDE_DIR}/LocalDefinition.h
  ${INCLUDE_DIR}/Method.h
  ${INCLUDE_DIR}/NewObject.h
  ${INCLUDE_DIR}/Program.h
  ${INCLUDE_DIR}/StaticDispatch.h
  ${INCLUDE_DIR}/StringConstant.h
  ${INCLUDE_DIR}/StringConstants.h
  ${INCLUDE_DIR}/Substring.h
  ${INCLUDE_DIR}/Symbol.h
  ${INCLUDE_DIR}/TreeNode.h
  ${INCLUDE_DIR}/UnaryOperator.h
  ${INCLUDE_DIR}/NullConstant.h
  ${INCLUDE_DIR}/WhileStatement.h

  src/ASTSerialization.cpp
  src/ASTVisitor.cpp
  )

add_library(catmint-ast STATIC ${AST_FILES})
target_link_libraries(catmint-ast LLVMSupport)
