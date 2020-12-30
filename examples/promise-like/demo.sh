#!/bin/sh
# shellcheck disable=SC2034,SC1091,SC2039

STATEBOT_LOG_LEVEL=4
# 0 for silence, 4 for everything

STATEBOT_USE_LOGGER=0
# 1 to use the `logger` command instead of `echo`

PROMISE_CHART='
  idle ->
    // Behaves a bit like a JS Promise
    pending ->
      (rejected | resolved) ->
    idle
'

# Implement a "perform_transitions" function to act on events:
perform_transitions ()
{
  local ON THEN
  ON=""
  THEN=""

  case $1 in
    'idle->pending')
      ON="start"
      THEN="statebot_emit okay persist"
    ;;
    'pending->resolved')
      ON="okay"
      THEN="statebot_emit done"
    ;;
    'rejected->idle'|'resolved->idle')
      ON="done"
    ;;
  esac

  echo $ON "$THEN"
}

# Implement an "on_transitions" function to act on transitions:
on_transitions ()
{
  local THEN
  THEN=""

  case $1 in
    'idle->pending')
      THEN="hello_world"
    ;;
    'rejected->idle'|'resolved->idle')
      THEN="all_finished"
    ;;
  esac

  echo $THEN
}

# Implement any "THEN" functions:
hello_world() { echo "Hello, World!"; }
all_finished() { echo "That was easy!"; }

# Import Statebot
cd "${0%/*}" || exit 255
. ../../statebot.sh
# (^- change the working-directory to where this script is)

statebot_init "demo" "idle" "start" "$PROMISE_CHART"
#   machine name -^     ^      ^           ^
#  1st-run state -------+      |           |
#  1st-run event --------------+           |
# statebot chart --------------------------+

echo      "Current state: $CURRENT_STATE"
echo     "Previous state: $PREVIOUS_STATE"
echo "Last emitted event: $PREVIOUS_EVENT"

if [ "$1" = "" ]; then
  exit
fi

# Allow resetting & emitting-events from the command-line:
if [ "$1" = "reset" ]; then
  statebot_reset
else
  statebot_emit "$1"
fi
