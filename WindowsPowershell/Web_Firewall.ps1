# --- CONFIGURATION ---
$DC_IP = "172.20.240.102"

Write-Host "Securing WEB SERVER..." -ForegroundColor Cyan

# --- PHASE 1: THE NUKE ---
Write-Host "Disabling all existing rules..." -ForegroundColor Yellow
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True
Get-NetFirewallRule | Disable-NetFirewallRule

# --- PHASE 2: PERMIT TRAFFIC ---

# 1. ALLOW Web Services - FROM ANY (For Scoring)
New-NetFirewallRule -DisplayName "200-ALLOW-Web-Services-Any" -Direction Inbound -LocalPort 80,443 -Protocol TCP -Action Allow

# 2. ALLOW Domain Controller Management
New-NetFirewallRule -DisplayName "001-ALLOW-DC-Communication" -Direction Inbound -RemoteAddress $DC_IP -Action Allow

# --- PHASE 3: LOCKDOWN ---
Set-NetFirewallProfile -Profile Domain,Public,Private -DefaultInboundAction Block
Write-Host "Web Server Locked Down." -ForegroundColor Green