#!/bin/bash

# ==========================================
# CCDC "Scorched Earth" General Hardening
# Distro: Ubuntu/Debian
# ==========================================
# USAGE: sudo ./harden_general.sh

echo "🔴 STARTING GENERAL HARDENING PROTOCOL..."

# 1. PRE-FLIGHT: BACKUPS
# ==========================================
echo "[*] Backing up critical config files..."
mkdir -p /root/ccdc_backups
cp /etc/passwd /etc/shadow /etc/group /etc/ssh/sshd_config /etc/sysctl.conf /root/ccdc_backups/
echo "✅ Backups saved to /root/ccdc_backups/"

# 2. SSH LOCKDOWN (The Front Door)
# ==========================================
echo "[*] Hardening SSH Configuration..."
# Disable Root Login
sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
# Disable Empty Passwords
sed -i 's/^#*PermitEmptyPasswords.*/PermitEmptyPasswords no/' /etc/ssh/sshd_config
# Disable X11 Forwarding (common lateral movement vector)
sed -i 's/^#*X11Forwarding.*/X11Forwarding no/' /etc/ssh/sshd_config
# Max Auth Tries (slows down brute force)
sed -i 's/^#*MaxAuthTries.*/MaxAuthTries 3/' /etc/ssh/sshd_config

# ⚠️ NUCLEAR OPTION: WIPE ALL SSH KEYS
# Red Team loves hiding keys in .ssh/authorized_keys. 
# Since you have passwords, you don't need keys right now.
echo "[*] Wiping all authorized_keys files to kill key-based persistence..."
find /home -name "authorized_keys" -delete
find /root -name "authorized_keys" -delete
echo "✅ SSH Hardened & Keys Wiped. Restarting Service..."
service ssh restart

# 3. CRON & AT JOBS (The "Time Bomb" Persistence)
# ==========================================
echo "[*] Securing Cron and At..."
# Deny everyone from using cron except root (you can undo this if needed)
echo "root" > /etc/cron.allow
echo "root" > /etc/at.allow
# Lock down the directories
chmod 700 /etc/cron.d /etc/cron.daily /etc/cron.hourly /etc/cron.weekly /etc/cron.monthly
chmod 600 /etc/crontab
echo "✅ Cron restricted to Root only."

# 4. NETWORK SYSCTL HARDENING (The Kernel)
# ==========================================
echo "[*] Applying Kernel Network Hardening..."
cat <<EOF >> /etc/sysctl.conf
# IP Spoofing protection
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
# Ignore ICMP broadcast requests
net.ipv4.icmp_echo_ignore_broadcasts = 1
# Disable source packet routing
net.ipv4.conf.all.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0
# Disable send redirects
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
# Block SYN attacks
net.ipv4.tcp_syncookies = 1
# Log Martians
net.ipv4.conf.all.log_martians = 1
EOF
sysctl -p > /dev/null
echo "✅ Kernel network parameters tightened."

# 5. BINARY NEUTERING (Living off the Land)
# ==========================================
echo "[*] Neutering compilers and fetchers..."
# Prevent compiling exploits on the box
chmod 000 /usr/bin/gcc /usr/bin/g++ /usr/bin/make /usr/bin/cc 2>/dev/null
# Prevent downloading malware (use with caution, might break your updates)
# chmod 000 /usr/bin/wget /usr/bin/curl 2>/dev/null 
# (Commented out wget/curl as you might need them, but consider it!)

echo "[*] Stripping SUID bits from dangerous binaries..."
# These allow regular users to execute as root. 
# You rarely need SUID on these in a competition.
chmod u-s /usr/bin/find /usr/bin/nmap /usr/bin/vim /usr/bin/vi /usr/bin/less /usr/bin/awk /usr/bin/sed /usr/bin/python* /bin/bash /bin/sh 2>/dev/null
echo "✅ Compilers locked & SUID stripped."

# 6. IMMUTABILITY (The "Chattr" Shield)
# ==========================================
echo "[*] Locking critical configuration files..."
# Prevent DNS hijacking
chattr +i /etc/resolv.conf
# Prevent Host file poisoning
chattr +i /etc/hosts
# Prevent adding new sudo users (Locking groups)
chattr +i /etc/group /etc/gshadow
# Prevent adding users (Locking passwd/shadow) - UNLOCK TO CHANGE PASSWORDS
chattr +i /etc/passwd /etc/shadow
echo "✅ Critical files are now IMMUTABLE (+i)."

# 7. HISTORY & LOGGING
# ==========================================
echo "[*] Securing shell history..."
# Force append-only history for everyone to prevent covering tracks
chattr +a /home/*/.bash_history 2>/dev/null
chattr +a /root/.bash_history 2>/dev/null
# Clear current history
history -c
echo "✅ History set to Append-Only."

echo "=========================================="
echo "🛡️  GENERAL HARDENING COMPLETE"
echo "=========================================="
echo "⚠️  IMPORTANT:"
echo "1. Your DNS (/etc/resolv.conf) is locked."
echo "2. You cannot add users or change passwords right now."
echo "   -> Run 'chattr -i /etc/shadow' to unlock, change pass, then relock."
echo "3. Review '/etc/cron.allow' if a service breaks."
echo "=========================================="