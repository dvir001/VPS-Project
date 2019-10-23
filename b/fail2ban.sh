#!/bin/bash

RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${RED}"
read -p "Ban time (eg 10m): "  bantime
read -p "Find time (eg 10m): "  findtime
read -p "Max retry (eg 5): "  maxretry

apt-get install fail2ban --assume-yes -qq

cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
sleep 1
echo -e "${YELLOW}"
echo Setting ban time to $bantime
echo -e ""
sed -i '63s/# //' /etc/fail2ban/jail.local
sed -i "63s/10m/$bantime/" /etc/fail2ban/jail.local
sleep 1
echo Setting find time to $findtime
echo -e ""
sed -i '67s/# //' /etc/fail2ban/jail.local
sed -i "67s/10m/$findtime/" /etc/fail2ban/jail.local
sleep 1
echo Setting max retry to $maxretry
echo -e ""
sed -i '70s/# //' /etc/fail2ban/jail.local
sed -i "70s/5/$maxretry/" /etc/fail2ban/jail.local
sleep 1
echo -e "$GREEN"
echo Starting fail2ban...
service fail2ban start
service fail2ban restart
echo -e ""
echo fail2ban Running



