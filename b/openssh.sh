#!/bin/bash

read -p "Enter The ip address that you want to allow access to SSH: "  ip
read -p "Enter The ip subnet: "  subnet

apt-get install ufw --assume-yes -qq
sudo ufw allow from $ip/$subnet to any port 22
echo Opend SHH for $ip/$subnet
