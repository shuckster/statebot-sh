#!/bin/sh
# shellcheck disable=SC2034

# [ ! UNTESTED ! ]

# Network
BT_SSID="BTWi-fi"
BT_IFACE=$(uci get wireless.sta.ifname)
BT_COOKIES="/tmp/bt_cookies.txt"
BT_PREVIOUS_ATTEMPT="/tmp/bt_previous_attempt.html"
BT_REBOOT_LOG="${HOME}/bt_reboot_log.txt"

# Portal status + login URLs
BT_STATUS_URL="https://www.btwifi.com:8443/home"
BT_LOGIN_URL="https://www.btwifi.com:8443/ante?partnerNetwork=btb"
BT_LOGIN_FORM="\
  xhtmlLogon=https://www.btwifi.com:8443/ante&\
  username=${__USERNAME__}&\
  password=${__PASSWORD__}&\
  provider=business"

# Remove indentation from the form above
BT_LOGIN_FORM=$(echo "${BT_LOGIN_FORM}"|sed -e 's/  //g')

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
