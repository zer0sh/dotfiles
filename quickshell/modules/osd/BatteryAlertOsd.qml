import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../.." as Root

// BatteryAlertOsd — Animated floating card for battery status alerts
// Displays prominent icons, pulsing animations, level progress bar,
// and Material Design 3 thematic accentuation.
Scope {
    id: batteryAlertOsd

    property string alertLevel: "warning"   // warning | critical | ultimatum | charging
    property int batteryPercent: 30
    property string alertTitle: "Batería baja"
    property string alertMessage: "Nivel al 30% — Considera conectar el cargador pronto"
    property bool isCharging: false

    function getLevelColor(level) {
        if (level === "charging") return "#69F0AE";
        if (level === "ultimatum") return "#FF1744";
        if (level === "critical") return "#FF5252";
        return "#FFA726"; // warning
    }

    function getLevelIcon(level) {
        if (level === "charging") return "󰂄";
        if (level === "ultimatum") return "󰂎";
        if (level === "critical") return "󰁺";
        return "󰁼"; // warning
    }

    function getPulseDuration(level) {
        if (level === "ultimatum") return 350;
        if (level === "critical") return 550;
        return 900; // warning & charging
    }

    function getAutoDismissInterval(level) {
        if (level === "ultimatum") return 12000;
        if (level === "critical") return 8000;
        if (level === "charging") return 5000;
        return 6000; // warning
    }

    function showAlert(level, percent, title, message) {
        alertLevel = level || "warning";
        batteryPercent = Math.max(0, Math.min(100, parseInt(percent) || 0));
        isCharging = (level === "charging");

        if (title && title !== "") alertTitle = title;
        else {
            if (level === "charging") alertTitle = "Cargador conectado";
            else if (level === "ultimatum") alertTitle = "Ultimátum de batería";
            else if (level === "critical") alertTitle = "Batería crítica";
            else alertTitle = "Batería baja";
        }

        if (message && message !== "") alertMessage = message;
        else {
            if (level === "charging") alertMessage = "La batería se está cargando (" + batteryPercent + "%)";
            else if (level === "ultimatum") alertMessage = "Nivel crítico al " + batteryPercent + "% — Apagado inminente";
            else if (level === "critical") alertMessage = "Nivel al " + batteryPercent + "% — Conecta el cargador de inmediato";
            else alertMessage = "Nivel al " + batteryPercent + "% — Conecta el cargador pronto";
        }

        dismissTimer.interval = getAutoDismissInterval(alertLevel);
        osdWin.showOsd();
    }

    function dismiss() {
        dismissAnim.start();
    }

    // ── IPC Handlers ─────────────────────────────────────────────────
    IpcHandler {
        target: "battery"

        function alert(level: string, percent: int, title: string, message: string): void {
            batteryAlertOsd.showAlert(level, percent, title, message);
        }

        function test(): void {
            batteryAlertOsd.showAlert("warning", 30, "Batería baja", "Nivel al 30% — Considera conectar el cargador pronto");
        }

        function testCritical(): void {
            batteryAlertOsd.showAlert("critical", 10, "Batería crítica", "Nivel al 10% — Conecta el cargador de inmediato");
        }

        function testUltimatum(): void {
            batteryAlertOsd.showAlert("ultimatum", 5, "Ultimátum de batería", "Nivel crítico al 5% — El equipo se apagará pronto");
        }

        function testCharging(): void {
            batteryAlertOsd.showAlert("charging", 55, "Cargador conectado", "La batería se está cargando (55%)");
        }

        function hide(): void {
            batteryAlertOsd.dismiss();
        }
    }

    // ── Overlay Window ───────────────────────────────────────────────
    PanelWindow {
        id: osdWin
        visible: false
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell:battery-alert"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        anchors.top: true
        anchors.left: true
        anchors.right: true
        implicitHeight: 140

        function showOsd() {
            dismissAnim.stop();
            if (!visible) {
                osdCard._opacity = 0;
                osdCard._slideY = -32;
                visible = true;
                appearAnim.start();
            }
            dismissTimer.restart();
        }

        // Auto-dismiss Timer
        Timer {
            id: dismissTimer
            interval: 6000
            repeat: false
            onTriggered: dismissAnim.start()
        }

        // Appear Animation
        ParallelAnimation {
            id: appearAnim
            NumberAnimation {
                target: osdCard
                property: "_opacity"
                from: 0
                to: 1
                duration: 240
                easing.type: Easing.OutQuad
            }
            NumberAnimation {
                target: osdCard
                property: "_slideY"
                from: -32
                to: 0
                duration: 320
                easing.type: Easing.OutBack
            }
        }

        // Dismiss Animation
        SequentialAnimation {
            id: dismissAnim
            ParallelAnimation {
                NumberAnimation {
                    target: osdCard
                    property: "_opacity"
                    to: 0
                    duration: 200
                    easing.type: Easing.InQuad
                }
                NumberAnimation {
                    target: osdCard
                    property: "_slideY"
                    to: -24
                    duration: 200
                    easing.type: Easing.InQuad
                }
            }
            ScriptAction { script: osdWin.visible = false; }
        }

        // Card Container
        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 46
            width: 420
            height: 82

            Rectangle {
                id: osdCard
                property real _opacity: 0
                property real _slideY: -32

                width: parent.width
                height: parent.height
                y: _slideY
                opacity: _opacity
                radius: 26

                color: Qt.rgba(Root.Theme.panelBg.r,
                               Root.Theme.panelBg.g,
                               Root.Theme.panelBg.b, 0.90)

                border.width: 1.5
                border.color: {
                    var c = batteryAlertOsd.getLevelColor(batteryAlertOsd.alertLevel);
                    return Qt.rgba(c.r !== undefined ? c.r : 1,
                                   c.g !== undefined ? c.g : 0.4,
                                   c.b !== undefined ? c.b : 0.4,
                                   batteryAlertOsd.alertLevel === "ultimatum" ? 0.95 : 0.75);
                }

                Behavior on border.color { ColorAnimation { duration: 250 } }

                // Outer ambient glow effect
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -4
                    radius: parent.radius + 4
                    z: -1
                    color: "transparent"
                    border.width: 2
                    border.color: {
                        var col = batteryAlertOsd.getLevelColor(batteryAlertOsd.alertLevel);
                        return Qt.rgba(col.r !== undefined ? col.r : 1,
                                       col.g !== undefined ? col.g : 0.4,
                                       col.b !== undefined ? col.b : 0.4,
                                       batteryAlertOsd.alertLevel === "ultimatum" ? 0.45 : 0.20);
                    }
                    opacity: osdCard._opacity
                }

                // Interactive click to open Control Center
                MouseArea {
                    id: cardMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: dismissTimer.stop()
                    onExited: dismissTimer.restart()
                    onClicked: {
                        Quickshell.execDetached(["qs", "ipc", "call", "controlcenter", "toggle"]);
                        batteryAlertOsd.dismiss();
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    anchors.topMargin: 12
                    anchors.bottomMargin: 12
                    spacing: 14

                    // ── Animated Icon Badge ───────────────────────────
                    Item {
                        Layout.preferredWidth: 50
                        Layout.preferredHeight: 50
                        Layout.alignment: Qt.AlignVCenter

                        Rectangle {
                            id: iconBadge
                            anchors.fill: parent
                            radius: 25

                            color: {
                                var col = batteryAlertOsd.getLevelColor(batteryAlertOsd.alertLevel);
                                return Qt.rgba(col.r !== undefined ? col.r : 1,
                                               col.g !== undefined ? col.g : 0.4,
                                               col.b !== undefined ? col.b : 0.4, 0.18);
                            }

                            border.width: 1
                            border.color: {
                                var col = batteryAlertOsd.getLevelColor(batteryAlertOsd.alertLevel);
                                return Qt.rgba(col.r !== undefined ? col.r : 1,
                                               col.g !== undefined ? col.g : 0.4,
                                               col.b !== undefined ? col.b : 0.4, 0.40);
                            }

                            // Icon Glyph
                            Text {
                                id: iconText
                                anchors.centerIn: parent
                                text: batteryAlertOsd.getLevelIcon(batteryAlertOsd.alertLevel)
                                font.family: Root.Theme.fontFamily
                                font.pixelSize: 24
                                color: batteryAlertOsd.getLevelColor(batteryAlertOsd.alertLevel)
                                scale: pulseScale

                                property real pulseScale: 1.0

                                SequentialAnimation on pulseScale {
                                    running: osdWin.visible
                                    loops: Animation.Infinite
                                    NumberAnimation {
                                        to: batteryAlertOsd.alertLevel === "ultimatum" ? 1.25 :
                                            (batteryAlertOsd.alertLevel === "critical" ? 1.18 : 1.10)
                                        duration: batteryAlertOsd.getPulseDuration(batteryAlertOsd.alertLevel)
                                        easing.type: Easing.InOutQuad
                                    }
                                    NumberAnimation {
                                        to: 1.0
                                        duration: batteryAlertOsd.getPulseDuration(batteryAlertOsd.alertLevel)
                                        easing.type: Easing.InOutQuad
                                    }
                                }
                            }
                        }
                    }

                    // ── Information Column ────────────────────────────
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 4

                        // Row 1: Title and Percentage Chip
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Text {
                                text: batteryAlertOsd.alertTitle
                                font.family: Root.Theme.fontFamily
                                font.pixelSize: 13
                                font.weight: Font.Bold
                                color: Root.Theme.textPrimary
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            // Percentage Pill Chip
                            Rectangle {
                                Layout.preferredHeight: 20
                                Layout.preferredWidth: pctText.implicitWidth + 14
                                radius: 10
                                color: {
                                    var col = batteryAlertOsd.getLevelColor(batteryAlertOsd.alertLevel);
                                    return Qt.rgba(col.r !== undefined ? col.r : 1,
                                                   col.g !== undefined ? col.g : 0.4,
                                                   col.b !== undefined ? col.b : 0.4, 0.22);
                                }
                                border.width: 1
                                border.color: batteryAlertOsd.getLevelColor(batteryAlertOsd.alertLevel)

                                Text {
                                    id: pctText
                                    anchors.centerIn: parent
                                    text: batteryAlertOsd.batteryPercent + "%"
                                    font.family: Root.Theme.fontFamily
                                    font.pixelSize: 11
                                    font.weight: Font.Bold
                                    color: batteryAlertOsd.getLevelColor(batteryAlertOsd.alertLevel)
                                }
                            }
                        }

                        // Row 2: Subtitle / Message
                        Text {
                            text: batteryAlertOsd.alertMessage
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: 11
                            color: Root.Theme.textSecondary
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        // Row 3: Animated Battery Level Progress Bar
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.topMargin: 2
                            height: 6
                            radius: 3
                            color: Qt.rgba(Root.Theme.textSecondary.r,
                                           Root.Theme.textSecondary.g,
                                           Root.Theme.textSecondary.b, 0.20)

                            Rectangle {
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                anchors.left: parent.left
                                width: Math.max(parent.height, parent.width * (batteryAlertOsd.batteryPercent / 100.0))
                                radius: parent.radius
                                color: batteryAlertOsd.getLevelColor(batteryAlertOsd.alertLevel)

                                Behavior on width {
                                    NumberAnimation {
                                        duration: 500
                                        easing.type: Easing.OutCubic
                                    }
                                }
                                Behavior on color {
                                    ColorAnimation { duration: 250 }
                                }
                            }
                        }
                    }

                    // ── Close Button ──────────────────────────────────
                    Item {
                        Layout.preferredWidth: 24
                        Layout.preferredHeight: 24
                        Layout.alignment: Qt.AlignTop

                        Rectangle {
                            id: closeBtn
                            anchors.fill: parent
                            radius: 12
                            color: closeMouseArea.containsMouse
                                   ? Qt.rgba(Root.Theme.textSecondary.r,
                                             Root.Theme.textSecondary.g,
                                             Root.Theme.textSecondary.b, 0.20)
                                   : "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: "󰅖"
                                font.family: Root.Theme.fontFamily
                                font.pixelSize: 14
                                color: closeMouseArea.containsMouse
                                       ? Root.Theme.textPrimary
                                       : Root.Theme.textSecondary
                            }

                            MouseArea {
                                id: closeMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: batteryAlertOsd.dismiss()
                            }
                        }
                    }
                }
            }
        }
    }
}
