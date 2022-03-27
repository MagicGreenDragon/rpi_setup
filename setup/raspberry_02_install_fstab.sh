#!/bin/bash

[[ $(whoami) != "root" ]] && echo "You must be root" && exit 1
[[ $# != 3 ]] && echo "Usage: $0 DevUUID FSType MountPoint" && exit 1

#### Inputs
export FSTAB_UUID=${1}
export FSTAB_TYPE=${2}
export FSTAB_MOUNT=${3}

#### RPi fstab Setup
echo "######## RPi fstab Setup ########"

# Creating mountpoint
echo -e "\n## Creating mountpoint..."
mkdir -vp ${FSTAB_MOUNT}

# Fstab Pre
echo -e "\n## Fstab Pre..."
cat /etc/fstab

# Configuring
echo -e "\n## Configuring..."
[[ $(grep ${FSTAB_UUID} /etc/fstab | wc -l) == 0 ]] && echo "UUID=${FSTAB_UUID} ${FSTAB_MOUNT} ${FSTAB_TYPE} rw,noexec,async,noatime,auto,nofail,nouser,nosymfollow 0 0" >> /etc/fstab

# Fstab Post
echo -e "\n## Fstab Post..."
cat /etc/fstab

# Mounting
echo -e "\n## Mounting..."
mount -a
