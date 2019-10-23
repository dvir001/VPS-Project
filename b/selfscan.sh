#!/bin/bash

RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
NC='\033[0m'

ip4=$(/sbin/ip -o -4 addr list eth0 | awk '{print $4}' | cut -d/ -f1)
echo -e "${YELLOW}"
echo -e "Scan starting ($ip4)..."
sleep 1
echo -e "${NC}"
nmap -sSUV -A -oN scanner.txt $ip4 | grep 'report for\|tcp\|udp\|Not shown\|MAC Address\|Running\|OS details\|Service Info'
echo -e "${GREEN}"
echo -e "Scan completed"
