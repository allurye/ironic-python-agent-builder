#!/bin/bash

echo "Resolving the configuration drive for Ironic."

PATH=/bin:/usr/bin:/sbin:/usr/sbin

# Inspired by/based on glean-early.sh
# https://opendev.org/opendev/glean/src/branch/master/glean/init/glean-early.sh

# NOTE(TheJulia): We care about iso images, and would expect lower case as a
# result. In the case of VFAT partitions, they would be upper case.
CONFIG_DRIVE_LABEL="config-2"

# Identify if we have an a publisher id set
publisher_id=""
if grep -q "ir_pub_id" /proc/cmdline; then
    publisher_id=$(cat /proc/cmdline | sed -e 's/^.*ir_pub_id=//' -e 's/ .*$//')
fi

mkdir -p /mnt/config

while true ; do
	echo "Looking for a device with publisher ID ${publisher_id} and label=${CONFIG_DRIVE_LABEL}"
    if [[ "${publisher_id}" != "" ]]; then
        # We need to enumerate through the devices, and obtain the
        for device in $(lsblk -o PATH,LABEL|grep ${CONFIG_DRIVE_LABEL}|cut -f1 -d" "); do
            device_id=$(udevadm info --query=property --property=ID_FS_PUBLISHER_ID $device | sed s/ID_FS_PUBLISHER_ID=//)
            if [[ "${publisher_id,,}" == "${device_id,,}" ]]; then
                # SUCCESS! Valid device! Do it!
                echo "Device ${device} matches the ${publisher_id}. Mounting..."
                mount -t iso9660 -o ro,mode=0700 "${device}" /mnt/config || true
                # We've mounted the device, the world is happy.
                exit 0
            else
                echo "Did not identify $device as a valid ISO for Ironic."
            fi
        done
    fi
	sleep 5
done
