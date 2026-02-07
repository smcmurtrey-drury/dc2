# --- CONFIGURATION ---
$NewTeamUser = "CCDC_Admin" 

Write-Host "STARTING AD USER HARDENING..." -ForegroundColor Cyan

# --- SECURE PASSWORD PROMPT ---
do {
    try {
        $InputPass = Read-Host "Enter Password for $NewTeamUser" -AsSecureString
        $ConfirmPass = Read-Host "Confirm Password" -AsSecureString
        
        $Ptr1 = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($InputPass)
        $Ptr2 = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($ConfirmPass)
        $Plain1 = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($Ptr1)
        $Plain2 = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($Ptr2)
        
        if ($Plain1 -ne $Plain2) { Write-Host "Passwords do not match!" -ForegroundColor Red }
    } finally {
        if ($Ptr1) { [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($Ptr1) }
        if ($Ptr2) { [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($Ptr2) }
    }
} while ($Plain1 -ne $Plain2)

$SecurePassword = $InputPass
Write-Host "Password confirmed." -ForegroundColor Green

# Import AD Module
Import-Module ActiveDirectory

# ---------------------------------------------------------
# 1. CREATE TEAM ADMIN
# ---------------------------------------------------------
try {
    Write-Host "Creating Team Admin ($NewTeamUser)..." -ForegroundColor Yellow
    New-ADUser -Name $NewTeamUser -AccountPassword $SecurePassword -Enabled $true -PasswordNeverExpires $true -ErrorAction Stop
    Write-Host "User Created." -ForegroundColor Green
}
catch {
    Write-Host "User exists. Resetting password..." -ForegroundColor Yellow
    Set-ADAccountPassword -Identity $NewTeamUser -NewPassword $SecurePassword -Reset
}

# Add to Groups (We do this BEFORE the purge so we don't lock ourselves out)
Add-ADGroupMember -Identity "Domain Admins" -Members $NewTeamUser -ErrorAction SilentlyContinue
Add-ADGroupMember -Identity "Enterprise Admins" -Members $NewTeamUser -ErrorAction SilentlyContinue
Add-ADGroupMember -Identity "Schema Admins" -Members $NewTeamUser -ErrorAction SilentlyContinue
Add-ADGroupMember -Identity "Administrators" -Members $NewTeamUser -ErrorAction SilentlyContinue

# ---------------------------------------------------------
# 2. THE PURGE (Remove Unauthorized Admins)
# ---------------------------------------------------------
Write-Host "PURGING UNAUTHORIZED ADMINS..." -ForegroundColor Red -BackgroundColor Yellow

# The High Value Target Groups
$CriticalGroups = @("Domain Admins", "Enterprise Admins", "Schema Admins", "Administrators")

foreach ($Group in $CriticalGroups) {
    Write-Host "Scanning Group: $Group" -ForegroundColor Cyan
    
    # Get current members
    $Members = Get-ADGroupMember -Identity $Group -ErrorAction SilentlyContinue
    
    foreach ($Member in $Members) {
        # WHITELIST: Only allow Built-in Admin and Us
        if ($Member.SamAccountName -ne "Administrator" -and $Member.SamAccountName -ne $NewTeamUser) {
            
            # Special check: Don't remove "Domain Admins" group from the "Administrators" group
            if ($Group -eq "Administrators" -and $Member.ObjectClass -eq "group") {
                Write-Host "  Skipping Group: $($Member.Name) (Allowed in Administrators)" -ForegroundColor Gray
                continue
            }

            Write-Host "  REMOVING SUSPICIOUS USER: $($Member.SamAccountName)" -ForegroundColor Red
            Remove-ADGroupMember -Identity $Group -Members $Member -Confirm:$false -ErrorAction SilentlyContinue
        }
        else {
            Write-Host "  Verifying: $($Member.SamAccountName) (Safe)" -ForegroundColor Green
        }
    }
}

# ---------------------------------------------------------
# 3. KILL GOLDEN TICKETS (KRBTGT Reset)
# ---------------------------------------------------------
Write-Host "Resetting KRBTGT (Double Tap)..." -ForegroundColor Yellow
Set-ADAccountPassword -Identity "krbtgt" -NewPassword $SecurePassword -Reset
Set-ADAccountPassword -Identity "krbtgt" -NewPassword $SecurePassword -Reset

# ---------------------------------------------------------
# 4. SECURE BUILT-IN ACCOUNTS
# ---------------------------------------------------------
Write-Host "Securing Built-ins..." -ForegroundColor Yellow
Disable-ADAccount -Identity "Guest"
Set-ADAccountPassword -Identity "Administrator" -NewPassword $SecurePassword -Reset

if (Get-ADUser -Identity $NewTeamUser) {
    Write-Host "Disabling Built-in Administrator..." -ForegroundColor Yellow
    Disable-ADAccount -Identity "Administrator"
}

Write-Host "DONE: Domain Admins Purged & Locked." -ForegroundColor Green