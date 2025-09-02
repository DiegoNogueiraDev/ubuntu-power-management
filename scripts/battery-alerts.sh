#!/bin/bash

# =============================================================================
# Battery Alert System - Advanced Notification Management
# =============================================================================

set -euo pipefail

readonly LOGS_DIR="$HOME/power-management/logs"
readonly ALERT_LOG="$LOGS_DIR/alerts.log"

# Alert thresholds
readonly CRITICAL_LEVEL=10
readonly LOW_LEVEL=20
readonly VERY_LOW_LEVEL=15
readonly FULL_LEVEL=95

# Alert intervals (to prevent spam)
readonly ALERT_INTERVAL=300  # 5 minutes

log_alert() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$ALERT_LOG"
}

# Check if alert was recently sent
should_send_alert() {
    local alert_type="$1"
    local last_alert_file="$LOGS_DIR/last-${alert_type}-alert"
    local current_time
    local last_alert_time
    
    current_time=$(date +%s)
    
    if [[ -f "$last_alert_file" ]]; then
        last_alert_time=$(cat "$last_alert_file")
        if (( current_time - last_alert_time < ALERT_INTERVAL )); then
            return 1  # Don't send alert
        fi
    fi
    
    echo "$current_time" > "$last_alert_file"
    return 0  # Send alert
}

# Send notification with sound and priority
send_notification() {
    local title="$1"
    local message="$2"
    local urgency="$3"
    local sound="$4"
    
    # Desktop notification
    DISPLAY=:0 notify-send -u "$urgency" -t 10000 "🔋 $title" "$message"
    
    # Sound notification (if available)
    if [[ "$sound" == "true" ]] && command -v paplay >/dev/null; then
        paplay /usr/share/sounds/alsa/Front_Left.wav 2>/dev/null &
    fi
    
    log_alert "$title: $message"
}

# Main battery monitoring
monitor_battery_alerts() {
    local battery_level
    local power_source
    local time_remaining
    local charging_status
    
    battery_level=$(acpi -b | grep -oP 'Battery \d+: \w+, \K\d+' | head -1)
    power_source=$(acpi -a | grep -q "on-line" && echo "AC" || echo "BAT")
    time_remaining=$(acpi -b | grep -oP '\d+:\d+:\d+' | head -1 || echo "N/A")
    charging_status=$(acpi -b | grep -oP 'Battery \d+: \K\w+' | head -1)
    
    # Critical battery
    if [[ "$power_source" == "BAT" ]] && (( battery_level <= CRITICAL_LEVEL )); then
        if should_send_alert "critical"; then
            send_notification "BATERIA CRÍTICA!" \
                "Nível: $battery_level% | Tempo restante: $time_remaining\n🚨 SALVE SEU TRABALHO IMEDIATAMENTE!" \
                "critical" "true"
        fi
        
    # Very low battery
    elif [[ "$power_source" == "BAT" ]] && (( battery_level <= VERY_LOW_LEVEL )); then
        if should_send_alert "very-low"; then
            send_notification "Bateria Muito Baixa" \
                "Nível: $battery_level% | Tempo restante: $time_remaining\n⚡ Conecte o carregador" \
                "critical" "true"
        fi
        
    # Low battery
    elif [[ "$power_source" == "BAT" ]] && (( battery_level <= LOW_LEVEL )); then
        if should_send_alert "low"; then
            send_notification "Bateria Baixa" \
                "Nível: $battery_level% | Tempo restante: $time_remaining\n🔌 Considere conectar o carregador" \
                "normal" "false"
        fi
        
    # Battery full
    elif [[ "$charging_status" == "Charging" ]] && (( battery_level >= FULL_LEVEL )); then
        if should_send_alert "full"; then
            send_notification "Bateria Carregada" \
                "Nível: $battery_level% | Status: $charging_status\n🔋 Considere desconectar o carregador" \
                "low" "false"
        fi
    fi
    
    # Power source change notifications
    local last_source_file="$LOGS_DIR/last-power-source-alert"
    if [[ -f "$last_source_file" ]]; then
        local last_source
        last_source=$(cat "$last_source_file")\n        if [[ "$last_source" != "$power_source" ]]; then\n            send_notification \"Fonte de Energia Alterada\" \\\n                \"Mudou para: $power_source | Bateria: $battery_level%\" \\\n                \"normal\" \"false\"\n        fi\n    fi\n    echo \"$power_source\" > \"$last_source_file\"\n}\n\n# Temperature monitoring\nmonitor_temperature_alerts() {\n    local cpu_temp_num\n    \n    cpu_temp_num=$(sensors 2>/dev/null | grep -i \"package\\|tctl\\|core\" | head -1 | grep -oP '\\+\\K\\d+' | head -1 || echo \"0\")\n    \n    if (( cpu_temp_num >= 85 )); then\n        if should_send_alert \"temp-critical\"; then\n            send_notification \"TEMPERATURA CRÍTICA!\" \\\n                \"CPU: ${cpu_temp_num}°C\\n🌡️ Sistema pode desligar automaticamente!\" \\\n                \"critical\" \"true\"\n        fi\n    elif (( cpu_temp_num >= 75 )); then\n        if should_send_alert \"temp-high\"; then\n            send_notification \"Temperatura Alta\" \\\n                \"CPU: ${cpu_temp_num}°C\\n🔥 Considere reduzir a carga de trabalho\" \\\n                \"normal\" \"false\"\n        fi\n    fi\n}\n\n# Power consumption alerts\nmonitor_power_consumption() {\n    local high_power_processes\n    \n    # Get top 3 power consuming processes\n    high_power_processes=$(ps aux --sort=-%cpu | awk 'NR>1 && $3>80 {print $11 \" (\" $3 \"%)\";}' | head -3)\n    \n    if [[ -n \"$high_power_processes\" ]] && should_send_alert \"high-consumption\"; then\n        send_notification \"Alto Consumo Detectado\" \\\n            \"Processos: $high_power_processes\\n⚡ Considere otimizar ou fechar aplicações\" \\\n            \"normal\" \"false\"\n    fi\n}\n\nmain() {\n    mkdir -p \"$LOGS_DIR\"\n    \n    case \"${1:-monitor}\" in\n        \"monitor\")\n            while true; do\n                monitor_battery_alerts\n                monitor_temperature_alerts\n                monitor_power_consumption\n                sleep 60\n            done\n            ;;\n        \"test\")\n            echo \"🧪 Testing notification system...\"\n            send_notification \"Teste do Sistema\" \"Sistema de alertas funcionando corretamente!\" \"normal\" \"false\"\n            ;;\n        \"status\")\n            echo \"📊 Alert System Status\"\n            echo \"=====================\"\n            echo \"📁 Logs directory: $LOGS_DIR\"\n            echo \"📝 Alert log: $ALERT_LOG\"\n            if [[ -f \"$ALERT_LOG\" ]]; then\n                echo \"📈 Recent alerts (last 5):\"\n                tail -5 \"$ALERT_LOG\"\n            else\n                echo \"📭 No alerts logged yet\"\n            fi\n            ;;\n        *)\n            echo \"🔔 Battery Alert System\"\n            echo \"\"\n            echo \"Usage: $0 {monitor|test|status}\"\n            echo \"\"\n            echo \"Commands:\"\n            echo \"  monitor  - Start continuous alert monitoring\"\n            echo \"  test     - Test notification system\"\n            echo \"  status   - Show alert system status\"\n            exit 1\n            ;;\n    esac\n}\n\nmain \"$@\""}}
</function_results>

<function_calls>
<invoke name="run_command">
<parameter name="command">chmod +x ~/power-management/scripts/battery-alerts.sh
