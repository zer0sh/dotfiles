pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: systemService

    readonly property string cachePath: "/home/zero/.config/quickshell/system-info.json"

    property string osName: "Debian GNU/Linux 13 (trixie)"
    property string kernel: "6.12.113+deb13-amd64"
    property string cpu: "AMD Ryzen 7 7735HS with Radeon Graphics"
    property string ram: "30.1 GB"
    property string packages: "2,718 (dpkg)"
    property string hostname: "deb"
    property string uptime: "N/A"

    function parseData(raw) {
        if (!raw || raw.trim() === "") return;
        try {
            var parsed = JSON.parse(raw);
            if (parsed.distro) systemService.osName = parsed.distro;
            if (parsed.kernel) systemService.kernel = parsed.kernel;
            if (parsed.cpu_model) systemService.cpu = parsed.cpu_model;
            if (parsed.memory && parsed.memory.total_mb) {
                var gb = (parsed.memory.total_mb / 1024).toFixed(1);
                systemService.ram = gb + " GB";
            }
            if (parsed.packages) systemService.packages = parsed.packages;
            if (parsed.hostname) systemService.hostname = parsed.hostname;
            if (parsed.uptime) systemService.uptime = parsed.uptime;
        } catch (e) {
            console.warn("[SystemService] Error parsing system info:", e);
        }
    }

    property QtObject fileReader: FileView {
        path: systemService.cachePath
        blockLoading: true
        watchChanges: true
        onLoaded: systemService.parseData(fileReader.text())
        onFileChanged: systemService.parseData(fileReader.text())
    }

    property Process infoProc: Process {
        id: infoProc
        command: ["/usr/bin/python3", "/home/zero/.config/quickshell/scripts/system-info.py"]
    }

    function refresh() {
        if (!infoProc.running) {
            infoProc.running = true;
        }
    }

    Component.onCompleted: {
        parseData(fileReader.text());
        refresh();
    }
}
