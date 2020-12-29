#!/bin/sh

# To use this, add the following to a new file in /etc/hotplug.d/iface/
#
# #!/bin/sh
# export DEVICE
# export ACTION
# /path/to/this/file/hotplug.sh

# Change to your network interface if the UCI command fails, eg:
# CC_IFACE="apcli0"
CC_IFACE=$(uci get wireless.sta.ifname)

# Change to the name of the required plugin
CC_PLUGIN="bt-wifi"

if [ "${DEVICE}" != "${CC_IFACE}" ]
then
  exit
fi

logger -t "cloud-connect" "HOTPLUG :: Device: ${DEVICE} / Action: ${ACTION}"

cd "${0%/*}" || exit 255

if [ "${ACTION}" = "ifdown" ]
then
  ./cloud-connect.sh ${CC_PLUGIN} ifdown
fi

if [ "${ACTION}" = "ifup" ]
then
  sleep 5
  ./cloud-connect.sh ${CC_PLUGIN} check
fi
