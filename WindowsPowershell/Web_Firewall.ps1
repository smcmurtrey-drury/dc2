# --- CONFIGURATION ---
$DC_IP = "172.20.240.102"

Write-Host "Securing WEB SERVER..." -ForegroundColor Cyan

# ---------------------------------------------------------------------
# PHASE 1: THE NUKE
# ---------------------------------------------------------------------
Write-Host "Disabling all existing firewall rules..." -ForegroundColor Yellow
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True
Get-NetFirewallRule | Disable-NetFirewallRule

# ---------------------------------------------------------------------
# PHASE 2: SPECIFIC ALLOW RULES
# ---------------------------------------------------------------------

# 1. ALLOW Domain Controller Management (Group Policy/Auth)
New-NetFirewallRule -DisplayName "001-ALLOW-DC-Communication" -Direction Inbound -RemoteAddress $DC_IP -Action Allow

# 2. ALLOW Web Services (HTTP/HTTPS) - Open to ANY
New-NetFirewallRule -DisplayName "200-ALLOW-Web-Services" -Direction Inbound -LocalPort 80,443 -Protocol TCP -Action Allow

# ---------------------------------------------------------------------
# PHASE 3: DEFAULT BLOCK
# ---------------------------------------------------------------------
Set-NetFirewallProfile -Profile Domain,Public,Private -DefaultInboundAction Block

Write-Host "DONE: Web Server is hardened." -ForegroundColor Green