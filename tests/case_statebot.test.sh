#!/bin/sh
# shellcheck disable=SC1091,SC2219,SC2039
. ./_assert.sh

TEST_CHART='
  idle -> first -> second -> third -> last
'

on_transitions()
{
  local THEN
  THEN=""

  if case_statebot "$1" '
    idle ->
      first ->
      second ->
      third
  '
  then
    THEN="entered_first_second_third"
  fi

  if case_statebot "$1" '
    third -> last
  '
  then
    THEN="entered_last"
  fi

  echo ${THEN}
}

callback_count=0
expected_callback_count=4

entered_first_second_third() { : $((callback_count+=1)); }
entered_last() { : $((callback_count+=1)); }

# Import Statebot and initialise it
cd "${0%/*}" || exit 255
# shellcheck disable=SC2034
STATEBOT_LOG_LEVEL=0
. ../statebot.sh

statebot_init "case_statebot" "idle" "" "${TEST_CHART}"
statebot_reset
assert_eq "${CURRENT_STATE}" "idle" \
  "First state is 'idle'"

statebot_enter "first"
assert_eq "${CURRENT_STATE}" "first" "idle->first"

statebot_enter "second"
assert_eq "${CURRENT_STATE}" "second" "first->second"

statebot_enter "third"
assert_eq "${CURRENT_STATE}" "third" "second->third"

statebot_enter "last"
assert_eq "${CURRENT_STATE}" "last" "third->last"
assert_eq "${callback_count}" "${expected_callback_count}" \
  "THEN-callbacks should have run ${expected_callback_count} times"

statebot_enter "last"
assert_eq "${callback_count}" "${expected_callback_count}" \
  "THEN-callbacks should still have run ${expected_callback_count} times"

statebot_enter "first"
assert_eq "${CURRENT_STATE}" "last" \
  "Tried to enter 'first', should stay on 'last'"
assert_eq "${PREVIOUS_STATE}" "third" \
  "Previous state is still 'third'"
assert_eq "${callback_count}" "${expected_callback_count}" \
  "THEN-callbacks should still really have run ${expected_callback_count} times"

#
# Cleanup
#
statebot_delete "case_statebot"

assert_describe "'case_statebot' does the right thing"
exit $?
