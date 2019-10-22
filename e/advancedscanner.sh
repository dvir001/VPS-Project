#!/bin/bash

RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
NC='\033[0m'
copyFile= '1'

SECONDS=0

echo -e "${YELLOW}"
echo -e "Scan Types:"
echo -e "\tQuick:	Shows all open ports quickly (~15 seconds)"
echo -e "\tBasic:	Runs Quick Scan, then a runs more thorough scan on found ports (~5 minutes)"
echo -e "\tUDP:	Runs \"Basic\" on UDP ports (~5 minutes)"
echo -e "\tFull:	Runs a full range port scan, then runs a thorough scan on new ports (~5-10 minutes)"
echo -e "\tVulns:	Runs CVE scan and nmap Vulns scan on all found ports (~5-15 minutes)"
echo -e "\tRecon:	Suggests recon commands, then prompts to automatically run them"
echo -e "\tAll:	Runs all the scans (~20-30 minutes)"
echo -e "\tRepeat:	Runs a full range port scan, then runs a thorough scan on new ports, will repeat itself every specified time (~5-10 minutes per scan)"
echo -e "${RED}"
read -p "Enter The ip addres for scan: "  ip
read -p "Enter The scan type: "  type


header(){
echo -e ""

if [ "$type" == "All" ]; then
	echo -e "${YELLOW}Running all scans on $ip"
else
	echo -e "${YELLOW}Running a $type scan on $ip"
fi

subnet=`echo "$ip" | cut -d "." -f 1,2,3`".0"

checkPing=`checkPing $ip`
nmapType="nmap -Pn"

: '
#nmapType=`echo "${checkPing}" | head -n 1`
if [ "$nmapType" != "nmap" ]; then 
	echo -e "${NC}"
	echo -e "${YELLOW}No ping detected.. Running with -Pn option!"
	echo -e "${NC}"
fi
'

ttl=`echo "${checkPing}" | tail -n 1`
if [[  `echo "${ttl}"` != "nmap -Pn" ]]; then
	osType="$(checkOS $ttl)"	
	echo -e "${NC}"
	echo -e "${GREEN}Host is likely running $osType"
	echo -e "${NC}"
fi

echo -e ""
echo -e ""
}

assignPorts(){
if [ -f nmap/Quick_$ip.nmap ]; then
	basicPorts=`cat nmap/Quick_$ip.nmap | grep open | cut -d " " -f 1 | cut -d "/" -f 1 | tr "\n" "," | cut -c3- | head -c-2`
fi

if [ -f nmap/Full_$ip.nmap ]; then
	if [ -f nmap/Quick_$ip.nmap ]; then
		allPorts=`cat nmap/Quick_$ip.nmap nmap/Full_$ip.nmap | grep open | cut -d " " -f 1 | cut -d "/" -f 1 | tr "\n" "," | cut -c3- | head -c-1`
	else
		allPorts=`cat nmap/Full_$ip.nmap | grep open | cut -d " " -f 1 | cut -d "/" -f 1 | tr "\n" "," | head -c-1`
	fi
fi

if [ -f nmap/UDP_$ip.nmap ]; then
	udpPorts=`cat nmap/UDP_$ip.nmap | grep -w "open " | cut -d " " -f 1 | cut -d "/" -f 1 | tr "\n" "," | cut -c3- | head -c-2`
	if [[ "$udpPorts" == "Al" ]]; then
		udpPorts=""
	fi
fi
}

checkPing(){
pingTest=`ping -c 1 -W 3 $ip | grep ttl`
if [[ -z $pingTest ]]; then
	echo "nmap -Pn"
else
	echo "nmap"
	ttl=`echo "${pingTest}" | cut -d " " -f 6 | cut -d "=" -f 2`
	echo "${ttl}"
fi
}

checkOS(){
if [ "$ip" == 256 ] || [ "$ip" == 255 ] || [ "$ip" == 254 ]; then
        echo "OpenBSD/Cisco/Oracle"
elif [ "$ip" == 128 ] || [ "$ip" == 127 ]; then
        echo "Windows"
elif [ "$ip" == 64 ] || [ "$ip" == 63 ]; then
        echo "Linux"
else
        echo "Unknown OS!"
fi
}

cmpPorts(){
oldIFS=$IFS
IFS=','
touch nmap/cmpPorts_$ip.txt

for i in `echo "${allPorts}"`
do
	if [[ "$i" =~ ^($(echo "${basicPorts}" | sed 's/,/\|/g'))$ ]]; then
       	       :
       	else
       	        echo -n "$i," >> nmap/cmpPorts_$ip.txt
       	fi
done

extraPorts=`cat nmap/cmpPorts_$ip.txt | tr "\n" "," | head -c-1`
rm nmap/cmpPorts_$ip.txt
IFS=$oldIFS
}

quickScan(){
echo -e "${GREEN}---------------------Starting Nmap Quick Scan---------------------"
echo -e "${NC}"

$nmapType -T4 --max-retries 1 --max-scan-delay 20 --defeat-rst-ratelimit --open -oN nmap/Quick_$ip.nmap $ip
assignPorts $ip

echo -e ""
echo -e ""
echo -e ""
}

basicScan(){
echo -e "${GREEN}---------------------Starting Nmap Basic Scan---------------------"
echo -e "${NC}"

if [ -z `echo "${basicPorts}"` ]; then
        echo -e "${YELLOW}No ports in quick scan.. Skipping!"
else
	$nmapType -sCV -p`echo "${basicPorts}"` -oN nmap/Basic_$ip.nmap $ip 
fi

if [ -f nmap/Basic_$ip.nmap ] && [[ ! -z `cat nmap/Basic_$ip.nmap | grep -w "Service Info: OS:"` ]]; then
	serviceOS=`cat nmap/Basic_$ip.nmap | grep -w "Service Info: OS:" | cut -d ":" -f 3 | cut -c2- | cut -d ";" -f 1 | head -c-1`
	if [[ "$osType" != "$serviceOS"  ]]; then
		osType=`echo "${serviceOS}"`
		echo -e "${NC}"
		echo -e "${NC}"
		echo -e "${GREEN}OS Detection modified to: $osType"
		echo -e "${NC}"
	fi
fi

echo -e ""
echo -e ""
echo -e ""
}

UDPScan(){
echo -e "${GREEN}----------------------Starting Nmap UDP Scan----------------------"
echo -e "${NC}"

$nmapType -sU --max-retries 1 --open -oN nmap/UDP_$ip.nmap $ip
assignPorts $ip

if [ ! -z `echo "${udpPorts}"` ]; then
        echo ""
        echo ""
        echo -e "${YELLOW}Making a script scan on UDP ports: `echo "${udpPorts}" | sed 's/,/, /g'`"
        echo -e "${NC}"
	if [ -f /usr/share/nmap/scripts/vulners.nse ]; then
        	$nmapType -sCVU --script vulners --script-args mincvss=7.0 -p`echo "${udpPorts}"` -oN nmap/UDP_$ip.nmap $ip
	else
        	$nmapType -sCVU -p`echo "${udpPorts}"` -oN nmap/UDP_$ip.nmap $ip
	fi
fi

echo -e ""
echo -e ""
echo -e ""
}

fullScan(){
echo -e "${GREEN}---------------------Starting Nmap Full Scan----------------------"
echo -e "${NC}"

$nmapType -p- --max-retries 1 --max-rate 500 --max-scan-delay 20 -T4 -v -oN nmap/Full_$ip.nmap $ip
assignPorts $ip

if [ -z `echo "${basicPorts}"` ]; then
	echo ""
        echo ""
        echo -e "${YELLOW}Making a script scan on all ports"
        echo -e "${NC}"
        $nmapType -sCV -p`echo "${allPorts}"` -oN nmap/Full_$ip.nmap $ip
	assignPorts $ip
else
	cmpPorts $ip
	if [ -z `echo "${extraPorts}"` ]; then
        	echo ""
        	echo ""
		allPorts=""
        	echo -e "${YELLOW}No new ports"
		rm nmap/Full_$ip.nmap
        	echo -e "${NC}"
	else
		echo ""
        	echo ""
        	echo -e "${YELLOW}Making a script scan on extra ports: `echo "${extraPorts}" | sed 's/,/, /g'`"
        	echo -e "${NC}"
        	$nmapType -sCV -p`echo "${extraPorts}"` -oN nmap/Full_$ip.nmap $ip
		assignPorts $ip
	fi
fi

echo -e ""
echo -e ""
echo -e ""
}

fullScanRepeat(){
while [ 1 ]
do
echo -e "${RED}"
read -p "How long to wait till next scan in seconds: "  time
echo -e "${GREEN}---------------------Starting Nmap Full Scan----------------------"
echo -e "${NC}"

$nmapType -p- --max-retries 1 --max-rate 500 --max-scan-delay 20 -T4 -v -oN nmap/Full_$ip.nmap $ip
assignPorts $ip

if [ -z `echo "${basicPorts}"` ]; then
	echo ""
        echo ""
        echo -e "${YELLOW}Making a script scan on all ports"
        echo -e "${NC}"
        $nmapType -sCV -p`echo "${allPorts}"` -oN nmap/Full_$ip.nmap $ip
	assignPorts $ip
else
	cmpPorts $ip
	if [ -z `echo "${extraPorts}"` ]; then
        	echo ""
        	echo ""
		allPorts=""
        	echo -e "${YELLOW}No new ports"
		rm nmap/Full_$ip.nmap
        	echo -e "${NC}"
	else
		echo ""
        	echo ""
        	echo -e "${YELLOW}Making a script scan on extra ports: `echo "${extraPorts}" | sed 's/,/, /g'`"
        	echo -e "${NC}"
        	$nmapType -sCV -p`echo "${extraPorts}"` -oN nmap/Full_$ip.nmap $ip
		assignPorts $ip
	fi
fi

echo -e ""
echo -e ""
echo -e ""
    sleep $time
done
}

vulnsScan(){
echo -e "${GREEN}---------------------Starting Nmap Vulns Scan---------------------"
echo -e "${NC}"

if [ -z `echo "${allPorts}"` ]; then
	portType="basic"
	ports=`echo "${basicPorts}"`
else
	portType="all"
	ports=`echo "${allPorts}"`
fi


if [ ! -f /usr/share/nmap/scripts/vulners.nse ]; then
	echo -e "${RED}Please install 'vulners.nse' nmap script:"
	echo -e "${RED}https://github.com/vulnersCom/nmap-vulners"
        echo -e "${RED}"
        echo -e "${RED}Skipping CVE scan!"
	echo -e "${NC}"
else    
	echo -e "${YELLOW}Running CVE scan on $portType ports"
	echo -e "${NC}"
	$nmapType -sV --script vulners --script-args mincvss=7.0 -p`echo "${ports}"` -oN nmap/CVEs_$ip.nmap $ip
	echo ""
fi

echo ""
echo -e "${YELLOW}Running Vuln scan on $portType ports"
echo -e "${NC}"
$nmapType -sV --script vuln -p`echo "${ports}"` -oN nmap/Vulns_$ip.nmap $ip
echo -e ""
echo -e ""
echo -e ""
}

recon(){

reconRecommend $ip | tee nmap/Recon_$ip.nmap

availableRecon=`cat nmap/Recon_$ip.nmap | grep $ip | cut -d " " -f 1 | sed 's/.\///g; s/.py//g; s/cd/odat/g;' | sort -u | tr "\n" "," | sed 's/,/,\ /g' | head -c-2`

secs=30
count=0

reconCommand=""

if [ ! -z "$availableRecon"  ]; then
	while [ ! `echo "${reconCommand}"` == "!" ]; do
		echo -e "${YELLOW}"
		echo -e "Which commands would you like to run?${NC}\nAll (Default), $availableRecon, Skip <!>\n"
		while [[ ${count} -lt ${secs} ]]; do
			tlimit=$(( $secs - $count ))
			echo -e "\rRunning Default in (${tlimit}) s: \c"
			read -t 1 reconCommand
			[ ! -z "$reconCommand" ] && { break ;  }
			count=$((count+1))
		done
		if [ "$reconCommand" == "All" ] || [ -z `echo "${reconCommand}"` ]; then
			runRecon $ip "All"
			reconCommand="!"
		elif [[ "$reconCommand" =~ ^($(echo "${availableRecon}" | tr ", " "|"))$ ]]; then
			runRecon $ip $reconCommand
			reconCommand="!"
		elif [ "$reconCommand" == "Skip" ] || [ "$reconCommand" == "!" ]; then
			reconCommand="!"
			echo -e ""
			echo -e ""
			echo -e ""
		else
			echo -e "${NC}"
			echo -e "${RED}Incorrect choice!"
			echo -e "${NC}"
		fi
	done
fi

}

reconRecommend(){
echo -e "${GREEN}---------------------Recon Recommendations----------------------"
echo -e "${NC}"

oldIFS=$IFS
IFS=$'\n'

if [ -f nmap/Full_$ip.nmap ] && [ -f nmap/Basic_$ip.nmap ]; then
	ports=`echo "${allPorts}"`
	file=`cat nmap/Basic_$ip.nmap nmap/Full_$ip.nmap | grep -w "open"`
elif [ -f nmap/Full_$ip.nmap ]; then
	ports=`echo "${allPorts}"`
	file=`cat nmap/Quick_$ip.nmap nmap/Full_$ip.nmap | grep -w "open"`
elif [ -f nmap/Basic_$ip.nmap ]; then
	ports=`echo "${basicPorts}"`
	file=`cat nmap/Basic_$ip.nmap | grep -w "open"`
else
	ports=`echo "${basicPorts}"`
	file=`cat nmap/Quick_$ip.nmap | grep -w "open"`

fi

if [[ ! -z `echo "${file}" | grep -i http` ]]; then
	echo -e "${NC}"
	echo -e "${YELLOW}Web Servers Recon:"
	echo -e "${NC}"
fi

for line in $file; do
	if [[ ! -z `echo "${line}" | grep -i http` ]]; then
		port=`echo "${line}" | cut -d "/" -f 1`
		if [[ ! -z `echo "${line}" | grep -w "IIS"` ]]; then
			pages=".html,.asp,.php"
		else
			pages=".html,.php"
		fi
		if [[ ! -z `echo "${line}" | grep ssl/http` ]]; then
			#echo "sslyze --regular $ip | tee recon/sslyze_$ip_$port.txt"
			echo "sslscan $ip | tee recon/sslscan_$ip_$port.txt"
			echo "gobuster dir -w /usr/share/wordlists/dirb/common.txt -l -t 30 -e -k -x $pages -u https://$ip:$port -o recon/gobuster_$ip_$port.txt"
			echo "nikto -host https://$ip:$port -ssl | tee recon/nikto_$ip_$port.txt"
		else
			echo "gobuster dir -w /usr/share/wordlists/dirb/common.txt -l -t 30 -e -k -x $pages -u http://$ip:$port -o recon/gobuster_$ip_$port.txt"
			echo "nikto -host $ip:$port | tee recon/nikto_$ip_$port.txt"
		fi
		echo ""
	fi
done

if [ -f nmap/Basic_$ip.nmap ]; then
	cms=`cat nmap/Basic_$ip.nmap | grep http-generator | cut -d " " -f 2`
	if [ ! -z `echo "${cms}"` ]; then
		for line in $cms; do
			port=`cat nmap/Basic_$ip.nmap | grep $line -B1 | grep -w "open" | cut -d "/" -f 1`
			if [[ "$cms" =~ ^(Joomla|WordPress|Drupal)$ ]]; then
				echo -e "${NC}"
				echo -e "${YELLOW}CMS Recon:"
				echo -e "${NC}"
			fi
			case "$cms" in
				Joomla!) echo "joomscan --url $ip:$port | tee recon/joomscan_$ip_$port.txt";;
				WordPress) echo "wpscan --url $ip:$port --enumerate p | tee recon/wpscan_$ip_$port.txt";;
				Drupal) echo "droopescan scan drupal -u $ip:$port | tee recon/droopescan_$ip_$port.txt";;
			esac
		done
	fi
fi

if [[ ! -z `echo "${file}" | grep -w "445/tcp"` ]]; then
	echo -e "${NC}"
	echo -e "${YELLOW}SMB Recon:"
	echo -e "${NC}"
	echo "smbmap -H $ip | tee recon/smbmap_$ip.txt"
	echo "smbclient -L \"//$ip/\" -U \"guest\"% | tee recon/smbclient_$ip.txt"
	if [[ $osType == "Windows" ]]; then
		echo "nmap -Pn -p445 --script vuln -oN recon/SMB_vulns_$ip.txt $ip"
	fi
	if [[ $osType == "Linux" ]]; then
		echo "enum4linux -a $ip | tee recon/enum4linux_$ip.txt"
	fi
	echo ""
elif [[ ! -z `echo "${file}" | grep -w "139/tcp"` ]] && [[ $osType == "Linux" ]]; then
	echo -e "${NC}"
	echo -e "${YELLOW}SMB Recon:"
	echo -e "${NC}"
	echo "enum4linux -a $ip | tee recon/enum4linux_$ip.txt"
	echo ""
fi


if [ -f nmap/UDP_$ip.nmap ] && [[ ! -z `cat nmap/UDP_$ip.nmap | grep open | grep -w "161/udp"` ]]; then
	echo -e "${NC}"
	echo -e "${YELLOW}SNMP Recon:"
	echo -e "${NC}"
	echo "snmp-check $ip -c public | tee recon/snmpcheck_$ip.txt"
	echo "snmpwalk -Os -c public -v $ip | tee recon/snmpwalk_$ip.txt"
	echo ""
fi

if [[ ! -z `echo "${file}" | grep -w "53/tcp"` ]]; then
	echo -e "${NC}"
	echo -e "${YELLOW}DNS Recon:"
	echo -e "${NC}"
	echo "host -l $ip $ip | tee recon/hostname_$ip.txt"
	echo "dnsrecon -r $subnet/24 -n $ip | tee recon/dnsrecon_$ip.txt"
	echo "dnsrecon -r 127.0.0.0/24 -n $ip | tee recon/dnsrecon-local_$ip.txt"
	echo ""
fi

if [[ ! -z `echo "${file}" | grep -w "1521/tcp"` ]]; then
	echo -e "${NC}"
	echo -e "${YELLOW}Oracle Recon \"Exc. from Default\":"
	echo -e "${NC}"
	echo "cd /opt/odat/;#$ip;"
	echo "./odat.py sidguesser -s $ip -p 1521"
	echo "./odat.py passwordguesser -s $ip -p 1521 -d XE --accounts-file accounts/accounts-multiple.txt"
	echo "cd -;#$ip;"
	echo ""
fi

IFS=$oldIFS

echo -e ""
echo -e ""
echo -e ""
}

runRecon(){
echo -e ""
echo -e ""
echo -e ""
echo -e "${GREEN}---------------------Running Recon Commands----------------------"
echo -e "${NC}"

oldIFS=$IFS
IFS=$'\n'

if [[ ! -d recon/ ]]; then
        mkdir recon/
fi

if [ "$type" == "All" ]; then
	reconCommands=`cat nmap/Recon_$ip.nmap | grep $ip | grep -v odat`
else
	reconCommands=`cat nmap/Recon_$ip.nmap | grep $ip | grep $type`
fi

for line in `echo "${reconCommands}"`; do
	currentScan=`echo $line | cut -d " " -f 1 | sed 's/.\///g; s/.py//g; s/cd/odat/g;' | sort -u | tr "\n" "," | sed 's/,/,\ /g' | head -c-2`
	fileName=`echo "${line}" | awk -F "recon/" '{print $type}' | head -c-1`
	if [ ! -z recon/`echo "${fileName}"` ] && [ ! -f recon/`echo "${fileName}"` ]; then
		echo -e "${NC}"
		echo -e "${YELLOW}Starting $currentScan scan"
		echo -e "${NC}"
		echo $line | /bin/bash
		echo -e "${NC}"
		echo -e "${YELLOW}Finished $currentScan scan"
		echo -e "${NC}"
		echo -e "${YELLOW}========================="
	fi
done

IFS=$oldIFS

echo -e ""
echo -e ""
echo -e ""
}

footer(){

echo -e "${GREEN}---------------------Finished all Nmap scans---------------------"
echo -e "${NC}"
echo -e ""

if (( $SECONDS > 3600 )) ; then
    let "hours=SECONDS/3600"
    let "minutes=(SECONDS%3600)/60"
    let "seconds=(SECONDS%3600)%60"
    echo -e "${YELLOW}Completed in $hours hour(s), $minutes minute(s) and $seconds second(s)" 
elif (( $SECONDS > 60 )) ; then
    let "minutes=(SECONDS%3600)/60"
    let "seconds=(SECONDS%3600)%60"
    echo -e "${YELLOW}Completed in $minutes minute(s) and $seconds second(s)"
else
    echo -e "${YELLOW}Completed in $SECONDS seconds"
fi
echo -e ""
}

if (( "$#" != 2 )); then
	usage
fi

if [[ $ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
	:
else
	echo -e "${RED}"
	echo -e "${RED}Invalid IP!"
	echo -e "${RED}"
	usage
fi

if [[ "$type" =~ ^(Quick|Basic|UDP|Full|Vulns|Recon|All|Repeat)$ ]]; then
	if [[ ! -d $ip ]]; then
	        mkdir $ip
	fi

	cd $ip
	
	if [[ ! -d nmap/ ]]; then
	        mkdir nmap/
	fi
	
	assignPorts $ip

	header $ip $type
	
	case "$type" in
		Quick) 	quickScan $ip;;
		Basic)	if [ ! -f nmap/Quick_$ip.nmap ]; then quickScan $ip; fi
			basicScan $ip;;
		UDP) 	UDPScan $ip;;
		Full) 	fullScan $ip;;
		Vulns) 	if [ ! -f nmap/Quick_$ip.nmap ]; then quickScan $ip; fi
			vulnsScan $ip;;
		Recon) 	if [ ! -f nmap/Quick_$ip.nmap ]; then quickScan $ip; fi
			if [ ! -f nmap/Basic_$ip.nmap ]; then basicScan $ip; fi
			recon $ip;;
		All)	quickScan $ip
			basicScan $ip
			UDPScan $ip
			fullScan $ip
			vulnsScan $ip
			recon $ip;;
		Repeat) fullScanRepeat $ip;;
	esac
	
	footer
else
	echo -e "${RED}"
	echo -e "${RED}Invalid Type!"
	echo -e "${RED}"
	usage
fi
