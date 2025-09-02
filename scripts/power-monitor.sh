#!/bin/bash

# =============================================================================
# Power Monitor Service - Continuous Power Management & Alerts
# =============================================================================

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly POWER_MANAGER="$SCRIPT_DIR/power-manager.sh"
readonly LOGS_DIR="$(dirname "$SCRIPT_DIR")/logs"
readonly MONITOR_LOG="$LOGS_DIR/monitor.log"
readonly PID_FILE="$LOGS_DIR/power-monitor.pid"

# Configuration
readonly CHECK_INTERVAL=60  # seconds
readonly LOW_BATTERY_THRESHOLD=20
readonly CRITICAL_BATTERY_THRESHOLD=10
readonly HIGH_TEMP_THRESHOLD=80
readonly HIGH_CPU_THRESHOLD=90

# Logging
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$MONITOR_LOG"
}

# Send desktop notification
notify() {
    local title="$1"
    local message="$2"
    local urgency="${3:-normal}"
    
    # Try to send notification to user session
    if command -v notify-send >/dev/null; then
        DISPLAY=:0 notify-send -u "$urgency" "🔋 $title" "$message"
    fi
    
    log "NOTIFICATION [$urgency]: $title - $message"
}

# Check if already running
check_running() {
    if [[ -f "$PID_FILE" ]]; then
        local pid
        pid=$(cat "$PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            echo "Power monitor already running (PID: $pid)"
            exit 1
        else
            rm -f "$PID_FILE"
        fi
    fi
}

# Cleanup on exit
cleanup() {
    log "Power monitor stopping..."
    rm -f "$PID_FILE"
    exit 0
}

# Monitor battery levels and auto-switch profiles
monitor_battery() {
    local current_level
    local power_source
    local time_remaining
    local battery_info
    
    battery_info=$("$POWER_MANAGER" status | grep "Battery" | head -1)
    current_level=$(acpi -b | grep -oP 'Battery \d+: \w+, \K\d+' | head -1)
    power_source=$(acpi -a | grep -q "on-line" && echo "AC" || echo "BAT")
    time_remaining=$(acpi -b | grep -oP '\d+:\d+:\d+' | head -1 || echo "N/A")
    
    # Critical battery warning
    if [[ "$power_source" == "BAT" ]] && (( current_level <= CRITICAL_BATTERY_THRESHOLD )); then
        notify "CRITICAL BATTERY!" "Battery at $current_level%! Save work immediately!" "critical"
        sudo "$POWER_MANAGER" apply powersave
    
    # Low battery warning
    elif [[ "$power_source" == "BAT" ]] && (( current_level <= LOW_BATTERY_THRESHOLD )); then
        notify "Low Battery Warning" "Battery at $current_level% - Time remaining: $time_remaining" "critical"
        sudo "$POWER_MANAGER" apply powersave
    
    # Power source changed - auto-adjust
    elif [[ -f "$LOGS_DIR/last-power-source" ]]; then
        local last_source
        last_source=$(cat "$LOGS_DIR/last-power-source")
        if [[ "$last_source" != "$power_source" ]]; then
            notify "Power Source Changed" "Switched to $power_source - Auto-adjusting profile" "normal"
            sudo "$POWER_MANAGER" auto
        fi
    fi
    
    echo "$power_source" > "$LOGS_DIR/last-power-source"
}

# Monitor CPU temperature and frequency
monitor_cpu() {
    local cpu_temp_num
    local cpu_load
    local cpu_freq
    
    cpu_temp_num=$(sensors 2>/dev/null | grep -i "package\|tctl\|core" | head -1 | grep -oP '\+\K\d+' | head -1 || echo "0")
    cpu_load=$(uptime | awk -F'[a-z]:' '{print $2}' | awk '{print $1}' | tr -d ',' | cut -d'.' -f1)
    cpu_freq=$(grep -r "cpu MHz" /proc/cpuinfo | head -1 | awk '{print $4}' | cut -d'.' -f1)
    
    # High temperature warning
    if (( cpu_temp_num >= HIGH_TEMP_THRESHOLD )); then
        notify "High CPU Temperature!" "CPU at ${cpu_temp_num}°C - Consider powersave mode" "critical"
    fi
    
    # High CPU load notification
    if (( cpu_load >= HIGH_CPU_THRESHOLD )); then
        log "High CPU load detected: ${cpu_load}% at ${cpu_freq}MHz"
    fi
}

# Monitor power-hungry processes
monitor_processes() {
    local high_cpu_processes
    
    # Get processes using >50% CPU
    high_cpu_processes=$(ps aux --sort=-%cpu | awk 'NR>1 && $3>50 {print $11 " (" $3 "%)"}' | head -3)
    
    if [[ -n "$high_cpu_processes" ]]; then
        log "High CPU processes detected: $high_cpu_processes"
    fi
}

# Main monitoring loop
monitor_loop() {
    log "Power monitor started (PID: $$)"
    echo "$$" > "$PID_FILE"
    
    trap cleanup EXIT INT TERM
    
    # Initial profile auto-selection
    sudo "$POWER_MANAGER" auto
    
    while true; do
        monitor_battery
        monitor_cpu
        monitor_processes
        
        sleep "$CHECK_INTERVAL"
    done
}

# Show monitor status
show_monitor_status() {
    if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        echo "✅ Power monitor is running (PID: $(cat "$PID_FILE"))"
        echo "📊 Last 5 log entries:"
        tail -5 "$MONITOR_LOG" 2>/dev/null || echo "No logs yet"
    else
        echo "❌ Power monitor is not running"
    fi
}

# Stop monitor
stop_monitor() {
    if [[ -f "$PID_FILE" ]]; then
        local pid
        pid=$(cat "$PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid"
            log "Power monitor stopped"
            echo "✅ Power monitor stopped"
        else
            rm -f "$PID_FILE"
            echo "❌ Power monitor was not running"
        fi
    else
        echo "❌ Power monitor is not running"
    fi
}

# Main function
main() {
    mkdir -p "$LOGS_DIR"
    
    case "${1:-help}" in
        "start")
            check_running
            monitor_loop
            ;;
        "stop")
            stop_monitor
            ;;
        "status")
            show_monitor_status
            ;;
        "restart")
            stop_monitor
            sleep 2
            check_running
            monitor_loop
            ;;
        *)
            echo "🔋 Power Monitor Service"
            echo ""
            echo "Usage: $0 {start|stop|status|restart}"
            echo ""
            echo "Commands:"
            echo "  start    - Start continuous monitoring"
            echo "  stop     - Stop monitoring service"
            echo "  status   - Show monitor status"
            echo "  restart  - Restart monitoring service"
            exit 1
            ;;
    esac
}

main "$@"
