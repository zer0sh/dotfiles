pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: lockService

    readonly property string scriptPath: "/home/zero/.config/quickshell/scripts/lock-manager.py"

    property bool enabled: true
    property int timeoutSeconds: 300
    property string formattedTime: "5 minutes"
    property bool isSaving: false
    property string statusMessage: ""

    // Presets in minutes/seconds for quick selection
    readonly property var presetOptions: [
        { label: "1 min", seconds: 60, desc: "1 minute" },
        { label: "2 min", seconds: 120, desc: "2 minutes" },
        { label: "5 min", seconds: 300, desc: "5 minutes (Default)" },
        { label: "10 min", seconds: 600, desc: "10 minutes" },
        { label: "15 min", seconds: 900, desc: "15 minutes" },
        { label: "25 min", seconds: 1500, desc: "25 minutes" },
        { label: "30 min", seconds: 1800, desc: "30 minutes" },
        { label: "1 hour", seconds: 3600, desc: "60 minutes" }
    ]

    signal lockSettingsChanged()

    function parseData(raw) {
        if (!raw || raw.trim() === "") return;
        try {
            var data = JSON.parse(raw.trim());
            if (typeof data.enabled === "boolean") lockService.enabled = data.enabled;
            if (typeof data.timeout === "number") lockService.timeoutSeconds = data.timeout;
            if (data.formatted) lockService.formattedTime = data.formatted;
            lockService.lockSettingsChanged();
        } catch (e) {
            console.warn("[LockService] Error parsing lock config JSON:", e);
        }
    }

    // Process to read current lock configuration
    property Process getProc: Process {
        id: getProc
        command: ["/usr/bin/python3", lockService.scriptPath, "get"]
        stdout: StdioCollector {
            onStreamFinished: {
                lockService.parseData(text);
            }
        }
    }

    // Process to update lock configuration
    property Process setProc: Process {
        id: setProc
        stdout: StdioCollector {
            onStreamFinished: {
                lockService.isSaving = false;
                lockService.parseData(text);
                lockService.statusMessage = "Lock timeout updated successfully";
            }
        }
        onExited: (code, status) => {
            lockService.isSaving = false;
        }
    }

    // Process to trigger hyprlock immediately
    property Process lockNowProc: Process {
        id: lockNowProc
        command: ["hyprlock"]
    }

    function refresh() {
        if (!getProc.running) {
            getProc.running = true;
        }
    }

    function setTimeout(seconds) {
        if (setProc.running) return;
        isSaving = true;
        setProc.command = ["/usr/bin/python3", lockService.scriptPath, "set", seconds.toString()];
        setProc.running = true;
    }

    function toggleEnabled(enable) {
        if (setProc.running) return;
        isSaving = true;
        if (enable) {
            var target = lockService.timeoutSeconds > 0 ? lockService.timeoutSeconds : 300;
            setProc.command = ["/usr/bin/python3", lockService.scriptPath, "set", target.toString()];
        } else {
            setProc.command = ["/usr/bin/python3", lockService.scriptPath, "disable"];
        }
        setProc.running = true;
    }

    function lockNow() {
        if (!lockNowProc.running) {
            lockNowProc.running = true;
        }
    }

    Component.onCompleted: {
        refresh();
    }
}
