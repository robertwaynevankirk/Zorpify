<# 
.SYNOPSIS
    Automates the setup of locally trusted SSL certificates using mkcert for LibreChat.

.DESCRIPTION
    This script downloads mkcert.exe, installs the local CA, generates SSL certificates for localhost,
    and places them in the specified SSL directory within the LibreChat project.

.PARAMETER ProjectRoot
    The root directory of your LibreChat project (e.g., C:\Users\robert\GitHub\Zorpify).

.NOTES
    - Ensure you have PowerShell 7 installed.
    - Run this script with appropriate permissions.
#>

param (
    [Parameter(Mandatory = $true)]
    [string]$ProjectRoot  # e.g., "C:\Users\robert\GitHub\Zorpify"
)

# Define paths
$mkcertVersion = "v1.4.4"  # Update to the latest version if necessary
$mkcertUrl = "https://github.com/FiloSottile/mkcert/releases/download/$mkcertVersion/mkcert-$mkcertVersion-windows-amd64.exe"
$mkcertPath = Join-Path -Path $ProjectRoot -ChildPath "mkcert.exe"
$sslDir = Join-Path -Path $ProjectRoot -ChildPath "custom\nginx\ssl"
$nginxDir = Join-Path -Path $ProjectRoot -ChildPath "custom\nginx"

# Function to download mkcert.exe
function Download-Mkcert {
    param (
        [string]$Url,
        [string]$Destination
    )

    Write-Host "Downloading mkcert from $Url..." -ForegroundColor Cyan
    try {
        Invoke-WebRequest -Uri $Url -OutFile $Destination -UseBasicParsing
        Write-Host "mkcert downloaded successfully to $Destination." -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to download mkcert. $_"
        exit 1
    }
}

# Function to install the local CA
function Install-LocalCA {
    param (
        [string]$MkcertExecutable
    )

    Write-Host "Installing the local Certificate Authority (CA)..." -ForegroundColor Cyan
    try {
        & $MkcertExecutable -install
        Write-Host "Local CA installed successfully." -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to install local CA. $_"
        exit 1
    }
}

# Function to generate SSL certificates for localhost
function Generate-SSL {
    param (
        [string]$MkcertExecutable,
        [string]$HostName,
        [string]$OutputCert,
        [string]$OutputKey
    )

    Write-Host "Generating SSL certificates for $HostName..." -ForegroundColor Cyan
    try {
        & $MkcertExecutable $HostName
        Write-Host "SSL certificates generated successfully." -ForegroundColor Green

        # Rename and move the certificates
        Move-Item -Path "localhost.pem" -Destination $OutputCert -Force
        Move-Item -Path "localhost-key.pem" -Destination $OutputKey -Force
        Write-Host "Certificates moved to $sslDir as 'self-signed.crt' and 'self-signed.key'." -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to generate SSL certificates. $_"
        exit 1
    }
}

# Main Script Execution

# Step 1: Create SSL directory if it doesn't exist
if (-Not (Test-Path $sslDir)) {
    Write-Host "Creating SSL directory at $sslDir..." -ForegroundColor Yellow
    try {
        New-Item -Path $sslDir -ItemType Directory -Force | Out-Null
        Write-Host "SSL directory created." -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to create SSL directory. $_"
        exit 1
    }
}
else {
    Write-Host "SSL directory already exists at $sslDir." -ForegroundColor Green
}

# Step 2: Download mkcert.exe if not present
if (-Not (Test-Path $mkcertPath)) {
    Download-Mkcert -Url $mkcertUrl -Destination $mkcertPath
    # Make mkcert.exe executable
    Set-ItemProperty -Path $mkcertPath -Name IsReadOnly -Value $false
}
else {
    Write-Host "mkcert.exe already exists at $mkcertPath." -ForegroundColor Green
}

# Step 3: Install the local CA
Install-LocalCA -MkcertExecutable $mkcertPath

# Step 4: Generate SSL certificates for localhost
$certOutput = Join-Path -Path $sslDir -ChildPath "self-signed.crt"
$keyOutput = Join-Path -Path $sslDir -ChildPath "self-signed.key"
Generate-SSL -MkcertExecutable $mkcertPath -HostName "localhost" -OutputCert $certOutput -OutputKey $keyOutput

Write-Host "SSL setup completed successfully!" -ForegroundColor Green
Write-Host "Your self-signed certificates are located at:" -ForegroundColor Cyan
Write-Host "Certificate: $certOutput" -ForegroundColor Cyan
Write-Host "Key: $keyOutput" -ForegroundColor Cyan
