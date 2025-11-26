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

# Import shared utilities
Import-Module "$PSScriptRoot\UserFilesUtils.psm1" -Force

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

Write-FileLog -Message "Starting migration process (MinSize: ${minSizeMB}MB, WhatIf: $WhatIf)" -Level 'INFO' -LogPath $logFile

# Check if D: drive exists
if (-not (Test-Path "D:\")) {
    Write-Host "ERROR: D: drive not found. Cannot proceed." -ForegroundColor Red
    Write-FileLog -Message "ERROR: D: drive not found" -Level 'ERROR' -LogPath $logFile
    exit 1
}

# ============================================================================
# SCAN FILES
# ============================================================================

Write-Host "Scanning for large files..." -ForegroundColor Yellow
Write-Host ""

$scanData = Scan-LargeUserFiles -MinSizeMB $minSizeMB -Verbose

if ($scanData.TotalFiles -eq 0) {
    Write-Host "No files found larger than ${minSizeMB}MB" -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "Found $($scanData.TotalFiles) files to process" -ForegroundColor Green
Write-Host ""

# ============================================================================
# MIGRATE FILES
# ============================================================================

$stats = @{
    TotalFiles = 0
    CopiedFiles = 0
    DeletedFiles = 0
    FailedFiles = 0
    TotalBytesMoved = 0
}

foreach ($user in $scanData.Results.Keys) {
    Write-Host "Processing user: $user..." -ForegroundColor Cyan
    Write-FileLog -Message "Scanning user: $user" -Level 'INFO' -LogPath $logFile
    
    foreach ($file in $scanData.Results[$user]) {
        $stats.TotalFiles++
        
        # Calculate destination path
        $relativePath = $file.FullPath.Replace("C:\Users\", "")
        $destPath = "D:\Users\$relativePath"
        
        $fileSizeMB = $file.SizeMB
        Write-Host "  Found: $($file.FullPath) ($fileSizeMB MB)" -ForegroundColor Gray
        
        if ($WhatIf) {
            Write-Host "    → Would move to: $destPath" -ForegroundColor DarkGray
            Write-FileLog -Message "WHATIF: Would move $($file.FullPath) to $destPath" -Level 'INFO' -LogPath $logFile
            continue
        }
        
        try {
            # Copy file with verification
            Write-Host "    Copying to D: drive..." -ForegroundColor Yellow
            $copySuccess = Copy-FileWithVerification -SourcePath $file.FullPath -DestinationPath $destPath
            
            if ($copySuccess) {
                Write-Host "    ✓ Copy verified!" -ForegroundColor Green
                
                # Attempt to delete (may fail if locked)
                try {
                    Write-Host "    Deleting from C: drive..." -ForegroundColor Yellow
                    Remove-Item -Path $file.FullPath -Force -ErrorAction Stop
                    $stats.DeletedFiles++
                    Write-Host "    ✓ Migrated successfully" -ForegroundColor Green
                    Write-FileLog -Message "SUCCESS: Moved $($file.FullPath) → $destPath ($fileSizeMB MB)" -Level 'SUCCESS' -LogPath $logFile
                } catch {
                    Write-Host "    ⚠ Could not delete (file may be locked). Copy successful, original kept." -ForegroundColor Yellow
                    Write-FileLog -Message "WARNING: Copied but could not delete $($file.FullPath): $($_.Exception.Message)" -Level 'WARNING' -LogPath $logFile
                }
                
                $stats.CopiedFiles++
                $stats.TotalBytesMoved += ($fileSizeMB * 1MB)
            } else {
                Write-Host "    ✗ Hash mismatch! Keeping original file." -ForegroundColor Red
                $stats.FailedFiles++
                Write-FileLog -Message "ERROR: Hash verification failed for $($file.FullPath)" -Level 'ERROR' -LogPath $logFile
            }
            
        } catch {
            $stats.FailedFiles++
            Write-Host "    ✗ Failed: $($_.Exception.Message)" -ForegroundColor Red
            Write-FileLog -Message "ERROR: Failed to move $($file.FullPath): $($_.Exception.Message)" -Level 'ERROR' -LogPath $logFile
        }
    }
    Write-Host ""
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
Write-FileLog -Message $summary -Level 'INFO' -LogPath $logFile

Write-Host ""
Write-Host "=" * 80 -ForegroundColor Green
