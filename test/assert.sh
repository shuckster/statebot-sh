#!/bin/bash

NOCOLOUR="\033[0m"
ORANGE="\033[0;33m"
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
PURPLE='\033[1;35m'

PREFIX_OKAY="[ ${GREEN}>${NOCOLOUR} ]"
PREFIX_FAIL="[ ${RED}x${NOCOLOUR} ]"
PREFIX_ALL_OKAY="[ ${GREEN}PASSED${NOCOLOUR} ]"
PREFIX_ALL_FAIL="[ ${RED}FAILED${NOCOLOUR} ]"

ONE_ASSERTION_FAILED=0

assert_eq()
{
  if [[ "$1" == "$2" ]]
  then
    echo -e "$PREFIX_OKAY $3"
  else
    echo -e "$PREFIX_FAIL $3"
    ONE_ASSERTION_FAILED=1
  fi
}

assert_ne()
{
  if [[ "$1" != "$2" ]]
  then
    echo -e "$PREFIX_OKAY $3"
  else
    echo -e "$PREFIX_FAIL $3"
    ONE_ASSERTION_FAILED=1
  fi
}

assert_describe()
{
  if [[ "$ONE_ASSERTION_FAILED" == "0" ]]
  then
    echo -e "$PREFIX_ALL_OKAY $1"
    echo ":"
    return 0
  else
    echo -e "$PREFIX_ALL_FAIL $1"
    echo ":"
    return 1
  fi
}
