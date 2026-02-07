#!/bin/bash
# ==============================================================================
# CCDC MANAGEMENT STATION HARDENING SCRIPT
# ROLE: Ansible Controller & Palo Alto GUI Access
# SYSTEM: Ubuntu Desktop/Server
# ==============================================================================

# 1. SAFETY CHECKS
if [[ $EUID -ne 0 ]]; then
   echo "CRITICAL: This script must be run as root. Use 'sudo ./harden_mgmt.sh'"
   exit 1
fi

echo "[*] STARTING HARDENING SEQUENCE FOR MANAGEMENT STATION..."

# ==============================================================================
# 2. FIREWALL LOCKDOWN (UFW)
# ==============================================================================
echo "[*] Configuring Firewall..."
# Ensure UFW is installed
apt-get install ufw -y

# Reset to defaults
ufw --force reset

# DEFAULT POLICIES
# Deny all incoming traffic (No one should be connecting TO this machine)
ufw default deny incoming
# Allow all outgoing traffic (So you can run Ansible and reach Palo Alto)
ufw default allow outgoing

# OPTIONAL: Allow SSH IN if your teammates need to login to this box
# ufw allow from <TEAM_SUBNET> to any port 22 proto tcp

# Enable Firewall
ufw --force enable
echo "[+] Firewall Active: All Incoming BLOCKED. Outgoing ALLOWED."

# ==============================================================================
# 3. SECURE ANSIBLE & TOOLS
# ==============================================================================
echo "[*] Ensuring Admin Tools are Ready..."
apt-get update
# Install Ansible, sshpass (for password auth in hosts.ini), and Firefox (for Palo GUI)
apt-get install -y ansible sshpass firefox network-manager

# ==============================================================================
# 4. REMOVE ATTACK SURFACES
# ==============================================================================
echo "[*] Removing Unnecessary Services..."
# This machine should NOT be a server. Remove server software.
apt-get purge -y apache2 nginx samba vsftpd telnetd bind9
apt-get autoremove -y

# ==============================================================================
# 5. SSH CLEANUP (Anti-Persistence)
# ==============================================================================
echo "[*] Nuking SSH Keys (Prevent Red Team Backdoors)..."
# Remove all authorized_keys files to force password authentication
find /home -name "authorized_keys" -delete
find /root -name "authorized_keys" -delete

# ==============================================================================
# 6. NETWORK HARDENING (Sysctl)
# ==============================================================================
echo "[*] Applying Kernel Security Settings..."
cat <<EOF > /etc/sysctl.d/99-ccdc-hardening.conf
# Ignore ICMP Broadcasts (Smurf attacks)
net.ipv4.icmp_echo_ignore_broadcasts = 1
# Disable Source Packet Routing (Prevent spoofing)
net.ipv4.conf.all.accept_source_route = 0
# Enable SYN Cookies (Prevent SYN floods)
net.ipv4.tcp_syncookies = 1
# Disable IP Forwarding (This machine is a workstation, not a router)
net.ipv4.ip_forward = 0
EOF
sysctl --system

# ==============================================================================
# 7. BROWSER PRIVACY (For Palo Alto GUI)
# ==============================================================================
echo "[*] Clearing Browser Caches..."
rm -rf /home/*/.cache/mozilla/firefox/*.default-release/cache2
rm -rf /root/.cache/mozilla/firefox/*.default-release/cache2

# ==============================================================================
# 8. PASSWORD ROTATION
# ==============================================================================
echo "========================================================"
echo "CRITICAL STEP: CHANGE YOUR PASSWORD NOW"
echo "========================================================"
echo "Enter new password for the current user ($SUDO_USER):"
passwd $SUDO_USER

echo "[*] Hardening Complete. REBOOT RECOMMENDED."