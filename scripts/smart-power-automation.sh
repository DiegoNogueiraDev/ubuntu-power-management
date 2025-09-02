#!/bin/bash

# =============================================================================
# Smart Power Automation - Context-Aware Profile Switching
# =============================================================================

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly POWER_MANAGER="$SCRIPT_DIR/power-manager.sh"
readonly LOGS_DIR="$(dirname "$SCRIPT_DIR")/logs"
readonly CONTEXT_LOG="$LOGS_DIR/context.log"

# Development indicators
readonly DEV_PROCESSES=("node" "npm" "yarn" "docker" "java" "python3" "code" "code-oss" "webstorm" "intellij")
readonly DEV_PORTS=("3000" "3001" "4200" "5000" "8000" "8080" "9000")

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$CONTEXT_LOG"
}

# Detect development context
detect_development_context() {
    local dev_score=0
    local process_count=0
    local port_count=0
    
    # Check for development processes
    for process in "${DEV_PROCESSES[@]}"; do
        if pgrep -f "$process" >/dev/null 2>&1; then
            ((process_count++))
            ((dev_score += 10))
        fi
    done
    
    # Check for development ports
    for port in "${DEV_PORTS[@]}"; do
        if netstat -tuln 2>/dev/null | grep -q ":$port "; then
            ((port_count++))
            ((dev_score += 5))
        fi
    done
    
    # Check for high CPU usage (compilation/building)
    local cpu_load
    cpu_load=$(uptime | awk -F'[a-z]:' '{print $2}' | awk '{print $1}' | tr -d ',' | cut -d'.' -f1 | sed 's/^0*//')
    if (( cpu_load > 70 )); then
        ((dev_score += 15))
    fi
    
    # Check for VS Code or IDEs
    if pgrep -f "code\|webstorm\|intellij" >/dev/null 2>&1; then
        ((dev_score += 20))
    fi
    
    echo "$dev_score"
}

# Detect presentation context
detect_presentation_context() {
    local present_score=0
    
    # Check for presentation software
    if pgrep -f "libreoffice\|firefox\|chrome\|zoom\|teams\|skype" >/dev/null 2>&1; then
        ((present_score += 20))
    fi
    
    # Check for external displays
    local display_count
    display_count=$(xrandr 2>/dev/null | grep -c " connected" || echo "1")
    if (( display_count > 1 )); then
        ((present_score += 15))
    fi
    
    # Check for webcam usage
    if lsof /dev/video* 2>/dev/null | grep -q video; then
        ((present_score += 10))
    fi
    
    echo "$present_score"
}

# Detect power-saving context
detect_powersave_context() {
    local save_score=0
    local battery_level
    local power_source
    
    # Get battery info
    battery_level=$(acpi -b | grep -oP 'Battery \d+: \w+, \K\d+' | head -1)
    power_source=$(acpi -a | grep -q "on-line" && echo "AC" || echo "BAT")
    
    # Low battery scenarios
    if [[ "$power_source" == "BAT" ]]; then
        if (( battery_level <= 30 )); then
            ((save_score += 50))
        elif (( battery_level <= 50 )); then
            ((save_score += 25))
        fi
    fi
    
    # Low CPU activity
    local cpu_load
    cpu_load=$(uptime | awk -F'[a-z]:' '{print $2}' | awk '{print $1}' | tr -d ',' | cut -d'.' -f1 | sed 's/^0*//')
    if [[ -n "$cpu_load" ]] && (( cpu_load < 20 )); then
        ((save_score += 15))
    fi
    
    # Evening hours (after 6 PM, before 9 AM)
    local current_hour
    current_hour=$(date '+%H')
    if (( current_hour >= 18 || current_hour <= 9 )); then
        ((save_score += 10))
    fi
    
    echo "$save_score"
}

# Intelligent profile selection
intelligent_profile_selection() {
    local dev_score
    local present_score
    local save_score
    local recommended_profile
    
    dev_score=$(detect_development_context)
    present_score=$(detect_presentation_context)  
    save_score=$(detect_powersave_context)
    
    log "Context scores - Development: $dev_score, Presentation: $present_score, PowerSave: $save_score"
    
    # Determine best profile based on scores
    if (( dev_score >= present_score && dev_score >= save_score && dev_score >= 30 )); then
        recommended_profile="development"
    elif (( present_score >= save_score && present_score >= 20 )); then
        recommended_profile="presentation"
    else
        recommended_profile="powersave"
    fi
    
    echo "$recommended_profile"
}

# Create desktop notification for profile change
notify_profile_change() {
    local profile="$1"
    local reason="$2"
    
    case "$profile" in
        "development")
            notify-send -u normal "🚀 Development Mode" "Switched to high-performance profile\nReason: $reason"
            ;;
        "presentation")
            notify-send -u normal "💼 Presentation Mode" "Switched to balanced profile\nReason: $reason"
            ;;
        "powersave")
            notify-send -u normal "🔋 Power Save Mode" "Switched to energy-saving profile\nReason: $reason"
            ;;
    esac
}

# Schedule automatic profile switching
schedule_automatic_switching() {
    local cron_job="*/5 * * * * /home/diego-nogueira/power-management/scripts/smart-power-automation.sh auto-check >/dev/null 2>&1"
    
    # Add to crontab if not already present
    if ! crontab -l 2>/dev/null | grep -q "smart-power-automation"; then
        (crontab -l 2>/dev/null; echo "$cron_job") | crontab -
        log "Automatic profile switching scheduled every 5 minutes"
        echo "✅ Automatic profile switching enabled (every 5 minutes)"
    else
        echo "✅ Automatic profile switching already enabled"
    fi
}

# Remove automatic switching
remove_automatic_switching() {
    crontab -l 2>/dev/null | grep -v "smart-power-automation" | crontab -
    log "Automatic profile switching disabled"
    echo "✅ Automatic profile switching disabled"
}

# Automatic check and switch (called by cron)
auto_check() {
    local current_profile
    local recommended_profile
    local battery_info
    
    current_profile=$(cat "$LOGS_DIR/current-profile" 2>/dev/null || echo "none")
    recommended_profile=$(intelligent_profile_selection)
    battery_info=$(acpi -b | head -1)
    
    if [[ "$current_profile" != "$recommended_profile" ]]; then
        log "Profile change needed: $current_profile -> $recommended_profile"
        sudo "$POWER_MANAGER" apply "$recommended_profile"
        notify_profile_change "$recommended_profile" "Auto-detected context change"
    fi
}

# Show context analysis
show_context() {
    local dev_score
    local present_score  
    local save_score
    local recommended
    
    dev_score=$(detect_development_context)
    present_score=$(detect_presentation_context)
    save_score=$(detect_powersave_context)
    recommended=$(intelligent_profile_selection)
    
    echo "🧠 INTELLIGENT CONTEXT ANALYSIS"
    echo "==============================="
    echo "🔧 Development Score: $dev_score"
    echo "💼 Presentation Score: $present_score"
    echo "🔋 PowerSave Score: $save_score"
    echo ""
    echo "🎯 Recommended Profile: $recommended"
    echo "==============================="
    
    # Show detected processes
    echo ""
    echo "🔍 Detected Development Processes:"
    for process in "${DEV_PROCESSES[@]}"; do
        if pgrep -f "$process" >/dev/null 2>&1; then
            echo "  ✅ $process"
        fi
    done
    
    echo ""
    echo "🌐 Active Development Ports:"
    for port in "${DEV_PORTS[@]}"; do
        if netstat -tuln 2>/dev/null | grep -q ":$port "; then
            echo "  ✅ Port $port"
        fi
    done
}

main() {
    mkdir -p "$LOGS_DIR"
    
    case "${1:-help}" in
        "analyze")
            show_context
            ;;
        "auto-apply")
            local recommended
            recommended=$(intelligent_profile_selection)
            echo "🎯 Recommended profile: $recommended"
            read -p "Apply this profile? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                sudo "$POWER_MANAGER" apply "$recommended"
                echo "✅ Profile applied: $recommended"
            fi
            ;;
        "auto-check")
            auto_check
            ;;
        "schedule")
            schedule_automatic_switching
            ;;
        "unschedule")
            remove_automatic_switching
            ;;
        *)
            echo "🧠 Smart Power Automation"
            echo ""
            echo "Usage: $0 {analyze|auto-apply|schedule|unschedule}"
            echo ""
            echo "Commands:"
            echo "  analyze     - Show context analysis and recommendations"
            echo "  auto-apply  - Recommend and optionally apply best profile"
            echo "  schedule    - Enable automatic profile switching (5-min intervals)"
            echo "  unschedule  - Disable automatic profile switching"
            echo ""
            exit 1
            ;;
    esac
}

main "$@"
