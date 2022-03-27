#!/bin/bash

[[ $(whoami) != "root" ]] && echo "You must be root" && exit 1
[[ $# != 4 ]] && echo "Usage: $0 RPiIP RPiGateway DNS1 DNS2" && exit 1

#### Inputs
export RASPI_NET_IP=${1}
export RASPI_NET_ROUTER_IP=${2}
export RASPI_NET_DNS_PRIM=${3}
export RASPI_NET_DNS_STBY=${4}

#### RPi Setup
echo -e "######## RPi Setup ########"

#### Installing base software and upgrades
echo -e "\n## Installing base software and upgrades..."
export DEBIAN_FRONTEND=noninteractive
apt -y update
apt -y install apt-transport-https build-essential ca-certificates curl gawk git less lsb-release net-tools python3 python3-pip python3-venv p7zip-full sed unzip vim wget zip
apt -y install ntfs-3g exfat-fuse exfat-utils
apt -y update && apt -y upgrade --with-new-pkgs && apt -y autoremove && apt -y clean
apt -y update && apt -y full-upgrade

#### Disabling automatic updates
echo -e "\n## Disabling automatic updates..."
apt -y purge unattended-upgrades
systemctl mask apt-daily-upgrade
systemctl mask apt-daily
systemctl disable apt-daily-upgrade.timer
systemctl disable apt-daily.timer

#### Setup default profile file
echo -e "\n## Setup default profile file..."
tee /etc/profile.d/custom.sh > /dev/null << EOT
export SYSTEMD_PAGER=
alias ll='ls -l'
EOT
cat /etc/profile.d/custom.sh

#### Setup Raspberry Pi Python virtualenv
echo -e "\n## Setup Raspberry Pi Python virtualenv..."
if [[ ! -f /opt/pyenv/bin/activate ]]
then
    python3 -m venv /opt/pyenv
    chown -R pi:pi /opt/pyenv
    source /opt/pyenv/bin/activate
    pip install --upgrade pip wheel setuptools
fi

#### Setup Pi user .bashrc file
echo -e "\n## Setup Pi user .bashrc file..."
[[ $(grep "Activate Python virtualenv" ~/.bashrc | wc -l) == 0 ]] && echo -e "\n# Activate Python virtualenv\nsource /opt/pyenv/bin/activate" >> ~/.bashrc
[[ $(grep "Setup aliases" ~/.bashrc | wc -l) == 0 ]] && echo -e "\n# Setup aliases\nalias ll='ls -l'" >> ~/.bashrc

#### Configuring DNS
echo -e "\n## Configuring DNS..."
tee -a /etc/resolv.conf > /dev/null << EOT
nameserver ${RASPI_NET_DNS_PRIM}
nameserver ${RASPI_NET_DNS_STBY}
EOT
cat /etc/resolv.conf
resolvconf -u

#### Configuring DHCP
echo -e "\n## Configuring DHCP..."
[[ $(grep "Raspberry Pi Static IP" /etc/dhcpcd.conf | wc -l) == 0 ]] && tee -a /etc/dhcpcd.conf > /dev/null << EOT

# Raspberry Pi Static IP
interface eth0
static ip_address=${RASPI_NET_IP}/24
static routers=${RASPI_NET_ROUTER_IP}
static domain_name_servers=${RASPI_NET_DNS_PRIM}
EOT
cat /etc/dhcpcd.conf

#### Rebooting
echo -e "\n## Rebooting..."
reboot
