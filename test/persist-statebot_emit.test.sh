#!/bin/sh
# shellcheck disable=SC1091,SC2219
. ./assert.sh

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

  echo $ON $THEN
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

  echo $THEN
}

callback_count=0
expected_callback_count=8

entered_first() { : $((callback_count+=1)); }
entered_second() { : $((callback_count+=1)); }
entered_third() { : $((callback_count+=1)); }
entered_last() { : $((callback_count+=1)); }

# Import Statebot and initialise it
cd "${0%/*}" || exit 255
# shellcheck disable=SC2034
STATEBOT_LOG_LEVEL=0
. ../statebot.sh

sb_init ()
{
  statebot_init "persist_statebot_emit" "idle" "" "$TEST_CHART"
}

sb_init
statebot_reset
assert_eq "$CURRENT_STATE" "idle" "First state is 'idle'"

statebot_emit "next" persist
assert_eq "$CURRENT_STATE" "idle" "First state is still 'idle'"

sb_init
assert_eq "$CURRENT_STATE" "first" "Persisted event emitted on init: we should be in 'first' now"

statebot_emit "next" persist
assert_eq "$CURRENT_STATE" "first" "Should still be in 'first' after second persisted emit"

sb_init
assert_eq "$CURRENT_STATE" "second" "Persisted event emitted on init: we should be in 'second' now"

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