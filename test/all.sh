#!/bin/sh
# shellcheck disable=SC2181,SC1091,SC2039
cd "${0%/*}" || exit 255
[ "$SHLVL" = "2" ] && export DISABLE_COLOUR="true"
. ./assert.sh

TESTS=$(ls ./*.test.sh)
failing_tests=0

for file in $TESTS
do
  echo "${YELLOW}$file${NOCOLOUR}"
  "$file" "$TEST_ARGS"
  if [ $? -ne 0 ]
  then
    : $((failing_tests+=1))
  fi
done

if [ "$failing_tests" -eq 0 ]
then
  echo ":"
  echo "| $PREFIX_ALL_OKAY All tests passed!"
  echo "|_____________________________________________ _ _ _  _  _"
  echo ""
  exit 0
else
  echo ":"
  echo "| $PREFIX_ALL_FAIL Some tests failed!"
  echo "|_____________________________________________ _ _ _  _  _"
  echo ""
  exit "$failing_tests"
fi
