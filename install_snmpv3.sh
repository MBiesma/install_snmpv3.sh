
#!/bin/bash
#
# install_snmpv3.sh
# Version 1.10 (2025-11-24)

set -euo pipefail

USERNAME="svcPRTGsnmp"
PRTG_DIR="/var/prtg/scripts"
SNMP_CONF="/etc/snmp/snmpd.conf"

GREEN='\e[32m'
RED='\e[31m'
NC='\e[0m'

download_script() {
    local url="$1"
    local dest="$2"

    echo -e "${GREEN}Downloading: $url${NC}"

    if ! wget -q -O "$dest" "$url"; then
        echo -e "${RED}[FATAL] Failed to download: $url${NC}"
        exit 1
    fi

    chmod +x "$dest"
}

echo -e "${GREEN}=== Detecting Operating System ===${NC}"

if grep -qi "ubuntu\|debian" /etc/os-release; then
    OS="ubuntu"
    echo -e "${GREEN}Ubuntu/Debian detected${NC}"
elif grep -qi "rhel\|centos\|almalinux\|rocky\|oracle\|ol" /etc/os-release; then
    OS="redhat"
    echo -e "${GREEN}RedHat-like OS detected${NC}"
else
    echo -e "${RED}Unsupported OS${NC}"
    exit 1
fi

mkdir -p "$PRTG_DIR"

echo -e "${GREEN}Checking if wget is installed...${NC}"
if ! command -v wget >/dev/null 2>&1; then
    echo -e "${GREEN}Installing wget...${NC}"
    if [ "$OS" = "ubuntu" ]; then
        apt update -y
        apt install -y wget
    else
        (command -v dnf >/dev/null 2>&1 && dnf install -y wget) || yum install -y wget
    fi
fi

echo -e "${GREEN}=== Downloading PRTG Scripts ===${NC}"

download_script "https://raw.githubusercontent.com/MBiesma/prtg_service_cron.sh/main/prtg_service_cron.sh" \
                "$PRTG_DIR/prtg_service_cron.sh"

download_script "https://raw.githubusercontent.com/MBiesma/prtg_service_sshd.sh/main/prtg_service_sshd.sh" \
                "$PRTG_DIR/prtg_service_sshd.sh"

download_script "https://raw.githubusercontent.com/MBiesma/prtg_service_talend-remote-engine.sh/main/prtg_service_talend-remote-engine.sh" \
                "$PRTG_DIR/prtg_service_talend-remote-engine.sh"

download_script "https://raw.githubusercontent.com/MBiesma/prtg_service_TALEND-RUNTIME.sh/main/prtg_service_TALEND-RUNTIME.sh" \
                "$PRTG_DIR/prtg_service_TALEND-RUNTIME.sh"

download_script "https://raw.githubusercontent.com/MBiesma/prtg_os_packages_upgradable.sh/main/prtg_os_packages_upgradable.sh" \
                "$PRTG_DIR/prtg_os_packages_upgradable.sh"

if [ -f "$SNMP_CONF" ]; then
    TS=$(date +%Y%m%d%H%M%S)
    BACKUP="${SNMP_CONF}-${TS}"
    echo -e "${RED}SNMP config exists, creating backup: $BACKUP${NC}"
    cp "$SNMP_CONF" "$BACKUP"
fi

echo -e "${GREEN}Installing SNMP packages...${NC}"

if [ "$OS" = "ubuntu" ]; then
    apt update -y
    apt install -y snmp snmpd libsnmp-dev
else
    (command -v dnf >/dev/null 2>&1 && dnf install -y net-snmp net-snmp-utils net-snmp-devel) \
        || yum install -y net-snmp net-snmp-utils net-snmp-devel
fi

echo -e "${GREEN}Configuring SNMP...${NC}"

systemctl enable snmpd || true
systemctl stop snmpd || true

if [ "$OS" = "ubuntu" ]; then
    sed -i 's/^agentAddress.*/agentAddress udp:161/' "$SNMP_CONF"
else
    sed -i 's/^agentAddress.*/agentAddress udp:161,udp6:[::1]:161/' "$SNMP_CONF"
fi

SNMPPASSWORD=$(head -c 16 /dev/urandom | base64 | tr -dc 'a-zA-Z1-9')

echo -e "${GREEN}Creating SNMPv3 user${NC}"

if [ "$OS" = "ubuntu" ]; then
    net-snmp-config --create-snmpv3-user -ro -A "$SNMPPASSWORD" -X "$SNMPPASSWORD" -a SHA -x AES "$USERNAME"
else
    net-snmp-create-v3-user -ro -A "$SNMPPASSWORD" -X "$SNMPPASSWORD" -a SHA -x AES "$USERNAME"
fi

cat <<EOF >> "$SNMP_CONF"
disk /
disk /boot
exec prtg_os_packages_upgradable $PRTG_DIR/prtg_os_packages_upgradable.sh
exec prtg_service_sshd $PRTG_DIR/prtg_service_sshd.sh
exec prtg_service_cron $PRTG_DIR/prtg_service_cron.sh
exec prtg_service_talend-remote-engine $PRTG_DIR/prtg_service_talend-remote-engine.sh
exec prtg_service_TALEND-RUNTIME $PRTG_DIR/prtg_service_TALEND-RUNTIME.sh
EOF

systemctl start snmpd

echo -e "${GREEN}==============================================================${NC}"
echo -e "   SNMP v3 Username:      ${RED}$USERNAME${NC}"
echo -e "   SNMP v3 Password:      ${RED}$SNMPPASSWORD${NC}"
echo -e "   Encryption Key:        ${RED}$SNMPPASSWORD${NC}"
echo -e "   Authentication:        SHA"
echo -e "   Encryption:            AES"
echo -e "${GREEN}==============================================================${NC}"
``
