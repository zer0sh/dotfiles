import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../.." as Root

Scope {
    id: hardwarePulse

    property real cpuPercent: 0
    property int cpuTemp: 0
    property real memUsedGb: 0
    property real memTotalGb: 0
    property real memPercent: 0
    property int batteryLevel: -1
    property string batteryStatus: ""

    property bool panelVisible: Root.GadgetsManager.isEnabled("hardwarepulse")
    property int posX: Root.GadgetsManager.getPosition("hardwarepulse", 80, 120).x
    property int posY: Root.GadgetsManager.getPosition("hardwarepulse", 80, 120).y

    Connections {
        target: Root.GadgetsManager
        function onStateChanged() {
            hardwarePulse.panelVisible = Root.GadgetsManager.isEnabled("hardwarepulse");
            var pos = Root.GadgetsManager.getPosition("hardwarepulse", 80, 120);
            hardwarePulse.posX = pos.x;
            hardwarePulse.posY = pos.y;
        }
    }

    IpcHandler {
        target: "hardwarepulse"
        function toggle(): void { Root.GadgetsManager.toggle("hardwarepulse") }
        function show(): void { Root.GadgetsManager.setEnabled("hardwarepulse", true) }
        function hide(): void { Root.GadgetsManager.setEnabled("hardwarepulse", false) }
        function refresh(): void {
            if (!hwProc.running) hwProc.running = true;
        }
    }

    Process {
        id: hwProc
        command: ["/home/zero/.config/quickshell/scripts/hardware-pulse.py"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var data = JSON.parse(text.trim());
                    if (data.cpu_percent !== undefined) hardwarePulse.cpuPercent = data.cpu_percent;
                    if (data.cpu_temp !== undefined) hardwarePulse.cpuTemp = data.cpu_temp;
                    if (data.mem_used_gb !== undefined) hardwarePulse.memUsedGb = data.mem_used_gb;
                    if (data.mem_total_gb !== undefined) hardwarePulse.memTotalGb = data.mem_total_gb;
                    if (data.mem_percent !== undefined) hardwarePulse.memPercent = data.mem_percent;
                    if (data.battery_level !== undefined) hardwarePulse.batteryLevel = data.battery_level;
                    if (data.battery_status !== undefined) hardwarePulse.batteryStatus = data.battery_status;
                } catch (e) {
                    console.log("[HardwarePulse] Parse error:", e);
                }
            }
        }
    }

    Timer {
        interval: 3000
        repeat: true
        running: true
        onTriggered: {
            if (!hwProc.running) hwProc.running = true;
        }
    }

    Component.onCompleted: {
        hwProc.running = true;
    }

    PanelWindow {
        id: win
        visible: hardwarePulse.panelVisible
        color: "transparent"

        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.namespace: "quickshell:hardwarepulse"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        mask: Region {
            item: mainCard
        }

        // Contenedor principal sin fondo ni bordes — arrastrable directamente
        Item {
            id: mainCard
            x: hardwarePulse.posX
            y: hardwarePulse.posY
            width: 290
            height: 185
            property bool isDragging: false

            Binding {
                target: mainCard
                property: "x"
                value: hardwarePulse.posX
                when: !mainCard.isDragging
            }
            Binding {
                target: mainCard
                property: "y"
                value: hardwarePulse.posY
                when: !mainCard.isDragging
            }

            MouseArea {
                id: dragArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: pressed ? Qt.ClosedHandCursor : (containsMouse ? Qt.OpenHandCursor : Qt.ArrowCursor)
                drag.target: mainCard
                drag.axis: Drag.XAndYAxis

                onPressed: {
                    mainCard.isDragging = true;
                }

                onReleased: {
                    var fx = Math.round(mainCard.x);
                    var fy = Math.round(mainCard.y);
                    hardwarePulse.posX = fx;
                    hardwarePulse.posY = fy;
                    Root.GadgetsManager.setPosition("hardwarepulse", fx, fy);
                    mainCard.isDragging = false;
                }
            }

            // Botón sutil de cierre al pasar el cursor
            Text {
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: 6
                z: 100
                text: "✕"
                font.family: Root.Theme.fontFamily
                font.pixelSize: 13
                font.weight: Font.Bold
                color: closeHover.hovered ? Root.Theme.error : Qt.rgba(Root.Theme.textSecondary.r, Root.Theme.textSecondary.g, Root.Theme.textSecondary.b, 0.45)
                opacity: dragArea.containsMouse ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 180 } }

                HoverHandler { id: closeHover }
                TapHandler {
                    onTapped: Root.GadgetsManager.setEnabled("hardwarepulse", false)
                }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 10

                // Título
                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "HARDWARE PULSE"
                        font.family: Root.Theme.fontFamily
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        font.letterSpacing: 1.5
                        color: Root.Theme.primary
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: hardwarePulse.cpuTemp > 0 ? hardwarePulse.cpuTemp + "°C" : ""
                        font.family: Root.Theme.fontFamily
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        color: hardwarePulse.cpuTemp >= 80 ? Root.Theme.error : Root.Theme.textSecondary
                    }
                }

                // Fila CPU
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "󰍛 CPU"
                            font.family: Root.Theme.iconFont
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                            color: Root.Theme.textPrimary
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: hardwarePulse.cpuPercent.toFixed(1) + "%"
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: 12
                            font.weight: Font.Bold
                            color: hardwarePulse.cpuPercent >= 80 ? Root.Theme.error : Qt.lighter(Root.Theme.primary, 1.2)
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 5
                        radius: 2.5
                        color: Qt.rgba(Root.Theme.primary.r, Root.Theme.primary.g, Root.Theme.primary.b, 0.15)

                        Rectangle {
                            width: Math.max(4, Math.min(parent.width, parent.width * (hardwarePulse.cpuPercent / 100)))
                            height: parent.height
                            radius: 2.5
                            color: hardwarePulse.cpuPercent >= 80 ? Root.Theme.error : Root.Theme.primary
                            Behavior on width { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
                        }
                    }
                }

                // Fila RAM
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "󰘚 RAM"
                            font.family: Root.Theme.iconFont
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                            color: Root.Theme.textPrimary
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: hardwarePulse.memUsedGb.toFixed(1) + " / " + hardwarePulse.memTotalGb.toFixed(0) + " GB (" + Math.round(hardwarePulse.memPercent) + "%)"
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: 12
                            font.weight: Font.Bold
                            color: Qt.lighter(Root.Theme.primary, 1.15)
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 5
                        radius: 2.5
                        color: Qt.rgba(Root.Theme.primary.r, Root.Theme.primary.g, Root.Theme.primary.b, 0.15)

                        Rectangle {
                            width: Math.max(4, Math.min(parent.width, parent.width * (hardwarePulse.memPercent / 100)))
                            height: parent.height
                            radius: 2.5
                            color: hardwarePulse.memPercent >= 85 ? Root.Theme.error : Root.Theme.primary
                            Behavior on width { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
                        }
                    }
                }

                // Fila Batería (si existe)
                RowLayout {
                    Layout.fillWidth: true
                    visible: hardwarePulse.batteryLevel >= 0
                    spacing: 6

                    Text {
                        text: hardwarePulse.batteryStatus === "Charging" ? "󰂄 BAT" : "󰁹 BAT"
                        font.family: Root.Theme.iconFont
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        color: Root.Theme.textPrimary
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: hardwarePulse.batteryLevel + "%" + (hardwarePulse.batteryStatus === "Charging" ? " ⚡" : "")
                        font.family: Root.Theme.fontFamily
                        font.pixelSize: 12
                        font.weight: Font.Bold
                        color: hardwarePulse.batteryLevel <= 20 && hardwarePulse.batteryStatus !== "Charging" ? Root.Theme.error : Root.Theme.textSecondary
                    }
                }
            }
        }
    }
}
