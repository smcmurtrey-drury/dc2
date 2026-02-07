# --- CONFIGURATION ---
$DomainName = (Get-ADDomain).Name
$GPOName    = "CCDC_Baseline_Policy"

Write-Host "STARTING AD MASTER HARDENING..." -ForegroundColor Cyan
Import-Module ActiveDirectory
Import-Module GroupPolicy
Import-Module DnsServer

# ---------------------------------------------------------
# PHASE 1: DNS HARDENING (The "Phase 5" in your list)
# ---------------------------------------------------------
Write-Host "Securing DNS Service..." -ForegroundColor Yellow

# 1. Disable Zone Transfers (Stops Recon)
try {
    Set-DnsServerPrimaryZone -Name $DomainName -SecureSecondaries TransferDisabled -ErrorAction Stop
    Write-Host "  [+] Zone Transfers DISABLED." -ForegroundColor Green
} catch { Write-Host "  [-] Could not set Zone Transfers (Zone might not be Primary)." -ForegroundColor Red }

# 2. Secure Dynamic Updates (Stops Rogue Records)
try {
    Set-DnsServerPrimaryZone -Name $DomainName -DynamicUpdate SecureOnly -ErrorAction Stop
    Write-Host "  [+] Dynamic Updates set to SECURE." -ForegroundColor Green
} catch { Write-Host "  [-] Could not set Dynamic Updates." -ForegroundColor Red }

# 3. Enable Cache Locking (Stops Poisoning)
# Set to 90% locking
Set-DnsServerCache -LockingPercent 90
Write-Host "  [+] DNS Cache Locking ENABLED (90%)." -ForegroundColor Green

# ---------------------------------------------------------
# PHASE 2: PASSWORD & LOCKOUT POLICY (The "Phase 2" in your list)
# ---------------------------------------------------------
# Note: Password Policies MUST be set on the "Default Domain Policy" to work effectively.
Write-Host "Enforcing Password & Lockout Policies..." -ForegroundColor Yellow

Set-ADDefaultDomainPasswordPolicy `
    -ComplexityEnabled $true `
    -MinPasswordLength 14 `
    -MaxPasswordAge "90.00:00:00" `
    -PasswordHistoryCount 24 `
    -LockoutDuration "00:15:00" `
    -LockoutObservationWindow "00:15:00" `
    -LockoutThreshold 5

Write-Host "  [+] Password Policy: 14 chars, Complexity ON, 90 Day Age." -ForegroundColor Green
Write-Host "  [+] Lockout Policy: 5 Attempts, 15 Mins Duration." -ForegroundColor Green

# ---------------------------------------------------------
# PHASE 3: CREATE HARDENING GPO
# ---------------------------------------------------------
Write-Host "Creating CCDC Hardening GPO..." -ForegroundColor Yellow

# Check if GPO exists, if not, create it
if (-not (Get-GPO -Name $GPOName -ErrorAction SilentlyContinue)) {
    New-GPO -Name $GPOName | New-GPLink -Target "dc=$DomainName,dc=local" -LinkEnabled Yes -Order 1 | Out-Null
    Write-Host "  [+] GPO '$GPOName' Created and Linked." -ForegroundColor Green
} else {
    Write-Host "  [*] GPO '$GPOName' already exists. Updating settings..." -ForegroundColor Gray
}

# ---------------------------------------------------------
# PHASE 4: REGISTRY-BASED HARDENING (Auditing, LSA, NTLM)
# ---------------------------------------------------------
Write-Host "Injecting Registry Security Settings..." -ForegroundColor Yellow

# Function to easily set registry keys in the GPO
function Set-RegPol {
    param($Key, $ValName, $Type, $Value)
    Set-GPRegistryValue -Name $GPOName -Key $Key -ValueName $ValName -Type $Type -Value $Value
}

# 1. COMMAND LINE AUDITING (Critical for IR)
# HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\System\Audit\ProcessCreationIncludeCmdLine_Enabled
Set-RegPol "HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\System\Audit" "ProcessCreationIncludeCmdLine_Enabled" DWord 1
Write-Host "  [+] Command Line Auditing ENABLED." -ForegroundColor Green

# 2. LSA PROTECTION (Anti-Mimikatz)
# HKLM\SYSTEM\CurrentControlSet\Control\Lsa\RunAsPPL
Set-RegPol "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" "RunAsPPL" DWord 1
Write-Host "  [+] LSA Protection (Anti-Mimikatz) ENABLED." -ForegroundColor Green

# 3. NTLM HARDENING (Restrict NTLMv1)
# HKLM\SYSTEM\CurrentControlSet\Control\Lsa\LmCompatibilityLevel (5 = Send NTLMv2 Response Only. Refuse LM & NTLM)
Set-RegPol "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" "LmCompatibilityLevel" DWord 5
Write-Host "  [+] NTLMv2 Enforcement ENABLED." -ForegroundColor Green

# 4. SMB SIGNING (Client & Server)
# HKLM\System\CurrentControlSet\Services\LanmanWorkstation\Parameters\RequireSecuritySignature
Set-RegPol "HKLM\System\CurrentControlSet\Services\LanmanWorkstation\Parameters" "RequireSecuritySignature" DWord 1
Set-RegPol "HKLM\System\CurrentControlSet\Services\LanmanServer\Parameters" "RequireSecuritySignature" DWord 1
Write-Host "  [+] SMB Signing ENABLED." -ForegroundColor Green

# ---------------------------------------------------------
# PHASE 5: DISABLE LOCAL ADMIN (The "Phase 2, Step 3")
# ---------------------------------------------------------
# We disable the local Administrator account via Registry GPO
# HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\FilterAdministratorToken
Set-RegPol "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" "FilterAdministratorToken" DWord 1
Write-Host "  [+] Local Admin Token Filtering ENABLED." -ForegroundColor Green

# ---------------------------------------------------------
# FINISH
# ---------------------------------------------------------
Write-Host "------------------------------------------------" -ForegroundColor Cyan
Write-Host "HARDENING COMPLETE." -ForegroundColor Green
Write-Host "ACTION ITEMS:" -ForegroundColor Yellow
Write-Host "1. Run 'gpupdate /force' on this server."
Write-Host "2. Manually configure 'Restricted Groups' in the GPO Editor."
Write-Host "   (Policies -> Windows Settings -> Security Settings -> Restricted Groups)"
Write-Host "------------------------------------------------" -ForegroundColor Cyan