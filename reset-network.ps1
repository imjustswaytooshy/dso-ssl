# Check if running as Administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script must be run as Administrator. Please restart PowerShell or Command Prompt as Administrator." -ForegroundColor Red
    Pause
    Exit
}

# Function to update service StartupType if the service is running
function Update-ServiceStartType {
    param (
        [string]$ServiceName,
        [string]$DesiredStartupType
    )
    
    # Get the service status
    $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    if ($service -and $service.Status -eq 'Running') {
        Set-Service -Name $ServiceName -StartupType $DesiredStartupType
        Write-Host "Service '$ServiceName' startup type set to '$DesiredStartupType'." -ForegroundColor Green
    } else {
        Write-Host "Service '$ServiceName' is not running. Skipping..." -ForegroundColor Yellow
    }
}

# Reset Internet Options to Default
Write-Host "Resetting Internet Options to Default..." -ForegroundColor Yellow
Invoke-Expression -Command "rundll32.exe inetcpl.cpl,ClearMyTracksByProcess 4351"

# Flush DNS Cache
Write-Host "Flushing DNS Cache..." -ForegroundColor Yellow
Clear-DnsClientCache

# Reset Network Adapter
Write-Host "Resetting Network Adapters..." -ForegroundColor Yellow
$adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
if ($adapters) {
    foreach ($adapter in $adapters) {
        Write-Host "Disabling Network Adapter: $($adapter.Name)" -ForegroundColor Cyan
        Disable-NetAdapter -Name $adapter.Name -Confirm:$false
        Start-Sleep -Seconds 2
        Write-Host "Enabling Network Adapter: $($adapter.Name)" -ForegroundColor Cyan
        Enable-NetAdapter -Name $adapter.Name -Confirm:$false
    }
} else {
    Write-Host "No active network adapters found." -ForegroundColor Red
}

# Reset TCP/IP Stack
Write-Host "Resetting TCP/IP Stack..." -ForegroundColor Yellow
netsh int ip reset

# Reset Winsock
Write-Host "Resetting Winsock Catalog..." -ForegroundColor Yellow
netsh winsock reset

# Release IP Address
Write-Host "Releasing IP Address..." -ForegroundColor Yellow
ipconfig /release

# Renew IP Address
Write-Host "Renewing IP Address..." -ForegroundColor Yellow
ipconfig /renew

# Flush ARP Cache
Write-Host "Clearing ARP Cache..." -ForegroundColor Yellow
arp -d *

# Clear Routing Tables
Write-Host "Clearing Routing Tables..." -ForegroundColor Yellow
route -f

# Reset Windows Firewall Rules
Write-Host "Resetting Windows Firewall to Default Settings..." -ForegroundColor Yellow
netsh advfirewall reset

# Enable Windows Firewall for All Profiles
Write-Host "Enabling Windows Firewall for All Profiles..." -ForegroundColor Yellow
netsh advfirewall set allprofiles state on

# Disable and Re-enable Network Discovery (optional)
Write-Host "Resetting Network Discovery Settings..." -ForegroundColor Yellow
Update-ServiceStartType -ServiceName "fdPHost" -DesiredStartupType "Automatic"
Update-ServiceStartType -ServiceName "fdResPub" -DesiredStartupType "Automatic"

Write-Host "Network and firewall reset completed successfully!" -ForegroundColor Green
