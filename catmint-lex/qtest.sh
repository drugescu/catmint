#!/bin/sh
rm -f ./test/hellox.cm.lext
echo Testing basic hellox.cm on parser and AST generation.
./bin/catmint-parser ./test/hellox.cm ./test/hellox.cm.lext
cat ./test/hellox.cm.lext
