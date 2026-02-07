# --- CONFIGURATION ---
$DC_IP = "172.20.240.102"

Write-Host "Securing FTP SERVER..." -ForegroundColor Cyan

# 1. SAFE NUKE (Disable bloat, keep Core networking)
# We loop through rules and disable them unless they are critical for the OS/GUI.
Write-Host "Scrubbing existing rules..." -ForegroundColor Yellow
$SystemGroups = @("*Core Networking*", "*Windows Management Instrumentation*", "*Windows Defender Firewall Remote Management*")
Get-NetFirewallRule | Where-Object { $_.Enabled -eq "True" } | ForEach-Object {
    $Rule = $_
    $IsSystem = $false
    foreach ($Group in $SystemGroups) { if ($Rule.DisplayGroup -like $Group) { $IsSystem = $true; break } }
    
    # If the rule is NOT a system rule, disable it.
    if (-not $IsSystem) { Disable-NetFirewallRule -Name $Rule.Name -ErrorAction SilentlyContinue }
}

# 2. SECURE MANAGEMENT (Lock WMI/Remote to DC ONLY)
Set-NetFirewallRule -DisplayGroup "*Windows Management Instrumentation*" -RemoteAddress $DC_IP -ErrorAction SilentlyContinue
Set-NetFirewallRule -DisplayGroup "*Windows Defender Firewall Remote Management*" -RemoteAddress $DC_IP -ErrorAction SilentlyContinue

# 3. COMPETITION RULES
# FTP Control (21) - Open to ANY
New-NetFirewallRule -DisplayName "200-ALLOW-FTP-Control-Any" -Direction Inbound -LocalPort 21 -Protocol TCP -Action Allow

# FTP Passive Mode (Crucial for Data Transfer)
Enable-NetFirewallRule -DisplayGroup "FTP Server" -ErrorAction SilentlyContinue

# 4. LOCKDOWN
Set-NetFirewallProfile -Profile Domain,Public,Private -DefaultInboundAction Block
Write-Host "FTP Server Secured." -ForegroundColor Green