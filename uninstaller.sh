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

echo -e "${YELLOW}-----------------------------------"
echo -e "Sixfab gateway uninstaller!"
echo -e "-----------------------------------${SET}"

# stop and remove services
echo -e "${YELLOW}Removing gateway services${SET}"
systemctl stop ttn-gateway.service
systemctl disable ttn-gateway.service

systemctl stop qmi_reconnect.service
systemctl disable qmi_reconnect.service


# remove lora gateway
echo -e "${YELLOW}Clearing lora gateway files${SET}"
rm -rf /opt/ttn-gateway

# remove qmi interface
echo -e "${YELLOW}Clearing qmi Files${SET}"
rm -rf /opt/qmi_files

echo -e "${YELLOW}All Done!${SET}"
