#!/bin/bash

apt-get install fail2ban --assume-yes -qq

cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
sleep 1
echo Setting bantime to 5m
sed -i '63s/# //' /etc/fail2ban/jail.local
sed -i '63s/10m/5m/' /etc/fail2ban/jail.local
sleep 1
echo Setting findtime to 5m
sed -i '67s/# //' /etc/fail2ban/jail.local
sed -i '67s/10m/5m/' /etc/fail2ban/jail.local
sleep 1
echo Setting maxretry to 10
sed -i '70s/# //' /etc/fail2ban/jail.local
sed -i '70s/5/10/' /etc/fail2ban/jail.local
sleep 1
echo Starting fail2ban...
service fail2ban start
service fail2ban restart
echo fail2ban Running



