pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: manager

    readonly property string configPath: "/home/zero/.config/quickshell/gadgets.json"

    // Central definition of all available desktop gadgets
    readonly property var availableGadgets: [
        {
            id: "deskclock",
            name: "Desk Clock",
            desc: "Floating digital clock with dynamic greetings and day progress bar",
            icon: "󰥔"
        },
        {
            id: "calendar",
            name: "Desktop Calendar",
            desc: "Interactive monthly calendar with month navigation and today highlight",
            icon: "󰸗"
        },
        {
            id: "weather",
            name: "Weather Forecast",
            desc: "Weather widget showing current conditions and 2-day forecast",
            icon: "󰖐"
        }
    ]

    property var stateMap: ({
        "deskclock": { "enabled": true, "x": 1420, "y": 100 },
        "calendar":  { "enabled": true, "x": 100,  "y": 700 },
        "weather":   { "enabled": true, "x": 1420, "y": 520 }
    })

    signal stateChanged()

    // ── Lectura persistente al iniciar ───────────────────────────
    property Process readProc: Process {
        id: readProc
        command: ["/bin/sh", "-c", "cat " + manager.configPath + " 2>/dev/null || true"]
        stdout: StdioCollector {
            onStreamFinished: {
                var raw = text.trim();
                if (raw !== "") {
                    try {
                        var parsed = JSON.parse(raw);
                        if (parsed && typeof parsed === "object") {
                            var updated = Object.assign({}, manager.stateMap);
                            for (var k in parsed) {
                                if (parsed.hasOwnProperty(k)) {
                                    updated[k] = Object.assign({}, updated[k] || {}, parsed[k]);
                                }
                            }
                            manager.stateMap = updated;
                            manager.stateChanged();
                        }
                    } catch (e) {
                        console.warn("[GadgetsManager] Error al parsear gadgets.json:", e);
                    }
                }
            }
        }
    }

    // ── Escritura persistente en segundo plano ───────────────────
    property Process saveProc: Process {
        id: saveProc
    }

    function saveState() {
        if (saveProc.running) saveProc.running = false;
        var jsonStr = JSON.stringify(manager.stateMap, null, 2);
        saveProc.command = [
            "/bin/sh", "-c",
            "mkdir -p ~/.config/quickshell && printf '%s\\n' '" +
            jsonStr.replace(/'/g, "'\\''") +
            "' > " + manager.configPath
        ];
        saveProc.running = true;
        manager.stateChanged();
    }

    function isEnabled(gadgetId) {
        if (manager.stateMap[gadgetId] && manager.stateMap[gadgetId].enabled !== undefined) {
            return manager.stateMap[gadgetId].enabled;
        }
        return true;
    }

    function setEnabled(gadgetId, enabled) {
        var updated = Object.assign({}, manager.stateMap);
        if (!updated[gadgetId]) {
            updated[gadgetId] = { enabled: true, x: 100, y: 100 };
        }
        updated[gadgetId].enabled = enabled;
        manager.stateMap = updated;
        saveState();
    }

    function toggle(gadgetId) {
        setEnabled(gadgetId, !isEnabled(gadgetId));
    }

    function getPosition(gadgetId, defaultX, defaultY) {
        if (manager.stateMap[gadgetId]) {
            var x = manager.stateMap[gadgetId].x !== undefined ? manager.stateMap[gadgetId].x : defaultX;
            var y = manager.stateMap[gadgetId].y !== undefined ? manager.stateMap[gadgetId].y : defaultY;
            return { x: x, y: y };
        }
        return { x: defaultX, y: defaultY };
    }

    function setPosition(gadgetId, x, y) {
        var updated = Object.assign({}, manager.stateMap);
        if (!updated[gadgetId]) {
            updated[gadgetId] = { enabled: true, x: x, y: y };
        } else {
            updated[gadgetId].x = x;
            updated[gadgetId].y = y;
        }
        manager.stateMap = updated;
        saveState();
    }

    // ── IPC Handler para manipulación remota ─────────────────────
    property IpcHandler ipcHandler: IpcHandler {
        target: "gadgets"
        function toggle(id: string): void {
            if (id && id !== "") manager.toggle(id);
        }
        function show(id: string): void {
            if (id && id !== "") manager.setEnabled(id, true);
        }
        function hide(id: string): void {
            if (id && id !== "") manager.setEnabled(id, false);
        }
    }

    Component.onCompleted: {
        readProc.running = true;
    }
}
