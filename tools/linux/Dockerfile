# A Linux machine for working on catmint from somewhere else.
#
#   docker build -t catmint-linux tools/linux
#   tools/linux/run.sh <command>        (runs in the repository, mounted)
#
# clang 16 builds the runtime (the oldest LLVM catmint supports, so every newer
# one reads the bitcode); LLVM 18 builds the compiler and is what a user on
# Ubuntu 24.04 has. lld and glibc's startup objects are all a user needs to
# link a program -- no C compiler.
FROM ubuntu:24.04
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      clang-16 llvm-16 \
      llvm-18 llvm-18-dev clang-18 lld-18 \
      flex bison cmake make g++ zlib1g-dev libzstd-dev libc6-dev \
      python3 ca-certificates libsdl2-dev \
 && rm -rf /var/lib/apt/lists/*
ENV LLVM_CONFIG=/usr/lib/llvm-18/bin/llvm-config \
    LLVM_BIN=/usr/lib/llvm-18/bin
WORKDIR /catmint
