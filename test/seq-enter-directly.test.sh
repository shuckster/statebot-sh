#!/bin/bash
# shellcheck disable=SC1091
source ./assert.sh

TEST_CHART='
  idle -> first -> second -> third -> last
'

on_transitions()
{
  local THEN=""

  case $1 in
    "idle->first")
      THEN="entered_first"
    ;;
    "first->second")
      THEN="entered_second"
    ;;
    "second->third")
      THEN="entered_third"
    ;;
    "third->last")
      THEN="entered_last"
    ;;
  esac

  echo "$THEN"
}

callback_count=0

entered_first() { ((callback_count+=1)); }
entered_second() { ((callback_count+=1)); }
entered_third() { ((callback_count+=1)); }
entered_last() { ((callback_count+=1)); }

# Import Statebot and initialise it
cd "${0%/*}" || exit 255
# shellcheck disable=SC2034
STATEBOT_LOG_LEVEL=0
source ../statebot.sh

statebot_init "seq_enter_directly" "idle" "" "$TEST_CHART"
statebot_reset
assert_eq "$CURRENT_STATE" "idle" "First state is 'idle'"

statebot_enter "first"
assert_eq "$CURRENT_STATE" "first" "->first"

statebot_enter "second"
assert_eq "$CURRENT_STATE" "second" "->second"

statebot_enter "third"
assert_eq "$CURRENT_STATE" "third" "->third"

statebot_enter "last"
assert_eq "$CURRENT_STATE" "last" "->last"
assert_eq "$callback_count" "4" "Expected callbacks to have been run 4 times"

statebot_enter "first"
assert_eq "$CURRENT_STATE" "last" "Tried to enter 'first', should stay on 'last'"
assert_eq "$PREVIOUS_STATE" "third" "Previous state is still 'third'"
assert_eq "$callback_count" "4" "Expected callbacks to have still only been run 4 times"

assert_describe "Can enter directly into states with 'statebot_enter'"
exit $?
