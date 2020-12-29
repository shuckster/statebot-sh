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

if [ "${DEVICE}" != "${CC_WIRELESS_IFACE}" ]
then
  exit
fi

logger -t "cloud-connect" "HOTPLUG :: Device: ${DEVICE} / Action: ${ACTION}"

if [ "${ACTION}" = "ifdown" ]
then
  ./cc.sh ifdown
fi

if [ "${ACTION}" = "ifup" ]
then
  sleep 5
  ./cc.sh check
fi
