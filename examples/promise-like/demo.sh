#!/bin/sh
# shellcheck disable=SC2034,SC1091,SC2039

STATEBOT_LOG_LEVEL=4
# 0 for silence, 4 for everything

STATEBOT_USE_LOGGER=0
# 1 to use the `logger` command instead of `echo`

# Define the states and allowed transitions:
PROMISE_CHART='

  idle ->
    // Behaves a bit like a JS Promise
    pending ->
      (rejected | resolved) ->
    idle

'

main ()
{
  statebot_init "demo" "idle" "start" "$PROMISE_CHART"
  #   machine name -^     ^      ^           ^
  #  1st-run state -------+      |           |
  #  1st-run event --------------+           |
  # statebot chart --------------------------+

  echo  "Current state: $CURRENT_STATE"
  echo "Previous state: $PREVIOUS_STATE"

  if [ "$1" = "" ]
  then
    exit
  fi

  # Send events/reset signal from the command-line:
  if [ "$1" = "reset" ]
  then
    statebot_reset
  else
    statebot_emit "$1"
  fi
}

#
# Callbacks:
#
hello_world ()
{
  echo "Hello, World!"
  statebot_emit "okay"
}

all_finished () {
  echo "Done and done!"
}

#
# Implement "perform_transitions" to act on events:
#
perform_transitions ()
{
  local ON THEN
  ON=""
  THEN=""

  case $1 in
    'idle->pending')
      ON="start"
      THEN="hello_world"
    ;;
    'pending->resolved')
      ON="okay"
      THEN="statebot_emit done"
    ;;
    'rejected->idle'|'resolved->idle')
      ON="done"
      THEN="all_finished"
    ;;
  esac

  echo $ON "$THEN"
}

#
# Entry point
#
cd "${0%/*}" || exit
# (^- change the directory to where this script is)

# Import Statebot-sh
# shellcheck disable=SC1091
. ../../statebot.sh

main "$1"
