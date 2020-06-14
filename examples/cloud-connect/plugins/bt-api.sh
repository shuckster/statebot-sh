#!/bin/sh
# shellcheck disable=SC2039

# The functions called here will be imported
# from `helpers.sh` during runtime, so check
# out that file for their definitions

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
  local first_try refresh_url redirect_result

  first_try=$(post_data_to_url "${BT_LOGIN_FORM}" "${BT_LOGIN_URL}" "${BT_CURL_OPTS}")
  if grep_in_text "${first_try}" "${BT_LOGIN_SUCCESS_TEXT}"
  then
    return 0
  fi

  refresh_url=$(get_meta_refresh_url_from_html "${first_try}")
  if [ "${refresh_url}" = "" ]
  then
    echo "${first_try}" > "${BT_PREVIOUS_ATTEMPT}"
    return 1
  fi

  # shellcheck disable=SC2086
  redirect_result=$(curl ${BT_CURL_OPTS} "${refresh_url}")
  if grep_in_text "${redirect_result}" "${BT_LOGIN_SUCCESS_TEXT}"
  then
    return 0
  fi

  echo "${redirect_result}" > "${BT_PREVIOUS_ATTEMPT}"
  return 1
}
