#!/bin/bash

#
# validate-sql-ultradisk.sh
#
# SYNOPSIS
#     Validates SQL Server on Windows VM with Ultra Disk configuration against Azure best practices.
#
# DESCRIPTION
#     This script checks if a SQL Server on Windows VM with Ultra Disk is configured according to Azure best practices.
#     It validates VM configuration, disk settings, SQL Server configuration, and storage layout.
#
# USAGE
#     ./validate-sql-ultradisk.sh -s <subscription-id> -g <resource-group> -n <vm-name> [-d]
#
# OPTIONS
#     -s, --subscription-id    Azure Subscription ID where the VM resides (required)
#     -g, --resource-group     Resource Group name containing the VM (required)
#     -n, --vm-name            Name of the Virtual Machine running SQL Server (required)
#     -d, --detailed           Show detailed information about each check (optional)
#     -h, --help               Display this help message
#
# EXAMPLES
#     ./validate-sql-ultradisk.sh -s "xxxxx-xxxx-xxxx" -g "rg-sqlvm" -n "sqlvm01"
#     ./validate-sql-ultradisk.sh -s "xxxxx-xxxx-xxxx" -g "rg-sqlvm" -n "sqlvm01" -d
#
# NOTES
#     Author: Azure Quick Review (azqr)
#     Version: 1.0.0
#     Requires: Azure CLI (az)
#

set -euo pipefail

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Counters
PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

# Parameters
SUBSCRIPTION_ID=""
RESOURCE_GROUP=""
VM_NAME=""
DETAILED_OUTPUT=false

# Output functions
write_success() {
    echo -e "${GREEN}✓ PASS: $1${NC}"
    PASS_COUNT=$((PASS_COUNT + 1))
}

write_failure() {
    echo -e "${RED}✗ FAIL: $1${NC}"
    FAIL_COUNT=$((FAIL_COUNT + 1))
}

write_warning() {
    echo -e "${YELLOW}⚠ WARN: $1${NC}"
    WARN_COUNT=$((WARN_COUNT + 1))
}

write_info() {
    echo -e "${CYAN}ℹ INFO: $1${NC}"
}

write_section_header() {
    echo ""
    echo -e "${MAGENTA}========================================${NC}"
    echo -e "${MAGENTA} $1${NC}"
    echo -e "${MAGENTA}========================================${NC}"
}

show_help() {
    grep '^#' "$0" | grep -v '#!/bin/bash' | sed 's/^# \?//'
    exit 0
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--subscription-id)
            SUBSCRIPTION_ID="$2"
            shift 2
            ;;
        -g|--resource-group)
            RESOURCE_GROUP="$2"
            shift 2
            ;;
        -n|--vm-name)
            VM_NAME="$2"
            shift 2
            ;;
        -d|--detailed)
            DETAILED_OUTPUT=true
            shift
            ;;
        -h|--help)
            show_help
            ;;
        *)
            echo -e "${RED}Error: Unknown option $1${NC}"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

# Validate required parameters
if [[ -z "$SUBSCRIPTION_ID" ]] || [[ -z "$RESOURCE_GROUP" ]] || [[ -z "$VM_NAME" ]]; then
    echo -e "${RED}Error: Missing required parameters${NC}"
    echo "Required: -s <subscription-id> -g <resource-group> -n <vm-name>"
    echo "Use -h or --help for usage information"
    exit 1
fi

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo -e "${RED}Error: Azure CLI (az) is not installed${NC}"
    echo "Install Azure CLI from: https://docs.microsoft.com/cli/azure/install-azure-cli"
    exit 1
fi

# SQL Server recommended VM sizes for Ultra Disk
RECOMMENDED_VM_SIZES=(
    "Standard_E4ds_v5" "Standard_E8ds_v5" "Standard_E16ds_v5" "Standard_E20ds_v5"
    "Standard_E32ds_v5" "Standard_E48ds_v5" "Standard_E64ds_v5"
    "Standard_E4ds_v4" "Standard_E8ds_v4" "Standard_E16ds_v4" "Standard_E20ds_v4"
    "Standard_E32ds_v4" "Standard_E48ds_v4" "Standard_E64ds_v4"
    "Standard_M8ms" "Standard_M16ms" "Standard_M32ms" "Standard_M64ms"
    "Standard_M128ms" "Standard_M208ms_v2" "Standard_M416ms_v2"
)

echo ""
echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║  SQL Server on Windows with Ultra Disk Validation Tool    ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"

# Connect to Azure
write_info "Setting Azure subscription context: $SUBSCRIPTION_ID"
if ! az account set --subscription "$SUBSCRIPTION_ID" 2>/dev/null; then
    echo -e "${RED}Error: Failed to set subscription. Please login with 'az login'${NC}"
    exit 1
fi
write_success "Connected to subscription: $SUBSCRIPTION_ID"

# Get VM details
write_info "Retrieving VM information for: $VM_NAME"
if ! VM_JSON=$(az vm show --resource-group "$RESOURCE_GROUP" --name "$VM_NAME" --output json 2>&1); then
    echo -e "${RED}Error: Failed to retrieve VM '$VM_NAME'${NC}"
    echo -e "${RED}$VM_JSON${NC}"
    exit 1
fi

if [[ -z "$VM_JSON" ]] || [[ "$VM_JSON" == "null" ]]; then
    echo -e "${RED}Error: VM '$VM_NAME' not found in resource group '$RESOURCE_GROUP'${NC}"
    exit 1
fi

write_success "VM found: $VM_NAME"

# Extract VM properties
VM_SIZE=$(echo "$VM_JSON" | jq -r '.hardwareProfile.vmSize')
VM_LOCATION=$(echo "$VM_JSON" | jq -r '.location')
VM_ZONES=$(echo "$VM_JSON" | jq -r '.zones[]? // empty' 2>/dev/null || true)
OS_DISK_NAME=$(echo "$VM_JSON" | jq -r '.storageProfile.osDisk.name')
OS_DISK_CACHING=$(echo "$VM_JSON" | jq -r '.storageProfile.osDisk.caching')

# ===========================================
# Section 1: VM Configuration
# ===========================================
write_section_header "1. VM CONFIGURATION VALIDATION"

# Check VM Size
echo ""
echo "[Check 1.1] VM Size for SQL Server with Ultra Disk"
if [[ "$DETAILED_OUTPUT" == true ]]; then
    write_info "Current VM Size: $VM_SIZE"
fi

# Check if VM size is in recommended list
if printf '%s\n' "${RECOMMENDED_VM_SIZES[@]}" | grep -q "^${VM_SIZE}$"; then
    write_success "VM size '$VM_SIZE' is recommended for SQL Server with Ultra Disk"
elif [[ "$VM_SIZE" =~ ^Standard_[EM].*ds_v[45] ]] || [[ "$VM_SIZE" =~ ^Standard_M.*[_]v[2-9] ]] || [[ "$VM_SIZE" =~ ^Standard_M.*ms ]]; then
    write_success "VM size '$VM_SIZE' supports Ultra Disk"
else
    write_failure "VM size '$VM_SIZE' may not be optimal for SQL Server with Ultra Disk"
    write_info "Recommended sizes: E-series v4/v5 or M-series VMs"
fi

# Check Availability Zone
echo ""
echo "[Check 1.2] Availability Zone Configuration"
if [[ -n "$VM_ZONES" ]]; then
    write_success "VM is deployed in Availability Zone: $VM_ZONES"
else
    write_warning "VM is not deployed in an Availability Zone (required for Ultra Disk high availability)"
    write_info "Consider redeploying VM in an Availability Zone for better SLA"
    write_info "Note: Ultra Disks require Availability Zone deployment"
fi

# Check Accelerated Networking
echo ""
echo "[Check 1.3] Accelerated Networking"
NIC_IDS=$(echo "$VM_JSON" | jq -r '.networkProfile.networkInterfaces[].id // empty' 2>/dev/null || true)
ALL_NICS_ACCELERATED=true

while IFS= read -r NIC_ID; do
    if [[ -n "$NIC_ID" ]]; then
        NIC_NAME=$(basename "$NIC_ID")
        NIC_RG=$(echo "$NIC_ID" | cut -d'/' -f5)
        
        if ACCELERATED=$(az network nic show --ids "$NIC_ID" --query "enableAcceleratedNetworking" -o tsv 2>/dev/null); then
            if [[ "$ACCELERATED" != "true" ]]; then
                ALL_NICS_ACCELERATED=false
                break
            fi
        else
            write_warning "Could not retrieve NIC information for: $NIC_NAME"
            ALL_NICS_ACCELERATED=false
            break
        fi
    fi
done <<< "$NIC_IDS"

if [[ "$ALL_NICS_ACCELERATED" == true ]]; then
    write_success "Accelerated Networking is enabled on all network interfaces"
else
    write_failure "Accelerated Networking is not enabled on all network interfaces"
    write_info "Enable Accelerated Networking for better SQL Server performance"
fi

# ===========================================
# Section 2: Disk Configuration
# ===========================================
write_section_header "2. DISK CONFIGURATION VALIDATION"

# Get data disks
DATA_DISKS_JSON=$(echo "$VM_JSON" | jq -c '.storageProfile.dataDisks[]? // empty' 2>/dev/null || true)
ULTRA_DISK_COUNT=0
PREMIUM_DISK_COUNT=0

# Arrays to store disk information
declare -a ULTRA_DISKS
declare -a DATA_DISK_NAMES
declare -a DATA_DISK_LUNS
declare -a DATA_DISK_CACHING

while IFS= read -r DISK; do
    if [[ -n "$DISK" ]]; then
        DISK_NAME=$(echo "$DISK" | jq -r '.name')
        DISK_LUN=$(echo "$DISK" | jq -r '.lun')
        DISK_CACHING=$(echo "$DISK" | jq -r '.caching')
        
        DATA_DISK_NAMES+=("$DISK_NAME")
        DATA_DISK_LUNS+=("$DISK_LUN")
        DATA_DISK_CACHING+=("$DISK_CACHING")
        
        # Get disk details
        if ! DISK_DETAIL=$(az disk show --resource-group "$RESOURCE_GROUP" --name "$DISK_NAME" --output json 2>&1); then
            write_warning "Could not retrieve details for disk: $DISK_NAME"
            continue
        fi
        DISK_SKU=$(echo "$DISK_DETAIL" | jq -r '.sku.name // "Unknown"')
        
        if [[ "$DISK_SKU" == "UltraSSD_LRS" ]]; then
            ULTRA_DISKS+=("$DISK_NAME")
            ULTRA_DISK_COUNT=$((ULTRA_DISK_COUNT + 1))
        elif [[ "$DISK_SKU" == *"Premium"* ]]; then
            PREMIUM_DISK_COUNT=$((PREMIUM_DISK_COUNT + 1))
        fi
    fi
done <<< "$DATA_DISKS_JSON"

DATA_DISKS_COUNT=${#DATA_DISK_NAMES[@]}

# Check if Ultra Disk is attached
echo ""
echo "[Check 2.1] Ultra Disk Attachment"
if [[ $ULTRA_DISK_COUNT -gt 0 ]]; then
    write_success "Found $ULTRA_DISK_COUNT Ultra Disk(s) attached to VM"
else
    write_failure "No Ultra Disks found attached to VM"
    write_info "Ultra Disks provide better performance for SQL Server workloads"
fi

# Check Ultra Disk Configuration
if [[ $ULTRA_DISK_COUNT -gt 0 ]]; then
    echo ""
    echo "[Check 2.2] Ultra Disk Configuration Details"
    
    for ULTRA_DISK in "${ULTRA_DISKS[@]}"; do
        if [[ "$DETAILED_OUTPUT" == true ]]; then
            write_info "Analyzing Ultra Disk: $ULTRA_DISK"
        fi
        
        if ! DISK_DETAIL=$(az disk show --resource-group "$RESOURCE_GROUP" --name "$ULTRA_DISK" --output json 2>&1); then
            write_warning "Could not retrieve details for Ultra Disk: $ULTRA_DISK"
            continue
        fi
        
        # Check IOPS
        IOPS=$(echo "$DISK_DETAIL" | jq -r '.diskIOPSReadWrite // 0')
        if [[ "$DETAILED_OUTPUT" == true ]]; then
            write_info "  - IOPS: $IOPS"
        fi
        
        if [[ $IOPS -ge 7500 ]]; then
            write_success "Ultra Disk '$ULTRA_DISK' has adequate IOPS: $IOPS (≥7500 recommended for SQL)"
        else
            write_warning "Ultra Disk '$ULTRA_DISK' has low IOPS: $IOPS (≥7500 recommended for SQL)"
        fi
        
        # Check Throughput (MB/s)
        THROUGHPUT=$(echo "$DISK_DETAIL" | jq -r '.diskMBpsReadWrite // 0')
        if [[ "$DETAILED_OUTPUT" == true ]]; then
            write_info "  - Throughput: $THROUGHPUT MB/s"
        fi
        
        if [[ $THROUGHPUT -ge 250 ]]; then
            write_success "Ultra Disk '$ULTRA_DISK' has adequate throughput: $THROUGHPUT MB/s"
        else
            write_warning "Ultra Disk '$ULTRA_DISK' has low throughput: $THROUGHPUT MB/s (≥250 recommended)"
        fi
        
        # Check Disk Size
        DISK_SIZE_GB=$(echo "$DISK_DETAIL" | jq -r '.diskSizeGB // 0')
        if [[ "$DETAILED_OUTPUT" == true ]]; then
            write_info "  - Size: $DISK_SIZE_GB GB"
        fi
        
        if [[ $DISK_SIZE_GB -ge 256 ]]; then
            write_success "Ultra Disk '$ULTRA_DISK' has adequate size: $DISK_SIZE_GB GB"
        else
            write_warning "Ultra Disk '$ULTRA_DISK' size is small: $DISK_SIZE_GB GB (≥256 GB recommended)"
        fi
    done
fi

# Check Host Caching Settings
echo ""
echo "[Check 2.3] Disk Caching Configuration"
for i in "${!DATA_DISK_NAMES[@]}"; do
    DISK_NAME="${DATA_DISK_NAMES[$i]}"
    CACHING="${DATA_DISK_CACHING[$i]}"
    
    if [[ "$DETAILED_OUTPUT" == true ]]; then
        write_info "Disk: $DISK_NAME - Caching: $CACHING"
    fi
    
    # Get disk SKU
    if ! DISK_DETAIL=$(az disk show --resource-group "$RESOURCE_GROUP" --name "$DISK_NAME" --output json 2>&1); then
        write_warning "Could not retrieve details for disk: $DISK_NAME"
        continue
    fi
    DISK_SKU=$(echo "$DISK_DETAIL" | jq -r '.sku.name // "Unknown"')
    
    if [[ "$DISK_SKU" == "UltraSSD_LRS" ]]; then
        if [[ "$CACHING" == "None" ]]; then
            write_success "Ultra Disk '$DISK_NAME' has correct caching: None"
        else
            write_failure "Ultra Disk '$DISK_NAME' has incorrect caching: $CACHING (should be None)"
        fi
    else
        # For Premium SSD data disks, ReadOnly is recommended
        if [[ "$CACHING" == "ReadOnly" ]]; then
            write_success "Premium disk '$DISK_NAME' has recommended caching: ReadOnly"
        else
            write_warning "Premium disk '$DISK_NAME' caching is: $CACHING (ReadOnly recommended for data)"
        fi
    fi
done

# Check OS Disk
echo ""
echo "[Check 2.4] OS Disk Configuration"
if ! OS_DISK_DETAIL=$(az disk show --resource-group "$RESOURCE_GROUP" --name "$OS_DISK_NAME" --output json 2>&1); then
    write_warning "Could not retrieve OS disk details: $OS_DISK_NAME"
    write_info "$OS_DISK_DETAIL"
else
    OS_DISK_SKU=$(echo "$OS_DISK_DETAIL" | jq -r '.sku.name // "Unknown"')
    OS_DISK_SIZE=$(echo "$OS_DISK_DETAIL" | jq -r '.diskSizeGB // 0')
    OS_DISK_IOPS=$(echo "$OS_DISK_DETAIL" | jq -r '.diskIOPSReadWrite // "N/A"')
    OS_DISK_THROUGHPUT=$(echo "$OS_DISK_DETAIL" | jq -r '.diskMBpsReadWrite // "N/A"')

    if [[ "$DETAILED_OUTPUT" == true ]]; then
        write_info "OS Disk: $OS_DISK_NAME - Type: $OS_DISK_SKU"
        write_info "OS Disk Size: $OS_DISK_SIZE GB"
        if [[ "$OS_DISK_IOPS" != "N/A" ]]; then
            write_info "OS Disk IOPS: $OS_DISK_IOPS"
            write_info "OS Disk Throughput: $OS_DISK_THROUGHPUT MB/s"
        fi
    fi
    
    if [[ "$OS_DISK_SKU" == *"Premium"* ]] || [[ "$OS_DISK_SKU" == "StandardSSD_LRS" ]]; then
        write_success "OS Disk is using Premium or Standard SSD: $OS_DISK_SKU"
    else
        write_failure "OS Disk is not using Premium SSD: $OS_DISK_SKU"
        write_info "Use -d flag for detailed explanation of performance impact"
        
        if [[ "$DETAILED_OUTPUT" == true ]]; then
            echo ""
            write_info "═══════════════════════════════════════════════════════════════════════"
            write_info "WHY OS DISK TYPE MATTERS FOR SQL SERVER PERFORMANCE:"
            write_info "═══════════════════════════════════════════════════════════════════════"
            echo "  1. WINDOWS PAGE FILE: SQL Server uses the page file on the OS disk for:"
            echo "     • Virtual memory overflow when physical RAM is exhausted"
            echo "     • Memory dump files during crashes or failures"
            echo "     • Standard HDD (Standard_LRS): ~500 IOPS, 60 MB/s"
            echo "     • Premium SSD (P30): 5,000 IOPS, 200 MB/s (10x faster)"
            echo ""
            echo "  2. SQL SERVER BINARIES & SYSTEM FILES:"
            echo "     • SQL Server executable files and DLLs loaded from OS disk"
            echo "     • System databases access (master, model, msdb) if not relocated"
            echo "     • Slow OS disk = slow SQL Server startup and service operations"
            echo ""
            echo "  3. WINDOWS UPDATE & PATCHING:"
            echo "     • Windows updates write extensively to OS disk"
            echo "     • Standard disk throttling can cause SQL Server I/O waits"
            echo "     • Can trigger performance degradation during maintenance windows"
            echo ""
            echo "  4. ERRORLOG & TRACE FILES:"
            echo "     • SQL Server error logs written to OS disk by default"
            echo "     • High-frequency logging (errors, warnings) causes I/O contention"
            echo "     • Can affect transaction log flush operations"
            echo ""
            echo "  5. TEMPDB CONSIDERATION:"
            echo "     • While TempDB should be on local SSD (D:), some overflow may occur"
            echo "     • OS disk I/O limits can cause spillover performance issues"
            echo ""
            echo "  PERFORMANCE IMPACT:"
            echo "  ┌────────────────────────────────────────────────────────────────┐"
            echo "  │ Scenario                    │ Standard HDD │ Premium SSD       │"
            echo "  ├─────────────────────────────┼──────────────┼───────────────────┤"
            echo "  │ SQL Startup Time            │ 2-5 min      │ 30-60 sec         │"
            echo "  │ Page File I/O Latency       │ 20-50ms      │ 2-5ms             │"
            echo "  │ Windows Update Impact       │ High         │ Minimal           │"
            echo "  │ Memory Pressure Handling    │ Severe       │ Moderate          │"
            echo "  │ Failover Cluster Quorum     │ Unreliable   │ Reliable          │"
            echo "  └─────────────────────────────┴──────────────┴───────────────────┘"
            echo ""
            echo "  RECOMMENDATION:"
            echo "  • Minimum: Premium SSD P10 (128 GB, 500 IOPS, 100 MB/s)"
            echo "  • Recommended: Premium SSD P20 (512 GB, 2,300 IOPS, 150 MB/s)"
            echo "  • For production: Premium SSD P30+ (1 TB, 5,000 IOPS, 200 MB/s)"
            write_info "═══════════════════════════════════════════════════════════════════════"
            echo ""
        fi
    fi

    if [[ "$OS_DISK_CACHING" == "ReadWrite" ]]; then
        write_success "OS Disk caching is set to ReadWrite (recommended)"
    else
        write_warning "OS Disk caching is: $OS_DISK_CACHING (ReadWrite recommended)"
    fi
fi

# Check Zone Alignment
echo ""
echo "[Check 2.5] Disk Zone Alignment"
if [[ -n "$VM_ZONES" ]]; then
    write_info "VM is in Availability Zone: $VM_ZONES"
    
    ALL_DISKS_ZONE_ALIGNED=true
    
    # Check OS Disk zone
    OS_DISK_ZONES=$(echo "$OS_DISK_DETAIL" | jq -r '.zones[]? // empty' 2>/dev/null || true)
    if [[ -n "$OS_DISK_ZONES" ]]; then
        if [[ "$OS_DISK_ZONES" == "$VM_ZONES" ]]; then
            write_success "OS Disk '$OS_DISK_NAME' is in the same zone as VM: Zone $OS_DISK_ZONES"
        else
            write_failure "OS Disk '$OS_DISK_NAME' is in Zone $OS_DISK_ZONES but VM is in Zone $VM_ZONES"
            ALL_DISKS_ZONE_ALIGNED=false
        fi
    else
        write_warning "OS Disk '$OS_DISK_NAME' is not zone-pinned (regional disk)"
        ALL_DISKS_ZONE_ALIGNED=false
    fi
    
    # Check Data Disks zones
    for i in "${!DATA_DISK_NAMES[@]}"; do
        DISK_NAME="${DATA_DISK_NAMES[$i]}"
        
        if ! DISK_DETAIL=$(az disk show --resource-group "$RESOURCE_GROUP" --name "$DISK_NAME" --output json 2>&1); then
            write_warning "Could not retrieve zone information for disk: $DISK_NAME"
            continue
        fi
        
        DISK_ZONES=$(echo "$DISK_DETAIL" | jq -r '.zones[]? // empty' 2>/dev/null || true)
        
        if [[ -n "$DISK_ZONES" ]]; then
            if [[ "$DISK_ZONES" == "$VM_ZONES" ]]; then
                if [[ "$DETAILED_OUTPUT" == true ]]; then
                    write_success "Data disk '$DISK_NAME' is in the same zone as VM: Zone $DISK_ZONES"
                fi
            else
                write_failure "Data disk '$DISK_NAME' is in Zone $DISK_ZONES but VM is in Zone $VM_ZONES"
                ALL_DISKS_ZONE_ALIGNED=false
            fi
        else
            write_warning "Data disk '$DISK_NAME' is not zone-pinned (regional disk)"
            ALL_DISKS_ZONE_ALIGNED=false
        fi
    done
    
    if [[ "$ALL_DISKS_ZONE_ALIGNED" == true ]] && [[ "$DETAILED_OUTPUT" == false ]]; then
        write_success "All data disks ($DATA_DISKS_COUNT) are in the same zone as VM: Zone $VM_ZONES"
    fi
else
    write_info "VM is not in an Availability Zone - skipping zone alignment check"
fi

# ===========================================
# Section 3: Storage Layout Best Practices
# ===========================================
write_section_header "3. STORAGE LAYOUT BEST PRACTICES"

echo ""
echo "[Check 3.1] Number of Data Disks"
if [[ "$DETAILED_OUTPUT" == true ]]; then
    write_info "Total data disks attached: $DATA_DISKS_COUNT"
fi

if [[ $DATA_DISKS_COUNT -ge 2 ]]; then
    write_success "Multiple data disks attached ($DATA_DISKS_COUNT) - allows separation of data/log files"
else
    write_warning "Only $DATA_DISKS_COUNT data disk(s) attached - consider separating data and log files on different disks"
fi

echo ""
echo "[Check 3.2] LUN Configuration"
if [[ "$DETAILED_OUTPUT" == true ]]; then
    LUNS_SORTED=$(printf '%s\n' "${DATA_DISK_LUNS[@]}" | sort -n | tr '\n' ',' | sed 's/,$//')
    write_info "Configured LUNs: $LUNS_SORTED"
fi

# Check if LUNs are sequential
LUNS_SEQUENTIAL=true
EXPECTED_LUN=0
for LUN in $(printf '%s\n' "${DATA_DISK_LUNS[@]}" | sort -n); do
    if [[ $LUN -ne $EXPECTED_LUN ]]; then
        LUNS_SEQUENTIAL=false
        break
    fi
    EXPECTED_LUN=$((EXPECTED_LUN + 1))
done

if [[ "$LUNS_SEQUENTIAL" == true ]]; then
    write_success "LUNs are configured sequentially starting from 0"
else
    write_warning "LUNs are not sequential - this may affect performance predictability"
fi

# ===========================================
# Section 4: SQL Server Best Practices
# ===========================================
write_section_header "4. SQL SERVER CONFIGURATION RECOMMENDATIONS"

echo ""
echo "[Check 4.1] Recommended SQL Server Configuration"
write_info "The following configurations should be verified on the SQL Server instance:"
echo "   • TempDB: Should be on local SSD (D: drive) with multiple files (8 or CPU count)"
echo "   • Data files: Should be on Ultra Disk with .mdf extension"
echo "   • Log files: Should be on separate Ultra Disk with .ldf extension"
echo "   • Backup files: Can be on Standard SSD or Premium SSD"
echo "   • Instant File Initialization: Should be enabled"
echo "   • Lock Pages in Memory: Should be enabled for SQL Server service account"
echo "   • Max Server Memory: Should be configured (leave 4-8GB for OS)"
echo "   • Max Degree of Parallelism (MAXDOP): Should be configured based on CPU count"
echo "   • Cost Threshold for Parallelism: Should be set to 50 or higher"
write_info "Note: These checks require SQL Server access and cannot be verified from Azure alone"

echo ""
echo "[Check 4.2] Recommended Storage Pools Configuration"
write_info "For Ultra Disks on Windows:"
echo "   • Create Storage Pools with simple (non-striped) layout for Ultra Disks"
echo "   • Set allocation unit size to 64KB for data and log volumes"
echo "   • Format with NTFS"
echo "   • Disable Windows write-cache buffer flushing for Ultra Disks"
write_info "Note: These settings should be configured in Windows Server"

# ===========================================
# Summary Report
# ===========================================
write_section_header "VALIDATION SUMMARY"

TOTAL_CHECKS=$((PASS_COUNT + FAIL_COUNT + WARN_COUNT))

echo ""
echo -e "${WHITE}VM: $VM_NAME${NC}"
echo -e "${WHITE}Resource Group: $RESOURCE_GROUP${NC}"
echo -e "${WHITE}VM Size: $VM_SIZE${NC}"
echo -e "${WHITE}Location: $VM_LOCATION${NC}"

echo ""
echo -e "${WHITE}┌─────────────────────────────────────┐${NC}"
echo -e "${WHITE}│         VALIDATION RESULTS          │${NC}"
echo -e "${WHITE}├─────────────────────────────────────┤${NC}"
printf "${WHITE}│ ${NC}Total Checks: %-23s${WHITE}│${NC}\n" "$TOTAL_CHECKS"
printf "${GREEN}│ Passed:       %-23s${WHITE}│${NC}\n" "$PASS_COUNT"
printf "${RED}│ Failed:       %-23s${WHITE}│${NC}\n" "$FAIL_COUNT"
printf "${YELLOW}│ Warnings:     %-23s${WHITE}│${NC}\n" "$WARN_COUNT"
echo -e "${WHITE}└─────────────────────────────────────┘${NC}"

if [[ $FAIL_COUNT -eq 0 ]] && [[ $WARN_COUNT -eq 0 ]]; then
    echo ""
    echo -e "${GREEN}✓ All checks passed! VM configuration follows best practices.${NC}"
    exit 0
elif [[ $FAIL_COUNT -eq 0 ]]; then
    echo ""
    echo -e "${YELLOW}⚠ Configuration is good but has warnings. Review recommendations above.${NC}"
    exit 0
else
    echo ""
    echo -e "${RED}✗ Configuration has failures. Please review and remediate issues above.${NC}"
    exit 1
fi
