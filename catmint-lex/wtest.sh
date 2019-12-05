#!/bin/sh

GREEN='\033[1;32m'
RED='\033[1;31m'
YELLOW='\033[1;33m'
WHITE='\033[1;37m'
NC='\033[0m'

errors=0
tests=0

printf "\n\n"
echo "${WHITE}Running the Catmint parser test suite...${NC}"
echo -n "Removing all AST files from test_suite..."
rm -f ./test_suite/*.ast
rm -f ./test_suite/*.errlog.txt
echo " done."
echo "Iterating through tests..."
echo "----------------------------------------------------------------------"
for file in ./test_suite/*.cm;
do
  tests=$((tests+1))
  echo "Running test file << ${YELLOW}$file${NC} >>"
  ./bin/catmint-parser $file $file.ast
  echo "Parsed << $file >>"
  
  # Test if reference file exists
  if [ -f "$file.ref" ]; then
  
    DIFF=$(diff $file.ast $file.ref)
    if [ "$DIFF" ]
    then
      echo "[ ${RED}ERROR${NC} ] : unexpected AST output! Consult << $file.errlog.txt >>"
      errors=$((errors+1))
      echo "$DIFF" > $file.errlog.txt
    else
      printf "[ ${GREEN}OK${NC} ] Output matches reference output.\n"
    fi
  
  else
    echo "[ ${RED}ERROR${NC} ] : reference AST output does not exist!"
    errors=$((errors+1))
  fi
  # cat $file.ast
  echo "----------------------------------------------------------------------"
done

if [ $errors -ne 0 ]
then
  echo "[ ${RED}ERROR${NC} ] : $errors/$tests tests have failed!"
else
  echo "\n[ ${GREEN}OK${NC} ] All $tests tests passed.\n"
fi

#rm -f ./test/hellox.cm.ast
#echo Testing basic hellox.cm on parser and AST generation.
#./bin/catmint-parser ./test/hellox.cm ./test/hellox.cm.ast
#cat ./test/hellox.cm.lext
