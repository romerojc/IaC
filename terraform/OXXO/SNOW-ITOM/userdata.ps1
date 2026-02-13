#ps1_sysnative
# ============================================================
# Cloud-Init Script - OXOCI-VM-APP-SNOWITON-PRD
# ServiceNow ITOM MID Server
# ============================================================
# CHG: CHG0140789
# Date: 02-12-2026
# ============================================================

# ============================================================
# STEP 1 - SET HOSTNAME
# ============================================================
Write-Output "Setting hostname..."
Rename-Computer -NewName "OXOCI-VM-APP-SNOWITON-PRD" -Force
Write-Output "Hostname set successfully."

# ============================================================
# STEP 2 - CREATE LOCAL ADMIN USERS
# ============================================================
Write-Output "Creating local admin users..."

$users = @(
    @{Name="cxmindwin";     Password="uPi39sug512satgDaJDz"; Description="CyberArk Vault - Windows Admin"},
    @{Name="drmindwin";     Password="qGgtPzYmie5W9yGzo5X0"; Description="CyberArk Vault - Windows Admin"},
    @{Name="cstisec";       Password="7Gnyu6jUeCfoK917eupg"; Description="Vulnerability Scanning - CyberArk"},
    @{Name="secscan";       Password="7Gnyu6jUeCfoK917eupg"; Description="Vulnerability Scanning - CyberArk"},
    @{Name="snowdisc";      Password="g6HNsBYrVMKbTXvY";     Description="ServiceNow Discovery"},
    @{Name="cstiope";       Password="7Gnyu6jUeCfoK917eupg"; Description="Security Team Admin"},
    @{Name="cloud_support"; Password="gY74!cne4GhLqzy";      Description="Cloud SysAdmin - Cloud Born"},
    @{Name="Admin01";       Password="uPi39sug512satgDaJDz"; Description="Service Owner Access"},
    @{Name="Provider01";    Password="eBR2mJVPDrbb9GKAmLB0"; Description="Vendor Access"}
    @{Name="automation";    Password="ZTcfJFLAfcY6T2gnkHAc"; Description="Automation tools access"}
    @{Name="admin_FEMSA";    Password="fii0sFax7w9QCneWhBN1"; Description="FEMSA Admin Access"}

)

foreach ($user in $users) {
    $username = $user.Name
    $description = $user.Description
    $password = ConvertTo-SecureString $user.Password -AsPlainText -Force

    if (-not (Get-LocalUser -Name $username -ErrorAction SilentlyContinue)) {
        New-LocalUser `
            -Name $username `
            -Password $password `
            -Description $description `
            -PasswordNeverExpires `
            -UserMayNotChangePassword `
            -AccountNeverExpires

        Add-LocalGroupMember -Group "Administrators" -Member $username

        Write-Output "User $username created and added to Administrators."
    } else {
        Write-Output "User $username already exists, skipping."
    }
}

Write-Output "Users created successfully."

# ============================================================
# STEP 3 - CYBERARK FIREWALL RULE
# ============================================================
Write-Output "Creating CyberArk firewall rule..."

New-NetFirewallRule `
    -DisplayName "Boveda_Cloud" `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort 3389,135,139,445 `
    -RemoteAddress "172.26.152.133","172.26.152.134","172.26.152.150","172.26.152.151" `
    -Action Allow `
    -Profile Any `
    -Enabled True

Write-Output "CyberArk firewall rule created successfully."

# ============================================================
# STEP 4 - WINRM HTTPS (5986) FOR ANSIBLE
# ============================================================
Write-Output "Configuring WinRM for Ansible..."

# Enable WinRM
Enable-PSRemoting -Force

# Create self-signed certificate
$cert = New-SelfSignedCertificate `
    -DnsName "OXOCI-VM-APP-SNOWITON-PRD" `
    -CertStoreLocation "Cert:\LocalMachine\My" `
    -NotAfter (Get-Date).AddYears(5)

# Create HTTPS listener
$thumbprint = $cert.Thumbprint
New-Item -Path "WSMan:\localhost\Listener" `
    -Transport HTTPS `
    -Address * `
    -CertificateThumbPrint $thumbprint `
    -Force

# Open WinRM HTTPS port in firewall
New-NetFirewallRule `
    -DisplayName "WinRM HTTPS - Ansible" `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort 5986 `
    -Action Allow `
    -Profile Any `
    -Enabled True

# Disable HTTP listener (5985) for security
Remove-Item -Path "WSMan:\localhost\Listener\Listener*" `
    -Recurse `
    -ErrorAction SilentlyContinue

# Harden WinRM
Set-Item -Path "WSMan:\localhost\Service\Auth\Basic" -Value $true
Set-Item -Path "WSMan:\localhost\Service\AllowUnencrypted" -Value $false

# Restart WinRM
Restart-Service WinRM

Write-Output "WinRM HTTPS configured successfully."

# ============================================================
# STEP 5 - DOMAIN JOIN PLACEHOLDER
# ============================================================
Write-Output "Domain join - PENDING MANUAL CONFIGURATION"
# TODO: Uncomment and fill credentials before running
# $domainUser = "PLACEHOLDER_DOMAIN_USER"
# $domainPassword = ConvertTo-SecureString "PLACEHOLDER_DOMAIN_PASSWORD" -AsPlainText -Force
# $credential = New-Object PSCredential("proximidad.com\$domainUser", $domainPassword)
# Add-Computer -DomainName "proximidad.com" -Credential $credential -Restart -Force

# ============================================================
# STEP 6 - RESTART TO APPLY HOSTNAME
# ============================================================
Write-Output "Restarting server to apply hostname change..."
Start-Sleep -Seconds 10
Restart-Computer -Force
