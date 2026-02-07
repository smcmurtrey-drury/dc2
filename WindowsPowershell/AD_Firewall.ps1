# --- CONFIGURATION ---
$LinuxMailIP   = "172.20.242.40"
$NetworkSubnet = "172.20.240.0/24"

Write-Host "Securing AD/DNS SERVER..." -ForegroundColor Cyan

# 1. Safe Nuke
Write-Host "Scrubbing existing rules..." -ForegroundColor Yellow
$SystemGroups = @("*Core Networking*", "*Windows Management Instrumentation*", "*Windows Defender Firewall Remote Management*")
Get-NetFirewallRule | Where-Object { $_.Enabled -eq "True" } | ForEach-Object {
    $Rule = $_
    $IsSystem = $false
    foreach ($Group in $SystemGroups) { if ($Rule.DisplayGroup -like $Group) { $IsSystem = $true; break } }
    if (-not $IsSystem) { Disable-NetFirewallRule -Name $Rule.Name -ErrorAction SilentlyContinue }
}

# 2. Secure Management (Lock WMI to Subnet for Group Policy/Login to work)
Set-NetFirewallRule -DisplayGroup "*Windows Management Instrumentation*" -RemoteAddress $NetworkSubnet -ErrorAction SilentlyContinue
Set-NetFirewallRule -DisplayGroup "*Windows Defender Firewall Remote Management*" -RemoteAddress $NetworkSubnet -ErrorAction SilentlyContinue

# 3. Competition Rules

# DNS (Open to World)
New-NetFirewallRule -DisplayName "900-ALLOW-DNS-Any-TCP" -Direction Inbound -LocalPort 53 -Protocol TCP -Action Allow
New-NetFirewallRule -DisplayName "900-ALLOW-DNS-Any-UDP" -Direction Inbound -LocalPort 53 -Protocol UDP -Action Allow

# AD Services (Subnet Only)
$AD_TCP = @(88, 135, 389, 445, 464, 636, 3268, 3269)
New-NetFirewallRule -DisplayName "100-ALLOW-AD-TCP-Subnet" -Direction Inbound -LocalPort $AD_TCP -Protocol TCP -RemoteAddress $NetworkSubnet -Action Allow

$AD_UDP = @(88, 389, 464)
New-NetFirewallRule -DisplayName "101-ALLOW-AD-UDP-Subnet" -Direction Inbound -LocalPort $AD_UDP -Protocol UDP -RemoteAddress $NetworkSubnet -Action Allow

# Mail Auth (Specific IP)
New-NetFirewallRule -DisplayName "102-ALLOW-LinuxMail-Auth" -Direction Inbound -LocalPort 88,389,636 -Protocol TCP -RemoteAddress $LinuxMailIP -Action Allow

# 4. Lockdown
Set-NetFirewallProfile -Profile Domain,Public,Private -DefaultInboundAction Block
Write-Host "AD/DNS Secured." -ForegroundColor Green