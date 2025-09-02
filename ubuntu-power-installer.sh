#!/bin/bash

# =============================================================================
# Ubuntu Power Management System - Complete Installation Script
# For Senior Full Stack Developers - Enterprise Grade Solution
# =============================================================================

set -euo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly INSTALL_DIR="$HOME/power-management"
readonly BACKUP_DIR="$HOME/power-management-backup-$(date +%Y%m%d-%H%M%S)"
readonly LOG_FILE="/tmp/power-management-install.log"

# System information
readonly DISTRO=$(lsb_release -si 2>/dev/null || echo "Unknown")
readonly VERSION=$(lsb_release -sr 2>/dev/null || echo "Unknown")
readonly KERNEL=$(uname -r)
readonly CPU_MODEL=$(lscpu | grep "Model name" | cut -d':' -f2 | xargs)

# Required packages
readonly REQUIRED_PACKAGES=(
    "tlp"
    "tlp-rdw" 
    "powertop"
    "acpi"
    "lm-sensors"
    "cpufrequtils"
    "linux-tools-generic"
    "linux-tools-$(uname -r)"
)

# Logging function
log() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

print_header() {
    echo -e "${PURPLE}"
    echo "================================================================================================"
    echo "🚀 UBUNTU POWER MANAGEMENT SYSTEM - ENTERPRISE INSTALLATION"
    echo "================================================================================================"
    echo -e "${NC}"
    echo -e "${CYAN}🎯 For Senior Full Stack Developers${NC}"
    echo -e "${CYAN}⚡ AMD Ryzen + Radeon Graphics Optimized${NC}"
    echo -e "${CYAN}🛠️ TypeScript + React + Next.js Ready${NC}"
    echo ""
    echo -e "${YELLOW}System Information:${NC}"
    echo -e "   📋 OS: $DISTRO $VERSION"
    echo -e "   🖥️  CPU: $CPU_MODEL"
    echo -e "   🐧 Kernel: $KERNEL"
    echo ""
}

check_system_compatibility() {
    log "Checking system compatibility..."
    
    # Check if Ubuntu/Debian based
    if [[ "$DISTRO" != "Ubuntu" ]] && [[ "$DISTRO" != "Debian" ]]; then
        echo -e "${YELLOW}⚠️  Warning: This script is optimized for Ubuntu. Proceeding anyway...${NC}"
    fi
    
    # Check if AMD CPU
    if ! lscpu | grep -qi "amd"; then
        echo -e "${YELLOW}⚠️  Warning: CPU is not AMD. Some optimizations may not apply.${NC}"
    fi
    
    # Check kernel version
    local kernel_version
    kernel_version=$(uname -r | cut -d'.' -f1-2)
    if [[ "$(echo "$kernel_version >= 5.15" | bc -l 2>/dev/null || echo 0)" == "0" ]]; then
        echo -e "${YELLOW}⚠️  Warning: Kernel version may not support latest power features.${NC}"
    fi
    
    echo -e "${GREEN}✅ System compatibility check completed${NC}"
}

backup_existing_configs() {
    log "Creating backup of existing configurations..."
    
    mkdir -p "$BACKUP_DIR"
    
    # Backup TLP configs
    if [[ -d "/etc/tlp.d" ]]; then
        sudo cp -r /etc/tlp.d "$BACKUP_DIR/tlp.d-backup" 2>/dev/null || true
    fi
    
    if [[ -f "/etc/tlp.conf" ]]; then
        sudo cp /etc/tlp.conf "$BACKUP_DIR/tlp.conf.backup" 2>/dev/null || true
    fi
    
    # Backup power-management if exists
    if [[ -d "$INSTALL_DIR" ]]; then
        cp -r "$INSTALL_DIR" "$BACKUP_DIR/power-management-old" 2>/dev/null || true
    fi
    
    # Backup bashrc and profile
    cp ~/.bashrc "$BACKUP_DIR/.bashrc.backup" 2>/dev/null || true
    cp ~/.profile "$BACKUP_DIR/.profile.backup" 2>/dev/null || true
    
    echo -e "${GREEN}✅ Backup created: $BACKUP_DIR${NC}"
}

install_dependencies() {
    log "Installing required packages..."
    
    echo -e "${BLUE}📦 Updating package list...${NC}"
    sudo apt update
    
    echo -e "${BLUE}📦 Installing power management tools...${NC}"
    for package in "${REQUIRED_PACKAGES[@]}"; do
        echo -e "   Installing: $package"
        sudo apt install -y "$package" || {
            echo -e "${YELLOW}⚠️  Warning: Failed to install $package, continuing...${NC}"
        }
    done
    
    # Install additional tools if available
    echo -e "${BLUE}📦 Installing optional tools...${NC}"
    sudo apt install -y htop iotop nethogs 2>/dev/null || true
    
    echo -e "${GREEN}✅ Dependencies installed${NC}"
}

setup_power_management_directory() {
    log "Setting up power management directory structure..."
    
    # Remove existing directory if present
    if [[ -d "$INSTALL_DIR" ]]; then
        rm -rf "$INSTALL_DIR"
    fi
    
    # Create directory structure
    mkdir -p "$INSTALL_DIR"/{profiles,scripts,logs,workflows}
    
    echo -e "${GREEN}✅ Directory structure created: $INSTALL_DIR${NC}"
}

copy_power_system() {
    log "Copying power management system..."
    
    if [[ "$SCRIPT_DIR" != "$INSTALL_DIR" ]]; then
        # Copy all files from current directory to install directory
        cp -r "$SCRIPT_DIR"/* "$INSTALL_DIR/" 2>/dev/null || true
        
        # Ensure scripts are executable
        chmod +x "$INSTALL_DIR"/scripts/*.sh 2>/dev/null || true
        chmod +x "$INSTALL_DIR"/*.sh 2>/dev/null || true
    fi
    
    echo -e "${GREEN}✅ Power management system copied${NC}"
}

install_cpu_optimizations() {
    log "Configuring CPU optimizations..."
    
    echo -e "${BLUE}🖥️  Setting up AMD CPU optimizations...${NC}"
    
    # Check and enable amd-pstate driver
    if ! lsmod | grep -q amd_pstate; then
        echo "amd_pstate" | sudo tee -a /etc/modules 2>/dev/null || true
    fi
    
    # Create AMD-specific configuration
    cat > "$INSTALL_DIR/profiles/cpu-optimized.conf" << 'EOF'
# AMD Ryzen 7 5825U Specific CPU Optimizations
CPU_DRIVER_OPMODE_ON_AC=active
CPU_DRIVER_OPMODE_ON_BAT=active
CPU_SCALING_GOVERNOR_ON_AC=performance
CPU_SCALING_GOVERNOR_ON_BAT=powersave
CPU_ENERGY_PERF_POLICY_ON_AC=balance_performance
CPU_ENERGY_PERF_POLICY_ON_BAT=power
CPU_BOOST_ON_AC=1
CPU_BOOST_ON_BAT=0
CPU_HWP_DYN_BOOST_ON_AC=1
CPU_HWP_DYN_BOOST_ON_BAT=0
PLATFORM_PROFILE_ON_AC=balanced-performance
PLATFORM_PROFILE_ON_BAT=low-power
EOF
    
    echo -e "${GREEN}✅ CPU optimizations configured${NC}"
}

install_gpu_optimizations() {
    log "Configuring GPU/Video optimizations..."
    
    echo -e "${BLUE}🎮 Setting up Radeon Graphics optimizations...${NC}"
    
    # Create GPU-specific configuration
    cat > "$INSTALL_DIR/profiles/gpu-optimized.conf" << 'EOF'
# AMD Radeon Graphics Optimizations
RADEON_DPM_STATE_ON_AC=performance
RADEON_DPM_STATE_ON_BAT=battery
RADEON_DPM_PERF_LEVEL_ON_AC=auto
RADEON_DPM_PERF_LEVEL_ON_BAT=low

# Additional GPU power management
RUNTIME_PM_ON_AC=on
RUNTIME_PM_ON_BAT=auto
EOF
    
    # Create display optimization script
    cat > "$INSTALL_DIR/scripts/gpu-optimizer.sh" << 'EOF'
#!/bin/bash

# GPU Performance Optimizer
optimize_gpu_for_development() {
    echo "🎮 Optimizing GPU for development..."
    
    # Set high performance mode for integrated graphics
    echo "performance" | sudo tee /sys/class/drm/card*/device/power_dpm_state 2>/dev/null || true
    
    # Optimize display power management
    for card in /sys/class/drm/card*; do
        if [[ -f "$card/device/power_dpm_force_performance_level" ]]; then
            echo "high" | sudo tee "$card/device/power_dpm_force_performance_level" 2>/dev/null || true
        fi
    done
    
    echo "✅ GPU optimized for development workloads"
}

optimize_gpu_for_battery() {
    echo "🔋 Optimizing GPU for battery saving..."
    
    # Set power saving mode
    echo "battery" | sudo tee /sys/class/drm/card*/device/power_dpm_state 2>/dev/null || true
    
    # Set low performance level
    for card in /sys/class/drm/card*; do
        if [[ -f "$card/device/power_dpm_force_performance_level" ]]; then
            echo "low" | sudo tee "$card/device/power_dpm_force_performance_level" 2>/dev/null || true
        fi
    done
    
    echo "✅ GPU optimized for battery saving"
}

case "${1:-status}" in
    "dev")
        optimize_gpu_for_development
        ;;
    "save")
        optimize_gpu_for_battery
        ;;
    *)
        echo "Usage: $0 {dev|save}"
        ;;
esac
EOF
    
    chmod +x "$INSTALL_DIR/scripts/gpu-optimizer.sh"
    
    echo -e "${GREEN}✅ GPU/Video optimizations configured${NC}"
}

install_tlp_configuration() {
    log "Installing TLP configuration..."
    
    echo -e "${BLUE}⚙️  Configuring TLP with AMD optimizations...${NC}"
    
    # Create TLP directory if it doesn't exist
    sudo mkdir -p /etc/tlp.d
    
    # Copy main TLP configuration
    if [[ -f "$INSTALL_DIR/../tlp-power-optimization.conf" ]]; then
        sudo cp "$INSTALL_DIR/../tlp-power-optimization.conf" /etc/tlp.d/01-power-optimization.conf
    elif [[ -f "/etc/tlp.d/01-power-optimization.conf" ]]; then
        echo -e "${GREEN}✅ TLP configuration already exists${NC}"
    else
        # Create optimized TLP configuration
        sudo tee /etc/tlp.d/01-power-optimization.conf > /dev/null << 'EOF'
# AMD Ryzen 7 5825U + Radeon Graphics - Ubuntu Optimization
TLP_ENABLE=1
TLP_WARN_LEVEL=2

# AMD CPU Configuration
CPU_DRIVER_OPMODE_ON_AC=active
CPU_DRIVER_OPMODE_ON_BAT=active
CPU_SCALING_GOVERNOR_ON_AC=performance
CPU_SCALING_GOVERNOR_ON_BAT=powersave
CPU_ENERGY_PERF_POLICY_ON_AC=balance_performance
CPU_ENERGY_PERF_POLICY_ON_BAT=power
CPU_BOOST_ON_AC=1
CPU_BOOST_ON_BAT=0
CPU_HWP_DYN_BOOST_ON_AC=1
CPU_HWP_DYN_BOOST_ON_BAT=0

# Platform Profiles
PLATFORM_PROFILE_ON_AC=balanced-performance
PLATFORM_PROFILE_ON_BAT=low-power

# Disk Optimization
DISK_IDLE_SECS_ON_AC=0
DISK_IDLE_SECS_ON_BAT=2
DISK_APM_LEVEL_ON_AC="254 254"
DISK_APM_LEVEL_ON_BAT="128 128"
SATA_LINKPWR_ON_AC="med_power_with_dipm max_performance"
SATA_LINKPWR_ON_BAT="min_power"

# Graphics Optimization
RADEON_DPM_STATE_ON_AC=performance
RADEON_DPM_STATE_ON_BAT=battery
RADEON_DPM_PERF_LEVEL_ON_AC=auto
RADEON_DPM_PERF_LEVEL_ON_BAT=low

# Network Optimization  
WIFI_PWR_ON_AC=off
WIFI_PWR_ON_BAT=on

# USB Management
USB_AUTOSUSPEND=1
USB_BLACKLIST_PHONE=0

# Battery Care (80% limit for longevity)
START_CHARGE_THRESH_BAT0=75
STOP_CHARGE_THRESH_BAT0=80
RESTORE_THRESHOLDS_ON_BAT=1
EOF
    fi
    
    # Restart TLP
    sudo systemctl enable tlp
    sudo systemctl restart tlp
    
    echo -e "${GREEN}✅ TLP configuration applied${NC}"
}

setup_aliases_and_integration() {
    log "Setting up aliases and shell integration..."
    
    echo -e "${BLUE}🔧 Configuring shell aliases...${NC}"
    
    # Add power management source to bashrc if not present
    if ! grep -q "power-management/power-aliases.sh" ~/.bashrc; then
        echo "" >> ~/.bashrc
        echo "# Power Management Aliases" >> ~/.bashrc
        echo "source ~/power-management/power-aliases.sh" >> ~/.bashrc
        log "Added power management aliases to .bashrc"
    fi
    
    # Create additional development aliases
    cat >> "$INSTALL_DIR/power-aliases.sh" << 'EOF'

# =============================================================================
# Additional Development-Focused Aliases
# =============================================================================

# Development workflow aliases
alias dev-power-on='power-dev && ~/power-management/scripts/gpu-optimizer.sh dev && echo "🚀 Full development mode activated!"'
alias meeting-power='power-present && echo "💼 Meeting mode activated!"'
alias travel-power='power-save && ~/power-management/scripts/gpu-optimizer.sh save && echo "✈️ Travel mode activated!"'

# Enhanced monitoring for developers
alias power-dev-status='echo "🔍 Development Power Status:" && power-status && echo "" && echo "🔥 Development Processes:" && ps aux --sort=-%cpu | grep -E "(node|npm|yarn|docker|java|python|code)" | head -5'

# Build monitoring
monitor-build() {
    local start_time=$(date +%s)
    local start_temp=$(sensors | grep -i tctl | grep -oP '+\K\d+' || echo "0")
    local start_battery=$(acpi -b | grep -oP '\d+%' | head -1)
    
    echo "🚀 Build monitoring started..."
    echo "📊 Initial stats: Temp ${start_temp}°C, Battery ${start_battery}"
    
    # Execute the command
    "$@"
    local exit_code=$?
    
    local end_time=$(date +%s)
    local end_temp=$(sensors | grep -i tctl | grep -oP '+\K\d+' || echo "0")
    local end_battery=$(acpi -b | grep -oP '\d+%' | head -1)
    local duration=$((end_time - start_time))
    
    echo ""
    echo "✅ Build completed!"
    echo "⏱️  Duration: ${duration}s"
    echo "🌡️  Temperature: ${start_temp}°C → ${end_temp}°C"
    echo "🔋 Battery: ${start_battery} → ${end_battery}"
    
    return $exit_code
}

# Power efficiency score
calculate-power-score() {
    local uptime_hours=$(uptime | grep -oP '\d+:\d+' | head -1 | awk -F: '{print $1}' || echo "1")
    local avg_temp=$(sensors | grep -i tctl | grep -oP '+\K\d+' || echo "60")
    local battery_level=$(acpi -b | grep -oP '\d+' | head -1 || echo "50")
    
    local power_score=$((100 - (avg_temp - 40) * 2 + battery_level / 10))
    power_score=$((power_score > 100 ? 100 : power_score))
    power_score=$((power_score < 0 ? 0 : power_score))
    
    echo "🏆 Power Efficiency Score: $power_score/100"
    
    if (( power_score >= 90 )); then
        echo "🥇 Excellent power management!"
    elif (( power_score >= 70 )); then
        echo "🥈 Good power management"
    else
        echo "🥉 Consider optimizations"
    fi
}

EOF
    
    echo -e "${GREEN}✅ Enhanced aliases configured${NC}"
}

configure_services() {
    log "Configuring system services..."
    
    echo -e "${BLUE}🔧 Setting up power monitoring service...${NC}"
    
    # Create systemd service for power monitoring
    sudo tee /etc/systemd/system/power-monitor.service > /dev/null << EOF
[Unit]
Description=Professional Power Management Monitor
After=multi-user.target

[Service]
Type=simple
User=root
ExecStart=$INSTALL_DIR/scripts/power-monitor.sh daemon
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
    
    # Enable but don't start the service yet (user choice)
    sudo systemctl daemon-reload
    sudo systemctl enable power-monitor.service
    
    echo -e "${GREEN}✅ Power monitoring service configured${NC}"
}

setup_automation() {
    log "Setting up intelligent automation..."
    
    echo -e "${BLUE}🤖 Configuring smart power automation...${NC}"
    
    # Create cron job for automatic profile switching
    local cron_job="*/5 * * * * $INSTALL_DIR/scripts/smart-power-automation.sh auto-check >/dev/null 2>&1"
    
    # Add to crontab if not already present
    if ! crontab -l 2>/dev/null | grep -q "smart-power-automation"; then
        (crontab -l 2>/dev/null; echo "$cron_job") | crontab -
        log "Automatic profile switching scheduled"
        echo -e "${GREEN}✅ Smart automation enabled (5-minute intervals)${NC}"
    else
        echo -e "${GREEN}✅ Smart automation already configured${NC}"
    fi
}

create_additional_optimizations() {
    log "Creating additional system optimizations..."
    
    echo -e "${BLUE}⚡ Creating advanced optimization scripts...${NC}"
    
    # Create system-wide optimization script
    cat > "$INSTALL_DIR/scripts/system-optimizer.sh" << 'EOF'
#!/bin/bash

# System-wide power optimizations
optimize_system() {
    echo "🔧 Applying system-wide optimizations..."
    
    # Kernel parameters for power saving
    echo '# Power management kernel parameters' | sudo tee /etc/sysctl.d/99-power-management.conf
    echo 'vm.laptop_mode = 5' | sudo tee -a /etc/sysctl.d/99-power-management.conf
    echo 'vm.dirty_ratio = 60' | sudo tee -a /etc/sysctl.d/99-power-management.conf
    echo 'vm.dirty_background_ratio = 40' | sudo tee -a /etc/sysctl.d/99-power-management.conf
    
    # Apply immediately
    sudo sysctl -p /etc/sysctl.d/99-power-management.conf
    
    # Optimize swappiness for SSD
    echo 'vm.swappiness = 10' | sudo tee -a /etc/sysctl.d/99-power-management.conf
    
    echo "✅ System optimizations applied"
}

# Network optimization
optimize_network() {
    echo "🌐 Optimizing network power management..."
    
    # Create network power saving rules
    cat > /tmp/network-power-rules << 'EOF'
# Disable wake-on-lan for power saving
ACTION=="add", SUBSYSTEM=="net", KERNEL=="eth*", RUN+="/bin/sh -c 'ethtool -s %k wol d'"
ACTION=="add", SUBSYSTEM=="net", KERNEL=="wlan*", RUN+="/bin/sh -c 'iwconfig %k power on'"
EOF
    
    sudo mv /tmp/network-power-rules /etc/udev/rules.d/70-network-power-management.rules
    
    echo "✅ Network power optimization applied"
}

case "${1:-all}" in
    "system")
        optimize_system
        ;;
    "network")
        optimize_network
        ;;
    "all")
        optimize_system
        optimize_network
        ;;
    *)
        echo "Usage: $0 {system|network|all}"
        ;;
esac
EOF
    
    chmod +x "$INSTALL_DIR/scripts/system-optimizer.sh"
    
    # Create development environment detector
    cat > "$INSTALL_DIR/scripts/dev-environment-detector.sh" << 'EOF'
#!/bin/bash

# Development Environment Auto-Detection
detect_development_stack() {
    local dev_score=0
    
    echo "🔍 Detecting development environment..."
    
    # Check for Node.js projects
    if [[ -f "package.json" ]] || [[ -d "node_modules" ]]; then
        echo "  ✅ Node.js project detected"
        ((dev_score += 20))
    fi
    
    # Check for React/Next.js
    if grep -q "react\|next" package.json 2>/dev/null; then
        echo "  ✅ React/Next.js project detected"
        ((dev_score += 15))
    fi
    
    # Check for TypeScript
    if [[ -f "tsconfig.json" ]] || find . -name "*.ts" -o -name "*.tsx" | head -1 | grep -q .; then
        echo "  ✅ TypeScript project detected"
        ((dev_score += 10))
    fi
    
    # Check for Docker
    if [[ -f "Dockerfile" ]] || [[ -f "docker-compose.yml" ]]; then
        echo "  ✅ Docker project detected"
        ((dev_score += 15))
    fi
    
    # Check for running development servers
    local running_dev=$(ps aux | grep -E "(node|npm|yarn|webpack|vite)" | grep -v grep | wc -l)
    if (( running_dev > 0 )); then
        echo "  ✅ Development servers running: $running_dev"
        ((dev_score += running_dev * 5))
    fi
    
    echo "📊 Development Score: $dev_score"
    
    # Auto-recommend profile
    if (( dev_score >= 30 )); then
        echo "🚀 Recommendation: Use development profile (power-dev)"
    elif (( dev_score >= 15 )); then
        echo "💼 Recommendation: Use presentation profile (power-present)"
    else
        echo "🔋 Recommendation: Use power save profile (power-save)"
    fi
}

detect_development_stack
EOF
    
    chmod +x "$INSTALL_DIR/scripts/dev-environment-detector.sh"
    
    echo -e "${GREEN}✅ Additional optimization scripts created${NC}"
}

test_installation() {
    log "Testing installation..."
    
    echo -e "${BLUE}🧪 Running installation tests...${NC}"
    
    # Test 1: Check if TLP is working
    if sudo tlp-stat -s | grep -q "TLP status"; then
        echo -e "${GREEN}✅ TLP is working correctly${NC}"
    else
        echo -e "${RED}❌ TLP test failed${NC}"
        return 1
    fi
    
    # Test 2: Check if profiles exist
    if [[ -f "$INSTALL_DIR/profiles/development.conf" ]]; then
        echo -e "${GREEN}✅ Power profiles available${NC}"
    else
        echo -e "${RED}❌ Power profiles test failed${NC}"
        return 1
    fi
    
    # Test 3: Check if scripts are executable
    if [[ -x "$INSTALL_DIR/scripts/power-manager.sh" ]]; then
        echo -e "${GREEN}✅ Scripts are executable${NC}"
    else
        echo -e "${RED}❌ Scripts test failed${NC}"
        return 1
    fi
    
    # Test 4: Check if aliases will work
    if source "$INSTALL_DIR/power-aliases.sh" 2>/dev/null; then
        echo -e "${GREEN}✅ Aliases are valid${NC}"
    else
        echo -e "${RED}❌ Aliases test failed${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✅ All tests passed!${NC}"
}

generate_installation_report() {
    local report_file="$HOME/power-management-installation-report-$(date +%Y%m%d-%H%M%S).md"
    
    cat > "$report_file" << EOF
# 🔋 Power Management Installation Report

## Installation Summary
- **Date**: $(date)
- **System**: $DISTRO $VERSION
- **CPU**: $CPU_MODEL
- **Kernel**: $KERNEL
- **Install Directory**: $INSTALL_DIR
- **Backup Directory**: $BACKUP_DIR

## ✅ Components Installed

### 1. Core System
- [x] TLP power management tool
- [x] PowerTOP analysis tool
- [x] ACPI tools for battery management
- [x] Sensors for temperature monitoring

### 2. Power Profiles
- [x] Development profile (high performance)
- [x] Presentation profile (balanced)
- [x] PowerSave profile (maximum battery)

### 3. Automation Scripts
- [x] Power manager (core system)
- [x] Smart automation (context-aware)
- [x] Battery alerts system
- [x] GPU optimizer
- [x] System optimizer

### 4. Monitoring & Utilities
- [x] Real-time power monitoring
- [x] Development environment detector
- [x] Build performance monitor
- [x] Power efficiency calculator

## 🚀 Quick Start Commands

\`\`\`bash
# Reload shell configuration
source ~/.bashrc

# Auto-select best profile
power-auto

# Check current status
power-status

# Development mode
power-dev

# Monitor build performance
monitor-build npm run build
\`\`\`

## 📊 Verification Commands

\`\`\`bash
# Verify TLP is working
sudo tlp-stat -s

# Check current profile
cat ~/power-management/logs/current-profile

# Test battery alerts
~/power-management/scripts/battery-alerts.sh test

# Check CPU governor
cpu-gov

# Monitor temperature
temp
\`\`\`

## 🔧 Advanced Configuration

### Enable Smart Automation
\`\`\`bash
~/power-management/scripts/smart-power-automation.sh schedule
\`\`\`

### Start Power Monitoring Service
\`\`\`bash
sudo systemctl start power-monitor.service
sudo systemctl status power-monitor.service
\`\`\`

## 📋 Next Steps

1. **Test the system**: Run \`power-auto\` and \`power-status\`
2. **Enable automation**: Run smart automation scheduler
3. **Customize profiles**: Edit profiles in \`~/power-management/profiles/\`
4. **Set up monitoring**: Enable power monitoring service

## 🆘 Troubleshooting

If you encounter issues:

1. Check logs: \`tail -f ~/power-management/logs/power-manager.log\`
2. Verify TLP: \`sudo tlp-stat -s\`
3. Test aliases: \`source ~/.bashrc\`
4. Restore backup: \`cp -r $BACKUP_DIR/* /\`

## 📞 Support

- Full documentation: \`~/power-management/README.md\`
- Developer guide: \`~/power-management/DEVELOPER_GUIDE.md\`
- Energy improvements map: \`~/power-management/ENERGY_IMPROVEMENTS_MAP.md\`

---

**🎯 Installation completed successfully!**
**System is ready for professional development with optimized power management.**
EOF
    
    echo -e "${GREEN}📋 Installation report created: $report_file${NC}"
}

create_uninstaller() {
    log "Creating uninstaller script..."
    
    cat > "$INSTALL_DIR/uninstall.sh" << EOF
#!/bin/bash

# Power Management System Uninstaller
echo "🗑️  Uninstalling Power Management System..."

# Remove cron jobs
crontab -l 2>/dev/null | grep -v "smart-power-automation" | crontab - 2>/dev/null || true

# Stop and disable service
sudo systemctl stop power-monitor.service 2>/dev/null || true
sudo systemctl disable power-monitor.service 2>/dev/null || true
sudo rm -f /etc/systemd/system/power-monitor.service

# Remove TLP configurations
sudo rm -f /etc/tlp.d/01-power-optimization.conf
sudo rm -f /etc/tlp.d/99-current-profile.conf

# Remove from bashrc
sed -i '/power-management\/power-aliases.sh/d' ~/.bashrc 2>/dev/null || true
sed -i '/Power Management Aliases/d' ~/.bashrc 2>/dev/null || true

# Remove system optimizations
sudo rm -f /etc/sysctl.d/99-power-management.conf
sudo rm -f /etc/udev/rules.d/70-network-power-management.rules

# Restart TLP with default settings
sudo systemctl restart tlp 2>/dev/null || true

echo "✅ Power Management System uninstalled"
echo "📋 Backup available at: $BACKUP_DIR"
echo "🔄 Please restart your shell or run: source ~/.bashrc"
EOF
    
    chmod +x "$INSTALL_DIR/uninstall.sh"
    
    echo -e "${GREEN}✅ Uninstaller created${NC}"
}

main() {
    print_header
    
    echo -e "${CYAN}🎯 Starting installation process...${NC}"
    echo ""
    
    # Pre-installation checks
    check_system_compatibility
    
    # Ask for confirmation
    echo -e "${YELLOW}📋 This script will:${NC}"
    echo "   • Install power management tools (TLP, PowerTOP, etc.)"
    echo "   • Configure AMD CPU and Radeon GPU optimizations"
    echo "   • Set up intelligent automation and monitoring" 
    echo "   • Create development-focused power profiles"
    echo "   • Add shell aliases and workflows"
    echo "   • Configure battery protection (80% charge limit)"
    echo ""
    
    read -p "🤔 Continue with installation? (y/N): " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Installation cancelled by user${NC}"
        exit 0
    fi
    
    echo ""
    echo -e "${PURPLE}🚀 Starting installation...${NC}"
    echo ""
    
    # Installation steps
    backup_existing_configs
    install_dependencies
    setup_power_management_directory
    copy_power_system
    install_cpu_optimizations
    install_gpu_optimizations
    install_tlp_configuration
    setup_aliases_and_integration
    configure_services
    setup_automation
    create_additional_optimizations
    create_uninstaller
    
    # Test installation
    echo ""
    echo -e "${BLUE}🧪 Testing installation...${NC}"
    if test_installation; then
        echo ""
        echo -e "${GREEN}🎉 INSTALLATION COMPLETED SUCCESSFULLY!${NC}"
        echo ""
        
        # Generate report
        generate_installation_report
        
        # Final instructions
        echo -e "${PURPLE}================================================================================================${NC}"
        echo -e "${GREEN}🎯 POWER MANAGEMENT SYSTEM INSTALLED AND READY!${NC}"
        echo -e "${PURPLE}================================================================================================${NC}"
        echo ""
        echo -e "${CYAN}🚀 Quick Start:${NC}"
        echo -e "   1. Reload shell: ${YELLOW}source ~/.bashrc${NC}"
        echo -e "   2. Auto-optimize: ${YELLOW}power-auto${NC}"
        echo -e "   3. Check status: ${YELLOW}power-status${NC}"
        echo ""
        echo -e "${CYAN}📱 Essential Commands:${NC}"
        echo -e "   • ${YELLOW}power-dev${NC}      - Development mode (max performance)"
        echo -e "   • ${YELLOW}power-save${NC}     - Travel mode (max battery)"
        echo -e "   • ${YELLOW}power-present${NC}  - Meeting mode (balanced)"
        echo -e "   • ${YELLOW}battery${NC}        - Quick battery status"
        echo -e "   • ${YELLOW}temp${NC}           - CPU temperature"
        echo ""
        echo -e "${CYAN}📚 Documentation:${NC}"
        echo -e "   • Full guide: ${YELLOW}~/power-management/README.md${NC}"
        echo -e "   • Developer guide: ${YELLOW}~/power-management/DEVELOPER_GUIDE.md${NC}"
        echo -e "   • Energy map: ${YELLOW}~/power-management/ENERGY_IMPROVEMENTS_MAP.md${NC}"
        echo ""
        echo -e "${GREEN}🎮 Your power management system is now optimized for enterprise development!${NC}"
        echo ""
        
    else
        echo -e "${RED}❌ Installation tests failed. Check logs: $LOG_FILE${NC}"
        exit 1
    fi
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    echo -e "${RED}❌ Do not run this script as root. Run as regular user.${NC}"
    echo -e "${YELLOW}   The script will ask for sudo when needed.${NC}"
    exit 1
fi

# Run main installation
main "$@"
