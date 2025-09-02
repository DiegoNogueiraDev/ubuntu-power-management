#!/bin/bash

# =============================================================================
# Power Management Script - Professional Energy Management
# Author: AI Assistant for Senior Full Stack Developer
# =============================================================================

set -euo pipefail

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROFILES_DIR="$(dirname "$SCRIPT_DIR")/profiles"
readonly LOGS_DIR="$(dirname "$SCRIPT_DIR")/logs"
readonly LOG_FILE="$LOGS_DIR/power-manager.log"
readonly CURRENT_PROFILE_FILE="$LOGS_DIR/current-profile"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

# Error handling
error_exit() {
    log "ERROR: $1" >&2
    exit 1
}

# Check if running as root for system changes
check_privileges() {
    if [[ $EUID -ne 0 ]] && [[ "$1" == "apply" ]]; then
        error_exit "Root privileges required for applying profiles. Use: sudo $0 $*"
    fi
}

# Get current battery status
get_battery_info() {
    local battery_level
    local power_source
    local time_remaining
    
    battery_level=$(acpi -b | grep -oP 'Battery \d+: \w+, \K\d+' | head -1)
    power_source=$(acpi -a | grep -q "on-line" && echo "AC" || echo "BAT")
    time_remaining=$(acpi -b | grep -oP '\d+:\d+:\d+' | head -1 || echo "N/A")
    
    echo "level=$battery_level,source=$power_source,remaining=$time_remaining"
}

# Get current CPU frequency and load
get_cpu_info() {
    local cpu_freq
    local cpu_load
    local cpu_temp
    
    cpu_freq=$(grep -r "cpu MHz" /proc/cpuinfo | head -1 | awk '{print $4}' | cut -d'.' -f1)
    cpu_load=$(uptime | awk -F'[a-z]:' '{print $2}' | awk '{print $1}' | tr -d ',')
    cpu_temp=$(sensors 2>/dev/null | grep -i "package\|tctl\|core" | head -1 | grep -oP '\+\d+\.\d+°C' | head -1 || echo "N/A")
    
    echo "freq=${cpu_freq}MHz,load=$cpu_load,temp=$cpu_temp"
}

# Apply TLP profile
apply_profile() {
    local profile_name="$1"
    local profile_file="$PROFILES_DIR/$profile_name.conf"
    
    if [[ ! -f "$profile_file" ]]; then
        error_exit "Profile not found: $profile_file"
    fi
    
    log "Applying profile: $profile_name"
    
    # Copy profile to TLP directory
    cp "$profile_file" "/etc/tlp.d/99-current-profile.conf"
    
    # Restart TLP to apply new settings
    systemctl restart tlp
    tlp start
    
    # Save current profile
    echo "$profile_name" > "$CURRENT_PROFILE_FILE"
    
    log "Profile applied successfully: $profile_name"
}

# Auto-select profile based on battery level and power source
auto_select_profile() {
    local battery_info
    local battery_level
    local power_source
    
    battery_info=$(get_battery_info)
    battery_level=$(echo "$battery_info" | cut -d',' -f1 | cut -d'=' -f2)
    power_source=$(echo "$battery_info" | cut -d',' -f2 | cut -d'=' -f2)
    
    log "Auto-selection: Battery $battery_level%, Power source: $power_source"
    
    if [[ "$power_source" == "AC" ]]; then
        if (( battery_level >= 80 )); then
            echo "development"
        elif (( battery_level >= 50 )); then
            echo "presentation"
        else
            echo "powersave"
        fi
    else
        if (( battery_level >= 60 )); then
            echo "presentation"
        elif (( battery_level >= 30 )); then
            echo "powersave"
        else
            echo "powersave"
        fi
    fi
}

# Status monitoring
show_status() {
    local battery_info
    local cpu_info
    local current_profile
    
    battery_info=$(get_battery_info)
    cpu_info=$(get_cpu_info)
    current_profile=$(cat "$CURRENT_PROFILE_FILE" 2>/dev/null || echo "default")
    
    echo "=================================="
    echo "🔋 POWER MANAGEMENT STATUS"
    echo "=================================="
    echo "📊 Battery: $(echo "$battery_info" | tr ',' '\n' | sed 's/=/ = /')"
    echo "🖥️  CPU: $(echo "$cpu_info" | tr ',' '\n' | sed 's/=/ = /')"
    echo "⚙️  Profile: $current_profile"
    echo "⏰ Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "=================================="
}

# Power consumption analysis
analyze_power() {
    log "Starting power analysis..."
    
    echo "🔍 Power Consumption Analysis"
    echo "=============================="
    
    # Run PowerTOP for 30 seconds
    echo "📊 Collecting power data (30s)..."
    timeout 30s powertop --html=/tmp/powertop-report.html &>/dev/null || true
    
    # Show top power consumers
    echo "🔋 Current Power Status:"
    acpi -b -a
    
    echo ""
    echo "⚡ CPU Governor Status:"
    cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor | sort | uniq -c
    
    echo ""
    echo "🌡️  Thermal Status:"
    sensors 2>/dev/null | grep -E "(Core|Package|Tctl)" || echo "No thermal sensors found"
    
    echo ""
    echo "📈 Top 5 Power Consuming Processes:"
    ps aux --sort=-%cpu | head -6
    
    log "Power analysis completed"
}

# Main function
main() {
    # Ensure log directory exists
    mkdir -p "$LOGS_DIR"
    
    case "${1:-status}" in
        "apply")
            check_privileges "$@"
            if [[ -z "${2:-}" ]]; then
                error_exit "Profile name required. Available: development, presentation, powersave"
            fi
            apply_profile "$2"
            ;;
        "auto")
            check_privileges "$@"
            local selected_profile
            selected_profile=$(auto_select_profile)
            log "Auto-selected profile: $selected_profile"
            apply_profile "$selected_profile"
            ;;
        "status")
            show_status
            ;;
        "analyze")
            analyze_power
            ;;
        "monitor")
            while true; do
                clear
                show_status
                sleep 10
            done
            ;;
        *)
            echo "🔋 Power Manager - Professional Energy Management"
            echo ""
            echo "Usage: $0 {apply|auto|status|analyze|monitor}"
            echo ""
            echo "Commands:"
            echo "  apply <profile>  - Apply specific profile (development|presentation|powersave)"
            echo "  auto            - Auto-select and apply best profile"
            echo "  status          - Show current power status"
            echo "  analyze         - Detailed power consumption analysis"
            echo "  monitor         - Real-time status monitoring"
            echo ""
            echo "Examples:"
            echo "  $0 apply development    # Apply development profile"
            echo "  $0 auto                # Auto-select best profile"
            echo "  $0 status              # Show current status"
            exit 1
            ;;
    esac
}

main "$@"
