<#
.SYNOPSIS
    Sets up Windows Subsystem for Linux (WSL) with Debian and prepares the system for Docker Desktop installation.

.DESCRIPTION
    This script ensures it runs with administrative privileges, enables necessary Windows features, disables conflicting features,
    installs and configures Debian on WSL2, updates the Debian distribution, and prompts the user to restart the system.

.NOTES
    - Requires Windows 10 version 2004 or higher (Build 19041 or higher) or Windows 11.
    - Designed to automate the setup process for WSL2 with Debian.
#>

# Exit immediately if a command exits with a non-zero status
$ErrorActionPreference = 'Stop'

# Function to check for Administrator privileges
function Ensure-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Warning "Administrator privileges required. Attempting to restart as Administrator..."
        # Relaunch the script with elevated privileges
        Start-Process -FilePath "PowerShell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
        exit
    }
}

# Function to enable Windows features
function Enable-WindowsFeatures {
    param (
        [string[]]$Features
    )
    foreach ($feature in $Features) {
        if (-not (Get-WindowsOptionalFeature -Online -FeatureName $feature).State -eq 'Enabled') {
            Write-Host "Enabling feature: $feature"
            dism.exe /online /enable-feature /featurename:$feature /all /norestart | Out-Null
            if ($LASTEXITCODE -ne 0) {
                throw "Failed to enable feature: $feature"
            }
        } else {
            Write-Host "Feature already enabled: $feature"
        }
    }
}

# Function to disable Windows features
function Disable-WindowsFeatures {
    param (
        [string[]]$Features
    )
    foreach ($feature in $Features) {
        if (-not (Get-WindowsOptionalFeature -Online -FeatureName $feature).State -eq 'Disabled') {
            Write-Host "Disabling feature: $feature"
            Disable-WindowsOptionalFeature -Online -FeatureName $feature -NoRestart -ErrorAction SilentlyContinue
            if ($?) {
                Write-Host "Successfully disabled: $feature"
            } else {
                Write-Warning "Failed to disable feature: $feature"
            }
        } else {
            Write-Host "Feature already disabled: $feature"
        }
    }
}

# Function to set WSL default version
function Set-WSLDefaultVersion {
    param (
        [int]$Version = 2
    )
    Write-Host "Setting WSL default version to WSL$Version..."
    wsl --set-default-version $Version
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to set WSL default version to $Version."
    }
}

# Function to install a WSL distribution
function Install-WSLDistribution {
    param (
        [string]$Distribution
    )
    if (-not (wsl --list --quiet | Where-Object { $_ -eq $Distribution })) {
        Write-Host "Installing WSL distribution: $Distribution..."
        wsl --install -d $Distribution
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to install WSL distribution: $Distribution."
        }
    } else {
        Write-Host "WSL distribution already installed: $Distribution."
    }
}

# Function to set WSL distribution version
function Set-WSLDistributionVersion {
    param (
        [string]$Distribution,
        [int]$Version = 2
    )
    Write-Host "Setting $Distribution to WSL$Version..."
    wsl --set-version $Distribution $Version
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Failed to set $Distribution to WSL$Version."
    }
}

# Function to update Debian
function Update-Debian {
    Write-Host "Updating Debian packages..."
    wsl -d Debian -- bash -c "sudo apt update && sudo apt full-upgrade -y"
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Failed to update Debian. Please check your network connection and try manually."
    }
}

# Function to prompt for system restart
function Prompt-Restart {
    $restart = Read-Host "A system restart is required to complete the setup. Would you like to restart now? (Y/N)"
    if ($restart -match '^[Yy]$') {
        Write-Host "Restarting the computer..."
        Restart-Computer -Force
    } else {
        Write-Warning "You chose not to restart. Some changes may not take effect until after a restart."
    }
}

# Main script execution
try {
    Ensure-Administrator

    # Enable required Windows features
    $requiredFeatures = @(
        "Microsoft-Windows-Subsystem-Linux",
        "VirtualMachinePlatform"
    )
    Enable-WindowsFeatures -Features $requiredFeatures

    # Disable conflicting Windows features
    $conflictingFeatures = @(
        "WindowsSandbox",
        "Microsoft-Hyper-V-All",
        "WindowsHypervisorPlatform"
    )
    Disable-WindowsFeatures -Features $conflictingFeatures

    # Set WSL to version 2 as default
    Set-WSLDefaultVersion -Version 2

    # Install Debian if not already installed
    Install-WSLDistribution -Distribution "Debian"

    # Ensure Debian is using WSL2
    Set-WSLDistributionVersion -Distribution "Debian" -Version 2

    # Launch Debian to complete initial setup
    Write-Host "Launching Debian for initial setup..."
    Start-Process -FilePath "wsl.exe" -ArgumentList "-d Debian" -Wait

    # Update Debian packages
    Update-Debian

    Write-Host "Setup complete. You can now install Docker Desktop."

    # Prompt for system restart
    Prompt-Restart

} catch {
    Write-Error "An error occurred: $_"
    Write-Error "Setup cannot continue. Please resolve the issue and try again."
    exit 1
}
