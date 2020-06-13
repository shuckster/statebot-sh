#!/bin/sh
# shellcheck disable=SC2034,SC2039,SC2059

if [ "${DISABLE_COLOUR}" != "true" ]
then
  NOCOLOUR="\e[0m"
  ORANGE="\e[0;33m"
  RED="\e[1;31m"
  GREEN="\e[1;32m"
  YELLOW="\e[1;33m"
  PURPLE='\e[1;35m'
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
    printf "${PREFIX_OKAY} $3\n"
  else
    printf "${PREFIX_FAIL} $3\n"
    printf "      ${RED}- Expected: $2\n"
    printf "      ${GREEN}+ Saw: $1\n"
    printf "${NOCOLOUR}\n"
    ONE_ASSERTION_FAILED=1
  fi
}

assert_ne()
{
  if [ "$1" != "$2" ]
  then
    printf "${PREFIX_OKAY} $3\n"
  else
    printf "${PREFIX_FAIL} $3\n"
    printf "      ${RED}- Expected: $1 to not be equal to $2\n"
    ONE_ASSERTION_FAILED=1
  fi
}

assert_list_eq ()
{
  local source_list test_list description
  source_list=$(echo "$1"|sort)
  test_list=$(echo "$2"|sort)
  description="$3"
  assert_eq "${source_list}" "${test_list}" "${description}"
}

assert_describe()
{
  if [ "${ONE_ASSERTION_FAILED}" = "0" ]
  then
    printf "${PREFIX_ALL_OKAY} $1\n"
    echo ""
    return 0
  else
    printf "${PREFIX_ALL_FAIL} $1\n"
    echo ""
    return 1
  fi
}
