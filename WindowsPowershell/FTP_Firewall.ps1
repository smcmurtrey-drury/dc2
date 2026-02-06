# --- CONFIGURATION ---
$DC_IP = "172.20.240.102"

Write-Host "Securing FTP SERVER..." -ForegroundColor Cyan

# --- PHASE 1: THE NUKE ---
Write-Host "Disabling all existing rules..." -ForegroundColor Yellow
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True
Get-NetFirewallRule | Disable-NetFirewallRule

# --- PHASE 2: PERMIT TRAFFIC ---

# 1. ALLOW FTP Control Port - FROM ANY (For Scoring)
New-NetFirewallRule -DisplayName "200-ALLOW-FTP-Control-Any" -Direction Inbound -LocalPort 21 -Protocol TCP -Action Allow

# 2. ALLOW FTP Passive Mode (Data Ports)
# This uses the Windows Service handler, which dynamically opens ports for established FTP sessions.
Enable-NetFirewallRule -DisplayGroup "FTP Server" -ErrorAction SilentlyContinue

# 3. ALLOW Domain Controller Management
New-NetFirewallRule -DisplayName "001-ALLOW-DC-Communication" -Direction Inbound -RemoteAddress $DC_IP -Action Allow

# --- PHASE 3: LOCKDOWN ---
Set-NetFirewallProfile -Profile Domain,Public,Private -DefaultInboundAction Block
Write-Host "FTP Server Locked Down." -ForegroundColor Green