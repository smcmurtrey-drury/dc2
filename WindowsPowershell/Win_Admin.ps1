# --- CONFIGURATION ---
$NewTeamUser = "CCDC_Admin" 

Write-Host "STARTING LOCAL USER HARDENING..." -ForegroundColor Cyan

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

# Store the plain password for 'net user' command
$FinalPassword = $Plain1
Write-Host "Password confirmed." -ForegroundColor Green

# ---------------------------------------------------------
# 1. CREATE TEAM ADMIN
# ---------------------------------------------------------
Write-Host "Creating Local Admin ($NewTeamUser)..." -ForegroundColor Yellow

# We use 'net user' for maximum compatibility
net user $NewTeamUser $FinalPassword /add /expires:never /active:yes 2>$null

# If user already exists, the above fails, so we force a password reset:
if ($LASTEXITCODE -ne 0) {
    Write-Host "User exists. Resetting password..." -ForegroundColor Yellow
    net user $NewTeamUser $FinalPassword
}

# Add to Administrators
net localgroup Administrators $NewTeamUser /add
Write-Host "SUCCESS: $NewTeamUser is now a Local Admin." -ForegroundColor Green

# ---------------------------------------------------------
# 2. DISABLE GUEST & BUILT-IN ADMIN
# ---------------------------------------------------------
Write-Host "Disabling Guest..." -ForegroundColor Yellow
net user Guest /active:no

Write-Host "Scrambling Built-in Administrator Password..." -ForegroundColor Yellow
net user Administrator $FinalPassword

# Verify our new user works before killing the built-in admin
$CheckUser = net user $NewTeamUser 2>$null
if ($CheckUser) {
    Write-Host "Disabling Built-in Administrator..." -ForegroundColor Yellow
    net user Administrator /active:no
    Write-Host "Built-in Administrator DISABLED." -ForegroundColor Green
} else {
    Write-Host "ERROR: New admin check failed. Keeping Built-in Admin active for safety." -ForegroundColor Red
}

# ---------------------------------------------------------
# 3. DISABLE OTHER ADMINS (Use with Caution!)
# ---------------------------------------------------------
# This snippet finds ANY user in the Administrators group that is NOT:
# 1. The Built-in Administrator
# 2. The user you just created ($NewTeamUser)
# 3. Domain Admins (if domain joined)
# And REMOVES them from the Admin group.

$LocalAdmins = Get-LocalGroupMember -Group "Administrators" -ErrorAction SilentlyContinue | Where-Object { 
    $_.Name -notlike "*Administrator" -and 
    $_.Name -notlike "*Domain Admins" -and 
    $_.Name -notlike "*$NewTeamUser"
}

if ($LocalAdmins) {
    Write-Host "FOUND SUSPICIOUS ADMINS: $($LocalAdmins.Name)" -ForegroundColor Red
    Write-Host "Removing them from Administrators group..." -ForegroundColor Red
    foreach ($Admin in $LocalAdmins) {
        # Extract just the username (stripping computer name)
        $CleanName = $Admin.Name.Split('\')[-1]
        net localgroup Administrators $CleanName /delete
    }
}

Write-Host "DONE: Local Accounts Locked Down." -ForegroundColor Green