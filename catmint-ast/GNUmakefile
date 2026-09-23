# Thin wrapper over the CMake build so sibling projects can just `make -C ../catmint-ast`.
# LLVM_CONFIG is the override the other two Makefiles take, and this one has
# to take it too or the documented `make LLVM_CONFIG=...` does not build the
# first of the three components. Distributions name the binary after the
# version -- llvm-config-18 on Ubuntu -- so there is often no plain
# `llvm-config` to find, which is how this was found: the build failed on
# Linux with "llvm-config: not found" followed by a confusing CMake error.
LLVM_CONFIG ?= $(shell command -v llvm-config 2>/dev/null || echo /opt/homebrew/opt/llvm@22/bin/llvm-config)
LLVM_DIR ?= $(shell $(LLVM_CONFIG) --cmakedir 2>/dev/null)
BUILD_DIR ?= build

.PHONY: build clean

build:
	@test -n "$(LLVM_DIR)" || { \
	  echo "catmint-ast: no LLVM found. Set LLVM_CONFIG to your llvm-config," >&2; \
	  echo "  e.g. make LLVM_CONFIG=/usr/bin/llvm-config-18" >&2; exit 1; }
	cmake -S . -B $(BUILD_DIR) -DLLVM_DIR=$(LLVM_DIR)
	cmake --build $(BUILD_DIR) -j

clean:
	rm -rf $(BUILD_DIR) CMakeCache.txt CMakeFiles/ cmake_install.cmake Makefile
