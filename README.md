# SNMP v3 Auto Setup Script

This Bash script automates the installation and configuration of **SNMP v3** on Debian/Ubuntu-based systems.  
It installs SNMP, creates a secure SNMP v3 user, and configures the system for monitoring with **PRTG** or any other SNMP-based network monitoring tool.

---

## 🧩 Features

This script performs the following actions automatically:

1. Checks if `/etc/snmp/snmpd.conf` already exists (prevents overwriting).
2. Performs system cleanup and updates:
   - `apt clean`
   - `apt update`
   - `apt autoremove -y`
3. Installs the required packages:
   - `snmp`
   - `snmpd`
   - `libsnmp-dev`
4. Enables and configures the SNMP daemon:
   - Changes the listening address from `127.0.0.1` to `0.0.0.0`.
5. Generates a **strong random password**.
6. Creates an **SNMP v3 user** with:
   - Username: `svcPRTGsnmp`
   - Authentication: `SHA`
   - Encryption: `AES`
7. Adds default **disk monitoring** for `/` and `/boot`.
8. Starts the SNMP service and displays its status.
9. Prints the SNMP v3 credentials (username, password, encryption key) to the terminal.

---

## ⚙️ Requirements

- A Debian or Ubuntu-based Linux system.
- Root or sudo privileges.
- An active internet connection (for package installation).

---

## 🚀 Usage

1. **Download or clone** the repository:
   ```bash
   git clone https://github.com/<your-username>/<repo-name>.git
   cd <repo-name>
   ```

2. **Make the script executable:**
   ```bash
   chmod +x setup-snmp.sh
   ```

3. **Run the script as root or with sudo:**
   ```bash
   sudo ./setup-snmp.sh
   ```

4. Once complete, your SNMP v3 credentials will be displayed in the terminal:
   ```
   Your username is: svcPRTGsnmp
   Your password is: <random password>
   Your Encryption Key is: <same random password>
   Authentication Method: SHA
   Encryption Type: AES
   ```

---

## 🧠 Useful Information

- Configuration file: `/etc/snmp/snmpd.conf`
- Manage the SNMP service:
  ```bash
  sudo systemctl status snmpd
  sudo systemctl restart snmpd
  sudo systemctl enable snmpd
  ```
- Test your SNMP v3 configuration locally:
  ```bash
  snmpwalk -v3 -u svcPRTGsnmp -l authPriv -a SHA -A <password> -x AES -X <password> localhost
  ```

---

## ⚠️ Security Notice

- The SNMP v3 username and password are **only displayed once** during script execution.  
  Store them securely — they are **not saved anywhere else**.
- The SNMP daemon is configured to listen on **all interfaces (0.0.0.0)**.  
  For security, restrict access to your SNMP port (UDP 161) using a firewall to allow only trusted monitoring servers (e.g., your PRTG probe).

