#!/bin/bash

YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[1;34m'
SET='\033[0m'

# Stop on the first sign of trouble
set -e

if [ $UID != 0 ]; then
    echo "ERROR: Operation not permitted. Forgot sudo?"
    exit 1
fi

SCRIPT_DIR=$(pwd)

VERSION="master"
if [[ $1 != "" ]]; then VERSION=$1; fi

echo "The Things Network Gateway installer"
#echo "Version $VERSION"

# Request gateway configuration data
# There are two ways to do it, manually specify everything
# or rely on the gateway EUI and retrieve settings files from remote (recommended)
echo "Gateway configuration:"

# Try to get gateway ID from MAC address
# First try eth0, if that does not exist, try wlan0 (for RPi Zero)
GATEWAY_EUI_NIC="eth0"
if [[ `grep "$GATEWAY_EUI_NIC" /proc/net/dev` == "" ]]; then
    GATEWAY_EUI_NIC="wlan0"
fi

if [[ `grep "$GATEWAY_EUI_NIC" /proc/net/dev` == "" ]]; then
    echo "ERROR: No network interface found. Cannot set gateway ID."
    exit 1
fi

GATEWAY_EUI=$(ip link show $GATEWAY_EUI_NIC | awk '/ether/ {print $2}' | awk -F\: '{print $1$2$3"FFFE"$4$5$6}')
GATEWAY_EUI=${GATEWAY_EUI^^} # toupper

echo -e "Detected EUI ${YELLOW}$GATEWAY_EUI${SET} from ${YELLOW}$GATEWAY_EUI_NIC${SET}"

echo -e "${YELLOW}Please choose TTN channel configuration:${SET}"
echo -e "${YELLOW}1: US_902_928${SET}"
echo -e "${YELLOW}2: EU_863_870${SET}"

read ttn_channel
case $ttn_channel in
    1)    echo -e "${YELLOW}You choose US_902_928${SET}";;
    2)    echo -e "${YELLOW}You choose EU_863_870${SET}";;
    *)    echo -e "${RED}Wrong Selection, exiting${SET}"; exit 1;
esac

echo
echo -e "${YELLOW}Host name [sixfab-gateway]:${SET}"
read NEW_HOSTNAME
if [[ $NEW_HOSTNAME == "" ]]; then NEW_HOSTNAME="sixfab-gateway"; fi

echo -e "${YELLOW}Latitude [0]: ${SET}"
read GATEWAY_LAT
if [[ $GATEWAY_LAT == "" ]]; then GATEWAY_LAT=0; fi

echo -e "${YELLOW}Longitude [0]: ${SET}"
read GATEWAY_LON
if [[ $GATEWAY_LON == "" ]]; then GATEWAY_LON=0; fi

echo -e "${YELLOW}Altitude [0]: ${SET}"
read GATEWAY_ALT
if [[ $GATEWAY_ALT == "" ]]; then GATEWAY_ALT=0; fi


# Change hostname if needed
CURRENT_HOSTNAME=$(hostname)

if [[ $NEW_HOSTNAME != $CURRENT_HOSTNAME ]]; then
    echo "Updating hostname to '$NEW_HOSTNAME'..."
    hostname $NEW_HOSTNAME
    echo $NEW_HOSTNAME > /etc/hostname
    sed -i "s/$CURRENT_HOSTNAME/$NEW_HOSTNAME/" /etc/hosts
fi

# Check dependencies
echo "Installing dependencies..."
apt-get install git minicom dialog -y

# Install LoRaWAN packet forwarder repositories
INSTALL_DIR=/opt/ttn-gateway
if [ ! -d "$INSTALL_DIR" ]; then mkdir $INSTALL_DIR; fi
pushd $INSTALL_DIR

# Build LoRa gateway app

if [ ! -d lora_gateway ]; then
    git clone https://github.com/Lora-net/lora_gateway.git
fi

pushd lora_gateway

cp $SCRIPT_DIR/library.cfg ./libloragw/library.cfg
cp $SCRIPT_DIR/loragw_spi.native.c ./libloragw/src/loragw_spi.native.c
make

popd

# Build packet forwarder

if [ ! -d packet_forwarder ]; then
    git clone https://github.com/Lora-net/packet_forwarder.git
fi

pushd packet_forwarder

cp $SCRIPT_DIR/start.sh ./lora_pkt_fwd/start.sh
cp $SCRIPT_DIR/set_eui.sh ./lora_pkt_fwd/set_eui.sh
cp $SCRIPT_DIR/update_gwid.sh ./lora_pkt_fwd/update_gwid.sh
cp $SCRIPT_DIR/global_conf.json ./lora_pkt_fwd/global_conf.json
cp $SCRIPT_DIR/lora_pkt_fwd.c ./lora_pkt_fwd/src/lora_pkt_fwd.c

make

popd

LOCAL_CONFIG_FILE=$INSTALL_DIR/packet_forwarder/lora_pkt_fwd/local_conf.json

#config local_conf.json

    echo -e "{\n\t\"gateway_conf\": {\n\t\t\"gateway_ID\": \"$GATEWAY_EUI\" \n\t}\n}" >$LOCAL_CONFIG_FILE

GATEWAY_INFO=$INSTALL_DIR/gateway-info

echo -e > $GATEWAY_INFO 
echo "--------------------------------------------------------" >> $GATEWAY_INFO
echo "Gateway EUI is: $GATEWAY_EUI" >> $GATEWAY_INFO
echo "--------------------------------------------------------" >> $GATEWAY_INFO

echo "Open TTN console and register your gateway using your EUI: https://console.thethingsnetwork.org/gateways" >> $GATEWAY_INFO
echo >> $GATEWAY_INFO

TTN_CH_CONF_DIR="$SCRIPT_DIR/lora_conf/serial/"

if [ $ttn_channel -eq 1 ]; then
	cp $STTN_CH_CONF_DIR/global_conf.us_902_928.json $INSTALL_DIR/packet_forwarder/lora_pkt_fwd/global_conf.json
fi

if [ $ttn_channel -eq 2 ]; then
        cp $TTN_CH_CONF_DIR/global_conf.eu_863_870.json $INSTALL_DIR/packet_forwarder/lora_pkt_fwd/global_conf.json
fi

sed -i 's/AMA0/USB1/' $INSTALL_DIR/packet_forwarder/lora_pkt_fwd/global_conf.json

# Start packet forwarder as a service
#cp ./start.sh $INSTALL_DIR/bin/
cp $SCRIPT_DIR/ttn-gateway.service /lib/systemd/system/
systemctl enable ttn-gateway.service
systemctl start ttn-gateway.service

cd $SCRIPT_DIR
#cp gateway-config /usr/bin/gateway-config
cp gateway-version* /usr/bin/
cp lora_conf /etc/ -rf

