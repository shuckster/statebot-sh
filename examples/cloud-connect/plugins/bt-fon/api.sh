#!/bin/sh
# shellcheck disable=SC1090

. "${PLUGIN_PATH}/.secrets"
. "${PLUGIN_PATH}/config.sh"

is_valid_network ()
{
  log "Checking Wifi connected to: ${FON_SSID}"
  grep_ssid "${FON_SSID}"
  return $?
}

is_logged_in ()
{
  log "Checking Captive Portal status..."
  grep_in_url "${PORTAL_STATUS_URL}" "${PORTAL_STATUS_TEXT}"
  return $?
}

login ()
{
  # shellcheck disable=SC2086
  FIRST_TRY=$(curl ${CURL_OPTS} -d "${PORTAL_LOGIN_FORM}" "${PORTAL_LOGIN_URL}")
  if echo "${FIRST_TRY}"|grep -q "${PORTAL_LOGIN_SUCCESS_TEXT}"
  then
    return 0
  fi

  REFRESH_URL=$(get_meta_refresh_url_from_html "${FIRST_TRY}")
  if [ "${REFRESH_URL}" = "" ]
  then
    echo "${FIRST_TRY}" > "${FON_PREVIOUS_ATTEMPT}"
    return 1
  fi

  # shellcheck disable=SC2086
  REDIRECT_RESULT=$(curl ${CURL_OPTS} "${REFRESH_URL}")
  if echo "${REDIRECT_RESULT}" | grep -q "${PORTAL_LOGIN_SUCCESS_TEXT}"
  then
    return 0
  fi

  echo "${REDIRECT_RESULT}" > "${FON_PREVIOUS_ATTEMPT}"
  return 1
}

is_reboot_allowed ()
{
  echo "$(date) :: Rebooting!" >> "${FON_REBOOT_LOG}"
  return 0
}

report_online_status ()
{
  curl --max-time 10 --silent --output /dev/null "${__REPORT_GRAPH__}"
}

#
# HELPERS
#

grep_ssid()
{
  TEST_SSID="$*"
  iwinfo "${FON_IFACE}" info|grep -q "${TEST_SSID}"
  return $?
}

grep_in_url()
{
  URL="$1"
  shift 1
  # shellcheck disable=SC2086
  curl ${CURL_OPTS} "${URL}" --stderr -|grep -q "$@"
  return $?
}

get_meta_refresh_url_from_html()
{
  echo "$@" | \
    grep -oi '<meta[^>]*>' | \
    grep '="refresh"' | \
    grep -oi 'url=[^"]*' | \
    cut -d'=' -f2- | \
    sed -e 's/&amp;/\&/g'
}
