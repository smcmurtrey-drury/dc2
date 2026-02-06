# --- CONFIGURATION ---
$DC_IP         = "172.20.240.102"

Write-Host "Securing WEB SERVER..." -ForegroundColor Cyan

# 1. Reset/Enable Firewall Profiles
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True

# 2. ALLOW Domain Controller Management (Group Policy/Auth)
New-NetFirewallRule -DisplayName "001-ALLOW-DC-Communication" -Direction Inbound -RemoteAddress $DC_IP -Action Allow

# 3. ALLOW Web Services (HTTP/HTTPS) - Open to ANY
New-NetFirewallRule -DisplayName "200-ALLOW-Web-Services" -Direction Inbound -LocalPort 80,443 -Protocol TCP -Action Allow

# 4. BLOCK All Other Inbound Traffic
Set-NetFirewallProfile -Profile Domain,Public,Private -DefaultInboundAction Block

Write-Host "DONE: Web Server is hardened." -ForegroundColor Green