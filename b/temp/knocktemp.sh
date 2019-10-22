#!/bin/bash

sudo iptables -A INPUT -i lo -j ACCEPT
sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
sudo iptables -A INPUT -j DROP
sudo iptables -S
sudo apt-get install iptables-persistent --assume-yes -qq
sudo service iptables-persistent start
sudo apt-get install knockd --assume-yes -qq

sudo nano /etc/knockd.conf

command = /sbin/iptables -I INPUT 1 -s %IP% -p tcp --dport 22 -j ACCEPT

sudo nano /etc/default/knockd
START_KNOCKD=1

sudo service knockd start

sudo nano /etc/knockd.conf

[options]
    UseSyslog

[SSH]
    sequence = 5438,3428,3280,4479
    tcpflags = syn
    seq_timeout = 15
    start_command = /sbin/iptables -I INPUT 1 -s %IP% -p tcp --dport 22 -j ACCEPT

    cmd_timeout = 10
    stop_command = /sbin/iptables -D INPUT -s %IP% -p tcp --dport 22 -j ACCEPT

sudo service knockd restart
























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



