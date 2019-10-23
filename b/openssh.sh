#!/bin/bash

RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${YELLOW}"
echo -e "This script will open port 22 for one IP addres"

echo -e "${RED}"
read -p "IP addres: "  ip
read -p "IP subnet: "  subnet

apt-get install ufw --assume-yes -qq
sudo ufw allow from $ip/$subnet to any port 22
echo -e "${GREEN}"
echo Opened port 22 for $ip/$subnet
