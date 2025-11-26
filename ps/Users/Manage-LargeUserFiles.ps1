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

# ============================================================================
# CONFIGURATION
# ============================================================================

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$reportFile = "$PSScriptRoot\LargeUserFiles_$timestamp.txt"
$logFile = "$PSScriptRoot\MoveLog_$timestamp.txt"

# System and program folders to exclude
$excludeFolders = @(
    # Application data (critical - DO NOT MOVE)
    'AppData', 'Application Data', 'Local Settings',
    
    # Development tools
    '.nuget', '.vscode', '.android', '.gradle', '.docker', '.m2', '.npm', 
    '.cargo', 'node_modules', 'venv', 'env', '.virtualenv',
    
    # Cloud sync folders
    'OneDrive', 'Dropbox', 'Google Drive', 'iCloudDrive',
    
    # Windows system folders
    'Saved Games', 'Searches', 'Links', 'Contacts', 'Favorites', 
    'Cookies', 'NetHood', 'PrintHood', 'Recent', 'SendTo', 
    'Start Menu', 'Templates',
    
    # Browser profiles
    '.mozilla', '.chrome', 'Chrome', 'Firefox', 'Edge',
    
    # Security sensitive
    '.ssh', '.gnupg', '.aws', '.kube',
    
    # IDE settings
    'workspace', '.idea', '.eclipse',
    
    # Game launchers
    'Steam', 'Epic Games', 'Battle.net',
    
    # System cache
    'Temp', 'tmp', 'cache', 'Cache'
)

# ============================================================================
# FUNCTIONS
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

function Scan-LargeFiles {
    param([int]$MinSizeMB)
    
    Write-Host ""
    Write-Host "  Scanning C:\Users for files larger than ${MinSizeMB}MB..." -ForegroundColor Yellow
    Write-Host "  This may take a few minutes..." -ForegroundColor DarkGray
    Write-Host ""
    
    $results = @{}
    $totalFiles = 0
    
    $userFolders = Get-ChildItem -Path 'C:\Users' -Directory -ErrorAction SilentlyContinue | 
        Where-Object { $_.Name -notin @('Public', 'Default', 'Default User', 'All Users') }
    
    foreach ($userFolder in $userFolders) {
        Write-Host "  Scanning: $($userFolder.Name)..." -ForegroundColor Cyan
        
        try {
            $files = Get-ChildItem -Path $userFolder.FullName -File -Recurse -Force -ErrorAction SilentlyContinue |
                Where-Object {
                    if ($_.Length -lt ($MinSizeMB * 1MB)) { return $false }
                    
                    $inExcludedFolder = $false
                    foreach ($exclude in $excludeFolders) {
                        if ($_.FullName -match "\\$exclude\\") {
                            $inExcludedFolder = $true
                            break
                        }
                    }
                    return (-not $inExcludedFolder)
                }
            
            $userFiles = @()
            foreach ($file in $files) {
                $totalFiles++
                $relativePath = $file.FullName.Replace($userFolder.FullName, "~").Replace('\', '/')
                
                $userFiles += [PSCustomObject]@{
                    Path = $relativePath
                    SizeMB = [math]::Round($file.Length / 1MB, 2)
                    FullPath = $file.FullName
                }
            }
            
            if ($userFiles.Count -gt 0) {
                $results[$userFolder.Name] = $userFiles | Sort-Object -Property SizeMB -Descending
            }
            
        } catch {
            Write-Host "  Error scanning $($userFolder.Name): $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    return @{
        Results = $results
        TotalFiles = $totalFiles
    }
}

function Generate-Report {
    param($ScanData, [int]$MinSizeMB)
    
    $report = @()
    $report += "=" * 80
    $report += "LARGE FILES REPORT (Files > ${MinSizeMB}MB)"
    $report += "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    $report += "Total files found: $($ScanData.TotalFiles)"
    $report += "=" * 80
    $report += ""
    
    foreach ($user in $ScanData.Results.Keys | Sort-Object) {
        $report += ""
        $report += "$user (Users/$user)"
        $report += "-" * 80
        
        foreach ($file in $ScanData.Results[$user]) {
            $report += "$($file.Path.PadRight(70)) | $($file.SizeMB) MB"
        }
        
        $totalSize = ($ScanData.Results[$user] | Measure-Object -Property SizeMB -Sum).Sum
        $report += ""
        $report += "Subtotal: $($ScanData.Results[$user].Count) files, $([math]::Round($totalSize, 2)) MB"
        $report += ""
    }
    
    $report | Out-File -FilePath $reportFile -Encoding UTF8
    
    Write-Host ""
    Write-Host ("=" * 80) -ForegroundColor Green
    Write-Host "  Report saved to: $reportFile" -ForegroundColor Green
    Write-Host ("=" * 80) -ForegroundColor Green
    Write-Host ""
}

function Get-FileHashQuick {
    param([string]$Path)
    try {
        return (Get-FileHash -Path $Path -Algorithm SHA256).Hash
    } catch {
        return $null
    }
}

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $logMessage = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [$Level] $Message"
    Add-Content -Path $logFile -Value $logMessage
}

function Move-FilesToD {
    param($ScanData)
    
    Write-Host ""
    Write-Host ("=" * 80) -ForegroundColor Yellow
    Write-Host "  MIGRATION TO D: DRIVE" -ForegroundColor Yellow
    Write-Host ("=" * 80) -ForegroundColor Yellow
    Write-Host ""
    
    # Check if D: exists
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
    
    Write-Log "Starting migration to D: drive"
    
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
            $destDir = Split-Path -Path $destPath -Parent
            
            Write-Host "    Processing: $($file.Path) ($($file.SizeMB) MB)" -ForegroundColor Gray
            
            try {
                # Create destination directory
                if (-not (Test-Path $destDir)) {
                    New-Item -Path $destDir -ItemType Directory -Force | Out-Null
                }
                
                # Copy file
                Write-Host "      → Copying..." -ForegroundColor DarkGray
                Copy-Item -Path $sourcePath -Destination $destPath -Force -ErrorAction Stop
                
                # Verify
                Write-Host "      → Verifying..." -ForegroundColor DarkGray
                $sourceHash = Get-FileHashQuick -Path $sourcePath
                $destHash = Get-FileHashQuick -Path $destPath
                
                if ($sourceHash -and $destHash -and ($sourceHash -eq $destHash)) {
                    # Try to delete
                    try {
                        Remove-Item -Path $sourcePath -Force -ErrorAction Stop
                        $stats.DeletedFiles++
                        Write-Host "      ✓ Migrated successfully" -ForegroundColor Green
                        Write-Log "SUCCESS: Moved $sourcePath → $destPath ($($file.SizeMB) MB)" "SUCCESS"
                    } catch {
                        Write-Host "      ⚠ Copied but file is locked (kept on C:)" -ForegroundColor Yellow
                        Write-Log "WARNING: Copied but locked: $sourcePath" "WARNING"
                    }
                    
                    $stats.CopiedFiles++
                    $stats.TotalBytesMoved += ($file.SizeMB * 1MB)
                } else {
                    Write-Host "      ✗ Verification failed!" -ForegroundColor Red
                    Remove-Item -Path $destPath -Force -ErrorAction SilentlyContinue
                    $stats.FailedFiles++
                    Write-Log "ERROR: Hash mismatch for $sourcePath" "ERROR"
                }
                
            } catch {
                $stats.FailedFiles++
                Write-Host "      ✗ Failed: $($_.Exception.Message)" -ForegroundColor Red
                Write-Log "ERROR: $sourcePath - $($_.Exception.Message)" "ERROR"
            }
        }
        Write-Host ""
    }
    
    # Show summary
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
Write-Host "    • Documents, Downloads, Videos, Pictures, Desktop" -ForegroundColor Gray
Write-Host "    • Teams meeting recordings" -ForegroundColor Gray
Write-Host "    • Large media files, ISOs, backups" -ForegroundColor Gray
Write-Host ""
Write-Host "  Files that will NOT be touched:" -ForegroundColor Yellow
Write-Host "    • AppData (program settings)" -ForegroundColor Gray
Write-Host "    • Cloud sync folders (OneDrive, Dropbox, etc.)" -ForegroundColor Gray
Write-Host "    • Development tools and caches" -ForegroundColor Gray
Write-Host ""

Show-Menu

Write-Host -NoNewline "  Your choice (1-3): " -ForegroundColor White
$choice = Read-Host

switch ($choice) {
    "1" {
        Show-Header "SCAN AND REPORT"
        $minSize = Get-MinimumSize
        $scanData = Scan-LargeFiles -MinSizeMB $minSize
        
        if ($scanData.TotalFiles -eq 0) {
            Write-Host ""
            Write-Host "  No files found larger than ${minSize}MB" -ForegroundColor Yellow
            Write-Host ""
        } else {
            Generate-Report -ScanData $scanData -MinSizeMB $minSize
            
            Write-Host "  Found $($scanData.TotalFiles) large files" -ForegroundColor Green
            Write-Host "  Review the report: $reportFile" -ForegroundColor Cyan
            Write-Host ""
        }
    }
    
    "2" {
        Show-Header "SCAN AND MIGRATE"
        $minSize = Get-MinimumSize
        $scanData = Scan-LargeFiles -MinSizeMB $minSize
        
        if ($scanData.TotalFiles -eq 0) {
            Write-Host ""
            Write-Host "  No files found larger than ${minSize}MB" -ForegroundColor Yellow
            Write-Host ""
        } else {
            Generate-Report -ScanData $scanData -MinSizeMB $minSize
            Move-FilesToD -ScanData $scanData
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
