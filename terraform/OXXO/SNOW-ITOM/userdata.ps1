#ps1_sysnative
# ============================================================
# Script 1 - Cloud-Init
# OXOCI-VM-APP-SNOWITON-PRD - ServiceNow ITOM MID Server
# CHG: CHG0140789 | Date: 02-12-2026
# ============================================================

# ============================================================
# STEP 1 - SET HOSTNAME
# ============================================================
Write-Output "Setting hostname..."
Rename-Computer -NewName "OXOCI-VM-APP-SNOWITON-PRD" -Force
Write-Output "Hostname set successfully."

# ============================================================
# STEP 2 - CYBERARK FIREWALL RULE
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
# STEP 3 - WINRM HTTPS (5986) FOR ANSIBLE
# ============================================================
Write-Output "Configuring WinRM for Ansible..."

# Enable WinRM
Enable-PSRemoting -Force

# Create self-signed certificate (5 year validity)
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
# STEP 4 - RESTART TO APPLY HOSTNAME
# ============================================================
Write-Output "Restarting server to apply hostname change..."
Start-Sleep -Seconds 10
Restart-Computer -Force