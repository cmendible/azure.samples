<#
.SYNOPSIS
    Fixes common SQL Server write performance configuration issues.

.DESCRIPTION
    This script automatically fixes:
    - Max Server Memory configuration (calculates appropriate value)
    - Lock Pages in Memory privilege for SQL Server service account
    - Windows Defender exclusions for SQL Server paths

.PARAMETER SQLInstance
    SQL Server instance name (default: localhost)

.PARAMETER MaxMemoryMB
    Optional: Manually specify max server memory in MB (otherwise auto-calculated)

.PARAMETER WhatIf
    Show what changes would be made without applying them

.EXAMPLE
    .\fix-sql-write-performance.ps1

.EXAMPLE
    .\fix-sql-write-performance.ps1 -SQLInstance "SQLSERVER01\INSTANCE01"

.EXAMPLE
    .\fix-sql-write-performance.ps1 -MaxMemoryMB 57344 -WhatIf

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
    [int]$MaxMemoryMB = 0,

    [Parameter(Mandatory = $false)]
    [switch]$WhatIf
)

#Requires -RunAsAdministrator

# Color output functions
function Write-Success {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor Green
}

function Write-Failure {
    param([string]$Message)
    Write-Host "✗ $Message" -ForegroundColor Red
}

function Write-Info {
    param([string]$Message)
    Write-Host "ℹ $Message" -ForegroundColor Cyan
}

function Write-SectionHeader {
    param([string]$Title)
    Write-Host "`n========================================" -ForegroundColor Magenta
    Write-Host " $Title" -ForegroundColor Magenta
    Write-Host "========================================" -ForegroundColor Magenta
}

# Check for SQL Server cmdlets
$sqlCmdletAvailable = Get-Command -Name Invoke-Sqlcmd -ErrorAction SilentlyContinue

if (-not $sqlCmdletAvailable) {
    try {
        Import-Module SqlServer -ErrorAction Stop
        Write-Info "Loaded SqlServer PowerShell module"
    } catch {
        try {
            Import-Module SQLPS -DisableNameChecking -ErrorAction Stop
            Write-Info "Loaded SQLPS PowerShell module"
        } catch {
            Write-Host "ERROR: SQL Server PowerShell module not found." -ForegroundColor Red
            Write-Host "Install with: Install-Module -Name SqlServer -AllowClobber" -ForegroundColor Red
            exit 1
        }
    }
}

Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  SQL Server Write Performance Fix Tool                    ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

if ($WhatIf) {
    Write-Host "`n⚠ WHATIF MODE: No changes will be applied`n" -ForegroundColor Yellow
}

# Test SQL Server connectivity
Write-Info "Testing SQL Server connectivity: $SQLInstance"
try {
    $version = Invoke-Sqlcmd -ServerInstance $SQLInstance -Query "SELECT @@VERSION AS Version" -ErrorAction Stop
    Write-Success "Connected to SQL Server: $SQLInstance"
} catch {
    Write-Failure "Cannot connect to SQL Server instance: $SQLInstance"
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

# ===========================================
# Fix 1: MAX SERVER MEMORY
# ===========================================
Write-SectionHeader "FIX 1: MAX SERVER MEMORY CONFIGURATION"

# Get current configuration
$currentMaxMem = Invoke-Sqlcmd -ServerInstance $SQLInstance -Query @"
SELECT value_in_use AS CurrentValue
FROM sys.configurations
WHERE name = 'max server memory (MB)'
"@

$currentMaxMemMB = $currentMaxMem.CurrentValue
Write-Info "Current Max Server Memory: $currentMaxMemMB MB"

# Calculate recommended value if not specified
if ($MaxMemoryMB -eq 0) {
    $totalRAM = [Math]::Round((Get-WmiObject Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
    $totalRAMMB = [Math]::Floor($totalRAM * 1024)
    
    # Leave 4GB minimum or 10% for OS, whichever is greater
    $osReserveMB = [Math]::Max(4096, [Math]::Ceiling($totalRAMMB * 0.1))
    $MaxMemoryMB = $totalRAMMB - $osReserveMB
    
    Write-Info "Total RAM: $totalRAM GB ($totalRAMMB MB)"
    Write-Info "OS Reserve: $osReserveMB MB"
    Write-Info "Recommended Max Server Memory: $MaxMemoryMB MB"
}

# Check if change is needed
if ($currentMaxMemMB -eq 2147483647) {
    Write-Info "Max Server Memory is set to default (unlimited) - needs configuration"
    
    if ($WhatIf) {
        Write-Host "WOULD EXECUTE: sp_configure 'max server memory (MB)', $MaxMemoryMB" -ForegroundColor Yellow
    } else {
        try {
            Invoke-Sqlcmd -ServerInstance $SQLInstance -Query @"
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'max server memory (MB)', $MaxMemoryMB;
RECONFIGURE;
"@ -ErrorAction Stop
            Write-Success "Max Server Memory configured to $MaxMemoryMB MB"
        } catch {
            Write-Failure "Failed to configure Max Server Memory"
            Write-Host $_.Exception.Message -ForegroundColor Red
        }
    }
} elseif ($currentMaxMemMB -ne $MaxMemoryMB) {
    Write-Info "Current value ($currentMaxMemMB MB) differs from recommended ($MaxMemoryMB MB)"
    $response = Read-Host "Do you want to update it? (Y/N)"
    
    if ($response -eq 'Y' -or $response -eq 'y') {
        if ($WhatIf) {
            Write-Host "WOULD EXECUTE: sp_configure 'max server memory (MB)', $MaxMemoryMB" -ForegroundColor Yellow
        } else {
            try {
                Invoke-Sqlcmd -ServerInstance $SQLInstance -Query @"
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'max server memory (MB)', $MaxMemoryMB;
RECONFIGURE;
"@ -ErrorAction Stop
                Write-Success "Max Server Memory updated to $MaxMemoryMB MB"
            } catch {
                Write-Failure "Failed to update Max Server Memory"
                Write-Host $_.Exception.Message -ForegroundColor Red
            }
        }
    } else {
        Write-Info "Skipped Max Server Memory update"
    }
} else {
    Write-Success "Max Server Memory is already configured correctly: $currentMaxMemMB MB"
}

# ===========================================
# Fix 2: LOCK PAGES IN MEMORY
# ===========================================
Write-SectionHeader "FIX 2: LOCK PAGES IN MEMORY PRIVILEGE"

# Get SQL Server service account
$sqlService = Get-WmiObject -Class Win32_Service | Where-Object { $_.Name -like 'MSSQL$*' -or $_.Name -eq 'MSSQLSERVER' } | Select-Object -First 1

if (-not $sqlService) {
    Write-Failure "Could not find SQL Server service"
} else {
    $serviceAccount = $sqlService.StartName
    Write-Info "SQL Server Service: $($sqlService.Name)"
    Write-Info "Service Account: $serviceAccount"
    
    # Check current Lock Pages setting
    $currentLockPages = Invoke-Sqlcmd -ServerInstance $SQLInstance -Query "SELECT sql_memory_model_desc FROM sys.dm_os_sys_info"
    
    if ($currentLockPages.sql_memory_model_desc -eq 'LOCK_PAGES') {
        Write-Success "Lock Pages in Memory is already enabled"
    } else {
        # Grant Lock Pages in Memory privilege (needed for all account types except LocalSystem)
        Write-Info "Granting 'Lock Pages in Memory' privilege to $serviceAccount"
        
        if ($WhatIf) {
            Write-Host "WOULD EXECUTE: Grant SeLockMemoryPrivilege to $serviceAccount" -ForegroundColor Yellow
        } else {
            try {
                # Export current security policy
                $tempFile = [System.IO.Path]::GetTempFileName()
                $null = secedit /export /cfg $tempFile /quiet
                
                # Read and modify policy
                $policy = Get-Content $tempFile
                $lockPagesLine = $policy | Where-Object { $_ -like 'SeLockMemoryPrivilege*' }
                
                if ($lockPagesLine) {
                    # Add service account to existing privilege
                    $newLine = $lockPagesLine + ",$serviceAccount"
                    $policy = $policy -replace [regex]::Escape($lockPagesLine), $newLine
                } else {
                    # Add new privilege line
                    $privilegeSection = ($policy | Select-String -Pattern '\[Privilege Rights\]').LineNumber - 1
                    $policy = $policy[0..$privilegeSection] + "SeLockMemoryPrivilege = $serviceAccount" + $policy[($privilegeSection + 1)..($policy.Length - 1)]
                }
                
                # Save modified policy
                $policy | Set-Content $tempFile
                
                # Import modified policy
                $null = secedit /configure /db secedit.sdb /cfg $tempFile /quiet
                Remove-Item $tempFile -Force
                
                Write-Success "Granted 'Lock Pages in Memory' privilege to $serviceAccount"
                Write-Host "⚠ SQL Server service restart required for this change to take effect" -ForegroundColor Yellow
                
                $response = Read-Host "Do you want to restart SQL Server now? (Y/N)"
                if ($response -eq 'Y' -or $response -eq 'y') {
                    Write-Info "Restarting SQL Server service: $($sqlService.Name)"
                    Restart-Service $sqlService.Name -Force
                    Write-Success "SQL Server service restarted"
                } else {
                    Write-Info "Skipped service restart - restart manually for changes to take effect"
                }
            } catch {
                Write-Failure "Failed to grant Lock Pages in Memory privilege"
                Write-Host $_.Exception.Message -ForegroundColor Red
            }
        }
    }
}

# ===========================================
# Fix 3: WINDOWS DEFENDER EXCLUSIONS
# ===========================================
Write-SectionHeader "FIX 3: WINDOWS DEFENDER EXCLUSIONS"

try {
    $defenderPrefs = Get-MpPreference -ErrorAction SilentlyContinue
    
    if (-not $defenderPrefs) {
        Write-Info "Windows Defender not active or accessible - skipping exclusions"
    } else {
        # Get all SQL Server paths
        $sqlPaths = Invoke-Sqlcmd -ServerInstance $SQLInstance -Query @"
SELECT DISTINCT 
    LEFT(physical_name, CHARINDEX('\', physical_name, LEN(physical_name) - CHARINDEX('\', REVERSE(physical_name)) + 1)) AS FolderPath
FROM sys.master_files
"@
        
        $exclusions = $defenderPrefs.ExclusionPath
        $pathsToAdd = @()
        
        foreach ($path in $sqlPaths.FolderPath) {
            if ($exclusions -notcontains $path) {
                $pathsToAdd += $path
            }
        }
        
        if ($pathsToAdd.Count -eq 0) {
            Write-Success "All SQL Server paths are already excluded from Windows Defender"
        } else {
            Write-Info "Found $($pathsToAdd.Count) SQL Server paths to add to exclusions:"
            $pathsToAdd | ForEach-Object { Write-Host "  - $_" -ForegroundColor White }
            
            if ($WhatIf) {
                Write-Host "WOULD EXECUTE: Add-MpPreference -ExclusionPath <paths>" -ForegroundColor Yellow
            } else {
                try {
                    foreach ($path in $pathsToAdd) {
                        Add-MpPreference -ExclusionPath $path -ErrorAction Stop
                        Write-Success "Added exclusion: $path"
                    }
                    Write-Success "Windows Defender exclusions configured successfully"
                } catch {
                    Write-Failure "Failed to add Windows Defender exclusions"
                    Write-Host $_.Exception.Message -ForegroundColor Red
                }
            }
        }
        
        # Also add SQL Server executable paths
        $sqlBinPath = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\*\Setup" -ErrorAction SilentlyContinue | Where-Object { $_.SqlProgramDir }).SqlProgramDir
        
        if ($sqlBinPath) {
            $sqlExe = Join-Path $sqlBinPath "MSSQL\Binn\sqlservr.exe"
            
            if ($exclusions -notcontains $sqlExe -and (Test-Path $sqlExe)) {
                Write-Info "Adding SQL Server executable to exclusions: $sqlExe"
                
                if ($WhatIf) {
                    Write-Host "WOULD EXECUTE: Add-MpPreference -ExclusionPath $sqlExe" -ForegroundColor Yellow
                } else {
                    try {
                        Add-MpPreference -ExclusionPath $sqlExe -ErrorAction Stop
                        Write-Success "Added exclusion: $sqlExe"
                    } catch {
                        Write-Failure "Failed to add SQL Server executable exclusion"
                        Write-Host $_.Exception.Message -ForegroundColor Red
                    }
                }
            }
        }
    }
} catch {
    Write-Failure "Error configuring Windows Defender exclusions"
    Write-Host $_.Exception.Message -ForegroundColor Red
}

# ===========================================
# Fix 4: DISABLE FILE INDEXING ON SQL VOLUMES
# ===========================================
Write-SectionHeader "FIX 4: DISABLE FILE INDEXING ON SQL VOLUMES"

try {
    # Get all SQL Server data/log volumes
    $sqlPaths = Invoke-Sqlcmd -ServerInstance $SQLInstance -Query @"
SELECT DISTINCT 
    LEFT(physical_name, 2) AS DriveLetter
FROM sys.master_files
WHERE database_id >= 2
"@
    
    $volumesToFix = @()
    
    foreach ($sqlPath in $sqlPaths) {
        $driveLetter = $sqlPath.DriveLetter
        $volume = Get-WmiObject -Class Win32_Volume | Where-Object { $_.DriveLetter -eq $driveLetter }
        
        if ($volume -and $volume.IndexingEnabled) {
            $volumesToFix += @{
                DriveLetter = $driveLetter
                Volume = $volume
            }
        }
    }
    
    if ($volumesToFix.Count -eq 0) {
        Write-Success "File indexing is already disabled on all SQL Server volumes"
    } else {
        Write-Info "Found $($volumesToFix.Count) SQL Server volumes with file indexing enabled:"
        $volumesToFix | ForEach-Object { Write-Host "  - $($_.DriveLetter)" -ForegroundColor White }
        
        if ($WhatIf) {
            Write-Host "WOULD EXECUTE: Disable file indexing on SQL volumes" -ForegroundColor Yellow
        } else {
            $response = Read-Host "Do you want to disable file indexing on these volumes? (Y/N)"
            
            if ($response -eq 'Y' -or $response -eq 'y') {
                foreach ($volInfo in $volumesToFix) {
                    try {
                        Write-Info "Disabling indexing on $($volInfo.DriveLetter) ..."
                        $volInfo.Volume.IndexingEnabled = $false
                        $volInfo.Volume.Put() | Out-Null
                        Write-Success "Disabled file indexing on $($volInfo.DriveLetter)"
                    } catch {
                        Write-Failure "Failed to disable indexing on $($volInfo.DriveLetter)"
                        Write-Host $_.Exception.Message -ForegroundColor Red
                    }
                }
                Write-Success "File indexing configuration completed"
            } else {
                Write-Info "Skipped file indexing configuration"
            }
        }
    }
} catch {
    Write-Failure "Error configuring file indexing"
    Write-Host $_.Exception.Message -ForegroundColor Red
}

# ===========================================
# SUMMARY
# ===========================================
Write-SectionHeader "FIX SUMMARY"

if ($WhatIf) {
    Write-Host "`nWhatIf mode - no changes were applied" -ForegroundColor Yellow
    Write-Host "Run without -WhatIf to apply changes" -ForegroundColor Yellow
} else {
    Write-Host "`nConfiguration fixes have been applied." -ForegroundColor Green
    Write-Host "Run the validation script again to verify all checks pass:" -ForegroundColor Cyan
    Write-Host "  .\validate-sql-write-performance.ps1 -SQLInstance $SQLInstance" -ForegroundColor White
}

Write-Host ""
