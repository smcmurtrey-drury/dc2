# --- CONFIGURATION ---
$LinuxMailIP   = "172.20.242.40"
$NetworkSubnet = "172.20.240.0/24"

Write-Host "Securing AD/DNS SERVER..." -ForegroundColor Cyan

# ---------------------------------------------------------------------
# PHASE 1: THE NUKE (Disable ALL existing rules)
# ---------------------------------------------------------------------
# This ensures no default Windows rules (like SMB to public, etc.) remain active.
Write-Host "Disabling all existing firewall rules..." -ForegroundColor Yellow
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True
Get-NetFirewallRule | Disable-NetFirewallRule

# ---------------------------------------------------------------------
# PHASE 2: SPECIFIC ALLOW RULES
# ---------------------------------------------------------------------

# 1. ALLOW AD Services (TCP) from the Subnet
# Includes: DNS(53), Kerberos(88), RPC(135), LDAP(389), SMB(445), LDAPS(636), GC(3268/9)
$AD_TCP = @(53, 88, 135, 389, 445, 464, 636, 3268, 3269)
New-NetFirewallRule -DisplayName "100-ALLOW-AD-TCP-Subnet" -Direction Inbound -LocalPort $AD_TCP -Protocol TCP -RemoteAddress $NetworkSubnet -Action Allow

# 2. ALLOW AD Services (UDP) from the Subnet
$AD_UDP = @(53, 88, 389, 464)
New-NetFirewallRule -DisplayName "101-ALLOW-AD-UDP-Subnet" -Direction Inbound -LocalPort $AD_UDP -Protocol UDP -RemoteAddress $NetworkSubnet -Action Allow

# 3. ALLOW Linux Mail Server Auth (Specific IP Only)
New-NetFirewallRule -DisplayName "102-ALLOW-LinuxMail-Auth" -Direction Inbound -LocalPort 88,389,636 -Protocol TCP -RemoteAddress $LinuxMailIP -Action Allow

# 4. ALLOW ICMP (Ping) - Optional but recommended for troubleshooting
New-NetFirewallRule -DisplayName "999-ALLOW-Ping" -Direction Inbound -Protocol ICMPv4 -Action Allow

# ---------------------------------------------------------------------
# PHASE 3: DEFAULT BLOCK
# ---------------------------------------------------------------------
Set-NetFirewallProfile -Profile Domain,Public,Private -DefaultInboundAction Block

Write-Host "DONE: AD/DNS Server is hardened and existing bloat rules are disabled." -ForegroundColor Green