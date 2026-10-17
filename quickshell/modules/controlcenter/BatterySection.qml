import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../.." as Root

// Battery Sub-Page — Material You Pixel Glassmorphism Battery Dashboard
Item {
    id: batteryPanel

    signal back()

    property var controlCenterRef: null

    // Battery metrics loaded via battery-info.py
    property int capacity: 0
    property string status: "Desconocido"
    property bool acOnline: false
    property real energyNowWh: 0.0
    property real energyFullWh: 0.0
    property real energyDesignWh: 0.0
    property real powerW: 0.0
    property real voltageV: 0.0
    property int cycles: 0
    property string technology: "Li-poly"
    property string threshold: ""
    property real healthPercent: 100.0
    property int timeRemainingMin: 0
    property bool isLoaded: false

    Process {
        id: batteryProc
        command: ["/home/zero/.config/quickshell/scripts/battery-info.py"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var data = JSON.parse(text.trim());
                    batteryPanel.capacity = data.capacity !== undefined ? data.capacity : 0;
                    batteryPanel.status = data.status || "Desconocido";
                    batteryPanel.acOnline = !!data.ac_online;
                    batteryPanel.energyNowWh = data.energy_now_wh || 0.0;
                    batteryPanel.energyFullWh = data.energy_full_wh || 0.0;
                    batteryPanel.energyDesignWh = data.energy_design_wh || 0.0;
                    batteryPanel.powerW = data.power_w || 0.0;
                    batteryPanel.voltageV = data.voltage_v || 0.0;
                    batteryPanel.cycles = data.cycles || 0;
                    batteryPanel.technology = data.technology || "Li-poly";
                    batteryPanel.threshold = data.threshold || "";
                    batteryPanel.healthPercent = data.health_percent || 100.0;
                    batteryPanel.timeRemainingMin = data.time_remaining_min || 0;
                    batteryPanel.isLoaded = true;
                } catch (e) {
                    console.log("Battery parse error:", e);
                }
            }
        }
    }

    Timer {
        interval: 10000
        repeat: true
        running: true
        onTriggered: {
            if (!batteryProc.running) batteryProc.running = true;
        }
    }

    Component.onCompleted: batteryProc.running = true

    function refresh() {
        if (!batteryProc.running) batteryProc.running = true;
    }

    function batteryStateColor() {
        if (status === "Charging") return Root.Theme.connected;
        if (capacity <= 20) return Root.Theme.error;
        return Root.Theme.primary;
    }

    function batteryIcon() {
        if (status === "Charging") return "battery_charging_full";
        if (capacity <= 15) return "battery_alert";
        if (capacity <= 30) return "battery_2_bar";
        if (capacity <= 50) return "battery_3_bar";
        if (capacity <= 70) return "battery_4_bar";
        if (capacity <= 85) return "battery_5_bar";
        if (capacity <= 95) return "battery_6_bar";
        return "battery_full";
    }

    function statusText() {
        if (status === "Charging") return "Charging";
        if (status === "Discharging") return "Discharging";
        if (status === "Full") return "Fully Charged";
        if (acOnline) return "Plugged in";
        return status;
    }

    function timeEstimateText() {
        if (timeRemainingMin <= 0) {
            if (status === "Full") return "Battery at 100%";
            if (acOnline) return "Calculating charge time...";
            return "Calculating battery life...";
        }
        var h = Math.floor(timeRemainingMin / 60);
        var m = timeRemainingMin % 60;
        var prefix = status === "Charging" ? "Full charge in approx. " : "About ";
        var suffix = status === "Charging" ? "" : " remaining";
        if (h > 0) {
            return prefix + h + " h " + (m > 0 ? (m + " min") : "") + suffix;
        }
        return prefix + m + " min" + suffix;
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 16

        // Header: Back button + Title + Refresh
        RowLayout {
            Layout.fillWidth: true
            spacing: 14

            Rectangle {
                Layout.preferredWidth: 40
                Layout.preferredHeight: 40
                radius: 20
                color: backMA.containsMouse ? Qt.rgba(255, 255, 255, 0.14) : Qt.rgba(255, 255, 255, 0.08)
                border.width: 1
                border.color: Qt.rgba(255, 255, 255, 0.12)

                Text {
                    anchors.centerIn: parent
                    text: "arrow_back"
                    font.family: Root.Theme.iconFont
                    font.pixelSize: 22
                    color: Root.Theme.textPrimary
                }

                MouseArea {
                    id: backMA
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: batteryPanel.back()
                }
            }

            ColumnLayout {
                spacing: 1
                Layout.fillWidth: true

                Text {
                    text: "Energy & Performance"
                    font.family: Root.Theme.fontFamily
                    font.pixelSize: 18
                    font.weight: Font.DemiBold
                    color: Root.Theme.textPrimary
                }

                Text {
                    text: "Hardware energy, health and power metrics"
                    font.family: Root.Theme.fontFamily
                    font.pixelSize: 12
                    color: Root.Theme.textSecondary
                }
            }

            Rectangle {
                Layout.preferredWidth: 38
                Layout.preferredHeight: 38
                radius: 19
                color: refreshMA.containsMouse ? Qt.rgba(255, 255, 255, 0.14) : Qt.rgba(255, 255, 255, 0.06)
                border.width: 1
                border.color: Qt.rgba(255, 255, 255, 0.10)

                Text {
                    anchors.centerIn: parent
                    text: "refresh"
                    font.family: Root.Theme.iconFont
                    font.pixelSize: 20
                    color: Root.Theme.textSecondary
                }

                MouseArea {
                    id: refreshMA
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: batteryPanel.refresh()
                }
            }
        }

        // Top Row: Hero Card (Gauge + Status) + Power Profile Selector
        RowLayout {
            Layout.fillWidth: true
            spacing: 16

            // Hero Card
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 150
                radius: 24
                color: Qt.rgba(255, 255, 255, 0.08)
                border.width: 1
                border.color: Qt.rgba(255, 255, 255, 0.14)
                clip: true

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 20

                    // Circular battery badge
                    Rectangle {
                        Layout.preferredWidth: 104
                        Layout.preferredHeight: 104
                        radius: 52
                        color: Qt.rgba(0, 0, 0, 0.25)
                        border.width: 3
                        border.color: batteryPanel.batteryStateColor()

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 0

                            Text {
                                text: batteryPanel.batteryIcon()
                                font.family: Root.Theme.iconFont
                                font.pixelSize: 32
                                color: batteryPanel.batteryStateColor()
                                Layout.alignment: Qt.AlignHCenter
                            }

                            Text {
                                text: batteryPanel.capacity + "%"
                                font.family: Root.Theme.fontFamily
                                font.pixelSize: 22
                                font.weight: Font.Bold
                                color: Root.Theme.textPrimary
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }
                    }

                    // Battery status details
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 6

                        RowLayout {
                            spacing: 8
                            Text {
                                text: batteryPanel.statusText()
                                font.family: Root.Theme.fontFamily
                                font.pixelSize: 18
                                font.weight: Font.DemiBold
                                color: Root.Theme.textPrimary
                            }

                            Rectangle {
                                visible: batteryPanel.acOnline
                                Layout.preferredHeight: 20
                                Layout.preferredWidth: 70
                                radius: 10
                                color: Qt.rgba(Root.Theme.connected.r, Root.Theme.connected.g, Root.Theme.connected.b, 0.20)

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 3
                                    Text {
                                        text: "bolt"
                                        font.family: Root.Theme.iconFont
                                        font.pixelSize: 12
                                        color: Root.Theme.connected
                                    }
                                    Text {
                                        text: "AC ON"
                                        font.family: Root.Theme.fontFamily
                                        font.pixelSize: 10
                                        font.weight: Font.Bold
                                        color: Root.Theme.connected
                                    }
                                }
                            }
                        }

                        Text {
                            text: batteryPanel.timeEstimateText()
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: 13
                            font.weight: Font.Medium
                            color: Root.Theme.primary
                        }

                        // Progress bar
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 8
                            radius: 4
                            color: Qt.rgba(255, 255, 255, 0.12)

                            Rectangle {
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: Math.max(0, parent.width * (batteryPanel.capacity / 100.0))
                                radius: 4
                                color: batteryPanel.batteryStateColor()
                                Behavior on width { NumberAnimation { duration: 300 } }
                            }
                        }

                        Text {
                            text: batteryPanel.energyNowWh + " Wh of " + batteryPanel.energyFullWh + " Wh available"
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: 11
                            color: Root.Theme.textSecondary
                        }
                    }
                }
            }

            // Power Profile Card
            Rectangle {
                Layout.preferredWidth: 320
                Layout.preferredHeight: 150
                radius: 24
                color: Qt.rgba(255, 255, 255, 0.08)
                border.width: 1
                border.color: Qt.rgba(255, 255, 255, 0.14)
                clip: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: "speed"
                            font.family: Root.Theme.iconFont
                            font.pixelSize: 18
                            color: Root.Theme.primary
                        }

                        Text {
                            text: "Power Profile"
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: 14
                            font.weight: Font.DemiBold
                            color: Root.Theme.textPrimary
                        }
                    }

                    // 3-Segmented Pill Selector
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        // Power Saver
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 64
                            radius: 16
                            color: (controlCenterRef && controlCenterRef.powerProfile === "power-saver")
                                ? Root.Theme.primary
                                : Qt.rgba(255, 255, 255, 0.08)
                            border.width: 1
                            border.color: (controlCenterRef && controlCenterRef.powerProfile === "power-saver")
                                ? Root.Theme.primary
                                : Qt.rgba(255, 255, 255, 0.12)

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 2

                                Text {
                                    text: "energy_savings_leaf"
                                    font.family: Root.Theme.iconFont
                                    font.pixelSize: 20
                                    color: (controlCenterRef && controlCenterRef.powerProfile === "power-saver")
                                        ? Root.Theme.tileActiveText
                                        : Root.Theme.textSecondary
                                    Layout.alignment: Qt.AlignHCenter
                                }

                                Text {
                                    text: "Power Saver"
                                    font.family: Root.Theme.fontFamily
                                    font.pixelSize: 11
                                    font.weight: Font.Medium
                                    color: (controlCenterRef && controlCenterRef.powerProfile === "power-saver")
                                        ? Root.Theme.tileActiveText
                                        : Root.Theme.textPrimary
                                    Layout.alignment: Qt.AlignHCenter
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (controlCenterRef) {
                                        controlCenterRef.setPowerProfileProc.command = ["powerprofilesctl", "set", "power-saver"]
                                        controlCenterRef.setPowerProfileProc.running = true
                                        controlCenterRef.powerProfile = "power-saver"
                                    }
                                }
                            }
                        }

                        // Balanced
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 64
                            radius: 16
                            color: (controlCenterRef && controlCenterRef.powerProfile === "balanced")
                                ? Root.Theme.primary
                                : Qt.rgba(255, 255, 255, 0.08)
                            border.width: 1
                            border.color: (controlCenterRef && controlCenterRef.powerProfile === "balanced")
                                ? Root.Theme.primary
                                : Qt.rgba(255, 255, 255, 0.12)

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 2

                                Text {
                                    text: "tune"
                                    font.family: Root.Theme.iconFont
                                    font.pixelSize: 20
                                    color: (controlCenterRef && controlCenterRef.powerProfile === "balanced")
                                        ? Root.Theme.tileActiveText
                                        : Root.Theme.textSecondary
                                    Layout.alignment: Qt.AlignHCenter
                                }

                                Text {
                                    text: "Balanced"
                                    font.family: Root.Theme.fontFamily
                                    font.pixelSize: 11
                                    font.weight: Font.Medium
                                    color: (controlCenterRef && controlCenterRef.powerProfile === "balanced")
                                        ? Root.Theme.tileActiveText
                                        : Root.Theme.textPrimary
                                    Layout.alignment: Qt.AlignHCenter
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (controlCenterRef) {
                                        controlCenterRef.setPowerProfileProc.command = ["powerprofilesctl", "set", "balanced"]
                                        controlCenterRef.setPowerProfileProc.running = true
                                        controlCenterRef.powerProfile = "balanced"
                                    }
                                }
                            }
                        }

                        // Performance
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 64
                            radius: 16
                            color: (controlCenterRef && controlCenterRef.powerProfile === "performance")
                                ? Root.Theme.primary
                                : Qt.rgba(255, 255, 255, 0.08)
                            border.width: 1
                            border.color: (controlCenterRef && controlCenterRef.powerProfile === "performance")
                                ? Root.Theme.primary
                                : Qt.rgba(255, 255, 255, 0.12)

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 2

                                Text {
                                    text: "speed"
                                    font.family: Root.Theme.iconFont
                                    font.pixelSize: 20
                                    color: (controlCenterRef && controlCenterRef.powerProfile === "performance")
                                        ? Root.Theme.tileActiveText
                                        : Root.Theme.textSecondary
                                    Layout.alignment: Qt.AlignHCenter
                                }

                                Text {
                                    text: "Performance"
                                    font.family: Root.Theme.fontFamily
                                    font.pixelSize: 11
                                    font.weight: Font.Medium
                                    color: (controlCenterRef && controlCenterRef.powerProfile === "performance")
                                        ? Root.Theme.tileActiveText
                                        : Root.Theme.textPrimary
                                    Layout.alignment: Qt.AlignHCenter
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (controlCenterRef) {
                                        controlCenterRef.setPowerProfileProc.command = ["powerprofilesctl", "set", "performance"]
                                        controlCenterRef.setPowerProfileProc.running = true
                                        controlCenterRef.powerProfile = "performance"
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Hardware Metrics Grid (4 Cards: Salud, Consumo, Ciclos, Protección)
        GridLayout {
            Layout.fillWidth: true
            columns: 4
            columnSpacing: 14
            rowSpacing: 14

            // Card 1: Salud de la batería
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 110
                radius: 20
                color: Qt.rgba(255, 255, 255, 0.08)
                border.width: 1
                border.color: Qt.rgba(255, 255, 255, 0.14)
                clip: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 4

                    RowLayout {
                        spacing: 6
                        Text {
                            text: "health_and_safety"
                            font.family: Root.Theme.iconFont
                            font.pixelSize: 18
                            color: Root.Theme.primary
                        }
                        Text {
                            text: "Battery Health"
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            color: Root.Theme.textSecondary
                        }
                    }

                    Text {
                        text: batteryPanel.healthPercent + "%"
                        font.family: Root.Theme.fontFamily
                        font.pixelSize: 22
                        font.weight: Font.Bold
                        color: Root.Theme.textPrimary
                    }

                    Text {
                        text: batteryPanel.energyFullWh + " / " + batteryPanel.energyDesignWh + " Wh"
                        font.family: Root.Theme.fontFamily
                        font.pixelSize: 11
                        color: Root.Theme.textSecondary
                    }
                }
            }

            // Card 2: Real-time power draw
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 110
                radius: 20
                color: Qt.rgba(255, 255, 255, 0.08)
                border.width: 1
                border.color: Qt.rgba(255, 255, 255, 0.14)
                clip: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 4

                    RowLayout {
                        spacing: 6
                        Text {
                            text: "bolt"
                            font.family: Root.Theme.iconFont
                            font.pixelSize: 18
                            color: Root.Theme.connected
                        }
                        Text {
                            text: "Current Draw"
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            color: Root.Theme.textSecondary
                        }
                    }

                    Text {
                        text: batteryPanel.powerW + " W"
                        font.family: Root.Theme.fontFamily
                        font.pixelSize: 22
                        font.weight: Font.Bold
                        color: Root.Theme.textPrimary
                    }

                    Text {
                        text: batteryPanel.voltageV + " V • " + (batteryPanel.status === "Charging" ? "Charging" : "Discharge")
                        font.family: Root.Theme.fontFamily
                        font.pixelSize: 11
                        color: Root.Theme.textSecondary
                    }
                }
            }

            // Card 3: Charge cycles and technology
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 110
                radius: 20
                color: Qt.rgba(255, 255, 255, 0.08)
                border.width: 1
                border.color: Qt.rgba(255, 255, 255, 0.14)
                clip: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 4

                    RowLayout {
                        spacing: 6
                        Text {
                            text: "autorenew"
                            font.family: Root.Theme.iconFont
                            font.pixelSize: 18
                            color: Root.Theme.primary
                        }
                        Text {
                            text: "Charge Cycles"
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            color: Root.Theme.textSecondary
                        }
                    }

                    Text {
                        text: batteryPanel.cycles + " cycles"
                        font.family: Root.Theme.fontFamily
                        font.pixelSize: 22
                        font.weight: Font.Bold
                        color: Root.Theme.textPrimary
                    }

                    Text {
                        text: batteryPanel.technology + " • Normal"
                        font.family: Root.Theme.fontFamily
                        font.pixelSize: 11
                        color: Root.Theme.textSecondary
                    }
                }
            }

            // Card 4: Conservation / Battery Protection Limit
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 110
                radius: 20
                color: Qt.rgba(255, 255, 255, 0.08)
                border.width: 1
                border.color: Qt.rgba(255, 255, 255, 0.14)
                clip: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 4

                    RowLayout {
                        spacing: 6
                        Text {
                            text: "verified_user"
                            font.family: Root.Theme.iconFont
                            font.pixelSize: 18
                            color: Root.Theme.primary
                        }
                        Text {
                            text: "Battery Protection"
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            color: Root.Theme.textSecondary
                        }
                    }

                    Text {
                        text: batteryPanel.threshold !== "" ? ("Limit " + batteryPanel.threshold + "%") : "100% Standard"
                        font.family: Root.Theme.fontFamily
                        font.pixelSize: 22
                        font.weight: Font.Bold
                        color: Root.Theme.textPrimary
                    }

                    Text {
                        text: "Conservation mode"
                        font.family: Root.Theme.fontFamily
                        font.pixelSize: 11
                        color: Root.Theme.connected
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }
    }
}
