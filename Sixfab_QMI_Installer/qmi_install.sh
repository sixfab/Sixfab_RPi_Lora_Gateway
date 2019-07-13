#!/bin/sh

: '
QMI installation script by Sixfab
Created By Metin Koc, Nov 2018
Modified by Saeed Johar,Yasin Kaya, June 2019
'

# Stop on the first sign of trouble
set -e

if [ $UID != 0 ]; then
    echo "ERROR: Operation not permitted. Forgot sudo?"
    exit 1
fi

YELLOW='\033[1;33m'
RED='\033[0;31m'
SET='\033[0m'

echo "${YELLOW}Clear old files${SET}"
rm -rf ~/files
rm -rf ~/files.zip

INS_DIR=~/files

echo "${YELLOW}Change directory to ~ ${SET}"
cd ~

echo "${YELLOW}Downloading source files${SET}"
wget https://github.com/sixfab/Sixfab_RPi_3G-4G-LTE_Base_Shield/raw/master/tutorials/QMI_tutorial/src/quectel-CM.zip
unzip quectel-CM.zip -d $INS_DIR && rm -r quectel-CM.zip


#echo "${YELLOW}Updating rpi${SET}"
#apt update

#echo "${YELLOW}Downlading kernel headers${SET}"
#apt install raspberrypi-kernel-headers
echo "${YELLOW}Checking Kernel${SET}"

case $(uname -r) in
    4.14*) echo $(uname -r) based kernel found
        echo "${YELLOW}Downloading source files${SET}"
        wget https://github.com/sixfab/Sixfab_RPi_3G-4G-LTE_Base_Shield/raw/master/tutorials/QMI_tutorial/src/4.14.zip -O drivers.zip
        unzip drivers.zip -d $INS_DIR && rm -r drivers.zip;;
    4.19*) echo $(uname -r) based kernel found 
        echo "${YELLOW}Downloading source files${SET}"
        wget https://github.com/sixfab/Sixfab_RPi_3G-4G-LTE_Base_Shield/raw/master/tutorials/QMI_tutorial/src/4.19.1.zip -O drivers.zip
        unzip drivers.zip -d $INS_DIR && rm -r drivers.zip;;
    *) echo "Driver for $(uname -r) kernel not found";exit 1;
esac

echo "${YELLOW}Installing udhcpc${SET}"
apt install udhcpc

echo "${YELLOW}Copying udhcpc default script${SET}"
mkdir -p /usr/share/udhcpc
cp -r  $INS_DIR/quectel-CM/default.script /usr/share/udhcpc/
chmod +x /usr/share/udhcpc/default.script

echo "${YELLOW}Change directory to /home/pi/files/drivers${SET}"
pushd $INS_DIR/drivers
make && make install
popd

echo "${YELLOW}Change directory to /home/pi/files/quectel-CM${SET}"
pushd $INS_DIR/quectel-CM
make
popd

echo "${YELLOW}After reboot please follow commands mentioned below${SET}"
echo "${YELLOW}go to $INS_DIR/quectel-CM and run sudo ./quectel-CM -s [YOUR APN]${SET}"

# read -p "Press ENTER key to reboot" ENTER
# reboot
