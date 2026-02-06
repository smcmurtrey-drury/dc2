# --- CONFIGURATION ---
$LinuxMailIP   = "172.20.242.40"
$NetworkSubnet = "172.20.240.0/24"

Write-Host "Securing AD/DNS SERVER..." -ForegroundColor Cyan

# --- PHASE 1: THE NUKE (Disable ALL existing rules) ---
Write-Host "Disabling all existing rules..." -ForegroundColor Yellow
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True
Get-NetFirewallRule | Disable-NetFirewallRule

# --- PHASE 2: PERMIT TRAFFIC ---

# 1. ALLOW DNS (Scored Service) - FROM ANY
# We separate this so the Scoreboard can check it, but attackers can't reach SMB.
New-NetFirewallRule -DisplayName "900-ALLOW-DNS-Any" -Direction Inbound -LocalPort 53 -Protocol TCP -Action Allow
New-NetFirewallRule -DisplayName "900-ALLOW-DNS-Any-UDP" -Direction Inbound -LocalPort 53 -Protocol UDP -Action Allow

# 2. ALLOW AD Services (TCP) from Internal Subnet ONLY
# REMOVED Port 53 from this list since it's now open to Any above.
# Includes: Kerberos(88), RPC(135), LDAP(389), SMB(445), Passwd(464), LDAPS(636), GC(3268/9)
$AD_TCP = @(88, 135, 389, 445, 464, 636, 3268, 3269)
New-NetFirewallRule -DisplayName "100-ALLOW-AD-TCP-Subnet" -Direction Inbound -LocalPort $AD_TCP -Protocol TCP -RemoteAddress $NetworkSubnet -Action Allow

# 3. ALLOW AD Services (UDP) from Internal Subnet
# REMOVED Port 53 from here as well.
$AD_UDP = @(88, 389, 464)
New-NetFirewallRule -DisplayName "101-ALLOW-AD-UDP-Subnet" -Direction Inbound -LocalPort $AD_UDP -Protocol UDP -RemoteAddress $NetworkSubnet -Action Allow

# 4. ALLOW Linux Mail Server Auth (Specific IP)
New-NetFirewallRule -DisplayName "102-ALLOW-LinuxMail-Auth" -Direction Inbound -LocalPort 88,389,636 -Protocol TCP -RemoteAddress $LinuxMailIP -Action Allow

# --- PHASE 3: LOCKDOWN ---
Set-NetFirewallProfile -Profile Domain,Public,Private -DefaultInboundAction Block
Write-Host "AD/DNS Locked Down (DNS Open to World)." -ForegroundColor Green