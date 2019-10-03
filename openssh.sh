#!/bin/bash

apt-get install ufw --assume-yes
sudo ufw allow from $1/$2 to any port 22
echo Opend SHH for $1/$2
