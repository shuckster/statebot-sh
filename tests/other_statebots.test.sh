#!/bin/sh
# shellcheck disable=SC1091
. ./_assert.sh

TEST_CHART='
  idle -> first -> second -> third -> last
'

# Import Statebot and initialise it
cd "${0%/*}" || exit 255
# shellcheck disable=SC2034
STATEBOT_LOG_LEVEL=0
. ../statebot.sh

# Create a few different Statebots. statebot_init shouldn't normally
# be run more than once in a single script. We're just doing it to
# test the following two functions:
#
#  - statebot_current_state_of
#  - statebot_persisted_event_of
#
statebot_init "other_statebot_1" "idle" "" "${TEST_CHART}"
statebot_emit "one" persist

statebot_init "other_statebot_2" "idle" "" "${TEST_CHART}"
statebot_enter "first"
statebot_emit "two" persist

statebot_init "other_statebot_3" "idle" "" "${TEST_CHART}"
statebot_enter "first"
statebot_enter "second"
statebot_emit "three" persist

statebot_init "blank_statebot" "noop" "-" "noop"
statebot_reset

#
# statebot_current_state_of
#
assert_eq "$(statebot_current_state_of other_statebot_1)" "idle" \
  "statebot_current_state_of other_statebot_1 is 'idle'"

assert_eq "$(statebot_current_state_of other_statebot_2)" "first" \
  "statebot_current_state_of other_statebot_2 is 'first'"

assert_eq "$(statebot_current_state_of other_statebot_3)" "second" \
  "statebot_current_state_of other_statebot_3 is 'second'"

#
# statebot_persisted_event_of
#
assert_eq "$(statebot_persisted_event_of other_statebot_1)" "one" \
  "statebot_persisted_event_of other_statebot_1 is 'one'"

assert_eq "$(statebot_persisted_event_of other_statebot_2)" "two" \
  "statebot_persisted_event_of other_statebot_2 is 'two'"

assert_eq "$(statebot_persisted_event_of other_statebot_3)" "three" \
  "statebot_persisted_event_of other_statebot_3 is 'three'"

#
# Cleanup
#
statebot_delete "other_statebot_1"
statebot_delete "other_statebot_2"
statebot_delete "other_statebot_3"
statebot_delete "blank_statebot"

assert_describe "Can get current-state/persisted-event of other Statebots"
exit $?
