#!/bin/bash

# =============================================================================
# GPU/Video Optimizer - AMD Radeon Graphics Power Management
# Optimized for AMD Barcelo (Ryzen 7 5825U integrated graphics)
# =============================================================================

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LOG_FILE="$(dirname "$SCRIPT_DIR")/logs/gpu-optimizer.log"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

# Get current GPU status
get_gpu_status() {
    local dpm_state
    local perf_level
    local gpu_freq
    
    dmp_state=$(cat /sys/class/drm/card*/device/power_dpm_state 2>/dev/null || echo "unknown")
    perf_level=$(cat /sys/class/drm/card*/device/power_dpm_force_performance_level 2>/dev/null || echo "unknown")
    
    echo "dmp_state=$dmp_state,perf_level=$perf_level"
}

# Optimize GPU for development workloads
optimize_gpu_for_development() {
    log "Optimizing GPU for development workloads..."
    
    echo "🎮 Activating GPU development mode..."
    
    # Set high performance DPM state
    for card in /sys/class/drm/card*; do
        if [[ -f "$card/device/power_dpm_state" ]]; then
            echo "performance" | sudo tee "$card/device/power_dpm_state" >/dev/null 2>&1 || true
            log "Set DPM state to performance for $card"
        fi
    done
    
    # Set high performance level
    for card in /sys/class/drm/card*; do
        if [[ -f "$card/device/power_dpm_force_performance_level" ]]; then
            echo "high" | sudo tee "$card/device/power_dpm_force_performance_level" >/dev/null 2>&1 || true
            log "Set performance level to high for $card"
        fi
    done
    
    # Optimize display power management for development
    for backlight in /sys/class/backlight/*; do
        if [[ -f "$backlight/brightness" ]] && [[ -f "$backlight/max_brightness" ]]; then
            local max_brightness
            max_brightness=$(cat "$backlight/max_brightness")
            local dev_brightness=$((max_brightness * 85 / 100))  # 85% for development
            echo "$dev_brightness" | sudo tee "$backlight/brightness" >/dev/null 2>&1 || true
            log "Set display brightness to 85% for development"
        fi
    done
    
    # Enable high performance mode for video decoding
    for card in /sys/class/drm/card*; do
        if [[ -f "$card/device/pp_power_profile_mode" ]]; then
            echo "1" | sudo tee "$card/device/pp_power_profile_mode" >/dev/null 2>&1 || true  # 3D Full Screen mode
            log "Set power profile to 3D mode for development"
        fi
    done
    
    echo "✅ GPU optimized for development workloads"
    log "GPU development optimization completed"
}

# Optimize GPU for battery saving
optimize_gpu_for_battery() {
    log "Optimizing GPU for battery saving..."
    
    echo "🔋 Activating GPU battery save mode..."
    
    # Set battery DPM state
    for card in /sys/class/drm/card*; do
        if [[ -f "$card/device/power_dpm_state" ]]; then
            echo "battery" | sudo tee "$card/device/power_dpm_state" >/dev/null 2>&1 || true
            log "Set DPM state to battery for $card"
        fi
    done
    
    # Set low performance level
    for card in /sys/class/drm/card*; do
        if [[ -f "$card/device/power_dpm_force_performance_level" ]]; then
            echo "low" | sudo tee "$card/device/power_dpm_force_performance_level" >/dev/null 2>&1 || true
            log "Set performance level to low for $card"
        fi
    done
    
    # Optimize display for battery (reduce brightness)
    for backlight in /sys/class/backlight/*; do
        if [[ -f "$backlight/brightness" ]] && [[ -f "$backlight/max_brightness" ]]; then
            local max_brightness
            max_brightness=$(cat "$backlight/max_brightness")
            local battery_brightness=$((max_brightness * 40 / 100))  # 40% for battery saving
            echo "$battery_brightness" | sudo tee "$backlight/brightness" >/dev/null 2>&1 || true
            log "Set display brightness to 40% for battery saving"
        fi
    done
    
    # Enable power saving mode for video
    for card in /sys/class/drm/card*; do
        if [[ -f "$card/device/pp_power_profile_mode" ]]; then
            echo "5" | sudo tee "$card/device/pp_power_profile_mode" >/dev/null 2>&1 || true  # Power Saving mode
            log "Set power profile to power saving mode"
        fi
    done
    
    echo "✅ GPU optimized for battery saving"
    log "GPU battery optimization completed"
}

# Optimize GPU for presentations/meetings
optimize_gpu_for_presentation() {
    log "Optimizing GPU for presentation mode..."
    
    echo "💼 Activating GPU presentation mode..."
    
    # Set balanced DPM state
    for card in /sys/class/drm/card*; do
        if [[ -f "$card/device/power_dpm_state" ]]; then
            echo "balanced" | sudo tee "$card/device/power_dpm_state" >/dev/null 2>&1 || true
            log "Set DPM state to balanced for $card"
        fi
    done
    
    # Set auto performance level (let GPU decide)
    for card in /sys/class/drm/card*; do
        if [[ -f "$card/device/power_dpm_force_performance_level" ]]; then
            echo "auto" | sudo tee "$card/device/power_dpm_force_performance_level" >/dev/null 2>&1 || true
            log "Set performance level to auto for $card"
        fi
    done
    
    # Optimize display for presentations (bright enough)
    for backlight in /sys/class/backlight/*; do
        if [[ -f "$backlight/brightness" ]] && [[ -f "$backlight/max_brightness" ]]; then
            local max_brightness
            max_brightness=$(cat "$backlight/max_brightness")
            local present_brightness=$((max_brightness * 75 / 100))  # 75% for presentations
            echo "$present_brightness" | sudo tee "$backlight/brightness" >/dev/null 2>&1 || true
            log "Set display brightness to 75% for presentations"
        fi
    done
    
    # Set video profile for presentations
    for card in /sys/class/drm/card*; do
        if [[ -f "$card/device/pp_power_profile_mode" ]]; then
            echo "2" | sudo tee "$card/device/pp_power_profile_mode" >/dev/null 2>&1 || true  # Video mode
            log "Set power profile to video mode for presentations"
        fi
    done
    
    echo "✅ GPU optimized for presentation mode"
    log "GPU presentation optimization completed"
}

# Show current GPU status
show_gpu_status() {
    echo "🎮 AMD Radeon Graphics Status"
    echo "============================"
    
    # GPU Driver
    local gpu_driver
    gpu_driver=$(cat /sys/class/drm/card*/device/driver 2>/dev/null | head -1 || echo "unknown")
    echo "📋 Driver: $gpu_driver"
    
    # DPM State
    local dmp_state
    dmp_state=$(cat /sys/class/drm/card*/device/power_dpm_state 2>/dev/null | head -1 || echo "unknown")
    echo "⚡ DPM State: $dmp_state"
    
    # Performance Level
    local perf_level
    perf_level=$(cat /sys/class/drm/card*/device/power_dpm_force_performance_level 2>/dev/null | head -1 || echo "unknown")
    echo "🎯 Performance Level: $perf_level"
    
    # Power Profile Mode
    local power_profile
    power_profile=$(cat /sys/class/drm/card*/device/pp_power_profile_mode 2>/dev/null | head -1 || echo "unknown")
    echo "🔧 Power Profile: $power_profile"
    
    # Display Brightness
    for backlight in /sys/class/backlight/*; do
        if [[ -f "$backlight/brightness" ]] && [[ -f "$backlight/max_brightness" ]]; then
            local current_brightness
            local max_brightness
            current_brightness=$(cat "$backlight/brightness")
            max_brightness=$(cat "$backlight/max_brightness")
            local brightness_percent=$((current_brightness * 100 / max_brightness))
            echo "💡 Display Brightness: ${brightness_percent}% (${current_brightness}/${max_brightness})"
            break
        fi
    done
    
    # GPU Memory Info
    if [[ -f "/sys/class/drm/card0/device/mem_info_vram_total" ]]; then
        local vram_total
        vram_total=$(cat /sys/class/drm/card0/device/mem_info_vram_total 2>/dev/null || echo "0")
        echo "💾 VRAM Total: $((vram_total / 1024 / 1024))MB"
    fi
    
    echo "============================"
}

# Test GPU optimization
test_gpu_optimization() {
    echo "🧪 Testing GPU optimization capabilities..."
    
    # Test if we can read GPU states
    if [[ -r "/sys/class/drm/card1/device/power_dpm_state" ]]; then
        echo "✅ GPU DPM state readable"
    else
        echo "❌ GPU DPM state not accessible"
    fi
    
    # Test if we can read performance levels
    if [[ -r "/sys/class/drm/card1/device/power_dpm_force_performance_level" ]]; then
        echo "✅ GPU performance level readable"
    else
        echo "❌ GPU performance level not accessible"
    fi
    
    # Test if we can control brightness
    local brightness_controllable=false
    for backlight in /sys/class/backlight/*; do
        if [[ -w "$backlight/brightness" ]]; then
            brightness_controllable=true
            break
        fi
    done
    
    if $brightness_controllable; then
        echo "✅ Display brightness controllable"
    else
        echo "❌ Display brightness not controllable (may need sudo)"
    fi
    
    # Test power profile modes
    if [[ -r "/sys/class/drm/card1/device/pp_power_profile_mode" ]]; then
        echo "✅ GPU power profile modes available"
        echo "📋 Available modes:"
        cat /sys/class/drm/card1/device/pp_power_profile_mode 2>/dev/null | head -10 || true
    else
        echo "❌ GPU power profile modes not available"
    fi
}

# Advanced GPU frequency monitoring
monitor_gpu_frequencies() {
    echo "📊 GPU Frequency Monitoring"
    echo "=========================="
    
    # Monitor GPU clocks if available
    for card in /sys/class/drm/card*; do
        if [[ -f "$card/device/pp_dpm_sclk" ]]; then
            echo "🔄 GPU Core Clock Levels:"
            cat "$card/device/pp_dpm_sclk" | head -10
        fi
        
        if [[ -f "$card/device/pp_dpm_mclk" ]]; then
            echo "💾 GPU Memory Clock Levels:"
            cat "$card/device/pp_dpm_mclk" | head -10
        fi
        break  # Only show first card
    done
}

# Display power management optimization
optimize_display_power() {
    echo "💡 Optimizing display power management..."
    
    # Get current brightness settings
    for backlight in /sys/class/backlight/*; do
        if [[ -f "$backlight/brightness" ]]; then
            local current=$(cat "$backlight/brightness")
            local max=$(cat "$backlight/max_brightness")
            local percent=$((current * 100 / max))
            echo "📊 Current brightness: ${percent}% (${current}/${max})"
        fi
    done
    
    # Check for multiple displays (presentation mode indicator)
    local display_count
    display_count=$(xrandr 2>/dev/null | grep -c " connected" || echo "1")
    echo "🖥️  Connected displays: $display_count"
    
    if (( display_count > 1 )); then
        echo "🔍 Multiple displays detected - optimizing for presentation"
        optimize_gpu_for_presentation
    fi
}

main() {
    # Ensure log directory exists
    mkdir -p "$(dirname "$LOG_FILE")"
    
    case "${1:-status}" in
        "dev"|"development")
            optimize_gpu_for_development
            ;;
        "save"|"battery"|"powersave")
            optimize_gpu_for_battery
            ;;
        "present"|"presentation"|"meeting")
            optimize_gpu_for_presentation
            ;;
        "status")
            show_gpu_status
            ;;
        "test")
            test_gpu_optimization
            ;;
        "monitor")
            monitor_gpu_frequencies
            ;;
        "display")
            optimize_display_power
            ;;
        *)
            echo "🎮 GPU/Video Optimizer - AMD Radeon Graphics"
            echo ""
            echo "Usage: $0 {dev|save|present|status|test|monitor|display}"
            echo ""
            echo "Commands:"
            echo "  dev         - Optimize for development (high performance)"
            echo "  save        - Optimize for battery saving (low power)"
            echo "  present     - Optimize for presentations (balanced)"
            echo "  status      - Show current GPU status"
            echo "  test        - Test GPU optimization capabilities"  
            echo "  monitor     - Monitor GPU frequencies"
            echo "  display     - Optimize display power management"
            echo ""
            echo "Examples:"
            echo "  $0 dev      # High performance for coding/builds"
            echo "  $0 save     # Battery saving for travel"
            echo "  $0 present  # Balanced for meetings/demos"
            echo ""
            exit 1
            ;;
    esac
}

main "$@"
