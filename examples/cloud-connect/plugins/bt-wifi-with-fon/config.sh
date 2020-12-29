#!/bin/sh
# shellcheck disable=SC2034

# Network
BT_SSID=${CC_WIRELESS_SSID_MATCH:-"BTWifi-with-FON"}
BT_IFACE=${CC_WIRELESS_IFACE:-"wlan-sta"}
BT_COOKIES="/tmp/bt_cookies.txt"
BT_PREVIOUS_ATTEMPT="/tmp/bt_previous_attempt.html"
BT_REBOOT_LOG="${HOME}/bt_reboot_log.txt"

# Portal status + login URLs
BT_STATUS_URL="https://www.btwifi.com:8443/home"
BT_LOGIN_URL="https://btwifi.portal.fon.com/remote\
  ?res=hsp-login\
  &HSPNAME=FonBT%3AGB\
  &WISPURL=https%3A%2F%2Fwww.btwifi.com%3A8443%2FfonLogon\
  &WISPURLHOME=https%3A%2F%2Fwww.btwifi.com%3A8443\
  &VNPNAME=FonBT%3AGB\
  &LOCATIONNAME=FonBT%3AGB"

# Remove indentation from URL above
BT_LOGIN_URL=$(echo "${BT_LOGIN_URL}"|sed -e 's/  //g')
BT_LOGIN_FORM="USERNAME=${__USERNAME__}&PASSWORD=${__PASSWORD__}"

# Found in the HTML when logged-in
BT_STATUS_TEXT="now logged on"
BT_LOGIN_SUCCESS_TEXT="${BT_STATUS_TEXT}"

BT_CURL_OPTS="\
  -L \
  --verbose \
  --max-time 60 \
  --interface ${BT_IFACE} \
  --cookie-jar ${BT_COOKIES} \
  --cookie ${BT_COOKIES}"
