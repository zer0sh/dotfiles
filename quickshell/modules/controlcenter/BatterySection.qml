import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Io
import "../.." as Root

// Battery Sub-Page — estado actual de la batería y un histórico sencillo
// "tipo Android" (gráfico de barras del porcentaje a lo largo del tiempo).
// Parent navega aquí vía currentPage = "battery"; back() regresa a main.
Item {
    id: batteryPanel

    signal back()

    property int percent: 0
    property string state: "Unknown"   // charging / discharging / full / Unknown
    property var history: []           // [{t: "", pct: number}, ...]

    // ── Estado en vivo ────────────────────────────────────────────
    Process {
        id: statusProc
        command: ["upower", "-i", "/org/freedesktop/UPower/devices/battery_BAT0"]
        stdout: StdioCollector {
            onStreamFinished: {
                var line, form;
                var lines = text.split("\n")
                for (var i = 0; i < lines.length; i++) {
                    line = lines[i]
                    if (line.indexOf("percentage:") >= 0) {
                        form = line.split(":")[1].trim()
                        var pct = parseInt(form)
                        batteryPanel.percent = isNaN(pct) ? 0 : pct
                    } else if (line.indexOf("state:") >= 0) {
                        batteryPanel.state = line.split(":")[1].trim()
                    }
                }
            }
        }
    }

    // ── Histórico (lee el log generado por battery-log.sh) ────────
    Process {
        id: histProc
        command: ["/bin/sh", "-c",
            "tail -n 288 ~/.cache/battery_history.log 2>/dev/null | " +
            "awk '{print $1, ($2+0), $3}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                batteryPanel.loadHistory(text)
            }
        }
    }

    function pad(n) { return n < 10 ? "0" + n : "" + n }

    function loadHistory(raw) {
        var out = []
        var lines = raw.trim().split("\n")
        var now = new Date()
        // fecha de hoy a medianoche para presentar la hora local
        for (var i = 0; i < lines.length; i++) {
            var parts = lines[i].trim().split(/\s+/)
            if (parts.length < 2) continue
            var ts = parseInt(parts[0])
            var pct = parseInt(parts[1])
            if (isNaN(ts) || isNaN(pct)) continue
            var d = new Date(ts * 1000)
            // horas desplazadas a H:mm
            out.push({ t: pad(d.getHours()) + ":" + pad(d.getMinutes()), pct: pct })
        }
        // muestra solo las últimas 24 muestras (2h a 5 min) para el gráfico
        batteryPanel.history = out.slice(-24)
    }

    Component.onCompleted: {
        statusProc.running = true
        histProc.running = true
    }

    // ── UI ────────────────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Header
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 64

            Rectangle { anchors.fill: parent; radius: Root.Theme.panelRadius; color: Root.Theme.surface }
            Rectangle { anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; height: Root.Theme.panelRadius; color: Root.Theme.surface }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Root.Theme.paddingNormal
                anchors.rightMargin: Root.Theme.paddingNormal
                spacing: 10

                Rectangle {
                    width: 38; height: 38; radius: Root.Theme.radiusSmall
                    color: backArea.containsMouse ? Root.Theme.surfaceContainerHigh : "transparent"
                    Text {
                        anchors.centerIn: parent
                        text: "󰁍"
                        color: backArea.containsMouse ? Root.Theme.textPrimary : Root.Theme.textSecondary
                        font.family: Root.Theme.fontFamily; font.pixelSize: Root.Theme.fontSizeLarge
                    }
                    MouseArea {
                        id: backArea; anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: batteryPanel.back()
                    }
                }

                Text {
                    text: "Battery"
                    color: Root.Theme.textPrimary
                    font.family: Root.Theme.fontFamily; font.pixelSize: Root.Theme.fontSizeLarge
                    font.weight: Font.DemiBold
                    Layout.fillWidth: true
                }
            }

            Rectangle { anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; height: 1; color: Root.Theme.surfaceContainerHigh }
        }

        // Cuerpo
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Root.Theme.paddingNormal
                spacing: Root.Theme.spacingLarge

                Item { Layout.fillHeight: true }

                // Icono + porcentaje grande
                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    width: 110; height: 110
                    radius: 55
                    color: Root.Theme.surfaceContainer
                    border.color: batteryPanel.batteryColor()
                    border.width: 2

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 0
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "󰁹"
                            font.family: Root.Theme.fontFamily; font.pixelSize: 40
                            color: batteryPanel.batteryColor()
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: batteryPanel.percent + "%"
                            font.family: Root.Theme.fontFamily; font.pixelSize: 26; font.weight: Font.Bold
                            color: Root.Theme.textPrimary
                        }
                    }
                }

                // Estado
                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: batteryPanel.stateLabel()
                    font.family: Root.Theme.fontFamily; font.pixelSize: Root.Theme.fontSizeNormal
                    color: Root.Theme.textSecondary
                }

                // Histórico
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Text {
                        text: "History"
                        color: Root.Theme.textSecondary
                        font.family: Root.Theme.fontFamily; font.pixelSize: Root.Theme.fontSizeXS
                        font.weight: Font.DemiBold
                    }

                    // Gráfico de barras (últimas 24 muestras)
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 240

                        Row {
                            anchors.fill: parent
                            spacing: 4
                            Repeater {
                                model: batteryPanel.history
                                delegate: Item {
                                    id: bar
                                    width: (parent.width - (batteryPanel.history.length - 1) * 4) / Math.max(1, batteryPanel.history.length)
                                    height: parent.height - 18

                                    Rectangle {
                                        height: Math.max(2, (parent.height - 18) * modelData.pct / 100)
                                        width: parent.width * 0.7
                                        anchors.bottom: parent.bottom
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        radius: 2
                                        color: batteryPanel.historyColor(modelData.pct)
                                    }
                                }
                            }
                        }

                        Text {
                            text: batteryPanel.historyLabel()
                            color: Root.Theme.textSecondary
                            font.family: Root.Theme.fontFamily; font.pixelSize: Root.Theme.fontSizeXS
                            horizontalAlignment: Text.AlignHCenter
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                }

                Item { Layout.fillHeight: true }
            }
        }
    }

    function historyLabel() {
        if (batteryPanel.history.length === 0) return "No data yet — check back later."
        return "Last " + batteryPanel.history.length * 5 + " min"
    }

    function stateLabel() {
        var s = batteryPanel.state.toLowerCase()
        if (s.indexOf("charging") >= 0) return "Charging"
        if (s.indexOf("discharging") >= 0) return "Discharging"
        if (s.indexOf("full") >= 0) return "Fully charged"
        return batteryPanel.state
    }

    function batteryColor() {
        if (batteryPanel.state.toLowerCase().indexOf("charging") >= 0 || batteryPanel.state.toLowerCase().indexOf("full") >= 0)
            return Root.Theme.primary
        if (batteryPanel.percent <= 15) return Root.Theme.error
        return Root.Theme.textPrimary
    }

    function historyColor(pct) {
        if (pct <= 15) return Root.Theme.error
        return Root.Theme.primary
    }
}
