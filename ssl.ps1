<# 
.SYNOPSIS
    Installs Let's Encrypt root certificates if they are not already installed.

.DESCRIPTION
    This script downloads the ISRG Root X1 and ISRG Root X2 certificates from Let's Encrypt
    and installs them into the Trusted Root Certification Authorities store if they are not present.
    If any certificates are already installed, it notifies the user and prompts for reinstallation of all installed certificates at once.

.NOTES
    Author: Prism
    Updated: 11-13-2024
    Version: 1.0.0

#>

$certificates = @{
    "ISRG Root X1" = "https://letsencrypt.org/certs/isrgrootx1.der"
    "ISRG Root X2" = "https://letsencrypt.org/certs/isrg-root-x2.der"
}

function Test-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

function Install-Certificate {
    param (
        [string]$Name,
        [string]$Url,
        [System.Security.Cryptography.X509Certificates.X509Store]$Store
    )

    try {
        $certPath = Join-Path -Path $env:TEMP -ChildPath "$Name.der"
        Invoke-WebRequest -Uri $Url -OutFile $certPath -UseBasicParsing

        $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
        $cert.Import($certPath)

        $Store.Add($cert)
        Write-Output "Successfully installed certificate '$Name'."

        Remove-Item -Path $certPath -Force
    }
    catch {
        throw "An error occurred while downloading or installing certificate '$Name': $_"
    }
}

try {
    if (-not (Test-Admin)) {
        Write-Output "Administrator privileges are required to install certificates."
        Write-Output "Please run PowerShell/Command Prompt as an administrator and try again."
        exit 1
    }

    $store = New-Object System.Security.Cryptography.X509Certificates.X509Store("Root", "LocalMachine")
    $store.Open("ReadWrite")

    $installedCerts = @()
    $notInstalledCerts = @()

    foreach ($name in $certificates.Keys) {
        $url = $certificates[$name]
        $certExists = $store.Certificates | Where-Object { $_.Subject -like "*CN=$name*" }

        if ($certExists) {
            $installedCerts += @{
                Name = $name
                Url  = $url
                Certs = $certExists
            }
        }
        else {
            $notInstalledCerts += @{
                Name = $name
                Url  = $url
            }
        }
    }

    if ($installedCerts.Count -gt 0) {
        Write-Output "The following certificate(s) are already installed:"

        foreach ($certInfo in $installedCerts) {
            foreach ($cert in $certInfo.Certs) {
                Write-Output " - $($certInfo.Name) (Thumbprint: $($cert.Thumbprint))"
            }
        }

        $response = Read-Host "Do you want to reinstall the above certificate(s)? (Y/N)"
        if ($response -match '^[Yy]') {
            foreach ($certInfo in $installedCerts) {
                foreach ($cert in $certInfo.Certs) {
                    $store.Remove($cert)
                }
            }

            foreach ($certInfo in $installedCerts) {
                Install-Certificate -Name $certInfo.Name -Url $certInfo.Url -Store $store
            }
        }
        else {
            Write-Output "Skipping reinstallation of existing certificate(s)."
        }
    }

    if ($notInstalledCerts.Count -gt 0) {
        foreach ($certInfo in $notInstalledCerts) {
            Write-Output "Certificate '$($certInfo.Name)' is not installed. Proceeding with installation."
            Install-Certificate -Name $certInfo.Name -Url $certInfo.Url -Store $store
        }
    }

    $store.Close()

    Write-Output "Certificate installation process completed successfully."
}
catch {
    Write-Error $_
    exit 1
}
