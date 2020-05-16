#!/bin/bash

# To use this, add the following to a new file in /etc/hotplug.d/iface/
#
# #!/bin/bash
# export DEVICE
# export ACTION
# /path/to/this/file/hotplug.sh

# Change apcli0 to your network interface
if [[ "$DEVICE" != "apcli0" ]]; then
  exit
fi

logger -t "cloud-connect" "HOTPLUG :: Device: $DEVICE / Action: $ACTION"

cd "${0%/*}"
if [[ "$ACTION" == "ifdown" ]]; then
  ./cloud-connect.sh bt-fon ifdown
fi
if [[ "$ACTION" == "ifup" ]]; then
  sleep 5
  ./cloud-connect.sh bt-fon check
fi
