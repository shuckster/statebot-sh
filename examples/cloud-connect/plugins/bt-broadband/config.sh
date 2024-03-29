#!/bin/sh
# shellcheck disable=SC2034

# Thanks to @adammcguk for testing and updating this config

# Network
BT_SSID=${CC_WIRELESS_SSID_MATCH:-"BTWi-fi\|BTWifi-with-FON"}
BT_IFACE=${CC_WIRELESS_IFACE:-"wlan-sta"}
BT_COOKIES="/tmp/bt_cookies.txt"
BT_PREVIOUS_ATTEMPT="/tmp/bt_previous_attempt.html"
BT_REBOOT_LOG="${HOME}/bt_reboot_log.txt"

# Portal status + login URLs
BT_STATUS_URL="https://www.btwifi.com:8443/home"
BT_LOGIN_URL="https://www.btwifi.com:8443/tbbLogon"
BT_LOGIN_FORM="\
  xhtmlLogon=https://www.btwifi.com:8443/tbbLogon&\
  submitButton=Login&\
  inputUsername=${__USERNAME__}&\
  username=${__USERNAME__}&\
  password=${__PASSWORD__}&\
  provider=tbb"

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
