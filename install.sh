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

chmod +x qmi_install.sh
chmod +x install_auto_connect.sh

./qmi_install.sh
./install_auto_connect.sh

popd

# lora gateway installation
LORA_PATH=./lora
pushd $LORA_PATH

chmod +x install.sh
./install.sh

popd

pushd $QMI_PATH
./make_wwan0_default.sh
popd

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
