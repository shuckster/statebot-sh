#!/bin/bash
# shellcheck disable=SC2034

# Network
FON_SSID="BTWifi-with-FON"
FON_IFACE="apcli0"
FON_COOKIES="/tmp/fon_cookies.txt"
FON_PREVIOUS_ATTEMPT="/tmp/fon_previous_attempt.html"
FON_REBOOT_LOG="$HOME/fon_reboot_log.txt"

# Current working URLs
PORTAL_STATUS_URL="https://www.btwifi.com:8443/home"
PORTAL_LOGIN_URL="https://btwifi.portal.fon.com/remote\
  ?res=hsp-login\
  &HSPNAME=FonBT%3AGB\
  &WISPURL=https%3A%2F%2Fwww.btwifi.com%3A8443%2FfonLogon\
  &WISPURLHOME=https%3A%2F%2Fwww.btwifi.com%3A8443\
  &VNPNAME=FonBT%3AGB\
  &LOCATIONNAME=FonBT%3AGB"

# Remove intentation from URL
PORTAL_LOGIN_URL=${PORTAL_LOGIN_URL// /}
PORTAL_LOGIN_FORM="USERNAME=${__USERNAME__}&PASSWORD=${__PASSWORD__}"

# Found in the HTML when logged-in
PORTAL_STATUS_TEXT="now logged on"
PORTAL_LOGIN_SUCCESS_TEXT="$PORTAL_STATUS_TEXT"

CURL_OPTS="\
  -L \
  --verbose \
  --max-time 60 \
  --interface $FON_IFACE \
  --cookie-jar $FON_COOKIES \
  --cookie $FON_COOKIES"
