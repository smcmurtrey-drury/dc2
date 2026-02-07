# --- CONFIGURATION ---
$DC_IP = "172.20.240.102"

Write-Host "Securing WORKSTATION (Safe Loop Mode)..." -ForegroundColor Cyan

# 1. READ RULES FIRST (Prevents the "Collection Modified" error)
Write-Host "Reading active rules..." -ForegroundColor Yellow
$ActiveRules = Get-NetFirewallRule | Where-Object { $_.Enabled -eq "True" }

# 2. SAFE SCRUB
Write-Host "Scrubbing non-essential rules..." -ForegroundColor Yellow
$SystemGroups = @(
    "*Core Networking*", 
    "*Windows Management Instrumentation*", 
    "*Windows Defender Firewall Remote Management*"
)

foreach ($Rule in $ActiveRules) {
    $IsSystem = $false
    # Check if this rule is in our "Do Not Kill" list
    foreach ($Group in $SystemGroups) { 
        if ($Rule.DisplayGroup -like $Group) { 
            $IsSystem = $true
            break 
        } 
    }
    
    # If it is NOT a system rule, disable it
    if (-not $IsSystem) { 
        Disable-NetFirewallRule -Name $Rule.Name -ErrorAction SilentlyContinue 
    }
}

# 3. COMPETITION RULES (Apply these explicitly)
Write-Host "Applying Security Rules..." -ForegroundColor Yellow

# Allow DC Communication (Critical for Login/GPO)
New-NetFirewallRule -DisplayName "001-ALLOW-DC-Communication" -Direction Inbound -RemoteAddress $DC_IP -Action Allow -ErrorAction SilentlyContinue

# Allow Ping (Optional, but good for scoring checks)
New-NetFirewallRule -DisplayName "999-ALLOW-Ping-Any" -Direction Inbound -Protocol ICMPv4 -Action Allow -ErrorAction SilentlyContinue

# 4. LOCKDOWN
Write-Host "Locking down..." -ForegroundColor Yellow
Set-NetFirewallProfile -Profile Domain,Public,Private -DefaultInboundAction Block

Write-Host "Workstation Secured." -ForegroundColor Green