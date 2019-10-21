#!/bin/sh
echo Testing basic hello2.cm on parser and AST generation.
./bin/catmint-parser ./test/hello2.cm ./test/hello2.cm.lext
cat ./test/hello2.cm.lext
