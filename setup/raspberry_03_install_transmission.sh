#!/bin/bash

[[ $(whoami) != "root" ]] && echo "You must be root" && exit 1
[[ ! -d ./files/transmission ]] && echo "Missing files folder" && exit 1
[[ $# != 3 ]] && echo "Usage: $0 WebUser WebPass DownloadFolder" && exit 1

#### Inputs
export TRANSMISSION_WEB_USER=${1}
export TRANSMISSION_WEB_PASS=${2}
export TRANSMISSION_DL_FOLDER=${3}

#### RPi Transmission Setup
echo "######## RPi Transmission Setup ########"

# Installing Transmission
echo -e "\n## Installing Transmission..."
apt -y install transmission-daemon
systemctl stop transmission-daemon

# Adding Transmission systemd unit drop-in
echo -e "\n## Adding Transmission systemd unit drop-in..."
mkdir -vp /etc/systemd/system/transmission-daemon.service.d
cp -v ./files/transmission/transmission-daemon.service.conf /etc/systemd/system/transmission-daemon.service.d/transmission-daemon.service.conf
chown root:root /etc/systemd/system/transmission-daemon.service.d/transmission-daemon.service.conf
chmod 644 /etc/systemd/system/transmission-daemon.service.d/transmission-daemon.service.conf
systemctl daemon-reload
systemctl cat transmission-daemon

# Managing folders
echo -e "\n## Managing folders..."
mkdir -p /var/lib/transmission-daemon/inprogress
chown debian-transmission:debian-transmission /var/lib/transmission-daemon/inprogress ${TRANSMISSION_DL_FOLDER}
chmod 775 /var/lib/transmission-daemon/inprogress ${TRANSMISSION_DL_FOLDER}
ln -fs /var/lib/transmission-daemon/complete ${TRANSMISSION_DL_FOLDER}

# Managing sysctl configurations
echo -e "\n## Managing sysctl configurations..."
cp -v ./files/transmission/99-transmission.conf /etc/sysctl.d
sysctl -p

# Managing settings
echo -e "\n## Managing settings..."
cp -v ./files/transmission/settings.json /etc/transmission-daemon/settings.json
sed -i -e "s/\${TRANSMISSION_WEB_USER}/${TRANSMISSION_WEB_USER}/" -e "s/\${TRANSMISSION_WEB_PASS}/${TRANSMISSION_WEB_PASS}/" /etc/transmission-daemon/settings.json
chown debian-transmission:debian-transmission /etc/transmission-daemon/settings.json
chmod 644 /etc/transmission-daemon/settings.json

# Starting Transmission
export SYSTEMD_PAGER=
echo -e "\n## Starting Transmission..."
systemctl enable --now transmission-daemon
systemctl status transmission-daemon
