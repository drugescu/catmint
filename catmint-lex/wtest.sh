#!/bin/sh
errors=0
tests=0
rm -f ./test_suite/*.ast
for file in ./test_suite/*.cm;
do
  tests=$((tests+1))
  echo "Running test file << $file >>"
  ./bin/catmint-parser $file $file.ast
  echo "Parsed << $file >>"
  DIFF=$(diff $file.ast $file.ref)
  if [ "$DIFF" ]
  then
    echo "[ ERROR ] : unexpected AST output."
    errors=$((errors+1))
  fi
  #cat $file.ast
  echo "-----------------------------------------------------------------"
done

if [ $errors -ne 0 ]
then
  echo "$errors/$tests tests have failed!"
else
  echo "All tests OK."
fi

#rm -f ./test/hellox.cm.ast
#echo Testing basic hellox.cm on parser and AST generation.
#./bin/catmint-parser ./test/hellox.cm ./test/hellox.cm.ast
#cat ./test/hellox.cm.lext
