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

.SAMPLE OUTPUT
    ================================================================================
    LARGE FILES REPORT (Files > 200MB)
    Generated: 2025-11-26 14:30:15
    Total files found: 47
    ================================================================================

    Hussain Shareef (Users/hussain)
    --------------------------------------------------------------------------------
    ~/Videos/Recordings/Meeting_2024.mp4                                 | 245.67 MB
    ~/Documents/Projects/backup.zip                                       | 128.43 MB
    ~/Downloads/ubuntu-22.04.iso                                          | 3840.00 MB
    ~/Pictures/Photos/Wedding_Album.zip                                  | 89.21 MB

    Subtotal: 4 files, 4303.31 MB

    Admin (Users/admin)
    --------------------------------------------------------------------------------
    ~/Desktop/database_backup.sql                                         | 156.89 MB
    ~/Downloads/setup_installer.exe                                       | 45.23 MB

    Subtotal: 2 files, 202.12 MB
#>

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

# Output file location (saved next to this script)
$outputFile = "$PSScriptRoot\LargeUserFiles.txt"

# System folders to exclude (not user-created content)
$excludeFolders = @(
    'AppData',              # Application data
    'Application Data',     # Legacy app data
    '.nuget',              # NuGet packages
    '.vscode',             # VS Code settings
    '.android',            # Android SDK
    '.gradle',             # Gradle cache
    'node_modules',        # Node.js packages
    'OneDrive',            # Cloud synced (separate backup)
    'Saved Games',         # Game saves
    'Searches',            # Windows search
    'Links',               # Windows shortcuts
    'Contacts',            # Windows contacts
    'Favorites'            # Browser favorites
)

# ============================================================================
# INITIALIZATION
# ============================================================================

Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "LARGE USER FILES SCANNER" -ForegroundColor Cyan
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "Scanning C:\Users for files larger than ${minSizeMB}MB..." -ForegroundColor Yellow
Write-Host "Excluding system folders: $($excludeFolders -join ', ')" -ForegroundColor DarkGray
Write-Host ""

# Initialize variables
$results = @{}
$totalFiles = 0
$startTime = Get-Date

# ============================================================================
# SCAN USER DIRECTORIES
# ============================================================================

# Get all user folders (exclude system/default profiles)
$userFolders = Get-ChildItem -Path 'C:\Users' -Directory -ErrorAction SilentlyContinue | 
    Where-Object { $_.Name -notin @('Public', 'Default', 'Default User', 'All Users') }

# Loop through each user folder
foreach ($userFolder in $userFolders) {
    Write-Host "Scanning: $($userFolder.Name)..." -ForegroundColor Cyan
    
    $userFiles = @()
    
    try {
        # Get all files recursively and filter by size and excluded folders
        $files = Get-ChildItem -Path $userFolder.FullName -File -Recurse -Force -ErrorAction SilentlyContinue |
            Where-Object {
                # Filter 1: File must be larger than minimum size
                if ($_.Length -lt ($minSizeMB * 1MB)) {
                    return $false
                }
                
                # Filter 2: File must not be in excluded folders
                $inExcludedFolder = $false
                foreach ($exclude in $excludeFolders) {
                    if ($_.FullName -match "\\$exclude\\") {
                        $inExcludedFolder = $true
                        break
                    }
                }
                
                # Return true only if NOT in excluded folder
                return (-not $inExcludedFolder)
            }
        
        # Process each large file found
        foreach ($file in $files) {
            $totalFiles++
            
            # Create relative path from user folder (replace C:\Users\username with ~)
            $relativePath = $file.FullName.Replace($userFolder.FullName, "~").Replace('\', '/')
            
            # Create file object
            $userFiles += [PSCustomObject]@{
                Path = $relativePath
                SizeMB = [math]::Round($file.Length / 1MB, 2)
                FullPath = $file.FullName
            }
            
            # Show progress
            Write-Host "  Found: $relativePath ($([math]::Round($file.Length / 1MB, 2)) MB)" -ForegroundColor DarkGray
        }
        
        # Store results for this user if any files found
        if ($userFiles.Count -gt 0) {
            $results[$userFolder.Name] = $userFiles | Sort-Object -Property SizeMB -Descending
        }
        
    } catch {
        # Handle any errors during scan
        Write-Host "  Error scanning $($userFolder.Name): $($_.Exception.Message)" -ForegroundColor Red
    }
}

# ============================================================================
# GENERATE REPORT
# ============================================================================

$elapsed = (Get-Date) - $startTime
Write-Host ""
Write-Host "=" * 80 -ForegroundColor Green
Write-Host "Scan complete! Found $totalFiles large files in $($elapsed.ToString('mm\:ss'))" -ForegroundColor Green
Write-Host "=" * 80 -ForegroundColor Green
Write-Host "Generating report..." -ForegroundColor Yellow
Write-Host ""

# Build report content
$report = @()
$report += "=" * 80
$report += "LARGE FILES REPORT (Files > ${minSizeMB}MB)"
$report += "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$report += "Total files found: $totalFiles"
$report += "=" * 80
$report += ""

# Add each user's files to report
foreach ($user in $results.Keys | Sort-Object) {
    $userPath = "Users/$user"
    $report += ""
    $report += "$user ($userPath)"
    $report += "-" * 80
    
    # List all files for this user
    foreach ($file in $results[$user]) {
        $report += "$($file.Path.PadRight(70)) | $($file.SizeMB) MB"
    }
    
    # Calculate subtotal for this user
    $totalSize = ($results[$user] | Measure-Object -Property SizeMB -Sum).Sum
    $report += ""
    $report += "Subtotal: $($results[$user].Count) files, $([math]::Round($totalSize, 2)) MB"
    $report += ""
}

# ============================================================================
# SAVE AND DISPLAY RESULTS
# ============================================================================

# Save report to file
$report | Out-File -FilePath $outputFile -Encoding UTF8

# Display report in console
$report | Write-Host

# Show completion message
Write-Host ""
Write-Host "=" * 80 -ForegroundColor Green
Write-Host "Report saved to: $outputFile" -ForegroundColor Green
Write-Host "=" * 80 -ForegroundColor Green