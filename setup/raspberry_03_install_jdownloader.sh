#!/bin/bash

[[ $(whoami) != "root" ]] && echo "You must be root" && exit 1
[[ ! -d ./files/jdownloader ]] && echo "Missing files folder" && exit 1
[[ $# != 4 ]] && echo "Usage: $0 MyJDMail MyJDPass DeviceName DefaultDownloadFolder" && exit 1

#### Inputs
export JD_MYJD_MAIL=${1}
export JD_MYJD_PASS=${2}
export JD_DEVICE_NAME=${3}
export JD_DL_FOLDER=${4}

#### Variables
export JD_INSTALL_LOG=/home/jdownloader/install.log
export JD_INSTALL_RES=/home/jdownloader/install.result
export JD_INSTALL_PATH=/home/jdownloader/jd
export JD_JAR_PATH=${JD_INSTALL_PATH}/JDownloader.jar
export JD_CFG_PATH=${JD_INSTALL_PATH}/cfg
export JD_EXT_PATH=${JD_INSTALL_PATH}/update/versioninfo/JD
export JD_CORE_PATH=${JD_INSTALL_PATH}/Core.jar
export JD_GENERAL_SETTINGS_JSON=${JD_CFG_PATH}/org.jdownloader.settings.GeneralSettings.json
export JD_RECONNECT_SETTINGS_JSON=${JD_CFG_PATH}/jd.controlling.reconnect.ReconnectConfig.json
export JD_MYJD_SETTINGS_JSON=${JD_CFG_PATH}/org.jdownloader.api.myjdownloader.MyJDownloaderSettings.json

#### JDownloader Setup
echo -e "######## JDownloader RPi Setup ########"

# Installing prerequisites
echo -e "\n## Installing prerequisites (only if java is not installed)..."
[[ ! -f /usr/bin/java ]] && apt -y install openjdk-8-jre-headless

# Creating user
echo -e "\n## Creating user..."
JD_USER_CHECK=$(grep "^jdownloader:" /etc/passwd | wc -l)
[[ ${JD_USER_CHECK} == 0 ]] && echo "Check: absent -> create"  && adduser --home /home/jdownloader --shell /usr/sbin/nologin --disabled-login --gecos "" jdownloader
[[ ${JD_USER_CHECK} == 1 ]] && echo "Check: present -> update" && usermod --home /home/jdownloader --shell /usr/sbin/nologin jdownloader

# Creating directories
echo -e "\n## Creating directories..."
mkdir -vp ${JD_INSTALL_PATH} ${JD_CFG_PATH} ${JD_EXT_PATH}
chown -Rv jdownloader:jdownloader ${JD_INSTALL_PATH}

# Downloading JAR
echo -e "\n## Downloading JAR..."
[[ ! -f ${JD_JAR_PATH} ]] && wget -O "${JD_JAR_PATH}" "http://installer.jdownloader.org/JDownloader.jar"
chown -v jdownloader:jdownloader ${JD_JAR_PATH}
chmod -v 644 ${JD_JAR_PATH}

# Checking JAR integrity
echo -e "\n## Checking JAR integrity..."
unzip -t ${JD_JAR_PATH} &> /dev/null
JD_JAR_CHECK=$?
[[ ${JD_JAR_CHECK} != 0 ]] && echo "Corrupted -> Fail" && exit 1
[[ ${JD_JAR_CHECK} == 0 ]] && echo "OK"

# Installing systemd unit
echo -e "\n## Installing systemd unit..."
cp -v ./files/jdownloader/jdownloader.service /etc/systemd/system/jdownloader.service
chown root:root /etc/systemd/system/jdownloader.service
chmod 644 /etc/systemd/system/jdownloader.service
systemctl daemon-reload
systemctl stop jdownloader

# Installing autoupdate script
echo -e "\n## Installing autoupdate script..."
if [[ ! -f ${JD_MYJD_SETTINGS_JSON}/org.jdownloader.extensions.eventscripter.EventScripterExtension.json ]]
then
    cp ./files/jdownloader/extensions.requestedinstalls.json ${JD_EXT_PATH}
    cp ./files/jdownloader/org.jdownloader.extensions.eventscripter.EventScripterExtension.json ${JD_CFG_PATH}
    cp ./files/jdownloader/org.jdownloader.extensions.eventscripter.EventScripterExtension.scripts.json ${JD_CFG_PATH}
    chown -v jdownloader:jdownloader ${JD_EXT_PATH}/extensions.requestedinstalls.json
    chown -v jdownloader:jdownloader ${JD_CFG_PATH}/org.jdownloader.extensions.eventscripter.EventScripterExtension.json
    chown -v jdownloader:jdownloader ${JD_CFG_PATH}/org.jdownloader.extensions.eventscripter.EventScripterExtension.scripts.json
    chmod -v 644 ${JD_EXT_PATH}/extensions.requestedinstalls.json
    chmod -v 644 ${JD_CFG_PATH}/org.jdownloader.extensions.eventscripter.EventScripterExtension.json
    chmod -v 644 ${JD_CFG_PATH}/org.jdownloader.extensions.eventscripter.EventScripterExtension.scripts.json
fi

# Creating default download folder
echo -e "\n## Creating default download folder..."
mkdir -vp ${JD_DL_FOLDER}
chown -v jdownloader:jdownloader ${JD_DL_FOLDER}
chmod -v 777 ${JD_DL_FOLDER}

# Configuring general settings
echo -e "\n## Configuring default general settings..."
[[ ! -f ${JD_GENERAL_SETTINGS_JSON} ]] && tee ${JD_GENERAL_SETTINGS_JSON} > /dev/null << EOT
{
    "defaultdownloadfolder": "${JD_DL_FOLDER}",
    "maxsimultanedownloads": 1,
    "maxsimultanedownloadsperhost": 1
}
EOT
chown -v jdownloader:jdownloader ${JD_GENERAL_SETTINGS_JSON}
chmod -v 644 ${JD_GENERAL_SETTINGS_JSON}

# Configuring default Reconnect settings
echo -e "\n## Configuring default Reconnect settings..."
[[ ! -f ${JD_RECONNECT_SETTINGS_JSON} ]] && tee ${JD_RECONNECT_SETTINGS_JSON} > /dev/null << EOT
{
    "autoreconnectenabled":false
}
EOT
chown -v jdownloader:jdownloader ${JD_RECONNECT_SETTINGS_JSON}
chmod -v 644 ${JD_RECONNECT_SETTINGS_JSON}

# Configuring default myJDownloader settings
echo -e "\n## Configuring default MyJDownloader settings..."
[[ ! -f ${JD_MYJD_SETTINGS_JSON} ]] && tee ${JD_MYJD_SETTINGS_JSON} > /dev/null << EOT
{
    "email": "${JD_MYJD_MAIL}",
    "password": "${JD_MYJD_PASS}",
    "devicename": "${JD_DEVICE_NAME}",
    "directconnectmode": "LAN",
    "autoconnectenabledv2": true
}
EOT
chown -v jdownloader:jdownloader ${JD_MYJD_SETTINGS_JSON}
chmod -v 644 ${JD_MYJD_SETTINGS_JSON}

# Installing JDownloader (can take some minutes)
echo -e "\n## Installing JDownloader (can take some minutes)..."
if [[ ! -f ${JD_CORE_PATH} ]]
then
    su - jdownloader -s /bin/bash -c "/usr/bin/java -Djava.awt.headless=true -jar ${JD_JAR_PATH} -norestart &> ${JD_INSTALL_LOG} ; echo $? > ${JD_INSTALL_RES}" &> /dev/null
    JD_INSTALL_RES=$(cat ${JD_INSTALL_RES})
    [[ ${JD_INSTALL_RES} == 0 ]] && echo "OK"
    [[ ${JD_INSTALL_RES} != 0 ]] && echo "FAILED (${JD_INSTALL_RES}) - For details see logfile -> ${JD_INSTALL_LOG}" && exit 1
else
    echo "OK"
fi

# Starting JDownloader
export SYSTEMD_PAGER=
echo -e "\n## Starting JDownloader..."
systemctl enable --now jdownloader
systemctl status jdownloader

# MyJDownloader hint
echo -e "\n## Now you can manage '${JD_DEVICE_NAME}' JDownloader instance via '${JD_MYJD_MAIL}' MyJDownloader account"
