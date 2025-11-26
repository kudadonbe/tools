<#
.SYNOPSIS
    Common utility functions for managing large user files.

.DESCRIPTION
    Shared functions used by all large file management scripts:
    - File scanning and filtering
    - Report generation
    - File operations (copy, verify, delete)
    - Logging utilities

.NOTES
    File Name  : UserFilesUtils.psm1
    Author     : Hussain Shareef
    Created    : 2025-11-26
#>

# ============================================================================
# CONFIGURATION
# ============================================================================

# System and program folders to exclude (protect all application data)
$script:ExcludeFolders = @(
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
# SCANNING FUNCTIONS
# ============================================================================

function Scan-LargeUserFiles {
    <#
    .SYNOPSIS
        Scans all user directories for large files.
    
    .PARAMETER MinSizeMB
        Minimum file size in megabytes to include in scan.
    
    .OUTPUTS
        Hashtable with Results (files by user) and TotalFiles count.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [int]$MinSizeMB
    )
    
    $results = @{}
    $totalFiles = 0
    
    $userFolders = Get-ChildItem -Path 'C:\Users' -Directory -ErrorAction SilentlyContinue | 
        Where-Object { $_.Name -notin @('Public', 'Default', 'Default User', 'All Users') }
    
    foreach ($userFolder in $userFolders) {
        Write-Verbose "Scanning: $($userFolder.Name)..."
        
        try {
            $files = Get-ChildItem -Path $userFolder.FullName -File -Recurse -Force -ErrorAction SilentlyContinue |
                Where-Object {
                    if ($_.Length -lt ($MinSizeMB * 1MB)) { return $false }
                    
                    $inExcludedFolder = $false
                    foreach ($exclude in $script:ExcludeFolders) {
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
            Write-Warning "Error scanning $($userFolder.Name): $($_.Exception.Message)"
        }
    }
    
    return @{
        Results = $results
        TotalFiles = $totalFiles
    }
}

# ============================================================================
# REPORT GENERATION
# ============================================================================

function New-LargeFilesReport {
    <#
    .SYNOPSIS
        Generates a formatted report from scan data.
    
    .PARAMETER ScanData
        Hashtable containing scan results from Scan-LargeUserFiles.
    
    .PARAMETER MinSizeMB
        Minimum size threshold used in the scan.
    
    .PARAMETER OutputPath
        Full path where the report should be saved.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$ScanData,
        
        [Parameter(Mandatory)]
        [int]$MinSizeMB,
        
        [Parameter(Mandatory)]
        [string]$OutputPath
    )
    
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
    
    $report | Out-File -FilePath $OutputPath -Encoding UTF8
}

# ============================================================================
# FILE OPERATIONS
# ============================================================================

function Get-FileHashQuick {
    <#
    .SYNOPSIS
        Calculate SHA256 hash of a file.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )
    
    try {
        return (Get-FileHash -Path $Path -Algorithm SHA256).Hash
    } catch {
        return $null
    }
}

function Copy-FileWithVerification {
    <#
    .SYNOPSIS
        Copies a file and verifies integrity using hash comparison.
    
    .PARAMETER SourcePath
        Source file path.
    
    .PARAMETER DestinationPath
        Destination file path.
    
    .OUTPUTS
        Boolean indicating success (hash verified).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$SourcePath,
        
        [Parameter(Mandatory)]
        [string]$DestinationPath
    )
    
    try {
        # Create destination directory if needed
        $destDir = Split-Path -Path $DestinationPath -Parent
        if (-not (Test-Path $destDir)) {
            New-Item -Path $destDir -ItemType Directory -Force | Out-Null
        }
        
        # Copy file
        Copy-Item -Path $SourcePath -Destination $DestinationPath -Force -ErrorAction Stop
        
        # Verify using hash
        $sourceHash = Get-FileHashQuick -Path $SourcePath
        $destHash = Get-FileHashQuick -Path $DestinationPath
        
        if ($sourceHash -and $destHash -and ($sourceHash -eq $destHash)) {
            return $true
        } else {
            # Clean up failed copy
            Remove-Item -Path $DestinationPath -Force -ErrorAction SilentlyContinue
            return $false
        }
        
    } catch {
        Write-Error "Copy failed: $($_.Exception.Message)"
        return $false
    }
}

# ============================================================================
# LOGGING
# ============================================================================

function Write-FileLog {
    <#
    .SYNOPSIS
        Writes a message to a log file.
    
    .PARAMETER Message
        Message to log.
    
    .PARAMETER Level
        Log level (INFO, WARNING, ERROR, SUCCESS).
    
    .PARAMETER LogPath
        Path to the log file.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        
        [Parameter()]
        [ValidateSet('INFO', 'WARNING', 'ERROR', 'SUCCESS')]
        [string]$Level = 'INFO',
        
        [Parameter(Mandatory)]
        [string]$LogPath
    )
    
    $logMessage = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [$Level] $Message"
    Add-Content -Path $LogPath -Value $logMessage
}

# ============================================================================
# EXPORTS
# ============================================================================

Export-ModuleMember -Function @(
    'Scan-LargeUserFiles',
    'New-LargeFilesReport',
    'Get-FileHashQuick',
    'Copy-FileWithVerification',
    'Write-FileLog'
)

Export-ModuleMember -Variable @(
    'ExcludeFolders'
)
