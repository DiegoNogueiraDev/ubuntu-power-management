# =============================================================================
# Power Management Aliases - Quick Access Commands
# =============================================================================

# Quick profile switching
alias power-dev='sudo ~/power-management/scripts/power-manager.sh apply development'
alias power-save='sudo ~/power-management/scripts/power-manager.sh apply powersave'
alias power-present='sudo ~/power-management/scripts/power-manager.sh apply presentation'
alias power-auto='sudo ~/power-management/scripts/power-manager.sh auto'

# Status and monitoring
alias power-status='~/power-management/scripts/power-manager.sh status'
alias power-analyze='~/power-management/scripts/power-manager.sh analyze'
alias power-monitor='~/power-management/scripts/power-manager.sh monitor'

# Service management
alias power-service-start='~/power-management/scripts/power-monitor.sh start'
alias power-service-stop='~/power-management/scripts/power-monitor.sh stop'
alias power-service-status='~/power-management/scripts/power-monitor.sh status'

# Quick system info
alias battery='acpi -b && acpi -a'
alias cpu-freq='cat /proc/cpuinfo | grep "cpu MHz" | head -4'
alias cpu-gov='cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor | sort | uniq -c'
alias temp='sensors 2>/dev/null | grep -E "(Core|Package|Tctl)"'

# TLP utilities
alias tlp-status='sudo tlp-stat -s'
alias tlp-battery='sudo tlp-stat -b'
alias tlp-processor='sudo tlp-stat -p'
alias tlp-graphics='sudo tlp-stat -g'
alias tlp-disk='sudo tlp-stat -d'

# PowerTOP utilities  
alias powertop-report='sudo powertop --html=/tmp/powertop-$(date +%Y%m%d-%H%M%S).html'
alias powertop-auto='sudo powertop --auto-tune'

# Development specific power commands
alias dev-power-on='power-dev && ~/power-management/scripts/gpu-optimizer.sh dev && echo "🚀 Full development mode activated (CPU + GPU)!"'
alias meeting-power='power-present && ~/power-management/scripts/gpu-optimizer.sh present && echo "💼 Presentation mode activated (CPU + GPU)!"'
alias travel-power='power-save && ~/power-management/scripts/gpu-optimizer.sh save && echo "✈️ Travel mode activated (CPU + GPU)!"'

# GPU specific commands
alias gpu-status='~/power-management/scripts/gpu-optimizer.sh status'
alias gpu-dev='~/power-management/scripts/gpu-optimizer.sh dev'
alias gpu-save='~/power-management/scripts/gpu-optimizer.sh save'
alias gpu-present='~/power-management/scripts/gpu-optimizer.sh present'
alias gpu-monitor='~/power-management/scripts/gpu-optimizer.sh monitor'

echo "🔋 Power Management aliases loaded!"
echo "💡 Quick commands: power-dev, power-save, power-present, power-auto"
echo "📊 Monitoring: power-status, power-analyze, battery, temp"
