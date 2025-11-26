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

# System folders to exclude
$excludeFolders = @(
    'AppData', 'Application Data', '.nuget', '.vscode', '.android', 
    '.gradle', 'node_modules', 'OneDrive', 'Saved Games', 
    'Searches', 'Links', 'Contacts', 'Favorites'
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
                
                # Copy file
                Write-Host "    Copying to D: drive..." -ForegroundColor Yellow
                Copy-Item -Path $file.FullName -Destination $destPath -Force
                
                # Verify copy with hash comparison
                Write-Host "    Verifying copy..." -ForegroundColor Yellow
                $sourceHash = Get-FileHashQuick -Path $file.FullName
                $destHash = Get-FileHashQuick -Path $destPath
                
                if ($sourceHash -and $destHash -and ($sourceHash -eq $destHash)) {
                    # Verification successful - delete original
                    Write-Host "    ✓ Verified! Deleting from C: drive..." -ForegroundColor Green
                    Remove-Item -Path $file.FullName -Force
                    
                    $stats.CopiedFiles++
                    $stats.DeletedFiles++
                    $stats.TotalBytesMoved += $file.Length
                    
                    Write-Log "SUCCESS: Moved $($file.FullName) → $destPath ($fileSizeMB MB)" "SUCCESS"
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
