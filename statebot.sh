#!/bin/sh
# shellcheck disable=SC2039

__STATEBOT_INFO__=':
|
| STATEBOT-SH 2.3.1
| - Write more robust and understandable programs.
|
| Github repo w/ example usage:
| - https://github.com/shuckster/statebot-sh
|
| Statebot runs in Node and the browser, too:
| - https://github.com/shuckster/statebot
|
|
| Written by Conan Theobald and MIT licensed.
|_____________________________________________ _ _ _  _  _
'

# shellcheck disable=SC2016
__STATEBOT_EXAMPLE__='
A basic implementation:
-----------------------

  #!/bin/sh
  STATEBOT_LOG_LEVEL=4
  # 0 for silence, 4 for everything

  STATEBOT_USE_LOGGER=0
  # 1 to use the `logger` command instead of `echo`

  PROMISE_CHART="

    idle ->
      // Behaves a bit like a JS Promise
      pending ->
        (rejected | resolved) ->
      idle

  "

  # Implement a "perform_transitions" function to act on events:
  perform_transitions ()
  {
    local ON THEN
    ON=""
    THEN=""

    case $1 in
      "idle->pending")
        ON="start"
        THEN="statebot_emit okay persist"
      ;;
      "pending->resolved")
        ON="okay"
        THEN="statebot_emit done"
      ;;
      "rejected->idle"|"resolved->idle")
        ON="done"
      ;;
    esac

    echo $ON $THEN
  }

  # Implement an "on_transitions" function to act on transitions:
  on_transitions ()
  {
    local THEN
    THEN=""

    case $1 in
      "idle->pending")
        THEN="echo Hello, World!"
      ;;
      "rejected->idle"|"resolved->idle")
        THEN="all_finished"
      ;;
    esac

    echo $THEN
  }

  # Implement any "THEN" functions:
  all_finished() { echo "That was easy!"; }

  # Import Statebot and initialise it
  cd "${0%/*}" || exit
  # (^- this changes the working-dir to the script-dir)
  . ./statebot.sh

  statebot_init "demo" "idle" "start" "$PROMISE_CHART"

  if [ "$1" = "" ]
  then
    exit
  fi

  # For this demo, allow emitting events from the command-line:
  if [ "$1" = "reset" ]
  then
    statebot_reset
  else
    statebot_emit "$1"
  fi

# Copy all this to a script and run it a few times
# to see what happens. :)

'

# shellcheck disable=SC2016
__STATEBOT_API__='
The Statebot-sh API:
--------------------

  statebot_inspect "$YOUR_CHART"
    #
    # When developing your charts, it is useful
    # to see the transitions they represent so
    # you can copy-paste into your perform/
    # on_transitions() functions.
    #
    # Use statebot_inspect() to give you this
    # information, and the states too.

  statebot_init "example" "idle" "start" "idle -> done"
    #                 ^      ^     ^         ^
    #   machine name -|      |     |         |
    #  1st-run state --------+     |         |
    #  1st-run event --------------+         |
    # statebot chart ------------------------+
    #
    # If your machine does not yet have an
    # entry in the CSV database, this will
    # initialise it with the values passed-in.
    #
    # If the machine already exists, then the
    # values in the DB will be used from this
    # point onwards.
    #
    # Only one machine is allowed per script,
    # so do not call this more than once in
    # order to try and have multiple state-
    # machines in the same script! It is easy
    # to use Statebot in many different and
    # independent scripts.
    #
    # (Charts are not stored in the DB, and
    # are specified as the last argument
    # in order to enforce setting defaults
    # for the initial state/event too.)

  statebot_emit "start" persist
    #              ^       ^
    # event name --+       |
    #                      |
    # Store this event ----+ (optional)
    # for a future run instead of calling it
    # immediately.
    #
    # When you run your script again later, the
    # event will be picked-up by the call to
    # statebot_init().

  statebot_enter "pending"
    #                ^
    #   state name --+
    #
    # Changes to the specified state, if allowed
    # by the rules in the state-chart.

  statebot_reset
    #
    # Reset the machine to its 1st-run state
    # & event. No events will be emitted.

  statebot_states_available_from_here
    #
    # List the states available from the
    # current-state.

  # Details about the current machine:
  echo "     Current state: $CURRENT_STATE"
  echo "    Previous state: $PREVIOUS_STATE"
  echo "Last emitted event: $PREVIOUS_EVENT"

'

#
# "Private" globals
#
__STATEBOT_LOG_LEVEL__=4
__STATEBOT_DB__="/tmp/statebots.csv"
__STATEBOT_INITIAL_STATE__=""
__STATEBOT_INITIAL_EVENT__=""
__STATEBOT_AFTER_EVENT__=""
__STATEBOT_AFTER_TRANSITION__=""
__STATEBOT_HANDLING_EVENT__=0
__STATEBOT_THEN_STACK_SIZE__=0
__STATEBOT_EVENT_COUNT=0
__STATEBOT_RC__="${HOME}/.statebot-rc"

#
# Command-line usage
#
if echo "$0"|grep -q -e '/statebot\.sh$'
then
  echo "${__STATEBOT_INFO__}"

  if [ "$1" != "--example" ] && [ "$1" != "--help" ]
  then
    echo "See an example with: ./statebot.sh --example"
  else
    echo "${__STATEBOT_EXAMPLE__}"
  fi

  if [ "$1" != "--api" ] && [ "$1" != "--help" ]
  then
    echo "See the API: ./statebot.sh --api"
  else
    echo "${__STATEBOT_API__}"
  fi

  if [ "$1" != "--db" ]
  then
    echo "See the status of all your machines: ./statebot.sh --db"
  else
    echo ""
    echo "Here's the content of ${__STATEBOT_DB__}:"
    cat "${__STATEBOT_DB__}"
  fi

  echo ""
  exit 1
fi

#
# "Public" globals
#
STATEBOT_NAME=""
STATEBOT_CHART=""
STATEBOT_VALID_STATES=""
STATEBOT_VALID_TRANSITIONS=""

CURRENT_STATE=""
PREVIOUS_STATE=""
PREVIOUS_EVENT=""

#
# By default, Statebot keeps track of your machines in a CSV:
#
# - /tmp/statebots.csv
#
# Change it using the variable STATEBOT_DB before importing
# Statebot into your script:
#
if [ "${STATEBOT_DB}" != "" ]
then
  __STATEBOT_DB__=${STATEBOT_DB}
fi

#
# The log-level can be changed using STATEBOT_LOG_LEVEL. Again,
# do this before importing Statebot into your script.
#
if [ "${STATEBOT_LOG_LEVEL}" != "" ]
then
  __STATEBOT_LOG_LEVEL__=${STATEBOT_LOG_LEVEL}
fi

#
# LOGGING
#

logit ()
{
  local msg

  msg="${*}"

  if [ ${__STATEBOT_HANDLING_EVENT__} -eq 1 ]
  then
    msg=$(echo "${msg}"|sed "s/<eId> */<eId:${__STATEBOT_EVENT_COUNT}> /")
  else
    msg=$(echo "${msg}"|sed 's/<eId> *//')
  fi

  if [ "${STATEBOT_USE_LOGGER}" = "1" ]
  then
    msg=$(echo "${msg}"|sed 's/^-/=/')
    logger -s -t "statebot" "${msg}"
  else
    echo "${msg}"
  fi
}

info ()
{
  [ "${__STATEBOT_LOG_LEVEL__}" -ge 4 ] && logit "INFO: ${*}"
}

log ()
{
  [ "${__STATEBOT_LOG_LEVEL__}" -ge 3 ] && logit "${*}"
}

warn ()
{
  [ "${__STATEBOT_LOG_LEVEL__}" -ge 2 ] && logit "WARN: ${*}"
}

error ()
{
  [ "${__STATEBOT_LOG_LEVEL__}" -ge 1 ] && logit "ERR!: ${*}"
}

#
# CHART PARSING
#

#
# Take a chart and decompose it into its individual transitions.
#
decompose_chart ()
{
  echo "${@}"|awk '
    BEGIN {
      condensed_line_count = 0
      rxLineContinuations = "(->|\\|)$"
      rxDisallowedCharacters = "[^a-z0-9!@#$%^&*:_+=<>|~.\x2D]"
      decomposed_line_count = 0
    }

    {
      line = $0
      line_wo_comment = remove_comment(line)
      line_sanitised = line_wo_comment
      gsub(rxDisallowedCharacters, "", line_sanitised)

      if ( line_sanitised != "" ) {
        if ( line_sanitised ~ rxLineContinuations ) {
          condensed_line = condensed_line "" line_sanitised
        } else {
          condensed_line_count += 1
          condensed_lines[condensed_line_count] = condensed_line "" line_sanitised
          condensed_line = ""
        }
      }
    }

    function remove_comment(line) {
      rxComment = "(\/\/[^\n\r]*)"
      sub(rxComment, "", line)
      return line
    }

    function decompose_line_into_route(line) {
      split_len = split(line, array, "->");
      line = ""

      for (split_idx = 1; split_idx <= split_len; split_idx++) {
        node = array[split_idx]

        if (split_idx != 1) {
          decomposed_line_count += 1
          decomposed_lines[decomposed_line_count] = previous_states "->" node
        }

        previous_states = node
      }
    }

    function decompose_route_into_transition(line) {
      split(line, nodes, "->");
      from_count = split(nodes[1], from_states, "|");
      to_count = split(nodes[2], to_states, "|");

      for (from_idx = 1; from_idx <= from_count; from_idx++ ) {
        for (to_idx = 1; to_idx <= to_count; to_idx++ ) {
          # Technique to remove duplicates and keep sort-order: 1/3
          route = from_states[from_idx] "->" to_states[to_idx]
          if (!transitions[route]) {
            transitions[route] = transitions_line_count++
          }
        }
      }
    }

    END {
      for (cnd_idx = 1; cnd_idx <= condensed_line_count; cnd_idx++) {
        condensed_line = condensed_lines[cnd_idx]
        decompose_line_into_route(condensed_line)
      }

      for (dcmp_idx = 1; dcmp_idx <= decomposed_line_count; dcmp_idx++) {
        decompose_route_into_transition(decomposed_lines[dcmp_idx])
      }

      # De-dupe + sort: 2/3
      for (trn_idx in transitions) {
        out[transitions[trn_idx]] = trn_idx
      }

      # De-dupe + sort: 3/3
      for (trn_idx = 0; trn_idx < transitions_line_count; trn_idx++) {
        print out[trn_idx]
      }
    }
  '
}

#
# Take a single chart-line and reduce it into its individual states.
#
decompose_transitions ()
{
  echo "${@}"|awk '
    {
      len = split($0,states,"->");
      # Technique to remove duplicates and keep sort-order: 1/3
      for (i = 1; i <= len; i++ ) {
        state = states[i]
        if (!data[state]) {
          data[state] = count++
        }
      }
    }
    END {
      # De-dupe + sort: 2/3
      for (i in data) {
        out[data[i]] = i
      }
      # De-dupe + sort: 3/3
      for (i = 0; i < count; i++) {
        if (out[i]) {
          print out[i]
        }
      }
    }
  '
}

#
# We use a stack to store the THEN="" commands. This allows us to
# specify statebot_emit() and statebot_enter() as THEN's.
#
# Since no arrays are allowed in sh, we use a fake one.
#
__statebot_then_stack_push ()
{
  local array_item

  : $((__STATEBOT_THEN_STACK_SIZE__+=1))
  array_item="__STATEBOT_THEN_FN_${__STATEBOT_THEN_STACK_SIZE__}"
  eval "${array_item}"='$@'
}

__statebot_then_stack_peek ()
{
  local array_item next_then

  array_item="__STATEBOT_THEN_FN_${__STATEBOT_THEN_STACK_SIZE__}"
  # shell-check disable=SC2140
  eval "next_then"='"$'"${array_item}"'"'
  echo "${next_then}"
}

__statebot_then_stack_clear_topmost ()
{
  local array_item

  array_item="__STATEBOT_THEN_FN_${__STATEBOT_THEN_STACK_SIZE__}"
  eval "${array_item}"=''
}

__statebot_run_then_stack ()
{
  if [ "${__STATEBOT_THEN_STACK_SIZE__}" -eq 0 ]
  then
    return 1
  fi

  local next_then

  while [ "${__STATEBOT_THEN_STACK_SIZE__}" -gt 0 ]
  do
    next_then="$(__statebot_then_stack_peek)"
    __statebot_then_stack_clear_topmost
    : $((__STATEBOT_THEN_STACK_SIZE__-=1))

    if ! ${next_then}
    then
      warn "<eId> Problem running THEN function: ${next_then}"
    fi
  done
}

#
# Transitions available from the current-state.
#
__statebot_transitions_available_from_here ()
{
  local transition

  for transition in ${STATEBOT_VALID_TRANSITIONS}
  do
    if ! echo "${transition}"|grep -q "^${CURRENT_STATE}->[^$]*"
    then
      continue
    fi
    echo "${transition}"
  done
}

#
# Bail-out of various functions if Statebot has not
# been initialised.
#
__statebot_bail ()
{
  error "<eId>: ${*}"
  error "Run the statebot.sh script for help"
  echo ""
}

#
# Looks at the last performed transition and invokes any handlers.
#
# Handlers are defined inside a user-defined on_transitions() function.
#
__statebot_get_handler_for_transition ()
{
  local test_transition last_transition THEN

  __STATEBOT_AFTER_TRANSITION__=""
  test_transition="$1"
  last_transition="${PREVIOUS_STATE}->${CURRENT_STATE}"

  if [ "${test_transition}" != "${last_transition}" ]
  then
    warn "Not handling invalid transition: ${test_transition}"
    return 1
  fi

  if ! type 'on_transitions' 2>&1|grep -q 'function'
  then
    info "<eId> on_transitions() undefined: Skipping transition handlers"
    return 1
  fi

  # Process user-defined on_transitions() ...
  info "<eId> Handling transition: ${last_transition}"
  THEN=$(on_transitions "${last_transition}")
  if [ "${THEN}" != "" ]
  then
    __STATEBOT_AFTER_TRANSITION__="${THEN}"
  fi

  return 0
}

#
# Takes an event and changes to the next state if available.
#
# If perform_transitions() returns a "THEN" command, then the global
# variable __STATEBOT_AFTER_EVENT__ will be set and statebot_emit()
# will run it.
#
__statebot_change_state_for_event_and_get_handler ()
{
  if ! type 'perform_transitions' 2>&1|grep -q 'function'
  then
    info "<eId> perform_transitions() undefined: Skipping event handlers"
    return 1
  fi

  if [ "$1" = "" ]
  then
    __statebot_bail "No event to process!"
    return 1
  fi

  local state_changed on_then on

  __STATEBOT_AFTER_EVENT__=""
  previous_event="$1"
  state_changed=0

  # Process user-defined perform_transitions() ...
  for transition in $(__statebot_transitions_available_from_here)
  do
    on_then=$(perform_transitions "${transition}")
    on=$(echo "${on_then}"|awk '{ print $1 }')

    if [ "${previous_event}" != "${on}" ]
    then
      continue
    fi

    info "<eId> Changing state: ${transition}"
    PREVIOUS_STATE="${CURRENT_STATE}"
    CURRENT_STATE=$(echo "${transition}"|awk 'BEGIN { FS="->" } { print $2 }')
    __STATEBOT_AFTER_EVENT__=$(echo "${on_then}"|awk '{ $1=""; sub(/^ */, "", $0); print }')
    state_changed=1
    break
  done

  return ${state_changed}
}

#
# Shows information about the current machine.
#
__statebot_info ()
{
  if [ "${__STATEBOT_INITIALISED__}" -eq 0 ]
  then
    __statebot_bail "Statebot not initialised"
    return 1
  fi

  log ". : "
  log "| |  Statebot :: ${STATEBOT_NAME}"
  log "| |  Current state: [${CURRENT_STATE}]"

  if [ "${PREVIOUS_EVENT}" != "" ]
  then
    log "| :  Event pending: ${PREVIOUS_EVENT}"
  fi

  log "|_|________________________________________ _ _ _  _  _ "
  log ""
}

#
# "PUBLIC" API
#

#
# See the all the transitions + states of a chart before
# committing to initialising it.
#
# Helps with writing the perform_transitions() and
# on_transitions() functions for your script.
#
#   statebot_inspect '
#     pending -> resolved | rejected -> done
#   '
#
statebot_inspect ()
{
  local chart transitions states

  chart="$1"
  transitions=$(decompose_chart "${chart}")
  states=$(decompose_transitions "${transitions}")

  log ""
  log "Chart:"
  log "---"
  log "${chart}"
  log ""
  log "Transitions:"
  log "---"
  log "${transitions}"
  log ""
  log "States:"
  log "---"
  log "${states}"
  log ""
}

#
# Initialise a Statebot:
#
#   statebot_init "name" "starting-state" "starting-event" '
#     // Statebot chart
#     pending -> resolved | rejected -> done
#   '
#
statebot_init ()
{
  local RETURN

  __statebot_init "$@"; RETURN=$?
  __statebot_run_then_stack
  return ${RETURN}
}
__statebot_init ()
{
  local name db_entry

  # These are only used if the current machine does not exist in the DB
  __STATEBOT_INITIAL_STATE__="$2"
  __STATEBOT_INITIAL_EVENT__="$3"

  # Check for DB
  if [ ! -f "${__STATEBOT_DB__}" ]
  then
    info "Creating DB: ${__STATEBOT_DB__}"
    touch "${__STATEBOT_DB__}"
  fi

  # Check for DB record, set initial values
  name="$1"
  if ! grep -q "^${name}," "${__STATEBOT_DB__}"
  then
    info "No record of this machine, creating..."
    echo "${name},${__STATEBOT_INITIAL_STATE__},${__STATEBOT_INITIAL_EVENT__}" >> "${__STATEBOT_DB__}"
  fi

  # Set current machine name/state/event
  STATEBOT_NAME=${name}
  db_entry=$(grep "^${name}," "${__STATEBOT_DB__}")
  CURRENT_STATE=$(echo "${db_entry}"|awk 'BEGIN { FS="," } { print $2 }')
  PREVIOUS_EVENT=$(echo "${db_entry}"|awk 'BEGIN { FS="," } { print $3 }')
  STATEBOT_CHART="$4"

  # Parse the chart
  STATEBOT_VALID_TRANSITIONS=$(decompose_chart "${STATEBOT_CHART}")
  # shellcheck disable=SC2034
  STATEBOT_VALID_STATES=$(decompose_transitions "${STATEBOT_VALID_TRANSITIONS}")

  # Load ~/.statebot-rc if it exists
  if [ -f "${__STATEBOT_RC__}" ]
  then
    # shellcheck disable=1090
    . "${__STATEBOT_RC__}"
  fi

  # We're initialised at this point
  __STATEBOT_INITIALISED__=1

  # Info + initial event, if we have one
  __statebot_info
  statebot_emit "${PREVIOUS_EVENT}" "__first-run__"
}

#
# Emit an event to the current machine:
#
#   statebot_emit "event-name"
#
statebot_emit ()
{
  local RETURN

  __statebot_emit "$@"; RETURN=$?
  __statebot_run_then_stack
  return ${RETURN}
}
__statebot_emit ()
{
  if [ ${__STATEBOT_INITIALISED__} -eq 0 ]
  then
    __statebot_bail "Statebot not initialised"
    return 1
  fi
  if [ "$1" = "" ]
  then
    if [ "$2" != "__first-run__" ]
    then
      __statebot_bail "No event to process"
    fi
    return 1
  fi

  local __previous_state emitted_event
  local persist_option persist_event
  local event_handled state_changed
  local name state event db

  __STATEBOT_HANDLING_EVENT__=1
  __previous_state="${CURRENT_STATE}"
  emitted_event="$1"
  persist_option="$2"

  __STATEBOT_AFTER_EVENT__=""
  __STATEBOT_AFTER_TRANSITION__=""

  : $((__STATEBOT_EVENT_COUNT+=1))
  info "<eId> Handling event: ${emitted_event}, from state [${CURRENT_STATE}]"

  # Persist event for another run, or execute it immediately?
  persist_event=""
  event_handled=0
  state_changed=0

  if [ "${persist_option}" = "persist" ]
  then
    info "<eId> Peristing event instead of emitting it"
    persist_event="${emitted_event}"
    PREVIOUS_EVENT=""
    event_handled=1
  else
    __statebot_change_state_for_event_and_get_handler "${emitted_event}"
    state_changed=$?
    if [ ${state_changed} -eq 1 ]
    then
      event_handled=1
    fi
  fi

  if [ ${event_handled} -eq 0 ]
  then
    info "<eId> Nothing happened"
  fi

  # Persist the current state
  name="${STATEBOT_NAME}"
  state="${CURRENT_STATE}"
  event="${persist_event}"
  db=$(sed -e "s/^${name},.*/${name},${state},${event}/" "${__STATEBOT_DB__}")
  echo "${db}" > "${__STATEBOT_DB__}"

  if [ ${state_changed} -eq 1 ]
  then
    # Handle perform_transitions() THEN="..."
    if [ "${__STATEBOT_AFTER_EVENT__}" != "" ]
    then
      __statebot_then_stack_push "${__STATEBOT_AFTER_EVENT__}"
    fi

    # Handle on_transitions() THEN="..."
    __statebot_get_handler_for_transition "${__previous_state}->${CURRENT_STATE}"
    if [ "${__STATEBOT_AFTER_TRANSITION__}" != "" ]
    then
      __statebot_then_stack_push "${__STATEBOT_AFTER_TRANSITION__}"
      __STATEBOT_AFTER_TRANSITION__=""
    fi
  fi

  __STATEBOT_HANDLING_EVENT__=0
  if [ ${event_handled} -eq 1 ]
  then
    return 0
  else
    return 1
  fi
}

#
# Enter a new state, so long as it is allowed from the current-state:
#
#   statebot_enter "state-name"
#
statebot_enter ()
{
  local RETURN

  __statebot_enter "$@"; RETURN=$?
  __statebot_run_then_stack
  return ${RETURN}
}
__statebot_enter ()
{
  if [ $__STATEBOT_INITIALISED__ -eq 0 ]
  then
    __statebot_bail "Statebot not initialised"
    return 1
  fi

  local next_state state_changed name state event db

  next_state="$1"
  state_changed=0

  if [ "${CURRENT_STATE}" = "${next_state}" ]
  then
    info "<eId> Not changing state, already in: ${next_state}"
    return 1
  fi

  for state in $(statebot_states_available_from_here)
  do
    if [ "${state}" != "${next_state}" ]
    then
      continue
    fi

    # Found the next valid state
    info "<eId> Changing state to: ${next_state}"
    __previous_state="${CURRENT_STATE}"
    CURRENT_STATE="${next_state}"

    # Persist the current state, clear the current event too
    name="${STATEBOT_NAME}"
    state="${CURRENT_STATE}"
    event=""
    db=$(sed -e "s/^${name},.*/${name},${state},${event}/" "${__STATEBOT_DB__}")
    echo "${db}" > "${__STATEBOT_DB__}"

    state_changed=1
    break
  done

  if [ ${state_changed} -eq 1 ]
  then
    PREVIOUS_STATE="${__previous_state}"
    __statebot_get_handler_for_transition "${PREVIOUS_STATE}->${CURRENT_STATE}"
  else
    info "<eId> Invalid transition: ${CURRENT_STATE}->${next_state}, not switching"
  fi

  # Handle on_transitions() THEN="..."
  if [ "${__STATEBOT_AFTER_TRANSITION__}" != "" ]
  then
    __statebot_then_stack_push "${__STATEBOT_AFTER_TRANSITION__}"
    __STATEBOT_AFTER_TRANSITION__=""
  fi

  if [ ${state_changed} -eq 1 ]
  then
    return 0
  else
    return 1
  fi
}

#
# Reset the machine to the initial-state & event.
# No events will be emitted.
#
#   statebot_reset
#
statebot_reset ()
{
  if [ ${__STATEBOT_INITIALISED__} -eq 0 ]
  then
    __statebot_bail "Statebot not initialised"
    return 1
  fi

  warn "<eId> Resetting machine!"

  local name state event db

  # Persist the current state
  name="${STATEBOT_NAME}"
  state="${__STATEBOT_INITIAL_STATE__}"
  event="${__STATEBOT_INITIAL_EVENT__}"
  db=$(sed -e "s/^${name},.*/${name},${state},${event}/" "${__STATEBOT_DB__}")
  echo "${db}" > "${__STATEBOT_DB__}"

  PREVIOUS_STATE=""
  CURRENT_STATE="${state}"
  PREVIOUS_EVENT="${event}"
}

#
# Output the states available from the current-state
#
#   AVAILABLE_STATES="$(statebot_states_available_from_here)"
#
statebot_states_available_from_here()
{
  __statebot_transitions_available_from_here|awk '
    BEGIN { FS="->" } { print $2 }
  '
}

#
# case_statebot() Asserts that a particular transition
# matches against the specified rules.
#
# Might be useful if your case-statements get out of
# hand in perform_transitions() and/or on_transitions(),
# but generally I'd recommend avoiding using it.
#
# If you must, use it like this:
#
# perform_transitions () {
#   local ON=""; local THEN=""
#   case $1 in
#     # Handle your "simple" transitions first:
#     "idle->pending")
#       ON="start"
#       THEN="statebot_emit okay"
#     ;;
#     *)
#       # Now in the wildcard section, use
#       # case_statebot() for your complex
#       # rules:
#       if case_statebot $1 "
#         rejected | resolved -> idle
#       "
#       then
#         ON="done"
#       fi
#     ;;
#   esac
#   echo $ON $THEN
# }
case_statebot ()
{
  local match transition

  match="$1"
  for transition in $(decompose_chart "$2")
  do
    if [ "${transition}" = "${match}" ]
    then
      return 0
    fi
  done
  return 1
}
