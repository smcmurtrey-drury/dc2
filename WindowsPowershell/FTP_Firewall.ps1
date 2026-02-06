# --- CONFIGURATION ---
$DC_IP = "172.20.240.102"

Write-Host "Securing FTP SERVER..." -ForegroundColor Cyan

# ---------------------------------------------------------------------
# PHASE 1: THE NUKE
# ---------------------------------------------------------------------
Write-Host "Disabling all existing firewall rules..." -ForegroundColor Yellow
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True
Get-NetFirewallRule | Disable-NetFirewallRule

# ---------------------------------------------------------------------
# PHASE 2: SPECIFIC ALLOW RULES
# ---------------------------------------------------------------------

# 1. ALLOW Domain Controller Management
New-NetFirewallRule -DisplayName "001-ALLOW-DC-Communication" -Direction Inbound -RemoteAddress $DC_IP -Action Allow

# 2. ALLOW FTP Control Port (21)
New-NetFirewallRule -DisplayName "200-ALLOW-FTP-Control" -Direction Inbound -LocalPort 21 -Protocol TCP -Action Allow

# 3. ALLOW FTP Passive Mode (Data Ports)
# Since we disabled ALL rules in Phase 1, we must explicitly re-enable the built-in FTP handling
Enable-NetFirewallRule -DisplayGroup "FTP Server" -ErrorAction SilentlyContinue

# ---------------------------------------------------------------------
# PHASE 3: DEFAULT BLOCK
# ---------------------------------------------------------------------
Set-NetFirewallProfile -Profile Domain,Public,Private -DefaultInboundAction Block

Write-Host "DONE: FTP Server is hardened." -ForegroundColor Green