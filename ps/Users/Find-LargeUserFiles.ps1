<#
.SYNOPSIS
    Finds large files created by users (excludes system-generated files).

.DESCRIPTION
    Scans all user directories in C:\Users for files larger than a specified size.
    Excludes system folders like AppData, node_modules, etc.
    Generates a formatted report grouped by user with file paths and sizes.

.PARAMETER MinSizeMB
    Minimum file size in megabytes to include in report (default: 200MB)

.EXAMPLE
    .\Find-LargeUserFiles.ps1
    Scans for files larger than 200MB and generates report

.NOTES
    File Name  : Find-LargeUserFiles.ps1
    Author     : Hussain Shareef
    Created    : 2025-11-26
    
.OUTPUTS
    LargeUserFiles.txt - Formatted report saved next to script
#>

# Import shared utilities
Import-Module "$PSScriptRoot\UserFilesUtils.psm1" -Force

# ============================================================================
# CONFIGURATION
# ============================================================================

# Prompt user for minimum file size
$minSizeMB = Read-Host "Enter minimum file size in MB (default: 200)"
if ([string]::IsNullOrWhiteSpace($minSizeMB) -or $minSizeMB -notmatch '^\d+$') {
    $minSizeMB = 200
    Write-Host "Using default size: 200MB" -ForegroundColor Yellow
} else {
    $minSizeMB = [int]$minSizeMB
    Write-Host "Using size: ${minSizeMB}MB" -ForegroundColor Yellow
}
Write-Host ""

# Output file location
$outputFile = "$PSScriptRoot\LargeUserFiles.txt"

# ============================================================================
# SCAN AND REPORT
# ============================================================================

Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "LARGE USER FILES SCANNER" -ForegroundColor Cyan
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "Scanning C:\Users for files larger than ${minSizeMB}MB..." -ForegroundColor Yellow
Write-Host ""

$startTime = Get-Date

# Scan for large files
$scanData = Scan-LargeUserFiles -MinSizeMB $minSizeMB -Verbose

$elapsed = (Get-Date) - $startTime

Write-Host ""
Write-Host "=" * 80 -ForegroundColor Green
Write-Host "Scan complete! Found $($scanData.TotalFiles) large files in $($elapsed.ToString('mm\:ss'))" -ForegroundColor Green
Write-Host "=" * 80 -ForegroundColor Green
Write-Host "Generating report..." -ForegroundColor Yellow
Write-Host ""

# Generate report
New-LargeFilesReport -ScanData $scanData -MinSizeMB $minSizeMB -OutputPath $outputFile

# Display summary
Write-Host ""
Write-Host "=" * 80 -ForegroundColor Green
Write-Host "Report saved to: $outputFile" -ForegroundColor Green
Write-Host "=" * 80 -ForegroundColor Green
