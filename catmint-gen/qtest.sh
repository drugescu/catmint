#!/bin/sh
#rm -f ./test/vect.cm.lext
#echo Testing basic vect.cm on parser and AST generation.
#./bin/catmint-parser ./test/vect.cm ./test/vect.cm.lext
#cat ./test/vect.cm.lext
file1=test/class_test.cm
echo "Testing semantic verification and code generation on existing AST ($file1)"
./bin/catmint-gen $file1.ast $file1.sem
