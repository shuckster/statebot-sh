#!/bin/sh
# shellcheck disable=SC2034,SC2039

CLOUD_CONNECT_ERRORS='/tmp/error_count.txt'
FAILURE_LIMIT=20
FAILURE_COUNT=0

CLOUD_CONNECT_CHART='

  idle ->

  pinging -> (online | offline) -> pinging
  offline -> logging-in -> (online | failure)
  failure -> offline

  // Go directly to [offline] on Hotplug "ifdown"
  online -> offline

  // Pause/resume functionality:
  (idle|pinging|online|offline|logging-in|failure) ->
    paused -> idle

'

#
# PLUGINS
#

cd "${0%/*}" || exit 255
PLUGIN_INFO=$(./load-plugins.sh "$@")
PLUGIN_EXIT=$?
PLUGIN_NAME=$(echo "${PLUGIN_INFO}"|awk '{ print $1 }')
PLUGIN_PATH=$(echo "${PLUGIN_INFO}"|awk '{ print $2 }')
PLUGIN_API=$(echo "${PLUGIN_INFO}"|awk '{ print $3 }')
EVENT=$(echo "${PLUGIN_INFO}"|awk '{ print $4 }')
case $PLUGIN_EXIT in
  1)
    echo "Specified plugin: [${PLUGIN_NAME}]"
  ;;
  2)
    echo "Just one plugin, defaulting to it: [${PLUGIN_NAME}]"
  ;;
  *)
    echo "${PLUGIN_INFO}"
    exit 1
  ;;
esac
echo "Loading plugin: ${PLUGIN_API}"
# shellcheck disable=SC1090
. "${PLUGIN_API}"

# Check that the right functions are available
VALID_PLUGIN=1
REQUIRED_FUNCTIONS='is_valid_network is_logged_in login is_reboot_allowed report_online_status'
for FN_NAME in ${REQUIRED_FUNCTIONS}
do
  if ! type "$FN_NAME" 2>&1|grep -q 'function'
  then
    echo "Plugin does not have a required function: ${FN_NAME}()"
    VALID_PLUGIN=0
  fi
done
if [ "${VALID_PLUGIN}" -eq 0 ]
then
  exit 1
fi

#
# IMPORT STATEBOT
#

STATEBOT_LOG_LEVEL=4
STATEBOT_USE_LOGGER=0
# shellcheck disable=SC1091
. ../../statebot.sh

if ! is_valid_network
then
  warn "is_valid_network() didn't pass, exiting..."
  exit 1
fi

#
# EVENTS
#

perform_transitions ()
{
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
    if case_statebot "$1" '
      (idle|pinging|online|offline|logging-in|failure) ->
        paused
    '
    then
      ON="pause"
    fi
    ;;
  esac

  echo ${ON} "${THEN}"
}

#
# IMPLEMENTATION
#

check_connection ()
{
  if is_logged_in
  then
    statebot_emit connected
  else
    statebot_emit disconnected
  fi
}

attempt_login ()
{
  warn "Not logged-in, trying..."
  if login
  then
    online_action
    statebot_emit connected
  else
    statebot_emit failed
  fi
}

online_action ()
{
  log "Online!"
  unbump_fail_count_for_this_session
  report_online_status
}

offline_message ()
{
  warn "OFFLINE!"
}

log_failure ()
{
  error "Could not login :("
  bump_fail_count_for_this_session
  try_a_reboot_if_necessary
  statebot_emit disconnected
}

#
# FAILURE COUNT HELPERS
#

load_fail_count_for_this_session ()
{
  if [ -f "${CLOUD_CONNECT_ERRORS}" ]
  then
    FAILURE_COUNT=$(cat "${CLOUD_CONNECT_ERRORS}")
  fi
}

bump_fail_count_for_this_session ()
{
  : $((FAILURE_COUNT+=1))
  echo "${FAILURE_COUNT}" > "${CLOUD_CONNECT_ERRORS}"
  warn "Failure count: ${FAILURE_COUNT}"
}

unbump_fail_count_for_this_session ()
{
  : $((FAILURE_COUNT-=1))
  if [ "${FAILURE_COUNT}" -lt 0 ]
  then
    FAILURE_COUNT=0
  fi
  echo "${FAILURE_COUNT}" > "${CLOUD_CONNECT_ERRORS}"
  log "Failure count: ${FAILURE_COUNT}"
}

we_have_failed_enough_to_try_a_reboot ()
{
  if [ ${FAILURE_COUNT} -ge ${FAILURE_LIMIT} ]
  then
    return 0
  fi
  return 1
}

try_a_reboot_if_necessary ()
{
  if ! we_have_failed_enough_to_try_a_reboot
  then
    log "Retry limit not yet reached..."
    return 1
  fi

  warn "Failure limit reached! Are we allowed to try a reboot?"

  if ! is_reboot_allowed
  then
    log "Not rebooting!"
    return 1
  fi

  warn "Rebooting!"
  reboot
}

load_fail_count_for_this_session

#
# STATEBOT
#

# Start Statebot
statebot_init "cloud-connect" "idle" "" "${CLOUD_CONNECT_CHART}"

# Emit events from the command-line
if [ "${EVENT}" != "" ]
then
  statebot_emit "${EVENT}"
fi
