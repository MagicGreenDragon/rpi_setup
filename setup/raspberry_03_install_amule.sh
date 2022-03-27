#!/bin/bash

[[ $(whoami) != "root" ]] && echo "You must be root" && exit 1
[[ ! -d ./files/amule ]] && echo "Missing files folder" && exit 1
[[ $# != 4 ]] && echo "Usage: $0 PortTCP PortUDP DownloadFolder Password" && exit 1

#### Inputs
export AMULE_PORT_TCP=${1}
export AMULE_PORT_UDP=${2}
export AMULE_DL_FOLDER=${3}
export AMULE_PASS=${4}

#### RPi aMule Setup
echo "######## RPi aMule Setup ########"

# Installing aMule
echo -e "\n## Installing aMule..."
apt -y install amule-daemon amule-utils
systemctl stop amule-daemon

# Installing systemd unit
echo -e "\n## Installing systemd unit..."
cp -v ./files/amule/amule-daemon.service /etc/systemd/system/amule-daemon.service
chown -v root:root /etc/systemd/system/amule-daemon.service
chmod -v 644 /etc/systemd/system/amule-daemon.service
systemctl daemon-reload
systemctl cat amule-daemon

# Creating aMule user
echo -e "\n## Creating aMule user..."
AMULE_USER_CHECK=$(grep "^amuleusr:" /etc/passwd | wc -l)
[[ ${AMULE_USER_CHECK} == 0 ]] && echo "Check: absent -> create"  && adduser --home /home/amuleusr --shell /usr/sbin/nologin --disabled-login --gecos "" amuleusr
[[ ${AMULE_USER_CHECK} == 1 ]] && echo "Check: present -> update" && usermod --home /home/amuleusr --shell /usr/sbin/nologin --move-home amuleusr

# Configuring aMule Daemon
echo -e "\n## Configuring aMule Daemon..."
cp -v ./files/amule/amule-daemon /etc/default/amule-daemon
chown root:root /etc/default/amule-daemon
chmod 644 /etc/default/amule-daemon

# Initializing aMule (start and stop it to create initial configuration if it is absent)
echo -e "\n## Initializing aMule..."
[[ ! -f /home/amuleusr/.aMule/amule.conf ]] && systemctl start amule-daemon && sleep 2 && systemctl stop amule-daemon

# Creating default download folder
echo -e "\n## Creating default download folder..."
mkdir -vp ${AMULE_DL_FOLDER}
chown -v amuleusr:amuleusr ${AMULE_DL_FOLDER}
chmod -v 777 ${AMULE_DL_FOLDER}
ln -fs /home/amuleusr/.aMule/Incoming ${AMULE_DL_FOLDER}

# Computing aMule version and encrypted password
AMULE_VERSION=$(amuled -v | cut -d ' ' -f2)
AMULE_PASS_ENC=$(echo -n "${AMULE_PASS}" | md5sum | cut -d ' ' -f1)

# Configuring aMule
echo -e "\n## Configuring aMule..."
cp -v ./files/amule/amule.conf /home/amuleusr/.aMule/amule.conf
sed -i -e "s/\${AMULE_VERSION}/${AMULE_VERSION}/" /home/amuleusr/.aMule/amule.conf
sed -i -e "s/\${AMULE_PORT_TCP}/${AMULE_PORT_TCP}/" -e "s/\${AMULE_PORT_UDP}/${AMULE_PORT_UDP}/" -e "s/\${AMULE_PASS_ENC}/${AMULE_PASS_ENC}/" /home/amuleusr/.aMule/amule.conf
chown -v amuleusr:amuleusr /home/amuleusr/.aMule/amule.conf
chmod -v 644 /home/amuleusr/.aMule/amule.conf

# Getting fresh version of 'server.met' and 'nodes.dat' files
echo -e "\n## Getting fresh version of 'server.met' and 'nodes.dat' files..."
wget -O /home/amuleusr/.aMule/nodes.dat https://upd.emule-security.org/nodes.dat
wget -O /home/amuleusr/.aMule/server.met https://upd.emule-security.org/server.met
chown -v amuleusr:amuleusr /home/amuleusr/.aMule/nodes.dat /home/amuleusr/.aMule/server.met
chmod -v 644 /home/amuleusr/.aMule/nodes.dat /home/amuleusr/.aMule/server.met

# Starting aMule
export SYSTEMD_PAGER=
echo -e "\n## Starting aMule..."
systemctl enable --now amule-daemon
systemctl status amule-daemon
