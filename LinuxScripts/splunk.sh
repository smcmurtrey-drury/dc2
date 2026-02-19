#!/bin/bash

# ==========================================
# Fedora Server Hardening: Postfix & Dovecot
# ==========================================
# Run as root: sudo ./fedora_mail_harden.sh

echo "🔴 STARTING FEDORA MAIL SERVER HARDENING PROTOCOL..."

if [ "$EUID" -ne 0 ]; then
  echo "[!] Please run as root."
  exit
fi

# 1. SELINUX ENFORCEMENT (The Red Team's worst enemy)
# ==========================================
echo "[*] Verifying and enforcing SELinux..."
# Force it on right now
setenforce 1 2>/dev/null
# Ensure it survives a reboot
sed -i.bak 's/^SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config
# Fix any messed up file contexts in the mail directories
restorecon -Rv /etc/postfix /etc/dovecot /var/spool/mail /var/spool/postfix >/dev/null
echo "✅ SELinux is Enforcing and contexts restored."

# 2. FIREWALLD LOCKDOWN
# ==========================================
echo "[*] Configuring Firewalld for Strict Mail Access..."
systemctl enable --now firewalld

# Set default zone to drop (ignores packets instead of rejecting, slowing scanners)
firewall-cmd --set-default-zone=drop >/dev/null

# Allow only necessary services
firewall-cmd --permanent --zone=drop --add-service=ssh >/dev/null
firewall-cmd --permanent --zone=drop --add-service=smtp >/dev/null  # Port 25
firewall-cmd --permanent --zone=drop --add-service=pop3 >/dev/null  # Port 110
firewall-cmd --permanent --zone=drop --add-service=pop3s >/dev/null # Port 995 (if using SSL)

# Reload to apply
firewall-cmd --reload >/dev/null
echo "✅ Firewalld locked down. Only SSH, SMTP, and POP3(S) allowed."

# 3. POSTFIX (SMTP) SAFE HARDENING
# ==========================================
echo "[*] Applying safe Postfix configurations..."
# Backup config
cp /etc/postfix/main.cf /etc/postfix/main.cf.bak

# Disable the VRFY command to stop Red Team from enumerating user accounts
postconf -e 'disable_vrfy_command = yes'

# Obfuscate the SMTP banner (don't leak OS or Postfix version)
postconf -e 'smtpd_banner = $myhostname ESMTP'

systemctl restart postfix
echo "✅ Postfix hardened (VRFY disabled, banner obfuscated)."

# 4. DOVECOT (POP3) SAFE HARDENING
# ==========================================
echo "[*] Applying safe Dovecot configurations..."
# Backup config
cp /etc/dovecot/dovecot.conf /etc/dovecot/dovecot.conf.bak

# Force Dovecot to ONLY serve POP3 (kills IMAP if it was left running by default)
sed -i.bak 's/^#protocols =.*/protocols = pop3/' /etc/dovecot/dovecot.conf

systemctl restart dovecot
echo "✅ Dovecot restricted to POP3 protocol."

# 5. SSH & OS LOCKDOWN
# ==========================================
echo "[*] Securing SSH and Kernel..."

# Disable Root SSH Login
sed -i.bak 's/^#*PermitRootLogin.*/PermitRootLogin no/g' /etc/ssh/sshd_config
systemctl restart sshd

# Kernel Network Hardening (Fedora specific pathing)
cat <<EOF > /etc/sysctl.d/99-ccdc-network.conf
net.ipv4.conf.all.rp_filter = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.tcp_syncookies = 1
EOF
sysctl --system >/dev/null

# Protect critical credential files
chmod 644 /etc/passwd
chmod 000 /etc/shadow
chattr +i /etc/passwd /etc/shadow

echo "=========================================="
echo "🛡️  FEDORA MAIL HARDENING COMPLETE"
echo "=========================================="
echo "⚠️  CRITICAL REMINDERS:"
echo "1. Your /etc/shadow file is IMMUTABLE (+i)."
echo "   -> Run 'chattr -i /etc/shadow' to rotate your passwords, then lock it back!"
echo "2. Dovecot is strictly running POP3 now. Check your SLA to ensure IMAP isn't required."
echo "=========================================="