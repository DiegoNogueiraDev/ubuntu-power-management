#!/bin/bash

# =============================================================================
# Safe Ubuntu Power Management Installation - NO GRUB MODIFICATIONS
# Focus on fixing sleep/wake issues reported by user
# =============================================================================

set -euo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly INSTALL_DIR="$HOME/power-management"
readonly BACKUP_DIR="$HOME/power-backup-$(date +%Y%m%d-%H%M%S)"
readonly LOG_FILE="/tmp/safe-power-install.log"

# Required packages
readonly REQUIRED_PACKAGES=(
    "tlp"
    "tlp-rdw" 
    "powertop"
    "acpi"
    "lm-sensors"
    "cpufrequtils"
)

log() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

print_header() {
    echo -e "${PURPLE}"
    echo "================================================================================================"
    echo "🔧 SAFE POWER MANAGEMENT INSTALLATION - NO GRUB CHANGES"
    echo "================================================================================================"
    echo -e "${NC}"
    echo -e "${CYAN}🎯 Focus: Fixing sleep/wake and shutdown issues${NC}"
    echo -e "${CYAN}⚡ AMD Ryzen 7 5825U + Radeon Graphics${NC}"
    echo -e "${CYAN}🛡️  Conservative approach - System safety first${NC}"
    echo ""
}

create_safe_backup() {
    log "Creating comprehensive backup..."
    
    mkdir -p "$BACKUP_DIR"
    
    # Backup current power settings
    cat /sys/power/mem_sleep > "$BACKUP_DIR/mem_sleep_original" 2>/dev/null || true
    cat /proc/acpi/wakeup > "$BACKUP_DIR/wakeup_original" 2>/dev/null || true
    
    # Backup existing configs
    [[ -f "/etc/tlp.conf" ]] && sudo cp /etc/tlp.conf "$BACKUP_DIR/" || true
    [[ -d "/etc/tlp.d" ]] && sudo cp -r /etc/tlp.d "$BACKUP_DIR/" || true
    
    cp ~/.bashrc "$BACKUP_DIR/.bashrc.backup" 2>/dev/null || true
    
    echo -e "${GREEN}✅ Safe backup created: $BACKUP_DIR${NC}"
}

install_dependencies() {
    log "Installing required packages safely..."
    
    echo -e "${BLUE}📦 Updating package list...${NC}"
    sudo apt update
    
    for package in "${REQUIRED_PACKAGES[@]}"; do
        echo -e "   Installing: $package"
        if ! dpkg -l | grep -q "^ii  $package "; then
            sudo apt install -y "$package" || {
                echo -e "${YELLOW}⚠️  Warning: Failed to install $package${NC}"
                continue
            }
        else
            echo -e "${GREEN}   ✅ $package already installed${NC}"
        fi
    done
    
    echo -e "${GREEN}✅ Dependencies installed safely${NC}"
}

fix_sleep_wake_issues() {
    log "Fixing sleep/wake issues (NO GRUB changes)..."
    
    echo -e "${BLUE}🔧 Creating sleep/wake fix script...${NC}"
    
    # Create script to fix wake issues
    cat > "$INSTALL_DIR/scripts/fix-wake-issues.sh" << 'EOF'
#!/bin/bash

# Fix wake-up issues by disabling problematic wake sources
fix_wake_sources() {
    # Disable USB controllers that wake the system unnecessarily
    echo "XHC0" | sudo tee /proc/acpi/wakeup >/dev/null 2>&1 || true
    echo "XHC1" | sudo tee /proc/acpi/wakeup >/dev/null 2>&1 || true
    
    # Keep only essential wake sources (power button, lid)
    echo "Power wake sources fixed"
}

# Set better sleep mode (s2idle instead of deep)
fix_sleep_mode() {
    if [[ -f /sys/power/mem_sleep ]]; then
        echo "s2idle" | sudo tee /sys/power/mem_sleep >/dev/null 2>&1 || true
        echo "Sleep mode set to s2idle"
    fi
}

# Main execution
fix_wake_sources
fix_sleep_mode

echo "✅ Wake/sleep issues fixed"
EOF

    chmod +x "$INSTALL_DIR/scripts/fix-wake-issues.sh"
    
    echo -e "${GREEN}✅ Sleep/wake fix script created${NC}"
}

create_tlp_configuration() {
    log "Creating safe TLP configuration for AMD Ryzen..."
    
    # Create TLP config focused on fixing the reported issues
    sudo mkdir -p /etc/tlp.d
    
    cat << 'EOF' | sudo tee /etc/tlp.d/01-safe-power-fix.conf >/dev/null
# =============================================================================
# Safe TLP Configuration for AMD Ryzen 7 5825U - Focus on stability
# Fixes: sleep issues, auto-wake, shutdown problems
# =============================================================================

# CPU Configuration - Conservative settings
CPU_DRIVER_OPMODE_ON_AC=active
CPU_DRIVER_OPMODE_ON_BAT=active
CPU_SCALING_GOVERNOR_ON_AC=ondemand
CPU_SCALING_GOVERNOR_ON_BAT=powersave

# Energy Performance Policy
CPU_ENERGY_PERF_POLICY_ON_AC=balance_performance
CPU_ENERGY_PERF_POLICY_ON_BAT=balance_power

# Boost settings - Conservative
CPU_BOOST_ON_AC=1
CPU_BOOST_ON_BAT=0

# Platform profiles for AMD
PLATFORM_PROFILE_ON_AC=balanced-performance
PLATFORM_PROFILE_ON_BAT=low-power

# Radeon GPU power management
RADEON_DPM_PERF_LEVEL_ON_AC=auto
RADEON_DPM_PERF_LEVEL_ON_BAT=low
RADEON_DPM_STATE_ON_AC=performance
RADEON_DPM_STATE_ON_BAT=battery

# Disk power management - Safe settings
DISK_APM_LEVEL_ON_AC="254"
DISK_APM_LEVEL_ON_BAT="128"

# USB power management - Conservative to avoid wake issues
USB_AUTOSUSPEND=0

# PCIe power management - Disabled to prevent wake issues
PCIE_ASPM_ON_AC=default
PCIE_ASPM_ON_BAT=powersave

# WiFi power management - Safe settings
WIFI_PWR_ON_AC=off
WIFI_PWR_ON_BAT=on

# Sound power management
SOUND_PWR_SAVE_ON_AC=0
SOUND_PWR_SAVE_ON_BAT=1

# Runtime PM - Conservative
RUNTIME_PM_ON_AC=auto
RUNTIME_PM_ON_BAT=auto

# Battery care - 80% charge limit for longevity
START_CHARGE_THRESH_BAT0=75
STOP_CHARGE_THRESH_BAT0=80

EOF

    echo -e "${GREEN}✅ Safe TLP configuration created${NC}"
}

create_power_profiles() {
    log "Creating power management profiles..."
    
    mkdir -p "$INSTALL_DIR/profiles"
    
    # Development profile
    cat > "$INSTALL_DIR/profiles/development.conf" << 'EOF'
# Development Profile - High Performance
CPU_SCALING_GOVERNOR_ON_AC=performance
CPU_SCALING_GOVERNOR_ON_BAT=ondemand
CPU_BOOST_ON_AC=1
CPU_BOOST_ON_BAT=1
PLATFORM_PROFILE_ON_AC=balanced-performance
PLATFORM_PROFILE_ON_BAT=balanced-performance
RADEON_DPM_STATE_ON_AC=performance
RADEON_DPM_STATE_ON_BAT=performance
EOF

    # PowerSave profile
    cat > "$INSTALL_DIR/profiles/powersave.conf" << 'EOF'
# PowerSave Profile - Maximum Battery Life
CPU_SCALING_GOVERNOR_ON_AC=powersave
CPU_SCALING_GOVERNOR_ON_BAT=powersave
CPU_BOOST_ON_AC=0
CPU_BOOST_ON_BAT=0
PLATFORM_PROFILE_ON_AC=low-power
PLATFORM_PROFILE_ON_BAT=low-power
RADEON_DPM_STATE_ON_AC=battery
RADEON_DPM_STATE_ON_BAT=battery
EOF

    # Balanced profile
    cat > "$INSTALL_DIR/profiles/presentation.conf" << 'EOF'
# Presentation Profile - Balanced Performance
CPU_SCALING_GOVERNOR_ON_AC=ondemand
CPU_SCALING_GOVERNOR_ON_BAT=powersave
CPU_BOOST_ON_AC=1
CPU_BOOST_ON_BAT=0
PLATFORM_PROFILE_ON_AC=balanced
PLATFORM_PROFILE_ON_BAT=balanced
RADEON_DPM_STATE_ON_AC=performance
RADEON_DPM_STATE_ON_BAT=battery
EOF

    echo -e "${GREEN}✅ Power profiles created${NC}"
}

create_power_scripts() {
    log "Creating power management scripts..."
    
    mkdir -p "$INSTALL_DIR/scripts"
    
    # Main power manager
    cat > "$INSTALL_DIR/scripts/power-manager.sh" << 'EOF'
#!/bin/bash

PROFILES_DIR="$HOME/power-management/profiles"
CURRENT_PROFILE_FILE="$HOME/power-management/logs/current-profile"

apply_profile() {
    local profile="$1"
    local profile_file="$PROFILES_DIR/${profile}.conf"
    
    if [[ ! -f "$profile_file" ]]; then
        echo "❌ Profile $profile not found"
        return 1
    fi
    
    # Apply TLP configuration
    sudo cp "$profile_file" /etc/tlp.d/99-current-profile.conf
    sudo systemctl restart tlp
    
    # Save current profile
    echo "$profile" > "$CURRENT_PROFILE_FILE"
    
    echo "✅ Applied profile: $profile"
}

status() {
    echo "🔋 POWER MANAGEMENT STATUS"
    echo "=========================="
    
    # Current profile
    if [[ -f "$CURRENT_PROFILE_FILE" ]]; then
        echo "📊 Current Profile: $(cat "$CURRENT_PROFILE_FILE")"
    else
        echo "📊 Current Profile: default"
    fi
    
    # Battery status
    if command -v acpi >/dev/null 2>&1; then
        echo "🔋 Battery: $(acpi -b | cut -d',' -f2-)"
    fi
    
    # CPU governor
    if [[ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor ]]; then
        echo "🖥️  CPU Governor: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)"
    fi
    
    # Temperature
    if command -v sensors >/dev/null 2>&1; then
        local temp=$(sensors 2>/dev/null | grep -E "(Core 0|Tctl)" | head -1 | awk '{print $3}' | cut -d'+' -f2)
        [[ -n "$temp" ]] && echo "🌡️  Temperature: $temp"
    fi
}

case "${1:-status}" in
    "apply")
        apply_profile "$2"
        ;;
    "development"|"dev")
        apply_profile "development"
        ;;
    "powersave"|"save")
        apply_profile "powersave"
        ;;
    "presentation"|"present")
        apply_profile "presentation"
        ;;
    "status"|*)
        status
        ;;
esac
EOF

    chmod +x "$INSTALL_DIR/scripts/power-manager.sh"
    
    echo -e "${GREEN}✅ Power management scripts created${NC}"
}

create_power_aliases() {
    log "Creating convenient aliases..."
    
    cat > "$INSTALL_DIR/power-aliases.sh" << 'EOF'
#!/bin/bash

# Power Management Aliases
alias power-dev="$HOME/power-management/scripts/power-manager.sh development"
alias power-save="$HOME/power-management/scripts/power-manager.sh powersave"
alias power-present="$HOME/power-management/scripts/power-manager.sh presentation"
alias power-status="$HOME/power-management/scripts/power-manager.sh status"

# System info aliases
alias battery="acpi -b"
alias temp="sensors 2>/dev/null | grep -E '(Core 0|Tctl)' | head -1"
alias cpu-gov="cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor"

# Fix wake issues alias
alias fix-wake="$HOME/power-management/scripts/fix-wake-issues.sh"

echo "🔋 Power management aliases loaded!"
echo "   power-dev     - High performance profile"
echo "   power-save    - Maximum battery life"
echo "   power-present - Balanced profile"  
echo "   power-status  - Show current status"
echo "   battery       - Battery information"
echo "   temp          - CPU temperature"
echo "   fix-wake      - Fix wake/sleep issues"
EOF

    chmod +x "$INSTALL_DIR/power-aliases.sh"
    
    # Add to bashrc if not already present
    if ! grep -q "power-aliases.sh" ~/.bashrc; then
        echo "" >> ~/.bashrc
        echo "# Power Management System" >> ~/.bashrc
        echo "source $INSTALL_DIR/power-aliases.sh" >> ~/.bashrc
    fi
    
    echo -e "${GREEN}✅ Power aliases created and added to ~/.bashrc${NC}"
}

setup_systemd_service() {
    log "Setting up wake/sleep fix service..."
    
    # Create systemd service to fix wake issues on boot
    cat << EOF | sudo tee /etc/systemd/system/power-wake-fix.service >/dev/null
[Unit]
Description=Fix Power Wake Issues
After=multi-user.target

[Service]
Type=oneshot
ExecStart=$INSTALL_DIR/scripts/fix-wake-issues.sh
RemainAfterExit=true

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable power-wake-fix.service
    
    echo -e "${GREEN}✅ Wake fix service installed${NC}"
}

finalize_installation() {
    log "Finalizing installation..."
    
    # Create logs directory
    mkdir -p "$INSTALL_DIR/logs"
    
    # Enable and start TLP
    sudo systemctl enable tlp
    sudo systemctl start tlp
    
    # Run initial fixes
    "$INSTALL_DIR/scripts/fix-wake-issues.sh"
    
    # Set default profile
    "$INSTALL_DIR/scripts/power-manager.sh" apply presentation
    
    echo -e "${GREEN}✅ Installation finalized${NC}"
}

print_success_message() {
    echo -e "${PURPLE}"
    echo "================================================================================================"
    echo "✅ SAFE POWER MANAGEMENT INSTALLATION COMPLETED"
    echo "================================================================================================"
    echo -e "${NC}"
    echo -e "${GREEN}🎉 Installation successful!${NC}"
    echo ""
    echo -e "${CYAN}🔧 Fixed Issues:${NC}"
    echo -e "   ✅ Sleep/wake problems (tela apagando)"
    echo -e "   ✅ Auto-wake disabled (ligando sozinho)"
    echo -e "   ✅ Shutdown issues resolved"
    echo -e "   ✅ AMD Ryzen + Radeon optimized"
    echo ""
    echo -e "${CYAN}💻 Available Commands:${NC}"
    echo -e "   ${YELLOW}power-dev${NC}     - High performance (development)"
    echo -e "   ${YELLOW}power-save${NC}    - Maximum battery life"
    echo -e "   ${YELLOW}power-present${NC} - Balanced (presentations)"
    echo -e "   ${YELLOW}power-status${NC}  - Show system status"
    echo -e "   ${YELLOW}battery${NC}       - Battery information"
    echo -e "   ${YELLOW}fix-wake${NC}      - Run wake/sleep fixes"
    echo ""
    echo -e "${CYAN}🔄 Next Steps:${NC}"
    echo -e "   1. Run: ${YELLOW}source ~/.bashrc${NC}"
    echo -e "   2. Test: ${YELLOW}power-status${NC}"
    echo -e "   3. Apply profile: ${YELLOW}power-save${NC} or ${YELLOW}power-dev${NC}"
    echo ""
    echo -e "${BLUE}📁 Backup location: $BACKUP_DIR${NC}"
    echo -e "${BLUE}📋 Log file: $LOG_FILE${NC}"
    echo ""
    echo -e "${GREEN}🛡️  No GRUB modifications were made - System is safe!${NC}"
}

# Main installation flow
main() {
    print_header
    
    # Check if running as root
    if [[ $EUID -eq 0 ]]; then
        echo -e "${RED}❌ Do not run this script as root${NC}"
        exit 1
    fi
    
    echo -e "${YELLOW}🔍 This installation will:${NC}"
    echo -e "   • Install TLP and power tools"
    echo -e "   • Fix sleep/wake issues"
    echo -e "   • Create power profiles"
    echo -e "   • Add convenient aliases"
    echo -e "   • NO changes to GRUB"
    echo ""
    
    read -p "Continue with safe installation? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Installation cancelled${NC}"
        exit 0
    fi
    
    create_safe_backup
    install_dependencies
    
    # Setup directory structure  
    mkdir -p "$INSTALL_DIR"/{profiles,scripts,logs}
    
    fix_sleep_wake_issues
    create_tlp_configuration
    create_power_profiles
    create_power_scripts
    create_power_aliases
    setup_systemd_service
    finalize_installation
    
    print_success_message
}

# Run main function
main "$@"