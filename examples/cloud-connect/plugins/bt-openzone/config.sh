#!/bin/sh
# shellcheck disable=SC2034

# Network
BT_SSID="BT-Wifi"
BT_IFACE="apcli0"
BT_COOKIES="/tmp/bt_cookies.txt"
BT_PREVIOUS_ATTEMPT="/tmp/bt_previous_attempt.html"
BT_REBOOT_LOG="${HOME}/bt_reboot_log.txt"

# Portal status + login URLs
BT_STATUS_URL="https://www.btwifi.com:8443/home"
BT_LOGIN_URL="https://www.btopenzone.com:8443/tbbLogon"
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
