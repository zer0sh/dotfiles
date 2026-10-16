#!/usr/bin/env bash
# battery-log.sh — daemon ligero que registra el porcentaje de batería y el
# estado cada 5 minutos en ~/.cache/battery_history.log (para el histórico
# del panel de batería). Guarda solo las últimas 288 muestras (~24 h a
# 1 muestra/5 min) para mantener el archivo pequeño.
set -u

LOG="$HOME/.cache/battery_history.log"
BAT="/sys/class/power_supply/BAT0"

[ -d "$HOME/.cache" ] || mkdir -p "$HOME/.cache"

while true; do
    cap=""
    status=""
    if [ -r "$BAT/capacity" ]; then
        cap="$(cat "$BAT/capacity" 2>/dev/null)"
        status="$(cat "$BAT/status" 2>/dev/null)"
    fi
    echo "$(date +%s)${cap:+ $cap}${status:+ $status}" >> "$LOG"
    # rotar: mantener solo las últimas 288 líneas
    tail -n 288 "$LOG" > "$LOG.tmp" && mv "$LOG.tmp" "$LOG"
    sleep 300
done
