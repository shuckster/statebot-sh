#!/bin/sh
# shellcheck disable=SC1090,SC2039

iface_connected_to_ssid()
{
  local iface ssid

  iface="$1"
  ssid="$2"
  iwinfo "${iface}" info|grep -q "${ssid}"
}

silently_get_url()
{
  local url

  url="$*"
  curl --max-time 10 --silent --output /dev/null "${url}"
}

grep_in_url()
{
  local url text rest_opts

  url="$1"
  text="$2"
  shift 2
  rest_opts="$*"
  # shellcheck disable=SC2086
  curl ${rest_opts} "${url}" --stderr -|grep -q "${text}"
}

grep_in_text()
{
  local needle haystack

  haystack="$1"
  shift 1
  needle="$*"
  echo "${haystack}"|grep -q "${needle}"
}

post_data_to_url()
{
  local data url rest_opts

  data="$1"
  url="$2"
  shift 2
  rest_opts="$*"
  # shellcheck disable=SC2086
  curl ${rest_opts} -d "${data}" "${url}"
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
