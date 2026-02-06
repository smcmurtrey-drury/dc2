# --- CONFIGURATION ---
$DC_IP         = "172.20.240.102"

Write-Host "Securing FTP SERVER..." -ForegroundColor Cyan

# 1. Reset/Enable Firewall Profiles
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True

# 2. ALLOW Domain Controller Management
New-NetFirewallRule -DisplayName "001-ALLOW-DC-Communication" -Direction Inbound -RemoteAddress $DC_IP -Action Allow

# 3. ALLOW FTP Control Port (21)
New-NetFirewallRule -DisplayName "200-ALLOW-FTP-Control" -Direction Inbound -LocalPort 21 -Protocol TCP -Action Allow

# 4. ALLOW FTP Passive Mode (Data Ports)
# This enables the Windows built-in rule group which handles dynamic data ports.
Enable-NetFirewallRule -DisplayGroup "FTP Server" -ErrorAction SilentlyContinue

# 5. BLOCK All Other Inbound Traffic
Set-NetFirewallProfile -Profile Domain,Public,Private -DefaultInboundAction Block

Write-Host "DONE: FTP Server is hardened." -ForegroundColor Green