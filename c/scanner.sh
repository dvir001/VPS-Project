#!/bin/bash

RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${RED}"
read -p "IP to scan: "  ip
echo -e "${NC}"
nmap -sSUV -A -oN scanner.txt $ip | grep 'report for\|tcp\|udp\|Not shown\|MAC Address\|Running\|OS details\|Service Info'
