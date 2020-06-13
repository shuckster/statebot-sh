#!/bin/sh
# shellcheck disable=SC1090

iface_connected_to_ssid()
{
  IFACE="$1"
  SSID="$2"
  iwinfo "${IFACE}" info|grep -q "${SSID}"
}

silently_get_url()
{
  URL="$*"
  curl --max-time 10 --silent --output /dev/null "${URL}"
}

grep_in_url()
{
  URL="$1"
  TEXT="$2"
  shift 2
  REST_OPTS="$*"
  # shellcheck disable=SC2086
  curl ${REST_OPTS} "${URL}" --stderr -|grep -q "${TEXT}"
}

grep_in_text()
{
  HAYSTACK="$1"
  shift 1
  NEEDLE="$*"
  echo "${HAYSTACK}"|grep -q "${NEEDLE}"
}

post_data_to_url()
{
  DATA="$1"
  URL="$2"
  shift 2
  REST_OPTS="$*"
  # shellcheck disable=SC2086
  curl ${REST_OPTS} -d "${DATA}" "${URL}"
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
