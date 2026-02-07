# --- CONFIGURATION ---
$DC_IP = "172.20.240.102"

Write-Host "Securing WEB SERVER..." -ForegroundColor Cyan

# 1. Safe Nuke
Write-Host "Scrubbing existing rules..." -ForegroundColor Yellow
$SystemGroups = @("*Core Networking*", "*Windows Management Instrumentation*", "*Windows Defender Firewall Remote Management*")
Get-NetFirewallRule | Where-Object { $_.Enabled -eq "True" } | ForEach-Object {
    $Rule = $_
    $IsSystem = $false
    foreach ($Group in $SystemGroups) { if ($Rule.DisplayGroup -like $Group) { $IsSystem = $true; break } }
    if (-not $IsSystem) { Disable-NetFirewallRule -Name $Rule.Name -ErrorAction SilentlyContinue }
}

# 2. Secure Management (Lock to DC)
Set-NetFirewallRule -DisplayGroup "*Windows Management Instrumentation*" -RemoteAddress $DC_IP -ErrorAction SilentlyContinue
Set-NetFirewallRule -DisplayGroup "*Windows Defender Firewall Remote Management*" -RemoteAddress $DC_IP -ErrorAction SilentlyContinue

# 3. Competition Rules
New-NetFirewallRule -DisplayName "200-ALLOW-Web-Services-Any" -Direction Inbound -LocalPort 80,443 -Protocol TCP -Action Allow

# 4. Lockdown
Set-NetFirewallProfile -Profile Domain,Public,Private -DefaultInboundAction Block
Write-Host "Web Server Secured." -ForegroundColor Green