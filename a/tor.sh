#!/bin/bash

RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${YELLOW}"
echo -e "Tor options:"
echo -e "\tStart:	Start Tor"
echo -e "\tStop:	Stop Tor"
echo -e "${RED}"
read -p "Enter option: "  type

Start(){
echo -e "${GREEN}---------------------Starting Tor---------------------"
echo -e "${YELLOW}"
echo -e "Installing / Updating Tor"
sleep 2

cd /etc
git clone https://github.com/GouveaHeitor/nipe
cd nipe
cat > y.txt << EOL
y

EOL
chmod +x setup.sh
./setup.sh < y.txt
echo -e "${Yellow}"
echo -e "Starting Tor"
perl /etc/nipe/nipe.pl start
sleep 1
echo -e ""
echo -e "${GREEN}Your connection is secure"
}

Stop(){
echo -e "${GREEN}---------------------Stoping Tor---------------------"
echo -e "${NC}"

cd /etc/nipe
perl nipe.pl stop
}

if [[ "$type" =~ ^(Start|Stop)$ ]]; then
	case "$type" in
		Start) 	Start;;
		Stop)	Stop;;
	esac
else
	echo -e "${RED}"
	echo -e "${RED}Invalid Type!"
	echo -e "${RED}"
	usage
fi
