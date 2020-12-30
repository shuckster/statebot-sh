#!/bin/sh
# shellcheck disable=SC2034,SC2039

CC_FAILURE_COUNT_FILE='/tmp/error_count.txt'
CC_FAILURE_COUNT=0
CC_FAILURE_LIMIT_BEFORE_REBOOT=${CC_FAILURE_LIMIT_BEFORE_REBOOT:-20}

STATEBOT_LOG_LEVEL=${STATEBOT_LOG_LEVEL:-4}
STATEBOT_USE_LOGGER=${STATEBOT_USE_LOGGER:-0}

CLOUD_CONNECT_CHART='

  idle ->
    pinging -> (online | offline) ->
    pinging

  offline ->
    logging-in ->
    online | failure

  failure ->
    offline | rebooting

  // Go directly to [offline] on Hotplug "ifdown"
  online -> offline

  // Pause/resume functionality:
  (idle | pinging | online | offline | logging-in | failure) ->
    paused -> idle

'

main()
{
  load_fail_count_for_this_session

  statebot_init "cloud-connect" "idle" "" "${CLOUD_CONNECT_CHART}"

  if [ "${1}" = "reset" ]
  then
    echo ""
    echo "Resetting..."
    echo ""
    statebot_reset
    exit 255
  fi

  if [ "${1}" != "" ]
  then
    statebot_emit "${1}"
  fi
}

load_plugin()
{
  local PLUGIN_INFO PLUGIN_EXIT PLUGIN_NAME PLUGIN_PATH PLUGIN_API

  PLUGIN_INFO=$(./_load-plugins.sh "$@")
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
}

#
# API SURFACE
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
  if try_a_reboot_if_necessary
  then
    statebot_emit rebooting
  else
    statebot_emit disconnected
  fi
}

#
# STATEBOT TRANSITIONS
#

perform_transitions ()
{
  local ON THEN

  ON=""
  THEN=""

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
    'failure->rebooting')
      ON="rebooting"
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
# ENTRY POINT
#
# - Load plugin
# - Helpers
# - Statebot
#

cd "${0%/*}" || exit 255

load_plugin "$@"

# shellcheck disable=SC1091
. ./_failure-counting.sh

# shellcheck disable=SC1091
. ../../statebot.sh

if ! is_valid_network
then
  warn "is_valid_network() didn't pass, exiting..."
  exit 1
fi

# EVENT was initialised within load_plugin
main "${EVENT}"
