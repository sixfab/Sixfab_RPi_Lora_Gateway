#!/bin/bash

# internet connection
QMI_PATH="./Sixfab_QMI_Installer/"
cd $QMI_PATH

sudo chmod +x qmi_install.sh
sudo chmod +x install_auto_connect.sh

sudo ./qmi_install.sh
sudo ./install_auto_connect.sh

# lora gateway installation
LORA_PATH="../RAK2245-RAK831-LoRaGateway-RPi-Raspbian-OS/lora"
cd $LORA_PATH

sudo chmod +x install.sh
sudo ./install.sh

echo "Installation Complete - Please Reboot"
echo "After reboot check gateway-eui text file in [Sixfab_RPi_Lora_Gateway] folder"

read -p "Press ENTER key to reboot" ENTER
reboot
