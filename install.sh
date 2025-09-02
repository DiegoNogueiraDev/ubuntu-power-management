#!/bin/bash

# =============================================================================
# Power Management System Installer
# Professional Energy Management for AMD Ryzen Development Environment
# =============================================================================

set -euo pipefail

readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Progress tracking
readonly TOTAL_STEPS=8
CURRENT_STEP=0

print_step() {
    ((CURRENT_STEP++))
    echo -e "${BLUE}[${CURRENT_STEP}/${TOTAL_STEPS}]${NC} $1"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
    exit 1
}

# Check if running on supported system
check_system() {
    print_step "Checking system compatibility..."
    
    if [[ ! -f /etc/lsb-release ]] || ! grep -q "Ubuntu" /etc/lsb-release; then
        print_error "This installer is designed for Ubuntu systems"
    fi
    
    if [[ $EUID -eq 0 ]]; then
        print_error "Do not run this installer as root"
    fi
    
    print_success "System compatibility verified"
}

# Install required packages
install_packages() {
    print_step "Installing required packages..."
    
    sudo apt update
    sudo apt install -y \
        acpi \
        tlp \
        tlp-rdw \
        powertop \
        cpufrequtils \
        linux-tools-common \
        linux-tools-generic \
        libnotify-bin \
        lm-sensors
    
    print_success "Packages installed successfully"
}

# Setup TLP configuration
setup_tlp() {
    print_step "Configuring TLP for AMD Ryzen..."
    
    # Backup original config
    if [[ ! -f /etc/tlp.conf.backup ]]; then
        sudo cp /etc/tlp.conf /etc/tlp.conf.backup
    fi
    
    # Create TLP directory
    sudo mkdir -p /etc/tlp.d
    
    # Copy optimized configuration
    sudo cp ~/power-management/tlp-power-optimization.conf /etc/tlp.d/01-power-optimization.conf
    
    # Enable and start TLP
    sudo systemctl enable tlp
    sudo systemctl start tlp
    
    print_success "TLP configured and activated"
}

# Setup power profiles
setup_profiles() {
    print_step "Setting up power profiles..."
    
    # Verify profiles exist
    for profile in development presentation powersave; do
        if [[ ! -f ~/power-management/profiles/${profile}.conf ]]; then
            print_error "Profile not found: ${profile}.conf"
        fi
    done
    
    print_success "Power profiles verified"
}

# Setup automation scripts
setup_scripts() {
    print_step "Configuring automation scripts..."
    
    # Make scripts executable
    chmod +x ~/power-management/scripts/*.sh
    
    # Test power manager
    if ! ~/power-management/scripts/power-manager.sh status >/dev/null; then
        print_error "Power manager script test failed"
    fi
    
    print_success "Automation scripts configured"
}

# Setup aliases
setup_aliases() {
    print_step "Installing command aliases..."
    
    # Check if aliases already added
    if ! grep -q "Power Management Aliases" ~/.bashrc; then
        echo "# Power Management Aliases" >> ~/.bashrc
        echo "source ~/power-management/power-aliases.sh" >> ~/.bashrc
    fi
    
    print_success "Aliases installed"
}

# Initialize monitoring
setup_monitoring() {
    print_step "Initializing monitoring system..."
    
    # Create logs directory
    mkdir -p ~/power-management/logs
    
    # Calibrate PowerTOP (quick calibration)
    print_warning "Running PowerTOP calibration (this may take a few minutes)..."
    sudo powertop --calibrate >/dev/null 2>&1 || print_warning "PowerTOP calibration had warnings (normal)"
    
    # Test notifications
    if command -v notify-send >/dev/null; then
        DISPLAY=:0 notify-send "🔋 Power Management" "System installed successfully!" || print_warning "Desktop notifications may not work in current session"
    fi
    
    print_success "Monitoring system initialized"
}

# Final configuration
finalize_setup() {
    print_step "Finalizing installation..."
    
    # Apply initial optimized profile
    sudo ~/power-management/scripts/power-manager.sh auto
    
    # Create desktop shortcut (if desktop environment available)
    if [[ -d ~/Desktop ]] || [[ -d ~/.local/share/applications ]]; then
        cat > ~/.local/share/applications/power-manager.desktop << EOF
[Desktop Entry]
Version=1.0
Name=Power Manager
Comment=Professional Power Management System
Exec=gnome-terminal -- ~/power-management/scripts/power-manager.sh status
Icon=battery
Terminal=true
Type=Application
Categories=System;Monitor;
EOF
    fi
    
    print_success "Installation finalized"
}

# Post-installation information
show_completion_info() {
    clear
    echo -e "${GREEN}"
    echo "🎉 POWER MANAGEMENT SYSTEM INSTALLED SUCCESSFULLY!"
    echo "=================================================="
    echo -e "${NC}"
    echo ""
    echo -e "${BLUE}🚀 Quick Start Commands:${NC}"
    echo "  power-dev       - Development mode (high performance)"
    echo "  power-save      - Power saving mode"
    echo "  power-present   - Presentation mode"
    echo "  power-auto      - Auto-select best profile"
    echo "  power-status    - Show current status"
    echo "  battery         - Quick battery info"
    echo ""
    echo -e "${BLUE}🤖 Smart Automation:${NC}"
    echo "  ~/power-management/scripts/smart-power-automation.sh analyze"
    echo "  ~/power-management/scripts/smart-power-automation.sh schedule"
    echo ""
    echo -e "${BLUE}📊 Monitoring:${NC}"
    echo "  power-monitor                    # Real-time monitoring"
    echo "  ~/power-management/scripts/battery-alerts.sh monitor"
    echo ""
    echo -e "${YELLOW}⚠️  Important Notes:${NC}"
    echo "  • Run 'source ~/.bashrc' to load aliases in current session"
    echo "  • Battery charge limit set to 80% for longevity"
    echo "  • Auto-profile switching available via cron scheduling"
    echo "  • All configurations optimized for your AMD Ryzen 7 5825U"
    echo ""
    echo -e "${GREEN}📖 Full documentation: ~/power-management/README.md${NC}"
    echo ""
    echo -e "${BLUE}🔋 Current Status:${NC}"
    ~/power-management/scripts/power-manager.sh status
}

# Main installation flow
main() {
    echo -e "${BLUE}"
    echo "🔋 Professional Power Management System Installer"
    echo "================================================="
    echo "Optimized for AMD Ryzen 7 5825U + Ubuntu 24.04"
    echo -e "${NC}"
    echo ""
    
    read -p "Proceed with installation? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation cancelled."
        exit 0
    fi
    
    echo ""
    echo "🚀 Starting installation..."
    echo ""
    
    check_system
    install_packages
    setup_tlp
    setup_profiles
    setup_scripts
    setup_aliases
    setup_monitoring
    finalize_setup
    
    echo ""
    show_completion_info
}

main "$@"
