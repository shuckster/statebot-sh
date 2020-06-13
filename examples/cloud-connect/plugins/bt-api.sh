#!/bin/sh
# shellcheck disable=SC1090

. "${PLUGIN_PATH}/.secrets"
. "${PLUGIN_PATH}/config.sh"
. "${PLUGIN_PATH}/../helpers.sh"

is_valid_network ()
{
  log "Checking Wifi connected to: ${BT_SSID}"
  iface_connected_to_ssid "${BT_IFACE}" "${BT_SSID}"
}

is_logged_in ()
{
  log "Checking Captive Portal status..."
  grep_in_url "${BT_STATUS_URL}" "${BT_STATUS_TEXT}" "${BT_CURL_OPTS}"
}

is_reboot_allowed ()
{
  echo "$(date) :: Rebooting!" >> "${BT_REBOOT_LOG}"
  return 0
}

report_online_status ()
{
  silently_get_url "${__REPORT_GRAPH__}"
}

login ()
{
  FIRST_TRY=$(post_data_to_url "${BT_LOGIN_FORM}" "${BT_LOGIN_URL}" "${BT_CURL_OPTS}")
  if grep_in_text "${FIRST_TRY}" "${BT_LOGIN_SUCCESS_TEXT}"
  then
    return 0
  fi

  REFRESH_URL=$(get_meta_refresh_url_from_html "${FIRST_TRY}")
  if [ "${REFRESH_URL}" = "" ]
  then
    echo "${FIRST_TRY}" > "${BT_PREVIOUS_ATTEMPT}"
    return 1
  fi

  # shellcheck disable=SC2086
  REDIRECT_RESULT=$(curl ${BT_CURL_OPTS} "${REFRESH_URL}")
  if grep_in_text "${REDIRECT_RESULT}" "${BT_LOGIN_SUCCESS_TEXT}"
  then
    return 0
  fi

  echo "${REDIRECT_RESULT}" > "${BT_PREVIOUS_ATTEMPT}"
  return 1
}
