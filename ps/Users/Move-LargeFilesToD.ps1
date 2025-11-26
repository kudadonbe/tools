<#
.SYNOPSIS
    Moves large user files from C:\Users to D:\Users with verification.

.DESCRIPTION
    Scans C:\Users for large files, copies them to D:\Users preserving folder structure,
    verifies successful copy using hash comparison, then deletes from C: drive.
    Creates a detailed log of all operations.

.PARAMETER MinSizeMB
    Minimum file size in megabytes to move (default: 200MB)

.PARAMETER WhatIf
    Show what would be moved without actually moving files

.EXAMPLE
    .\Move-LargeFilesToD.ps1
    Move files larger than 200MB with verification

.EXAMPLE
    .\Move-LargeFilesToD.ps1 -MinSizeMB 500 -WhatIf
    Preview what files larger than 500MB would be moved

.NOTES
    File Name  : Move-LargeFilesToD.ps1
    Author     : Hussain Shareef
    Created    : 2025-11-26
    
.OUTPUTS
    MoveLog_[timestamp].txt - Detailed log of all operations
#>

[CmdletBinding()]
param(
    [Parameter()]
    [int]$MinSizeMB,
    
    [Parameter()]
    [switch]$WhatIf
)

# ============================================================================
# CONFIGURATION
# ============================================================================

# Prompt for minimum size if not provided
if (-not $MinSizeMB) {
    $minSizeMB = Read-Host "Enter minimum file size in MB (default: 200)"
    if ([string]::IsNullOrWhiteSpace($minSizeMB) -or $minSizeMB -notmatch '^\d+$') {
        $minSizeMB = 200
        Write-Host "Using default size: 200MB" -ForegroundColor Yellow
    } else {
        $minSizeMB = [int]$minSizeMB
    }
} else {
    $minSizeMB = $MinSizeMB
}

Write-Host "Using minimum size: ${minSizeMB}MB" -ForegroundColor Yellow
Write-Host ""

# Log file location
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logFile = "$PSScriptRoot\MoveLog_$timestamp.txt"

# System and program folders to exclude (protect all application data)
$excludeFolders = @(
    # Application data (critical - DO NOT MOVE)
    'AppData',              # All application settings and data
    'Application Data',     # Legacy app data symlink
    'Local Settings',       # Legacy local settings
    
    # Development tools (packages and caches)
    '.nuget',               # NuGet packages
    '.vscode',              # VS Code settings
    '.android',             # Android SDK
    '.gradle',              # Gradle cache
    '.docker',              # Docker data
    '.m2',                  # Maven repository
    '.npm',                 # NPM cache
    '.cargo',               # Rust packages
    'node_modules',         # Node.js packages
    'venv',                 # Python virtual environments
    'env',                  # Python virtual environments
    '.virtualenv',          # Python virtual environments
    
    # Cloud sync folders (already backed up)
    'OneDrive',             # OneDrive sync
    'Dropbox',              # Dropbox sync
    'Google Drive',         # Google Drive sync
    'iCloudDrive',          # iCloud sync
    
    # Windows system folders
    'Saved Games',          # Game saves
    'Searches',             # Saved searches
    'Links',                # Quick access links
    'Contacts',             # Windows contacts
    'Favorites',            # Browser favorites
    'Cookies',              # Browser cookies
    'NetHood',              # Network shortcuts
    'PrintHood',            # Printer shortcuts
    'Recent',               # Recent files list
    'SendTo',               # Send to menu items
    'Start Menu',           # Start menu shortcuts
    'Templates',            # Document templates
    
    # Browser profiles (contain settings and extensions)
    '.mozilla',             # Firefox
    '.chrome',              # Chrome
    'Chrome',               # Chrome user data
    'Firefox',              # Firefox user data
    'Edge',                 # Edge user data
    
    # Program-specific folders
    '.ssh',                 # SSH keys (security sensitive)
    '.gnupg',               # GPG keys (security sensitive)
    '.aws',                 # AWS credentials (security sensitive)
    '.kube',                # Kubernetes config (security sensitive)
    'workspace',            # IDE workspaces
    '.idea',                # IntelliJ settings
    '.eclipse',             # Eclipse settings
    
    # Game launchers
    'Steam',                # Steam (program files)
    'Epic Games',           # Epic Games launcher
    'Battle.net',           # Blizzard launcher
    
    # System cache
    'Temp',                 # Temporary files
    'tmp',                  # Temporary files
    'cache',                # General cache
    'Cache'                 # General cache
)

# ============================================================================
# FUNCTIONS
# ============================================================================

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $logMessage = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [$Level] $Message"
    Add-Content -Path $logFile -Value $logMessage
    
    switch ($Level) {
        "ERROR"   { Write-Host $Message -ForegroundColor Red }
        "SUCCESS" { Write-Host $Message -ForegroundColor Green }
        "WARNING" { Write-Host $Message -ForegroundColor Yellow }
        default   { Write-Host $Message }
    }
}

function Get-FileHashQuick {
    param([string]$Path)
    try {
        return (Get-FileHash -Path $Path -Algorithm SHA256).Hash
    } catch {
        return $null
    }
}

# ============================================================================
# INITIALIZATION
# ============================================================================

Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "LARGE FILE MIGRATION: C:\Users → D:\Users" -ForegroundColor Cyan
Write-Host "=" * 80 -ForegroundColor Cyan

if ($WhatIf) {
    Write-Host "WHATIF MODE: No files will be moved" -ForegroundColor Yellow
    Write-Host ""
}

Write-Log "Starting migration process (MinSize: ${minSizeMB}MB, WhatIf: $WhatIf)"

# Check if D: drive exists
if (-not (Test-Path "D:\")) {
    Write-Log "ERROR: D: drive not found. Cannot proceed." "ERROR"
    exit 1
}

# Initialize counters
$stats = @{
    TotalFiles = 0
    CopiedFiles = 0
    DeletedFiles = 0
    FailedFiles = 0
    TotalBytesMoved = 0
}

# ============================================================================
# SCAN AND MOVE FILES
# ============================================================================

# Get all user folders
$userFolders = Get-ChildItem -Path 'C:\Users' -Directory -ErrorAction SilentlyContinue | 
    Where-Object { $_.Name -notin @('Public', 'Default', 'Default User', 'All Users') }

foreach ($userFolder in $userFolders) {
    Write-Host ""
    Write-Host "Processing user: $($userFolder.Name)..." -ForegroundColor Cyan
    Write-Log "Scanning user: $($userFolder.Name)"
    
    try {
        # Find large files
        $files = Get-ChildItem -Path $userFolder.FullName -File -Recurse -Force -ErrorAction SilentlyContinue |
            Where-Object {
                if ($_.Length -lt ($minSizeMB * 1MB)) { return $false }
                
                $inExcludedFolder = $false
                foreach ($exclude in $excludeFolders) {
                    if ($_.FullName -match "\\$exclude\\") {
                        $inExcludedFolder = $true
                        break
                    }
                }
                return (-not $inExcludedFolder)
            }
        
        # Process each file
        foreach ($file in $files) {
            $stats.TotalFiles++
            
            # Calculate destination path (C:\Users\username\... → D:\Users\username\...)
            $relativePath = $file.FullName.Replace("C:\Users\", "")
            $destPath = "D:\Users\$relativePath"
            $destDir = Split-Path -Path $destPath -Parent
            
            $fileSizeMB = [math]::Round($file.Length / 1MB, 2)
            Write-Host "  Found: $($file.FullName) ($fileSizeMB MB)" -ForegroundColor Gray
            
            if ($WhatIf) {
                Write-Host "    → Would move to: $destPath" -ForegroundColor DarkGray
                Write-Log "WHATIF: Would move $($file.FullName) to $destPath"
                continue
            }
            
            try {
                # Create destination directory if needed
                if (-not (Test-Path $destDir)) {
                    New-Item -Path $destDir -ItemType Directory -Force | Out-Null
                    Write-Log "Created directory: $destDir"
                }
                
                # Copy file (NOT move - safer for locked files)
                Write-Host "    Copying to D: drive..." -ForegroundColor Yellow
                Copy-Item -Path $file.FullName -Destination $destPath -Force -ErrorAction Stop
                
                # Verify copy with hash comparison
                Write-Host "    Verifying copy..." -ForegroundColor Yellow
                $sourceHash = Get-FileHashQuick -Path $file.FullName
                $destHash = Get-FileHashQuick -Path $destPath
                
                if ($sourceHash -and $destHash -and ($sourceHash -eq $destHash)) {
                    # Verification successful - safely delete original
                    Write-Host "    ✓ Verified! Deleting from C: drive..." -ForegroundColor Green
                    
                    # Attempt to delete (may fail if file is locked - that's OK)
                    try {
                        Remove-Item -Path $file.FullName -Force -ErrorAction Stop
                        $stats.DeletedFiles++
                        Write-Log "SUCCESS: Moved $($file.FullName) → $destPath ($fileSizeMB MB)" "SUCCESS"
                    } catch {
                        Write-Host "    ⚠ Could not delete (file may be locked). Copy successful, original kept." -ForegroundColor Yellow
                        Write-Log "WARNING: Copied but could not delete $($file.FullName): $($_.Exception.Message)" "WARNING"
                    }
                    
                    $stats.CopiedFiles++
                    $stats.TotalBytesMoved += $file.Length
                } else {
                    # Verification failed - keep original
                    Write-Host "    ✗ Hash mismatch! Keeping original file." -ForegroundColor Red
                    Remove-Item -Path $destPath -Force -ErrorAction SilentlyContinue
                    $stats.FailedFiles++
                    Write-Log "ERROR: Hash verification failed for $($file.FullName)" "ERROR"
                }
                
            } catch {
                $stats.FailedFiles++
                Write-Log "ERROR: Failed to move $($file.FullName): $($_.Exception.Message)" "ERROR"
            }
        }
        
    } catch {
        Write-Log "ERROR: Failed to scan $($userFolder.Name): $($_.Exception.Message)" "ERROR"
    }
}

# ============================================================================
# SUMMARY
# ============================================================================

Write-Host ""
Write-Host "=" * 80 -ForegroundColor Green
Write-Host "MIGRATION COMPLETE" -ForegroundColor Green
Write-Host "=" * 80 -ForegroundColor Green

$summary = @"

Summary:
--------
Total files found:     $($stats.TotalFiles)
Successfully copied:   $($stats.CopiedFiles)
Deleted from C:       $($stats.DeletedFiles)
Failed:               $($stats.FailedFiles)
Total data moved:     $([math]::Round($stats.TotalBytesMoved / 1GB, 2)) GB

Log file: $logFile
"@

Write-Host $summary
Write-Log $summary

Write-Host ""
Write-Host "=" * 80 -ForegroundColor Green
