#!/bin/bash

[[ $(whoami) != "root" ]] && echo "You must be root" && exit 1
[[ ! -d ./files/jellyfin ]] && echo "Missing files folder" && exit 1

#### RPi Jellyfin Setup
echo "######## RPi Jellyfin Setup ########"

# Installing Jellyfin
echo -e "\n## Installing Jellyfin..."
curl https://repo.jellyfin.org/debian/jellyfin_team.gpg.key | gpg --dearmor | tee /usr/share/keyrings/jellyfin-archive-keyring.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/jellyfin-archive-keyring.gpg arch=$( dpkg --print-architecture )] https://repo.jellyfin.org/debian $( lsb_release -c -s ) main" | tee /etc/apt/sources.list.d/jellyfin.list > /dev/null
apt -y update
apt -y install jellyfin
systemctl stop jellyfin

# Enabling Jellyfin GPU access
echo -e "\n## Enabling Jellyfin GPU access..."
usermod -a -G video jellyfin

# Adding Jellyfin systemd unit drop-in
echo -e "\n## Adding Jellyfin systemd unit drop-in..."
mkdir -vp /etc/systemd/system/jellyfin.service.d
cp -v ./files/jellyfin/jellyfin.service.conf /etc/systemd/system/jellyfin.service.d/jellyfin.service.conf
chown root:root /etc/systemd/system/jellyfin.service.d/jellyfin.service.conf
chmod 644 /etc/systemd/system/jellyfin.service.d/jellyfin.service.conf
systemctl daemon-reload
systemctl cat jellyfin

# Starting Jellyfin
export SYSTEMD_PAGER=
echo -e "\n## Starting Jellyfin..."
systemctl enable --now jellyfin
systemctl status jellyfin

# Current RPi CPU/GPU memory assignement
echo -e "\n## Current RPi CPU/GPU memory assignement:"
vcgencmd get_mem arm
vcgencmd get_mem gpu

# RPi GPU assigned memory edit istructions
echo -e "\n## RPi GPU assigned memory edit istructions:"
echo "- Run 'raspi-config' command"
echo "- Select 'Performance Options'"
echo "- Select 'GPU Memory'"
echo "- Insert memory in MB to assign at GPU"
echo "- Select 'OK, 'Finish', and finally 'Yes' to reboot"
