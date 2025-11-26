<#
.SYNOPSIS
    Interactive TUI for managing large user files - scan, report, and optionally migrate.

.DESCRIPTION
    Combined interface for finding and managing large files in C:\Users.
    - Scan for large files and generate report
    - Optionally migrate files to D:\Users with verification
    - Interactive menu-driven interface

.EXAMPLE
    .\Manage-LargeUserFiles.ps1
    Launch interactive TUI to scan and manage large files

.NOTES
    File Name  : Manage-LargeUserFiles.ps1
    Author     : Hussain Shareef
    Created    : 2025-11-26
    
.OUTPUTS
    - LargeUserFiles_[timestamp].txt - Scan report
    - MoveLog_[timestamp].txt - Migration log (if files moved)
#>

# Import shared utilities
Import-Module "$PSScriptRoot\UserFilesUtils.psm1" -Force

# ============================================================================
# CONFIGURATION
# ============================================================================

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$reportFile = "$PSScriptRoot\LargeUserFiles_$timestamp.txt"
$logFile = "$PSScriptRoot\MoveLog_$timestamp.txt"

# ============================================================================
# UI FUNCTIONS
# ============================================================================

function Show-Header {
    param([string]$Title)
    Clear-Host
    Write-Host ""
    Write-Host ("=" * 80) -ForegroundColor Cyan
    Write-Host "  $Title" -ForegroundColor Cyan
    Write-Host ("=" * 80) -ForegroundColor Cyan
    Write-Host ""
}

function Show-Menu {
    Write-Host "  What would you like to do?" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  [1] Scan and generate report only" -ForegroundColor White
    Write-Host "  [2] Scan and move files to D: drive" -ForegroundColor White
    Write-Host "  [3] Exit" -ForegroundColor DarkGray
    Write-Host ""
}

function Get-MinimumSize {
    Write-Host "  Enter minimum file size in MB:" -ForegroundColor Yellow
    Write-Host "  (Press Enter for default: 200MB)" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host -NoNewline "  Size (MB): " -ForegroundColor White
    
    $input = Read-Host
    if ([string]::IsNullOrWhiteSpace($input) -or $input -notmatch '^\d+$') {
        return 200
    }
    return [int]$input
}

# ============================================================================
# WORKFLOW FUNCTIONS
# ============================================================================

function Invoke-ScanWorkflow {
    param([int]$MinSize)
    
    Write-Host ""
    Write-Host "  Scanning C:\Users for files larger than ${MinSize}MB..." -ForegroundColor Yellow
    Write-Host "  This may take a few minutes..." -ForegroundColor DarkGray
    Write-Host ""
    
    $scanData = Scan-LargeUserFiles -MinSizeMB $MinSize -Verbose
    
    Write-Host ""
    if ($scanData.TotalFiles -eq 0) {
        Write-Host "  No files found larger than ${MinSize}MB" -ForegroundColor Yellow
    } else {
        New-LargeFilesReport -ScanData $scanData -MinSizeMB $MinSize -OutputPath $reportFile
        
        Write-Host ""
        Write-Host ("=" * 80) -ForegroundColor Green
        Write-Host "  Report saved to: $reportFile" -ForegroundColor Green
        Write-Host ("=" * 80) -ForegroundColor Green
        Write-Host ""
        Write-Host "  Found $($scanData.TotalFiles) large files" -ForegroundColor Green
    }
    
    return $scanData
}

function Invoke-MigrationWorkflow {
    param($ScanData)
    
    Write-Host ""
    Write-Host ("=" * 80) -ForegroundColor Yellow
    Write-Host "  MIGRATION TO D: DRIVE" -ForegroundColor Yellow
    Write-Host ("=" * 80) -ForegroundColor Yellow
    Write-Host ""
    
    if (-not (Test-Path "D:\")) {
        Write-Host "  ERROR: D: drive not found!" -ForegroundColor Red
        Write-Host ""
        return
    }
    
    Write-Host "  Found $($ScanData.TotalFiles) files to migrate" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Files will be:" -ForegroundColor White
    Write-Host "    1. Copied to D:\Users\<username>\..." -ForegroundColor Gray
    Write-Host "    2. Verified using SHA256 hash" -ForegroundColor Gray
    Write-Host "    3. Deleted from C: only if verification succeeds" -ForegroundColor Gray
    Write-Host ""
    Write-Host -NoNewline "  Proceed with migration? (Y/N): " -ForegroundColor Yellow
    
    $confirm = Read-Host
    if ($confirm -ne 'Y' -and $confirm -ne 'y') {
        Write-Host "  Migration cancelled." -ForegroundColor Yellow
        Write-Host ""
        return
    }
    
    Write-FileLog -Message "Starting migration to D: drive" -Level 'INFO' -LogPath $logFile
    
    $stats = @{
        TotalFiles = 0
        CopiedFiles = 0
        DeletedFiles = 0
        FailedFiles = 0
        TotalBytesMoved = 0
    }
    
    Write-Host ""
    Write-Host "  Starting migration..." -ForegroundColor Cyan
    Write-Host ""
    
    foreach ($user in $ScanData.Results.Keys) {
        Write-Host "  Processing: $user" -ForegroundColor Cyan
        
        foreach ($file in $ScanData.Results[$user]) {
            $stats.TotalFiles++
            
            $sourcePath = $file.FullPath
            $relativePath = $sourcePath.Replace("C:\Users\", "")
            $destPath = "D:\Users\$relativePath"
            
            Write-Host "    Processing: $($file.Path) ($($file.SizeMB) MB)" -ForegroundColor Gray
            
            try {
                Write-Host "      -> Copying..." -ForegroundColor DarkGray
                $copySuccess = Copy-FileWithVerification -SourcePath $sourcePath -DestinationPath $destPath
                
                if ($copySuccess) {
                    Write-Host "      -> Verifying..." -ForegroundColor DarkGray
                    try {
                        Remove-Item -Path $sourcePath -Force -ErrorAction Stop
                        $stats.DeletedFiles++
                        Write-Host "      [OK] Migrated successfully" -ForegroundColor Green
                        Write-FileLog -Message "SUCCESS: Moved $sourcePath to $destPath ($($file.SizeMB) MB)" -Level 'SUCCESS' -LogPath $logFile
                    } catch {
                        Write-Host "      [WARN] Copied but file is locked (kept on C:)" -ForegroundColor Yellow
                        Write-FileLog -Message "WARNING: Copied but locked: $sourcePath" -Level 'WARNING' -LogPath $logFile
                    }
                    
                    $stats.CopiedFiles++
                    $stats.TotalBytesMoved += ($file.SizeMB * 1MB)
                } else {
                    Write-Host "      [ERROR] Verification failed!" -ForegroundColor Red
                    $stats.FailedFiles++
                    Write-FileLog -Message "ERROR: Hash mismatch for $sourcePath" -Level 'ERROR' -LogPath $logFile
                }
                
            } catch {
                $stats.FailedFiles++
                Write-Host "      [ERROR] Failed: $($_.Exception.Message)" -ForegroundColor Red
                Write-FileLog -Message "ERROR: $sourcePath - $($_.Exception.Message)" -Level 'ERROR' -LogPath $logFile
            }
        }
        Write-Host ""
    }
    
    Write-Host ""
    Write-Host ("=" * 80) -ForegroundColor Green
    Write-Host "  MIGRATION COMPLETE" -ForegroundColor Green
    Write-Host ("=" * 80) -ForegroundColor Green
    Write-Host ""
    Write-Host "  Total files found:     $($stats.TotalFiles)" -ForegroundColor White
    Write-Host "  Successfully copied:   $($stats.CopiedFiles)" -ForegroundColor Green
    Write-Host "  Deleted from C:        $($stats.DeletedFiles)" -ForegroundColor Green
    Write-Host "  Failed:                $($stats.FailedFiles)" -ForegroundColor Red
    Write-Host "  Total data moved:      $([math]::Round($stats.TotalBytesMoved / 1GB, 2)) GB" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Log file: $logFile" -ForegroundColor DarkGray
    Write-Host ""
}

# ============================================================================
# MAIN PROGRAM
# ============================================================================

Show-Header "LARGE USER FILES MANAGER"

Write-Host "  This tool helps you manage large files in C:\Users" -ForegroundColor White
Write-Host ""
Write-Host "  Files that WILL be scanned:" -ForegroundColor Green
Write-Host "    * Documents, Downloads, Videos, Pictures, Desktop" -ForegroundColor Gray
Write-Host "    * Teams meeting recordings" -ForegroundColor Gray
Write-Host "    * Large media files, ISOs, backups" -ForegroundColor Gray
Write-Host ""
Write-Host "  Files that will NOT be touched:" -ForegroundColor Yellow
Write-Host "    * AppData (program settings)" -ForegroundColor Gray
Write-Host "    * Cloud sync folders (OneDrive, Dropbox, etc.)" -ForegroundColor Gray
Write-Host "    * Development tools and caches" -ForegroundColor Gray
Write-Host ""

Show-Menu

Write-Host -NoNewline "  Your choice (1-3): " -ForegroundColor White
$choice = Read-Host

switch ($choice) {
    "1" {
        Show-Header "SCAN AND REPORT"
        $minSize = Get-MinimumSize
        $scanData = Invoke-ScanWorkflow -MinSize $minSize
        
        if ($scanData.TotalFiles -gt 0) {
            Write-Host "  Review the report: $reportFile" -ForegroundColor Cyan
            Write-Host ""
        }
    }
    
    "2" {
        Show-Header "SCAN AND MIGRATE"
        $minSize = Get-MinimumSize
        $scanData = Invoke-ScanWorkflow -MinSize $minSize
        
        if ($scanData.TotalFiles -gt 0) {
            Invoke-MigrationWorkflow -ScanData $scanData
        }
    }
    
    "3" {
        Write-Host ""
        Write-Host "  Goodbye!" -ForegroundColor Cyan
        Write-Host ""
        exit 0
    }
    
    default {
        Write-Host ""
        Write-Host "  Invalid choice. Exiting." -ForegroundColor Red
        Write-Host ""
        exit 1
    }
}

Write-Host ""
Write-Host "  Press any key to exit..." -ForegroundColor DarkGray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
