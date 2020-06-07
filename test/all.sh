#!/bin/bash
# shellcheck disable=SC2181,SC1091
cd "${0%/*}" || exit 255
source ./assert.sh

TESTS=$(ls ./*.test.sh)

failing_tests=0

for file in $TESTS
do
  "$file"
  if [[ $? -ne 0 ]]
  then
    ((failing_tests+=1))
  fi
done

if [[ $failing_tests -eq 0 ]]
then
  echo -e "|"
  echo -e "| $PREFIX_ALL_OKAY All tests passed!"
  echo -e "|_____________________________________________ _ _ _  _  _"
  echo ""
  exit 0
else
  echo -e "|"
  echo -e "| $PREFIX_ALL_FAIL Some tests failed!"
  echo -e "|_____________________________________________ _ _ _  _  _"
  echo ""
  exit "$failing_tests"
fi
