#!/bin/bash

CLOUD_CONNECT_ERRORS='/tmp/error_count.txt'
FAILURE_LIMIT=20
let FAILURE_COUNT=0

CLOUD_CONNECT_CHART='

  idle ->

  pinging ->
    (online | offline) ->
      pinging

  offline ->
    logging-in -> (online | failure)

  failure -> offline

  // Go directly to [offline] on Hotplug "ifdown"
  online -> offline

  // Pause/resume functionality.
  (idle|pinging|online|offline|logging-in|failure) ->
    paused -> idle

'

#
# PLUGINS
#

cd "${0%/*}";
PLUGIN_INFO=$(./load-plugins.sh "$@")
PLUGIN_EXIT=$?
PLUGIN_NAME=$(echo "$PLUGIN_INFO" | awk '{ print $1 }')
PLUGIN_PATH=$(echo "$PLUGIN_INFO" | awk '{ print $2 }')
PLUGIN_API=$(echo "$PLUGIN_INFO" | awk '{ print $3 }')
EVENT=$(echo "$PLUGIN_INFO" | awk '{ print $4 }')
case $PLUGIN_EXIT in
  1)
    echo "Specified plugin: [$PLUGIN_NAME]"
  ;;
  2)
    echo "Just one plugin, defaulting to it: [$PLUGIN_NAME]"
  ;;
  *)
    echo $PLUGIN_INFO
    exit 1
  ;;
esac
echo "Loading plugin: $PLUGIN_API"
source $PLUGIN_API

# Check that the right functions are available
VALID_PLUGIN=1
REQUIRED_FUNCTIONS='is_valid_network is_logged_in login is_reboot_allowed report_online_status'
for FN_NAME in ${REQUIRED_FUNCTIONS}; do
  type $FN_NAME 2>&1|grep -q 'function'
  if [[ $? -eq 1 ]]; then
    echo "Plugin does not have a required function: $FN_NAME()"
    VALID_PLUGIN=0
  fi
done
if [[ $VALID_PLUGIN -eq 0 ]]; then
  exit 1
fi

#
# IMPORT STATEBOT
#

STATEBOT_LOG_LEVEL=4
STATEBOT_USE_LOGGER=0
source ../../statebot.sh

#
# CHECK WE'RE ON A VALID NETWORK
#

is_valid_network
if [ $? -ne 0 ]
then
  warn "is_valid_network() didn't pass, exiting..."
  statebot_reset
  exit 1
fi

#
# EVENTS
#

perform_transitions () {
  local ON=""; local THEN=""
  case $1 in
    # check status
    'idle->pinging'|'offline->pinging'|'online->pinging')
      ON="check"
      THEN="check_connection"
    ;;

    # online: already logged-in
    'pinging->online'|'logging-in->online')
      ON="connected"
      THEN="online_action"
    ;;

    # offline: happy login path
    'pinging->offline')
      ON="disconnected"
      THEN="statebot_emit login"
    ;;
    'offline->logging-in')
      ON="login"
      THEN="attempt_login"
    ;;

    # offline: unhappy login path
    'logging-in->failure')
      ON="failed"
      THEN="log_failure"
    ;;
    'failure->offline')
      ON="disconnected"
      THEN="offline_message"
    ;;

    # hotplug ifdown
    'online->offline')
      ON="ifdown"
    ;;

    # resume
    'paused->idle')
      ON="resume"
    ;;
    *)
    # pause
    case_statebot $1 '
      (idle|pinging|online|offline|logging-in|failure) ->
        paused
    '
    if [[ $? -eq 1 ]]; then
      ON="pause"
    fi
    ;;
  esac
  echo $ON $THEN
}

#
# IMPLEMENTATION
#

check_connection () {
  is_logged_in
  if [ $? -eq 0 ]; then
    statebot_emit connected
  else
    statebot_emit disconnected
  fi
}

attempt_login () {
  warn "Not logged-in, trying..."
  login
  if [ $? -eq 0 ];
  then
    online_action
    statebot_emit connected
  else
    statebot_emit failed
  fi
}

online_action () {
  log "Online!"
  unbump_fail_count_for_this_session
  report_online_status
}

offline_message () {
  warn "OFFLINE!"
}

log_failure () {
  error "Could not login :("
  bump_fail_count_for_this_session
  try_a_reboot_if_necessary
  statebot_emit disconnected
}

#
# FAILURE COUNT HELPERS
#

load_fail_count_for_this_session () {
  if [ -f "$CLOUD_CONNECT_ERRORS" ]; then
    let FAILURE_COUNT=$(cat $CLOUD_CONNECT_ERRORS)
  fi
}

bump_fail_count_for_this_session () {
  let FAILURE_COUNT+=1
  echo $FAILURE_COUNT > "$CLOUD_CONNECT_ERRORS"
  warn "Failure count: $FAILURE_COUNT"
}

unbump_fail_count_for_this_session () {
  let FAILURE_COUNT-=1
  if [ $FAILURE_COUNT -lt 0 ]; then
    let FAILURE_COUNT=0
  fi
  echo $FAILURE_COUNT > "$CLOUD_CONNECT_ERRORS"
  log "Failure count: $FAILURE_COUNT"
}

have_we_failed_enough_to_try_a_reboot () {
  if [ $FAILURE_COUNT -ge $FAILURE_LIMIT ]; then
    return 1
  else
    return 0
  fi
}

try_a_reboot_if_necessary () {
  have_we_failed_enough_to_try_a_reboot
  if [ $? -eq 1 ]; then
    warn "Failure limit reached! Are we allowed to try a reboot?"

    is_reboot_allowed
    if [ $? -eq 1 ]; then
      warn "Rebooting!"
      reboot
    else
      log "Not rebooting!"
    fi
  else
    log "Retry limit not yet reached..."
  fi
}

load_fail_count_for_this_session

#
# STATEBOT
#

# Start Statebot
statebot_init "cloud-connect" "idle" "" "${CLOUD_CONNECT_CHART}"

# Emit events from the command-line
if [[ "$EVENT" != "" ]]; then
  statebot_emit "$EVENT"
fi
