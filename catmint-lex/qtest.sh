#!/bin/sh
rm -f ./test/vect.cm.lext
echo Testing basic vect.cm on parser and AST generation.
./bin/catmint-parser ./test/vect.cm ./test/vect.cm.lext
cat ./test/vect.cm.lext
