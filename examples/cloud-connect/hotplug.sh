#!/bin/sh

# To use this, add the following to a new file in /etc/hotplug.d/iface/
#
# #!/bin/sh
# export DEVICE
# export ACTION
# /path/to/this/file/hotplug.sh

cd "${0%/*}" || exit 255

# shellcheck disable=SC1091
. ./_config.sh

if [ "" = "${CC_WIRELESS_IFACE}" ]
then
  logger -t "cloud-connect" "HOTPLUG :: CC_WIRELESS_IFACE not defined!"
  exit
fi

logger -t "cloud-connect" "HOTPLUG :: Device: ${DEVICE} / Action: ${ACTION}"

if [ "${DEVICE}" != "${CC_WIRELESS_IFACE}" ]
then
  exit
fi

on_ifdown()
{
  ./cc.sh ifdown
}

on_ifup()
{
  sleep 5
  ./cc.sh check
}

case "${ACTION}" in
  'disconnected')
    on_ifdown
  ;;
  'ifdown')
    on_ifdown
  ;;
  'ifup')
    on_ifup
  ;;
esac
