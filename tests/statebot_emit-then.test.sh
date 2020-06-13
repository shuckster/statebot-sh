#!/bin/sh
# shellcheck disable=SC2034,SC1091,SC2039
. ./_assert.sh

TEST_CHART='
  idle -> pending -> (rejected | resolved) -> finished
'

perform_transitions ()
{
  local ON=""; local THEN=""

  case $1 in
    'idle->pending')
      ON="start"
      THEN="statebot_emit okay"
    ;;
    'pending->resolved')
      ON="okay"
      THEN="statebot_emit done"
    ;;
    'rejected->finished'|'resolved->finished')
      ON="done"
    ;;
  esac

  echo ${ON} "${THEN}"
}

on_transitions()
{
  local THEN=""

  if case_statebot "$1" '
    idle -> pending -> (rejected | resolved) -> finished
  '
  then
    THEN="on_entered"
  fi

  echo ${THEN}
}

on_callback_count=0
on_expected_callback_count=3

on_entered() { : $((on_callback_count+=1)); }

# Import Statebot and initialise it
cd "${0%/*}" || exit 255
# shellcheck disable=SC2034
STATEBOT_LOG_LEVEL=0
. ../statebot.sh

statebot_init "statebot_emit-then" "idle" "" "${TEST_CHART}"
statebot_reset
assert_eq "${CURRENT_STATE}" "idle" "First state is 'idle'"

statebot_emit "start"
assert_eq "${CURRENT_STATE}" "finished" \
  "Last state is 'finished'"
assert_eq "${on_callback_count}" "${on_expected_callback_count}" \
  "on_transitions() THEN-callbacks should have run ${on_expected_callback_count} times"

assert_describe "Can 'statebot_emit' from within a THEN-callback"
exit $?
