#!/bin/bash

# Stop on the first sign of trouble
set -e

if [ $UID != 0 ]; then
    echo "ERROR: Operation not permitted. Forgot sudo?"
    exit 1
fi

YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[1;34m'
SET='\033[0m'

# internet connection
QMI_PATH=./Sixfab_QMI_Installer/
pushd $QMI_PATH

sudo chmod +x qmi_install.sh
sudo chmod +x install_auto_connect.sh

sudo ./qmi_install.sh
sudo ./install_auto_connect.sh

popd

# lora gateway installation
LORA_PATH=./lora
pushd $LORA_PATH

sudo chmod +x install.sh
sudo ./install.sh

popd

# change routing table permanently
echo "interface wwan0;" >> /etc/dhcpcd.conf
echo "metric 200;" >> /etc/dhcpcd.conf

echo "Routing table is changed permanently"
echo "Given priority to wwan0 interface for cellular connection"

echo -e "${BLUE}--------------------------------------------------------------------------------"
echo -e "Installation Complete - Please Reboot"
echo -e "After reboot check /opt/ttn-gateway/gateway-info"
echo -e "--------------------------------------------------------------------------------${SET}"

echo -e "${YELLOW}"
cat /opt/ttn-gateway/gateway-info
echo
read -p "Press ENTER key to reboot" ENTER
reboot
