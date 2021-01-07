#!/bin/sh
# shellcheck disable=SC1091,SC2219,SC2039
. ./_assert.sh

TEST_CHART='
  idle -> first -> second -> third -> last
'

perform_transitions()
{
  local ON THEN
  ON=""
  THEN=""

  case $1 in
    "idle->first")
      ON="next"
      THEN="perf_entered_first"
    ;;
    "first->second")
      ON="next"
      THEN="perf_entered_second"
    ;;
    "second->third")
      ON="next"
      THEN="perf_entered_third"
    ;;
    "third->last")
      ON="next"
      THEN="perf_entered_last"
    ;;
  esac

  echo ${ON} ${THEN}
}

on_transitions()
{
  local THEN
  THEN=""

  case $1 in
    "idle->first")
      THEN="on_entered_first"
    ;;
    "first->second")
      THEN="on_entered_second"
    ;;
    "second->third")
      THEN="on_entered_third"
    ;;
    "third->last")
      THEN="on_entered_last"
    ;;
  esac

  echo ${THEN}
}

perf_callback_count=0
perf_expected_callback_count=4
on_callback_count=0
on_expected_callback_count=4

perf_entered_first() { : $((perf_callback_count+=1)); }
perf_entered_second() { : $((perf_callback_count+=1)); }
perf_entered_third() { : $((perf_callback_count+=1)); }
perf_entered_last() { : $((perf_callback_count+=1)); }

on_entered_first() { : $((on_callback_count+=1)); }
on_entered_second() { : $((on_callback_count+=1)); }
on_entered_third() { : $((on_callback_count+=1)); }
on_entered_last() { : $((on_callback_count+=1)); }

# Import Statebot and initialise it
cd "${0%/*}" || exit 255
# shellcheck disable=SC2034
STATEBOT_LOG_LEVEL=0
. ../statebot.sh

sb_init ()
{
  statebot_init "statebot_emit-persist" "idle" "" "${TEST_CHART}"
}

sb_init
statebot_reset
assert_eq "${CURRENT_STATE}" "idle" \
  "First state is 'idle'"

statebot_emit "next" persist
assert_eq "${CURRENT_STATE}" "idle" \
  "First state is still 'idle'"

sb_init
assert_eq "${CURRENT_STATE}" "first" \
  "Persisted event emitted on init: we should be in 'first' now"

statebot_emit "next" persist
assert_eq "${CURRENT_STATE}" "first" \
  "Should still be in 'first' after second persisted emit"

sb_init
assert_eq "${CURRENT_STATE}" "second" \
  "Persisted event emitted on init: we should be in 'second' now"

statebot_emit "next"
assert_eq "${CURRENT_STATE}" "third" \
  "Next state is 'third'"

statebot_emit "next"
assert_eq "${CURRENT_STATE}" "last" \
  "Final state is 'last'"
assert_eq "${perf_callback_count}" "${perf_expected_callback_count}" \
  "perform_transitions() THEN-callbacks should have run ${perf_expected_callback_count} times"
assert_eq "${on_callback_count}" "${on_expected_callback_count}" \
  "on_transitions() THEN-callbacks should have run ${on_expected_callback_count} times"

statebot_emit "next"
assert_eq "${CURRENT_STATE}" "last" \
  "Final state is still 'last'"
assert_eq "${perf_callback_count}" "${perf_expected_callback_count}" \
  "perform_transitions() THEN-callbacks should still have run ${perf_expected_callback_count} times"
assert_eq "${on_callback_count}" "${on_expected_callback_count}" \
  "on_transitions() THEN-callbacks should still have run ${on_expected_callback_count} times"

#
# Cleanup
#
statebot_delete "statebot_emit-persist"

assert_describe "Can 'statebot_emit' a single common event to move through states"
exit $?
