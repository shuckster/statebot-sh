#!/bin/sh
# shellcheck disable=SC2181,SC1091,SC2039,SC2059
cd "${0%/*}" || exit 255
[ ! -t 1 ] && export DISABLE_COLOUR="true"
. ./_assert.sh

TESTS=$(ls ./*.test.sh)
failing_tests=0

for file in ${TESTS}
do
  printf "${YELLOW}${file}${NOCOLOUR}\n"
  "${file}" "${TEST_ARGS}"
  if [ $? -ne 0 ]
  then
    : $((failing_tests+=1))
  fi
done

if [ "${failing_tests}" -eq 0 ]
then
  echo ":"
printf "| ${PREFIX_ALL_OKAY} All tests passed!\n"
  echo "|_____________________________________________ _ _ _  _  _"
  echo ""
  exit 0
else
  echo ":"
printf "| ${PREFIX_ALL_FAIL} Some tests failed!\n"
  echo "|_____________________________________________ _ _ _  _  _"
  echo ""
  exit "${failing_tests}"
fi
