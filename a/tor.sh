#!/bin/bash

function tor
{
ifconfigcode="ifconfig.co/country"
location=$(curl -s $ifconfigcode)
if [ $location == 'Israel' ]
then
echo "Your location is from israel..."
sleep 3
echo "Conecting to tor networks..."
sleep 3
echo "Looking for tor..."
sleep 3
cd /root
git clone --quiet https://github.com/GouveaHeitor/nipe
cd nipe
chmod +x setup.sh
./setup.sh --assume-yes --qq
perl /root/nipe/nipe.pl install
perl /root/nipe/nipe.pl start
echo "Your connection is secure"
else
echo "Your connection is secure"
fi
}

tor
