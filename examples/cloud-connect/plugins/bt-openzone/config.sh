#!/bin/sh
# shellcheck disable=SC2034

# [UNTESTED!]

# URL/form info based on @SpikeTheLobster's
# comment over on this Gist:
# - https://gist.github.com/sscarduzio/05ed0b41d6234530d724#gistcomment-3336485

# Network
BT_SSID="BT-Wifi"
BT_IFACE="apcli0"
BT_COOKIES="/tmp/bt_cookies.txt"
BT_PREVIOUS_ATTEMPT="/tmp/bt_previous_attempt.html"
BT_REBOOT_LOG="${HOME}/bt_reboot_log.txt"

# Portal status + login URLs
BT_STATUS_URL="https://www.btopenzone.com:8443/home"
BT_LOGIN_URL="https://www.btwifi.com:8443/ante"
BT_LOGIN_FORM="\
  xhtmlLogon=https://www.btwifi.com:8443/ante&\
  USERNAME=${__USERNAME__}&\
  PASSWORD=${__PASSWORD__}&\
  provider=btoz"

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
