#!/usr/bin/env bash
# restart-quickshell.sh — reinicia Quickshell para recargar los cambios de QML.
# Uso: ./restart-quickshell.sh   (relanza y verifica la capa deskclock)
#      ./restart-quickshell.sh --validate  (solo valida el QML, sin reiniciar)
set -euo pipefail

SHELL_QML="$HOME/.config/quickshell/shell.qml"

validate() {
    echo "[1/3] Validando QML..."
    local log; log="$(mktemp)"
    timeout 6 qs -p "$SHELL_QML" >"$log" 2>&1 || true
    if grep -qiE "error|cannot|unavailable" "$log"; then
        echo "   (error) — revisa:"
        grep -iE "error|cannot|unavailable" "$log" | head
        rm -f "$log"
        return 1
    fi
    if grep -qiE "WARN" "$log"; then
        echo "   (aviso) warnings:"
        grep -iE "WARN" "$log" | head
    fi
    echo "   OK"
    rm -f "$log"
    return 0
}


restart() {
    echo "[2/3] Deteniendo Quickshell..."
    pkill -x quickshell 2>/dev/null || true
    pkill -f "qs -d -p $SHELL_QML" 2>/dev/null || true
    # (qs se mata con SIGTERM; la instancia daemonizada responde)
    sleep 2

    echo "[3/3] Relanzando Quickshell..."
    setsid nohup qs -d -p "$SHELL_QML" >/dev/null 2>&1 < /dev/null & disown
    sleep 4

    local pid; pid="$(pgrep -f "qs -d -p $SHELL_QML" | head -1 || pgrep -x quickshell | head -1 || true)"
    if [[ -z "$pid" ]]; then
        echo "   (error) Quickshell no arrancó."
        return 1
    fi
    echo "   Corriendo pid $pid"

    echo "  Capa deskclock:"
    hyprctl layers 2>/dev/null | grep -iE "namespace: quickshell:deskclock" || echo "   (no visible)"
}


if [[ "${1:-}" == "--validate" ]]; then
    validate
else
    validate && restart
fi
