#!/bin/sh
#rm -f ./test/vect.cm.lext
#echo Testing basic vect.cm on parser and AST generation.
#./bin/catmint-parser ./test/vect.cm ./test/vect.cm.lext
#cat ./test/vect.cm.lext
file1=test/class_test.cm
#echo "Parsing file $file1..."
#../catmint-lex/bin/catmint-parser $file1 $file1.ast
echo "\n\nTesting semantic verification and code generation on existing AST ($file1)"
./bin/catmint-gen $file1.ast $file1.sem

ir="$(basename $file1).ast.ll"
runtime="runtime.ll"
bc="$(basename $file1).bc"
/usr/lib/llvm-10/bin/llvm-link $ir $runtime -o $bc
/usr/lib/llvm-10/bin/lli $bc