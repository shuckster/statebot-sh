#!/bin/bash

source $PLUGIN_PATH/.secrets
source $PLUGIN_PATH/config.sh

is_valid_network () {
  log "Checking Wifi connected to: $FON_SSID"
  grep_ssid "$FON_SSID"
  return $?
}

is_logged_in () {
  log "Checking Captive Portal status..."
  grep_in_url "$PORTAL_STATUS_URL" "$PORTAL_STATUS_TEXT"
  return $?
}

login () {
  CURL_RESULT=$(curl $CURL_OPTS -d "$PORTAL_LOGIN_FORM" "$PORTAL_LOGIN_URL")
  echo "$CURL_RESULT" > "$FON_PREVIOUS_ATTEMPT"
  echo "$CURL_RESULT" | grep -q "$PORTAL_LOGIN_SUCCESS_TEXT"
  return $?
}

is_reboot_allowed () {
  echo "$(date) :: Rebooting!" >> "$FON_REBOOT_LOG"
  return 1
}

report_online_status () {
  curl --max-time 10 --silent --output /dev/null "${__REPORT_GRAPH__}"
}

#
# HELPERS
#

grep_ssid() {
  TEST_SSID="$@"
  iwinfo $FON_IFACE info | grep -q "$TEST_SSID"
  return $?
}

grep_in_url() {
  URL="$1"
  shift 1
  curl $CURL_OPTS "$URL" --stderr - | grep -q "$@"
  return $?
}
