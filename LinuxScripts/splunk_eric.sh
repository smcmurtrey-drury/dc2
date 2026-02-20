#!/bin/bash

echo "=========================================="
echo "🛡️ Initiating CCDC Splunk Hardening Script"
echo "=========================================="

# Ensure script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root."
  exit
fi

# ---------------------------------------------------------
# 1. IMMUTABILITY: Protect the Engine & Passwords
# ---------------------------------------------------------
echo "[+] Locking down the Splunk engine and password files..."
SPLUNK_DIR="/opt/splunk"

if [ -d "$SPLUNK_DIR" ]; then
    # Protect the blue team password file
    if [ -f "$SPLUNK_DIR/etc/passwd" ]; then
        chattr +i $SPLUNK_DIR/etc/passwd
        echo "  -> Splunk passwd file made immutable."
    fi
    
    # Protect the core engine binaries
    if [ -f "$SPLUNK_DIR/bin/splunk" ]; then
        chattr +i $SPLUNK_DIR/bin/splunk
        chattr +i $SPLUNK_DIR/bin/splunkd
        echo "  -> Splunk engine binaries made immutable."
    fi
else
    echo "  -> WARNING: Splunk directory not found at $SPLUNK_DIR. Verify installation path."
fi

# ---------------------------------------------------------
# 2. FIREWALL: Lock Down Ports
# ---------------------------------------------------------
echo "[+] Configuring UFW Firewall..."
# Reset UFW to default state
ufw --force reset > /dev/null

# Set default deny policies
ufw default deny incoming
ufw default allow outgoing

# Allow necessary ports
ufw allow 8000/tcp # Splunk Web UI
ufw allow 22/tcp   # SSH (Secured via keys)
# ufw allow 8089/tcp # Uncomment if Splunk Management port is strictly needed

# Enable firewall silently
ufw --force enable
echo "  -> Firewall enabled. Only ports 8000 and 22 are open."

# ---------------------------------------------------------
# 3. SSH HARDENING: Key-Auth Only
# ---------------------------------------------------------
echo "[+] Hardening SSH Configuration..."
SSHD_CONFIG="/etc/ssh/sshd_config"

# Disable password authentication
sed -i 's/^#*PasswordAuthentication .*/PasswordAuthentication no/' $SSHD_CONFIG
# Disable root login over SSH
sed -i 's/^#*PermitRootLogin .*/PermitRootLogin no/' $SSHD_CONFIG

# Restart SSH service
systemctl restart ssh || systemctl restart sshd
echo "  -> SSH secured. Password auth disabled."

# ---------------------------------------------------------
# 4. USER AUDITING
# ---------------------------------------------------------
echo "[+] Auditing system users..."

# Lock any rogue root accounts (UID 0) that aren't the actual root user
awk -F: '($3 == "0") {print $1}' /etc/passwd | grep -v '^root$' | xargs -I {} passwd -l {}

# Explicit check for the docker user to ensure it cannot be abused for shell access
if id "docker" &>/dev/null; then
    echo "  -> Docker user detected. Verifying shell access..."
    # Optional: Change docker user shell to nologin if it doesn't strictly need shell access
    usermod -s /usr/sbin/nologin docker
    echo "  -> Docker user shell restricted to /usr/sbin/nologin."
fi

echo "=========================================="
echo "✅ Hardening Complete. Hold the line!"
echo "=========================================="