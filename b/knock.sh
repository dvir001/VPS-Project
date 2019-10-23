#!/bin/bash

#Install iptables-persistent
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | sudo debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | sudo debconf-set-selections
sudo apt-get -y install iptables-persistent --assume-yes -qq
#Edit ip table
cd /tmp/
cat > iptables.rules << EOL
*filter
:INPUT ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
-A INPUT -i lo -j ACCEPT
-A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
-A INPUT -p tcp --dport 80 -j ACCEPT
-A INPUT -j DROP
COMMIT
EOL
iptables-save > /tmp/iptables.rules
#sudo iptables -S
#Start iptables-persistent
sudo service netfilter-persistent start
#Install knock
sudo apt-get -y install knockd --assume-yes -qq
#Config knockd
sed -i '7s/-A/-I/' /etc/knockd.conf
sed -i '5s/0/1/' /etc/default/knockd
#start knock
sudo service knockd start
#Configuring Knockd to Close Connections Automatically
sed -i '5s/7000,8000,9000/1000,2000,3000/' /etc/knockd.conf
sed -i '11s/9000,8000,7000/3000,2000,1000/' /etc/knockd.conf
sed -i '15s//        cmd_timeout = 10' /etc/knockd.conf
knockd='        cmd_timeout = 10'
sed -e "\|$knockd|h; \${x;s|$knockd||;{g;t};a\\" -e "$knockd" -e "}" /etc/knockd.conf
sleep 1
knockd2='        stop_command = /sbin/iptables -D INPUT -s %IP% -p tcp --dport 22 -j ACCEPT'
sed -e "\|$knockd2|h; \${x;s|$knockd2||;{g;t};a\\" -e "$knockd2" -e "}" /etc/knockd.conf
#restart knock
sudo service knockd restart



