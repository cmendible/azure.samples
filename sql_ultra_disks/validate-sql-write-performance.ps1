<#
.SYNOPSIS
    Validates SQL Server on Windows configuration that impacts WRITE performance.

.DESCRIPTION
    This script checks SQL Server and Windows configurations from inside the VM
    that directly impact write performance for SQL Server with Ultra Disk.
    Must be run locally on the SQL Server with Administrator privileges.

.PARAMETER SQLInstance
    SQL Server instance name (default: localhost)

.PARAMETER Detailed
    Show detailed information about each check

.EXAMPLE
    .\validate-sql-write-performance.ps1

.EXAMPLE
    .\validate-sql-write-performance.ps1 -SQLInstance "SQLSERVER01\INSTANCE01" -Detailed

.NOTES
    Author: Azure Quick Review (azqr)
    Version: 1.0.0
    Requires: Administrator privileges, SQL Server PowerShell module
    Run from the SQL Server VM
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$SQLInstance = "localhost",

    [Parameter(Mandatory = $false)]
    [switch]$Detailed
)

#Requires -RunAsAdministrator

# Initialize counters
$script:passCount = 0
$script:failCount = 0
$script:warnCount = 0

# Color functions (define early)
function Write-Success {
    param([string]$Message)
    Write-Host "✓ PASS: $Message" -ForegroundColor Green
    $script:passCount++
}

function Write-Failure {
    param([string]$Message)
    Write-Host "✗ FAIL: $Message" -ForegroundColor Red
    $script:failCount++
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠ WARN: $Message" -ForegroundColor Yellow
    $script:warnCount++
}

function Write-Info {
    param([string]$Message)
    Write-Host "ℹ INFO: $Message" -ForegroundColor Cyan
}

function Write-SectionHeader {
    param([string]$Title)
    Write-Host "`n========================================" -ForegroundColor Magenta
    Write-Host " $Title" -ForegroundColor Magenta
    Write-Host "========================================" -ForegroundColor Magenta
}

# Check for SQL Server cmdlets (either SqlServer or SQLPS module)
$sqlCmdletAvailable = Get-Command -Name Invoke-Sqlcmd -ErrorAction SilentlyContinue

if (-not $sqlCmdletAvailable) {
    # Try to import SqlServer module
    try {
        Import-Module SqlServer -ErrorAction Stop
        Write-Info "Loaded SqlServer PowerShell module"
    } catch {
        # Try SQLPS as fallback (older SQL Server versions)
        try {
            Import-Module SQLPS -DisableNameChecking -ErrorAction Stop
            Write-Info "Loaded SQLPS PowerShell module"
        } catch {
            Write-Host "ERROR: SQL Server PowerShell module not found." -ForegroundColor Red
            Write-Host "Install with: Install-Module -Name SqlServer -AllowClobber" -ForegroundColor Red
            Write-Host "Or ensure SQL Server Management Tools are installed (includes SQLPS module)" -ForegroundColor Red
            exit 1
        }
    }
} else {
    # Cmdlets already available (SQLPS or SqlServer module likely auto-loaded)
    Write-Info "SQL Server cmdlets already available"
}

Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  SQL Server Write Performance Validation Tool             ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

# Test SQL Server connectivity
Write-Info "Testing SQL Server connectivity: $SQLInstance"
try {
    $testQuery = Invoke-Sqlcmd -ServerInstance $SQLInstance -Query "SELECT @@VERSION AS Version" -ErrorAction Stop
    Write-Success "Connected to SQL Server: $SQLInstance"
    if ($Detailed) {
        Write-Info "SQL Version: $($testQuery.Version.Split("`n")[0])"
    }
} catch {
    Write-Host "ERROR: Cannot connect to SQL Server instance: $SQLInstance" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

# ===========================================
# Section 1: STORAGE & DISK CONFIGURATION
# ===========================================
Write-SectionHeader "1. STORAGE & DISK CONFIGURATION (WRITE IMPACT)"

# Get all SQL Server data/log volumes (including system databases)
$sqlPaths = Invoke-Sqlcmd -ServerInstance $SQLInstance -Query @"
SELECT DISTINCT 
    LEFT(physical_name, 2) AS DriveLetter,
    type_desc AS FileType
FROM sys.master_files
WHERE database_id >= 2  -- Include TempDB and user databases
"@

$volumes = Get-Volume | Where-Object { $_.DriveType -eq 'Fixed' -and $_.DriveLetter }

Write-Host "`n[Check 1.1] Allocation Unit Size (Critical for Write Performance)"
$sqlVolumesChecked = 0
foreach ($vol in $volumes) {
    $driveLetter = $vol.DriveLetter + ":"
    $isSqlVolume = $sqlPaths | Where-Object { $_.DriveLetter -eq $driveLetter }
    
    if ($isSqlVolume) {
        $sqlVolumesChecked++
        $allocationUnitSize = $vol.AllocationUnitSize
        
        if ($Detailed) {
            Write-Info "Drive $driveLetter - Allocation Unit Size: $allocationUnitSize bytes"
        }
        
        if ($allocationUnitSize -eq 65536) {
            Write-Success "Drive $driveLetter has optimal allocation unit size: 64KB (65536 bytes)"
        } else {
            Write-Failure "Drive $driveLetter has suboptimal allocation unit size: $allocationUnitSize bytes (should be 64KB/65536)"
            Write-Info "  Impact: Small allocation units cause excessive I/O operations for large writes"
            Write-Info "  Action: Requires reformatting - backup data, reformat with 64KB, restore"
        }
    }
}
if ($sqlVolumesChecked -eq 0) {
    Write-Warning "No SQL Server volumes found to check allocation unit size"
}

Write-Host "`n[Check 1.2] NTFS Compression (Must be Disabled)"
$sqlVolumesChecked = 0
foreach ($vol in $volumes) {
    $driveLetter = $vol.DriveLetter + ":"
    $isSqlVolume = $sqlPaths | Where-Object { $_.DriveLetter -eq $driveLetter }
    
    if ($isSqlVolume) {
        $sqlVolumesChecked++
        $volume = Get-WmiObject -Class Win32_Volume | Where-Object { $_.DriveLetter -eq $driveLetter }
        $compressed = $volume.Compressed
        
        if ($Detailed) {
            Write-Info "Drive $driveLetter - Compression: $compressed"
        }
        
        if (-not $compressed) {
            Write-Success "Drive $driveLetter has compression disabled"
        } else {
            Write-Failure "Drive $driveLetter has compression enabled"
            Write-Info "  Impact: Compression adds CPU overhead and reduces write throughput by 30-50%"
            Write-Info "  Action: Disable with: compact /u $driveLetter\ /s /i"
        }
    }
}
if ($sqlVolumesChecked -eq 0) {
    Write-Warning "No SQL Server volumes found to check NTFS compression"
}

Write-Host "`n[Check 1.3] File Indexing (Should be Disabled)"
$sqlVolumesChecked = 0
foreach ($vol in $volumes) {
    $driveLetter = $vol.DriveLetter + ":"
    $isSqlVolume = $sqlPaths | Where-Object { $_.DriveLetter -eq $driveLetter }
    
    if ($isSqlVolume) {
        $sqlVolumesChecked++
        $volume = Get-WmiObject -Class Win32_Volume | Where-Object { $_.DriveLetter -eq $driveLetter }
        $indexing = $volume.IndexingEnabled
        
        if ($Detailed) {
            Write-Info "Drive $driveLetter - Indexing: $indexing"
        }
        
        if (-not $indexing) {
            Write-Success "Drive $driveLetter has file indexing disabled"
        } else {
            Write-Failure "Drive $driveLetter has file indexing enabled"
            Write-Info "  Impact: Indexing service causes write I/O contention"
            Write-Info "  Action: Disable indexing in volume properties"
        }
    }
}
if ($sqlVolumesChecked -eq 0) {
    Write-Warning "No SQL Server volumes found to check file indexing"
}

Write-Host "`n[Check 1.4] Write-Cache Buffer Flushing (Disable for Ultra Disks)"
$disks = Get-PhysicalDisk | Where-Object { $_.BusType -ne 'Virtual' }
$disksChecked = 0
foreach ($disk in $disks) {
    $diskNumber = $disk.DeviceId
    $cacheEnabled = (Get-Disk -Number $diskNumber).WriteCacheEnabled
    
    # Check all SSDs (Azure Ultra/Premium disks are SSDs)
    if ($disk.MediaType -eq 'SSD') {
        $disksChecked++
        
        if ($Detailed) {
            Write-Info "Disk $diskNumber ($($disk.FriendlyName)) - Write Cache Enabled: $cacheEnabled, Media: $($disk.MediaType)"
        }
        
        # For Premium/Ultra SSDs, write cache should be evaluated
        if (-not $cacheEnabled) {
            Write-Success "SSD Disk $diskNumber ($($disk.FriendlyName)) has write cache buffer flushing disabled"
        } else {
            Write-Info "SSD Disk $diskNumber ($($disk.FriendlyName)) has write cache enabled: $cacheEnabled"
            Write-Info "  Note: For Azure Ultra Disks, consider disabling for lower latency"
            Write-Info "  Action: Set-Disk -Number $diskNumber -WriteCacheEnabled `$false"
        }
    }
}
if ($disksChecked -eq 0) {
    Write-Warning "No SSD disks found to check write cache settings"
}

Write-Host "`n[Check 1.5] Physical Disk Sector Size (4K Native Optimal)"
$disks = Get-PhysicalDisk | Where-Object { $_.BusType -ne 'Virtual' }
$disksChecked = 0
foreach ($disk in $disks) {
    $diskNumber = $disk.DeviceId
    $diskInfo = Get-Disk -Number $diskNumber
    $physicalSectorSize = $diskInfo.PhysicalSectorSize
    $logicalSectorSize = $diskInfo.LogicalSectorSize
    
    # Check all SSDs
    if ($disk.MediaType -eq 'SSD') {
        $disksChecked++
        
        if ($Detailed) {
            Write-Info "Disk $diskNumber ($($disk.FriendlyName)) - Physical: $physicalSectorSize bytes, Logical: $logicalSectorSize bytes"
        }
        
        # 4K native (4096 physical / 4096 logical) - optimal
        if ($physicalSectorSize -eq 4096 -and $logicalSectorSize -eq 4096) {
            Write-Success "SSD Disk $diskNumber has optimal 4K native sector size (4096/4096)"
        }
        # 4K native with 512 logical (common, acceptable)
        elseif ($physicalSectorSize -eq 4096 -and $logicalSectorSize -eq 512) {
            Write-Success "SSD Disk $diskNumber has 4K physical with 512 logical sectors (acceptable)"
            if ($Detailed) {
                Write-Info "  Note: This is common for Azure disks, minimal performance impact"
            }
        }
        # 512e emulation (512 logical on 4K physical) - warning
        elseif ($physicalSectorSize -eq 4096 -and $logicalSectorSize -ne 4096 -and $logicalSectorSize -ne 512) {
            Write-Warning "SSD Disk $diskNumber may be using 512e emulation: Physical=$physicalSectorSize, Logical=$logicalSectorSize"
            Write-Info "  Impact: Potential write amplification on misaligned writes"
        }
        # Old 512 byte sectors - warning
        elseif ($physicalSectorSize -eq 512) {
            Write-Warning "SSD Disk $diskNumber uses legacy 512-byte sectors (Physical=$physicalSectorSize)"
            Write-Info "  Note: Modern Ultra Disks use 4K sectors for better performance"
        }
        # Display info for any other configuration
        else {
            Write-Info "SSD Disk $diskNumber sector size: Physical=$physicalSectorSize, Logical=$logicalSectorSize"
        }
    }
}
if ($disksChecked -eq 0) {
    Write-Warning "No SSD disks found to check sector size"
}

# ===========================================
# Section 2: TEMPDB CONFIGURATION
# ===========================================
Write-SectionHeader "2. TEMPDB CONFIGURATION (WRITE INTENSIVE)"

Write-Host "`n[Check 2.1] TempDB Location (Should be on Local SSD or Ultra Disk)"
$tempdbFiles = Invoke-Sqlcmd -ServerInstance $SQLInstance -Query @"
SELECT 
    name,
    physical_name,
    size * 8 / 1024 AS SizeMB,
    type_desc
FROM sys.master_files
WHERE database_id = 2
"@

# Get mapping of drive letters to disk types
$partitions = Get-Partition | Where-Object { $_.DriveLetter }
$diskMap = @{}
foreach ($partition in $partitions) {
    $disk = Get-PhysicalDisk | Where-Object { $_.DeviceId -eq (Get-Disk -Number $partition.DiskNumber).Number }
    if ($disk) {
        $diskMap["$($partition.DriveLetter):"] = @{
            MediaType = $disk.MediaType
            BusType = $disk.BusType
        }
    }
}

foreach ($file in $tempdbFiles) {
    $filePath = $file.physical_name
    $driveLetter = $filePath.Substring(0, 2)
    
    if ($Detailed) {
        Write-Info "TempDB $($file.type_desc): $filePath ($($file.SizeMB) MB)"
    }
    
    # Check if on D: (local ephemeral SSD) - optimal
    if ($driveLetter -eq 'D:') {
        Write-Success "TempDB file on local ephemeral SSD (D:): $($file.name)"
    }
    # Check if on Ultra/Premium SSD (acceptable)
    elseif ($diskMap.ContainsKey($driveLetter) -and $diskMap[$driveLetter].MediaType -eq 'SSD') {
        Write-Success "TempDB file on SSD storage: $($file.name) on $driveLetter"
        if ($Detailed) {
            Write-Info "  Note: D: drive (local SSD) is optimal, but premium SSD is acceptable"
        }
    }
    # Not on SSD - failure
    else {
        Write-Failure "TempDB file NOT on SSD storage: $($file.name) is on $driveLetter"
        Write-Info "  Impact: Significantly slower write performance, increased latency"
        Write-Info "  Action: Move TempDB to D: drive or Ultra/Premium SSD for optimal performance"
    }
}

Write-Host "`n[Check 2.2] TempDB File Count (Should match CPU count)"
$cpuCount = (Get-WmiObject Win32_Processor | Measure-Object -Property NumberOfLogicalProcessors -Sum).Sum
$tempdbDataFiles = ($tempdbFiles | Where-Object { $_.type_desc -eq 'ROWS' }).Count
$recommendedFiles = if ($cpuCount -lt 8) { $cpuCount } else { 8 }

if ($Detailed) {
    Write-Info "Logical CPUs: $cpuCount, TempDB Data Files: $tempdbDataFiles, Recommended: $recommendedFiles"
}

if ($tempdbDataFiles -eq $recommendedFiles) {
    Write-Success "TempDB has optimal file count: $tempdbDataFiles files"
} elseif ($tempdbDataFiles -lt $recommendedFiles) {
    Write-Warning "TempDB has fewer files than recommended: $tempdbDataFiles (recommended: $recommendedFiles)"
    Write-Info "  Impact: Allocation contention, reduced write throughput"
} else {
    Write-Warning "TempDB has more files than needed: $tempdbDataFiles (recommended: $recommendedFiles)"
}

Write-Host "`n[Check 2.3] TempDB Equal File Sizing"
$tempdbDataFileSizes = $tempdbFiles | Where-Object { $_.type_desc -eq 'ROWS' } | Select-Object -ExpandProperty SizeMB
$allEqual = ($tempdbDataFileSizes | Select-Object -Unique).Count -eq 1

if ($allEqual) {
    Write-Success "All TempDB data files are equal size: $($tempdbDataFileSizes[0]) MB"
} else {
    Write-Failure "TempDB data files have unequal sizes: $($tempdbDataFileSizes -join ', ') MB"
    Write-Info "  Impact: Proportional fill algorithm causes uneven distribution"
    Write-Info "  Action: Resize all files to same size"
}

# ===========================================
# Section 3: DATA & LOG FILE CONFIGURATION
# ===========================================
Write-SectionHeader "3. DATA & LOG FILE CONFIGURATION"

Write-Host "`n[Check 3.1] Data and Log File Separation"
$userDatabases = Invoke-Sqlcmd -ServerInstance $SQLInstance -Query @"
SELECT 
    d.name AS DatabaseName,
    f.physical_name,
    f.type_desc,
    LEFT(f.physical_name, 3) AS DriveLetter
FROM sys.databases d
INNER JOIN sys.master_files f ON d.database_id = f.database_id
WHERE d.database_id > 4
ORDER BY d.name, f.type_desc
"@

$dbGroups = $userDatabases | Group-Object DatabaseName

foreach ($db in $dbGroups) {
    $dataFiles = $db.Group | Where-Object { $_.type_desc -eq 'ROWS' }
    $logFiles = $db.Group | Where-Object { $_.type_desc -eq 'LOG' }
    
    $dataDrives = $dataFiles.DriveLetter | Select-Object -Unique
    $logDrives = $logFiles.DriveLetter | Select-Object -Unique
    
    if ($Detailed) {
        Write-Info "Database: $($db.Name) - Data: $($dataDrives -join ','), Log: $($logDrives -join ',')"
    }
    
    if ($dataDrives -ne $logDrives) {
        Write-Success "Database '$($db.Name)' has data and log files separated"
    } else {
        Write-Failure "Database '$($db.Name)' has data and log files on same drive: $dataDrives"
        Write-Info "  Impact: Write contention between data and log operations"
        Write-Info "  Action: Move log files to separate drive/volume"
    }
}

Write-Host "`n[Check 3.2] Autogrowth Settings (Should use Fixed Size)"
$filesWithPercentGrowth = Invoke-Sqlcmd -ServerInstance $SQLInstance -Query @"
SELECT 
    d.name AS DatabaseName,
    f.name AS FileName,
    f.type_desc,
    f.growth,
    f.is_percent_growth
FROM sys.databases d
INNER JOIN sys.master_files f ON d.database_id = f.database_id
WHERE d.database_id > 4 AND f.is_percent_growth = 1
"@

if ($filesWithPercentGrowth) {
    foreach ($file in $filesWithPercentGrowth) {
        Write-Failure "Database '$($file.DatabaseName)' file '$($file.FileName)' uses percentage growth: $($file.growth)%"
        Write-Info "  Impact: Unpredictable growth, can cause write stalls"
    }
} else {
    Write-Success "All database files use fixed-size autogrowth"
}

# ===========================================
# Section 4: SQL SERVER MEMORY & IFI
# ===========================================
Write-SectionHeader "4. SQL SERVER MEMORY & INSTANT FILE INITIALIZATION"

Write-Host "`n[Check 4.1] Max Server Memory Configuration"
$memConfig = Invoke-Sqlcmd -ServerInstance $SQLInstance -Query @"
SELECT 
    name,
    value_in_use
FROM sys.configurations
WHERE name IN ('max server memory (MB)', 'min server memory (MB)')
"@

$totalRAM = [Math]::Round((Get-WmiObject Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
$maxMemConfig = ($memConfig | Where-Object { $_.name -eq 'max server memory (MB)' }).value_in_use
$maxMemGB = [Math]::Round($maxMemConfig / 1024, 2)
$recommendedMax = $totalRAM - [Math]::Max(4, [Math]::Ceiling($totalRAM * 0.1))

if ($Detailed) {
    Write-Info "Total RAM: $totalRAM GB, Max Server Memory: $maxMemGB GB, Recommended: $recommendedMax GB"
}

if ($maxMemConfig -ne 2147483647) {
    if ($maxMemGB -le $recommendedMax -and $maxMemGB -ge ($recommendedMax - 4)) {
        Write-Success "Max Server Memory is configured appropriately: $maxMemGB GB"
    } else {
        Write-Warning "Max Server Memory may not be optimal: $maxMemGB GB (recommended: ~$recommendedMax GB)"
    }
} else {
    Write-Failure "Max Server Memory is set to default (unlimited): $maxMemConfig MB"
    Write-Info "  Impact: Can cause OS memory pressure and paging to disk"
    Write-Info "  Action: Configure to leave 4-8GB for OS"
}

Write-Host "`n[Check 4.2] Lock Pages in Memory"
$lockPages = Invoke-Sqlcmd -ServerInstance $SQLInstance -Query "SELECT sql_memory_model_desc FROM sys.dm_os_sys_info"

if ($lockPages.sql_memory_model_desc -eq 'LOCK_PAGES') {
    Write-Success "Lock Pages in Memory is enabled"
} else {
    Write-Failure "Lock Pages in Memory is NOT enabled: $($lockPages.sql_memory_model_desc)"
    Write-Info "  Impact: Memory can be paged to disk, causing write performance degradation"
    Write-Info "  Action: Grant 'Lock Pages in Memory' to SQL Server service account"
}

Write-Host "`n[Check 4.3] Instant File Initialization (IFI)"
try {
    $ifiCheck = Invoke-Sqlcmd -ServerInstance $SQLInstance -Query @"
SELECT 
    instant_file_initialization_enabled
FROM sys.dm_server_services
WHERE servicename LIKE 'SQL Server%'
"@

    if ($ifiCheck.instant_file_initialization_enabled -eq 1) {
        Write-Success "Instant File Initialization (IFI) is enabled"
    } else {
        Write-Failure "Instant File Initialization (IFI) is NOT enabled"
        Write-Info "  Impact: Data file growth causes zero-initialization, write stalls"
        Write-Info "  Action: Grant 'Perform Volume Maintenance Tasks' to SQL service account"
    }
} catch {
    Write-Warning "Could not check IFI status (may require SQL Server 2016+)"
}

# ===========================================
# Section 5: TRANSACTION LOG & VLF
# ===========================================
Write-SectionHeader "5. TRANSACTION LOG CONFIGURATION"

Write-Host "`n[Check 5.1] Virtual Log File (VLF) Count"
$databases = Invoke-Sqlcmd -ServerInstance $SQLInstance -Query "SELECT name FROM sys.databases WHERE database_id > 4"

foreach ($db in $databases) {
    try {
        $vlfCount = Invoke-Sqlcmd -ServerInstance $SQLInstance -Database $db.name -Query "DBCC LOGINFO" -ErrorAction Stop
        $vlfCountValue = $vlfCount.Count
        
        if ($Detailed) {
            Write-Info "Database '$($db.name)' - VLF Count: $vlfCountValue"
        }
        
        if ($vlfCountValue -le 50) {
            Write-Success "Database '$($db.name)' has optimal VLF count: $vlfCountValue"
        } elseif ($vlfCountValue -le 100) {
            Write-Warning "Database '$($db.name)' has elevated VLF count: $vlfCountValue (optimal: <50)"
        } else {
            Write-Failure "Database '$($db.name)' has excessive VLF count: $vlfCountValue (optimal: <50)"
            Write-Info "  Impact: Log write performance degradation, slower backups/restores"
            Write-Info "  Action: Shrink and regrow log file with appropriate size"
        }
    } catch {
        Write-Warning "Could not check VLF count for database '$($db.name)'"
    }
}

# ===========================================
# Section 6: WINDOWS CONFIGURATION
# ===========================================
Write-SectionHeader "6. WINDOWS CONFIGURATION"

Write-Host "`n[Check 6.1] Power Plan Configuration"
$powerPlan = powercfg /getactivescheme
if ($powerPlan -like "*High performance*") {
    Write-Success "Power plan is set to High Performance"
} else {
    Write-Failure "Power plan is NOT set to High Performance: $powerPlan"
    Write-Info "  Impact: CPU throttling can reduce write throughput"
    Write-Info "  Action: Set to High Performance plan"
}

Write-Host "`n[Check 6.2] Page File Configuration"
$pageFile = Get-WmiObject -Class Win32_PageFileSetting
if ($pageFile) {
    $pageFileDrive = $pageFile.Name.Substring(0, 2)
    $pageFileSize = if ($pageFile.InitialSize -eq 0) { "System Managed" } else { "$($pageFile.InitialSize) MB" }
    
    if ($Detailed) {
        Write-Info "Page File: $($pageFile.Name), Size: $pageFileSize"
    }
    
    if ($pageFileDrive -ne 'D:') {
        Write-Success "Page file is not on local SSD (D:): $pageFileDrive"
    } else {
        Write-Warning "Page file is on ephemeral D: drive (may be lost on reboot)"
    }
} else {
    Write-Info "Page file is system-managed (no custom configuration)"
}

# ===========================================
# Section 7: ANTI-VIRUS EXCLUSIONS
# ===========================================
Write-SectionHeader "7. ANTI-VIRUS EXCLUSIONS"

Write-Host "`n[Check 7.1] Windows Defender Exclusions (if enabled)"
try {
    $defenderPrefs = Get-MpPreference -ErrorAction SilentlyContinue
    if ($defenderPrefs) {
        $exclusions = $defenderPrefs.ExclusionPath
        $sqlPaths = Invoke-Sqlcmd -ServerInstance $SQLInstance -Query @"
SELECT DISTINCT 
    LEFT(physical_name, CHARINDEX('\', physical_name, 4)) AS FolderPath
FROM sys.master_files
"@
        
        $allExcluded = $true
        foreach ($path in $sqlPaths.FolderPath) {
            $isExcluded = $exclusions -contains $path
            if (-not $isExcluded) {
                $allExcluded = $false
                if ($Detailed) {
                    Write-Warning "SQL path not excluded from Defender: $path"
                }
            }
        }
        
        if ($allExcluded) {
            Write-Success "All SQL Server paths are excluded from Windows Defender"
        } else {
            Write-Failure "Some SQL Server paths are NOT excluded from Windows Defender"
            Write-Info "  Impact: Real-time scanning causes write I/O contention"
            Write-Info "  Action: Add SQL data/log paths to exclusion list"
        }
    } else {
        Write-Info "Windows Defender not active or accessible"
    }
} catch {
    Write-Info "Could not check Windows Defender configuration"
}

# ===========================================
# SUMMARY
# ===========================================
Write-SectionHeader "VALIDATION SUMMARY"

$totalChecks = $script:passCount + $script:failCount + $script:warnCount
$cpuCoresForDisplay = (Get-WmiObject Win32_Processor | Measure-Object -Property NumberOfLogicalProcessors -Sum).Sum

Write-Host "`nSQL Server Instance: $SQLInstance" -ForegroundColor White
Write-Host "Total RAM: $totalRAM GB" -ForegroundColor White
Write-Host "CPU Cores: $cpuCoresForDisplay" -ForegroundColor White

Write-Host "`n┌─────────────────────────────────────┐" -ForegroundColor White
Write-Host "│         VALIDATION RESULTS          │" -ForegroundColor White
Write-Host "├─────────────────────────────────────┤" -ForegroundColor White
Write-Host "│ Total Checks: $($totalChecks.ToString().PadRight(23))│" -ForegroundColor White
Write-Host "│ " -NoNewline
Write-Host "Passed:       $($script:passCount.ToString().PadRight(23))" -NoNewline -ForegroundColor Green
Write-Host "│" -ForegroundColor White
Write-Host "│ " -NoNewline
Write-Host "Failed:       $($script:failCount.ToString().PadRight(23))" -NoNewline -ForegroundColor Red
Write-Host "│" -ForegroundColor White
Write-Host "│ " -NoNewline
Write-Host "Warnings:     $($script:warnCount.ToString().PadRight(23))" -NoNewline -ForegroundColor Yellow
Write-Host "│" -ForegroundColor White
Write-Host "└─────────────────────────────────────┘" -ForegroundColor White

if ($script:failCount -eq 0 -and $script:warnCount -eq 0) {
    Write-Host "`n✓ Excellent! All write performance checks passed." -ForegroundColor Green
    exit 0
} elseif ($script:failCount -eq 0) {
    Write-Host "`n⚠ Good configuration with some warnings. Review recommendations above." -ForegroundColor Yellow
    exit 0
} else {
    Write-Host "`n✗ Critical write performance issues found. Please remediate failures above." -ForegroundColor Red
    Write-Host "   These configuration issues WILL impact SQL Server write performance." -ForegroundColor Red
    exit 1
}
