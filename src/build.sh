#!/bin/sh

set -e
set -x

wget https://downloads.raspberrypi.org/raspios_lite_armhf/images/raspios_lite_armhf-2020-08-24/2020-08-20-raspios-buster-armhf-lite.zip

sha256sum *.zip | | grep -q 4522df4a29f9aac4b0166fbfee9f599dab55a997c855702bfe35329c13334668

unzip *.zip

loop="`losetup -f --show -P *.img`"

trap "losetup -d ${loop}" EXIT

#
# /boot is the VFAT partition of the Raspbian image with config.txt and cmdline.txt
#
mkdir /boot
mount ${loop}p1 /boot

# enable SSH
touch /boot/ssh

# configure WiFi
#cp /src/wpa_supplicant.conf /boot/

# disable bluetooth
echo 'dtoverlay=pi3-disable-bt' >> /boot/config.txt 

# enable USB OTG ethernet dongle emulation
# you could also set static MAC addresses for g_ether in cmdline.txt if needed:
#  g_ether.host_addr=00:11:22:33:44:55 g_ether.dev_addr=66:77:88:99:aa:bb
echo 'dtoverlay=dwc2' >> /boot/config.txt
sed -i -e 's/ rootwait / rootwait modules-load=dwc2,g_ether /' /boot/cmdline.txt

umount /boot

#
# The root ext4 filesystem for Raspbian is the second partition
#
mount ${loop}p2 /mnt

# disable the default password for the 'pi' user
sed -i -e 's/pi:[^:]*/pi:*/' /mnt/etc/shadow

# enable ssh public key access to the default 'pi' user
install -o 1000 -m 700 -d /mnt/home/pi/.ssh
install -o 1000 -m 700 /src/authorized_keys /mnt/home/pi/.ssh/

# set the hostname on boot based on hardware info
install -o 0 -m 755 /src/mac-hostname.sh /mnt/etc/
install -o 0 -m 755 /src/mac-hostname.service /mnt/etc/systemd/system/
install -d -o 0 -m 755 /mnt/etc/systemd/system/network.target.wants
ln -s /mnt/etc/systemd/system/mac-hostname.service /mnt/etc/systemd/system/network.target.wants/mac-hostname.service

umount /mnt 
