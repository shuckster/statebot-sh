#!/bin/bash
# shellcheck disable=SC1091,SC2219
source ./assert.sh

TEST_CHART='
  idle -> first -> second -> third -> last
'

perform_transitions()
{
  local ON=""; local THEN=""

  case $1 in
    "idle->first")
      ON="next"
      THEN="entered_first"
    ;;
    "first->second")
      ON="next"
      THEN="entered_second"
    ;;
    "second->third")
      ON="next"
      THEN="entered_third"
    ;;
    "third->last")
      ON="next"
      THEN="entered_last"
    ;;
  esac

  echo "$ON" "$THEN"
}

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
expected_callback_count=8

entered_first() { let callback_count+=1; }
entered_second() { let callback_count+=1; }
entered_third() { let callback_count+=1; }
entered_last() { let callback_count+=1; }

# Import Statebot and initialise it
cd "${0%/*}" || exit 255
# shellcheck disable=SC2034
STATEBOT_LOG_LEVEL=0
source ../statebot.sh

statebot_init "seq_single_event" "idle" "" "$TEST_CHART"
statebot_reset
assert_eq "$CURRENT_STATE" "idle" "First state is 'idle'"

statebot_emit "next"
assert_eq "$CURRENT_STATE" "first" "Next state is 'first'"

statebot_emit "next"
assert_eq "$CURRENT_STATE" "second" "Next state is 'second'"

statebot_emit "next"
assert_eq "$CURRENT_STATE" "third" "Next state is 'third'"

statebot_emit "next"
assert_eq "$CURRENT_STATE" "last" "Final state is 'last'"
assert_eq "$callback_count" "$expected_callback_count" "THEN-callbacks should have run $expected_callback_count times"

statebot_emit "next"
assert_eq "$CURRENT_STATE" "last" "Final state is still 'last'"
assert_eq "$callback_count" "$expected_callback_count" "THEN-callbacks should still have run $expected_callback_count times"

assert_describe "Can 'statebot_emit' a single common event to move through states"
exit $?
