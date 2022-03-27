#!/bin/bash

[[ $(whoami) != "root" ]] && echo "You must be root" && exit 1
[[ ! -d ./files/vsftpd ]] && echo "Missing files folder" && exit 1

#### RPi FTP Server Setup
echo "######## RPi FTP Server Setup ########"

# Installing vsftpd
echo -e "\n## Installing vsftpd..."
apt -y install vsftpd
systemctl stop vsftpd

# Configurating vsftpd
echo -e "\n## Configurating vsftpd..."
cp -v ./files/vsftpd/vsftpd.conf /etc/vsftpd.conf
chmod -v 644 /etc/vsftpd.conf
chown -v root:root /etc/vsftpd.conf
echo "ftpuser" > /etc/vsftpd.user_list

# Creating FTP user
echo -e "\n## Creating FTP user..."
FTP_USER_CHECK=$(grep "^ftpuser:" /etc/passwd | wc -l)
[[ ${FTP_USER_CHECK} == 0 ]] && echo "Check: absent -> create"  && adduser --home /home/ftpuser --shell /bin/bash --disabled-login --gecos "" ftpuser
[[ ${FTP_USER_CHECK} == 1 ]] && echo "Check: present -> update" && usermod --home /home/ftpuser --shell /bin/bash --move-home ftpuser
echo "ftpuser:VerySecurePassword" | chpasswd
echo -e "\n## Done\n- user: ftpuser\n - pass: VerySecurePassword"

# Starting vsftpd
export SYSTEMD_PAGER=
echo -e "\n## Starting vsftpd..."
systemctl enable --now vsftpd
systemctl status vsftpd
