#!/bin/sh

set -e

PREFIX="datapi"
SERIAL="`awk '/Serial/ {print $3}' /proc/cpuinfo`"
WIFIMAC="`sed 's/://g' /sys/class/net/wlan0/address`"
OLDHOST="`cat /etc/hostname`"
NEWHOST="${PREFIX}-${WIFIMAC}"

if [ "${NEWHOST}" != "{OLDHOST}" ]; then
# fails. too early for this? editing file and setting hostname manually as below works
#	hostnamectl set-hostname "${NEWHOST}"
	echo "${NEWHOST}" > /etc/hostname
	hostname "${NEWHOST}"
	sed -Ei "s/^127.0.1.1[ \t]+${OLDHOST}$/127.0.1.1\t${NEWHOST}/g" /etc/hosts
fi

exit 0
