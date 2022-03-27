## Raspberry Pi Setup

* Install OS in RPi SD card (suggested **Raspberry Pi Imager** software and **Raspberry Pi OS Lite**)

* Copy setup folder in RPi

* As root, go in RPi setup folder and execute the following commands:
```bash
# Setup RPi (reboot executed at the end)
./raspberry_01_setup.sh <RPiIP> <RpiGateway> <DNS1> <DNS2>

# Configuring RPi fstab
./raspberry_02_install_fstab.sh <DevUUID> <FSType> <MountPoint>
... repeat it for all disks to add in fstab ...
  
# Install RPi Web Command Server
./raspberry_02_install_rpwcs.sh

# Install FTP service
./raspberry_02_install_vsftpd.sh

# Install aMule
./raspberry_03_install_amule.sh <PortTCP> <PortUDP> <DownloadFolder> <Password>

# Install JDownloader
./raspberry_03_install_jdownloader.sh <MyJDMail> <MyJDPass> <DeviceName> <DefaultDownloadFolder>

# Install Jellyfin
./raspberry_03_install_jellyfin.sh

# Install Transmission
./raspberry_03_install_transmission.sh <WebUser> <WebPass> <DownloadFolder>
```
