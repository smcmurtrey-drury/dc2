# --- CONFIGURATION ---
$DC_IP         = "172.20.240.102"

Write-Host "Securing WINDOWS WORKSTATION..." -ForegroundColor Cyan

# 1. Reset/Enable Firewall Profiles
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True

# 2. ALLOW Domain Controller Management
New-NetFirewallRule -DisplayName "001-ALLOW-DC-Communication" -Direction Inbound -RemoteAddress $DC_IP -Action Allow

# 3. BLOCK All Other Inbound Traffic
Set-NetFirewallProfile -Profile Domain,Public,Private -DefaultInboundAction Block

Write-Host "DONE: Workstation is hardened." -ForegroundColor Green