# Thin wrapper over the CMake build so sibling projects can just `make -C ../catmint-ast`.
LLVM_DIR ?= $(shell /opt/homebrew/opt/llvm@22/bin/llvm-config --cmakedir 2>/dev/null || llvm-config --cmakedir)
BUILD_DIR ?= build

.PHONY: build clean

build:
	cmake -S . -B $(BUILD_DIR) -DLLVM_DIR=$(LLVM_DIR)
	cmake --build $(BUILD_DIR) -j

clean:
	rm -rf $(BUILD_DIR) CMakeCache.txt CMakeFiles/ cmake_install.cmake Makefile
