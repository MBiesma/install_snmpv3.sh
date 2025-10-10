#!/bin/bash

# Version 1.1

USERNAME="svcPRTGsnmp"

# Do NOT edit below here!


# Define color variables
GREEN='\e[32m'
RED='\e[31m'
NC='\e[0m' # No Color (reset to default)

# Define the file path
FILE_PATH="/etc/snmp/snmpd.conf"

# Check if the file exists
if [ -f "$FILE_PATH" ]; then
   echo -e "\n${RED}  !!! File $FILE_PATH already exists. Exiting script. !!!\n${NC}"
   exit 1
else
   echo -e "\n${GREEN}  ... File $FILE_PATH does not exist. Continuing script.${NC}"
fi

#   echo -e "${GREEN}Enter IP adres from PRTG probe : ${NC}"
#read prtgprobeip
#   echo -e "${GREEN}  ... IP adres from PRTG probe saved${NC}"

   echo -e "\n${GREEN}  ... Run apt clean${NC}"
apt clean

   echo -e "\n${GREEN}  ... Run apt update${NC}"
apt update

   echo -e "\n${GREEN} ... Run apt autoremove${NC}"
apt autoremove -y

   echo -e "\n${GREEN} ... Install snmp snmpd libsnmp-dev with apt${NC}"
apt install snmp snmpd libsnmp-dev -y

   echo -e "\n${GREEN}  ... Enable SNMPD to Start on Boot${NC}"
systemctl enable snmpd

   echo -e "\n${GREEN}  ... Stopping SNMPD to use the net-snmp-config command${NC}"
systemctl stop snmpd

   echo -e "\n${GREEN}  ... Edit SNMPD listening address from 127.0.0.1 to 0.0.0.0${NC}"
sed -i 's/127.0.0.1/0.0.0.0/g' /etc/snmp/snmpd.conf


# Generate a random password
SNMPPASSWORD=$(head -c 16 /dev/urandom | base64 | tr -dc 'a-zA-Z1-9')

   echo -e "\n${GREEN}  ... Create SNMP v3 user and add to configuration files${NC}"
net-snmp-config --create-snmpv3-user -ro -A $SNMPPASSWORD -X $SNMPPASSWORD -a SHA -x AES $USERNAME

   echo -e "\n${GREEN}  ... Add disk monitoring for / and /boot to /etc/snmp/snmpd.conf ${NC}"
grep -q 'disk /' '/etc/snmp/snmpd.conf' || echo "disk /" >> /etc/snmp/snmpd.conf
grep -q 'disk /boot' '/etc/snmp/snmpd.conf' || echo "disk /boot" >> /etc/snmp/snmpd.conf

   echo -e "\n${GREEN}  ... Starting SNMPD ${NC}"
systemctl start snmpd
systemctl status snmpd | head -3 | tail +3


# Display the username andpassword
   echo -e "\n${GREEN}  .........................................................................  ${NC}"
     echo -e "${GREEN}  ...       ${NC}"
     echo -e "${GREEN}  ...            Your username is:${NC} ${RED}$USERNAME${NC}"
     echo -e "${GREEN}  ...            Your password is:${NC} ${RED}$SNMPPASSWORD${NC}"
     echo -e "${GREEN}  ...      Your Encryption Key is:${NC} ${RED}$SNMPPASSWORD${NC}"
     echo -e "${GREEN}  ...       Authentication Method:${NC} ${RED}SHA${NC}"
     echo -e "${GREEN}  ...             Encryption Type:${NC} ${RED}AES${NC}"
     echo -e "${GREEN}  ...  ${NC}"
     echo -e "${GREEN}  .........................................................................  ${NC}"
   echo ""
