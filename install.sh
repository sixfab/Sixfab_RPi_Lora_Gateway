#!/bin/bash

# take recovery of system files
RECOVERY_DIR="/opt/ttn_gateway_recovery"
mkdir $RECOVERY_DIR
cp /etc/dhcpcd.conf $RECOVERY_DIR/dhcpcd.conf

# internet connection
QMI_PATH="./Sixfab_QMI_Installer/"
pushd $QMI_PATH

sudo chmod +x qmi_install.sh
sudo chmod +x install_auto_connect.sh

sudo ./qmi_install.sh
sudo ./install_auto_connect.sh

popd

# lora gateway installation
LORA_PATH="./RAK2245-RAK831-LoRaGateway-RPi-Raspbian-OS/lora"
pushd $LORA_PATH

sudo chmod +x install.sh
sudo ./install.sh

popd

# recover dhcpcd.conf
mv $RECOVERY_DIR/dhcpcd.conf /etc/dhcpcd.conf

# change routing table permanently
echo "interface wwan0;" >> /etc/dhcpcd.conf
echo "metric 200;" >> /etc/dhcpcd.conf

echo "Routing table is changed permanently"
echo "Given priority to wwan0 interface for cellular connection"

echo "--------------------------------------------------------------------------------"
echo "Installation Complete - Please Reboot"
echo "After reboot check gateway-eui text file in [Sixfab_RPi_Lora_Gateway] folder"
echo "--------------------------------------------------------------------------------"

read -p "Press ENTER key to reboot" ENTER
reboot
