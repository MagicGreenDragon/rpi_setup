#!/bin/bash

[[ $(whoami) != "root" ]] && echo "You must be root" && exit 1
[[ ! -d ./files/rpwcs ]] && echo "Missing files folder" && exit 1

#### Raspberry Pi Web Control Server
echo -e "######## Raspberry Pi Web Control Server Setup ########"

# Installing Python prerequisites
echo -e "\n## Installing Python prerequisites..."
pip install -r ./files/rpwcs/requirements.txt

# Coping Flask application
echo -e "\n## Coping Flask application..."
cp -rv ./files/rpwcs/rpwcs /var/www/
chmod 644 /var/www/rpwcs/rpwcs.py
chown -R root:root /var/www/rpwcs

# Installing systemd unit
echo -e "\n## Installing systemd unit..."
cp -v ./files/rpwcs/rpwcs.service /etc/systemd/system/rpwcs.service
chown -v root:root /etc/systemd/system/rpwcs.service
chmod -v 644 /etc/systemd/system/rpwcs.service
systemctl daemon-reload
systemctl stop rpwcs

# Starting rpwcs
export SYSTEMD_PAGER=
echo -e "\n## Starting rpwcs..."
systemctl enable --now rpwcs
systemctl status rpwcs
