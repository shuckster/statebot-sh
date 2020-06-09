#!/bin/sh
# shellcheck disable=SC2034,SC2039

if [ "$DISABLE_COLOUR" != "true" ]
then
  NOCOLOUR="\033[0m"
  ORANGE="\033[0;33m"
  RED="\033[1;31m"
  GREEN="\033[1;32m"
  YELLOW="\033[1;33m"
  PURPLE='\033[1;35m'
fi

PREFIX_OKAY="[ ${GREEN}>${NOCOLOUR} ]"
PREFIX_FAIL="[ ${RED}x${NOCOLOUR} ]"
PREFIX_ALL_OKAY="[ ${GREEN}PASSED${NOCOLOUR} ]"
PREFIX_ALL_FAIL="[ ${RED}FAILED${NOCOLOUR} ]"

ONE_ASSERTION_FAILED=0

assert_eq()
{
  if [ "$1" = "$2" ]
  then
    echo "$PREFIX_OKAY $3"
  else
    echo "$PREFIX_FAIL $3"
    echo "      ${RED}- Expected: $2"
    echo "      ${GREEN}+ Saw: $1"
    echo "${NOCOLOUR}"
    ONE_ASSERTION_FAILED=1
  fi
}

assert_ne()
{
  if [ "$1" != "$2" ]
  then
    echo "$PREFIX_OKAY $3"
  else
    echo "$PREFIX_FAIL $3"
    echo "      ${RED}- Expected: $1 to not be equal to $2"
    ONE_ASSERTION_FAILED=1
  fi
}

assert_describe()
{
  if [ "$ONE_ASSERTION_FAILED" = "0" ]
  then
    echo "$PREFIX_ALL_OKAY $1"
    echo ""
    return 0
  else
    echo "$PREFIX_ALL_FAIL $1"
    echo ""
    return 1
  fi
}
