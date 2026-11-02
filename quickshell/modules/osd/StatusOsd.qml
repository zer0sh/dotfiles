import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../.." as Root
import "../notifications" as Notifications

// StatusOsd — Dynamic Island status indicator for system toggles:
// Airplane mode, Caps Lock, Power profile, DND, Caffeine.
Scope {
    id: statusOsd

    property QtObject controlCenterRef: null

    property string currentIcon: "󰀝"
    property string currentTitle: "SYSTEM"
    property string currentStatus: "ACTIVE"
    property string currentVariant: "primary"

    readonly property color accentColor: {
        if (currentVariant === "error")       return Root.Theme.error
        if (currentVariant === "connected")   return Root.Theme.connected
        if (currentVariant === "secondary")   return Root.Theme.textSecondary
        if (currentVariant === "performance") return Root.Theme.primary
        return Root.Theme.primary
    }

    readonly property color badgeBgColor: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.15)

    function show(icon, title, status, variant) {
        currentIcon = icon
        currentTitle = title
        currentStatus = status
        currentVariant = variant || "primary"

        dismissAnim.stop()
        appearAnim.stop()
        if (!visible) {
            osdCard._slideY = -osdCard.height
            osdCard._opacity = 0
            visible = true
        }
        appearAnim.start()
        dismissTimer.restart()
    }

    property bool visible: false

    // ── IPC Handler: `qs ipc call osd show "󰀝|AIRPLANE|ON|error"` ──
    IpcHandler {
        target: "osd"

        function show(payload: string): void {
            var parts = payload.split("|")
            if (parts.length >= 3) {
                statusOsd.show(parts[0], parts[1], parts[2], parts[3] || "primary")
            } else {
                statusOsd.show("󰋽", payload, "", "primary")
            }
        }
    }

    // ── Caps Lock Watcher ───────────────────────────────────────────
    property bool capsLock: false
    property bool _capsReady: false

    Process {
        id: capsProc
        command: ["sh", "-c", "cat /sys/class/leds/*::capslock/brightness 2>/dev/null | head -1"]
        stdout: StdioCollector {
            onStreamFinished: {
                var val = text.trim()
                if (val !== "") {
                    var active = (val === "1")
                    if (statusOsd._capsReady) {
                        if (active !== statusOsd.capsLock) {
                            statusOsd.capsLock = active
                            statusOsd.show(
                                "󰬈",
                                "CAPS LOCK",
                                active ? "ON" : "OFF",
                                active ? "primary" : "secondary"
                            )
                        }
                    } else {
                        statusOsd.capsLock = active
                        statusOsd._capsReady = true
                    }
                }
            }
        }
    }

    Timer {
        interval: 120
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!capsProc.running)
                capsProc.running = true
        }
    }

    // ── Startup delay so initial values don't pop up ────────────────
    property bool _ready: false
    Timer {
        interval: 1000
        repeat: false
        running: true
        onTriggered: statusOsd._ready = true
    }

    // ── ControlCenter Watchers (Airplane, Power, Caffeine) ──────────
    Connections {
        target: statusOsd.controlCenterRef

        function onAirplaneModeEnabledChanged() {
            if (!statusOsd._ready) return
            var on = statusOsd.controlCenterRef.airplaneModeEnabled
            statusOsd.show(
                on ? "󰀝" : "󰀞",
                "AIRPLANE MODE",
                on ? "ON" : "OFF",
                on ? "error" : "primary"
            )
        }

        function onPowerProfileChanged() {
            if (!statusOsd._ready) return
            var p = statusOsd.controlCenterRef.powerProfile
            var icon = "󰾆"
            var label = "BALANCED"
            var variant = "primary"
            if (p === "performance") {
                icon = "󰓅"
                label = "PERFORMANCE"
                variant = "performance"
            } else if (p === "power-saver") {
                icon = "󰌪"
                label = "POWER SAVER"
                variant = "connected"
            }
            statusOsd.show(icon, "POWER PROFILE", label, variant)
        }

        function onCaffeineEnabledChanged() {
            if (!statusOsd._ready) return
            var on = statusOsd.controlCenterRef.caffeineEnabled
            statusOsd.show(
                "󰅶",
                "CAFFEINE",
                on ? "ACTIVE" : "INACTIVE",
                on ? "connected" : "secondary"
            )
        }
    }

    // ── DND Watcher ─────────────────────────────────────────────────
    Connections {
        target: Notifications.NotificationService

        function onDndEnabledChanged() {
            if (!statusOsd._ready) return
            var on = Notifications.NotificationService.dndEnabled
            statusOsd.show(
                on ? "󰂛" : "󰂚",
                "DO NOT DISTURB",
                on ? "ON" : "OFF",
                on ? "error" : "primary"
            )
        }
    }

    // ── Overlay Window ──────────────────────────────────────────────
    PanelWindow {
        id: osdWin
        visible: statusOsd.visible
        color:   "transparent"
        exclusionMode:               ExclusionMode.Ignore
        WlrLayershell.layer:         WlrLayer.Overlay
        WlrLayershell.namespace:     "quickshell:status-osd"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        anchors.top:   true
        anchors.left:  true
        anchors.right: true
        implicitHeight: Root.Theme.shelfHeight + 70

        mask: Region {
            item: osdWrapper
        }

        Timer {
            id: dismissTimer
            interval: 2000
            repeat:   false
            onTriggered: dismissAnim.start()
        }

        // Appear: slide down + fade in from behind Waybar
        ParallelAnimation {
            id: appearAnim
            NumberAnimation {
                target: osdCard; property: "_opacity"
                to: 1; duration: 220; easing.type: Easing.OutQuad
            }
            NumberAnimation {
                target: osdCard; property: "_slideY"
                to: 0; duration: 260; easing.type: Easing.OutCubic
            }
        }

        // Dismiss: slide up + fade out behind Waybar
        SequentialAnimation {
            id: dismissAnim
            ParallelAnimation {
                NumberAnimation {
                    target: osdCard; property: "_opacity"
                    to: 0; duration: 180; easing.type: Easing.InQuad
                }
                NumberAnimation {
                    target: osdCard; property: "_slideY"
                    to: -osdCard.height; duration: 200; easing.type: Easing.InQuad
                }
            }
            ScriptAction { script: statusOsd.visible = false }
        }

        // ── Card container anchored directly to Waybar shelf ─────────
        Item {
            id: osdWrapper
            width: 416
            height: 56
            anchors.top: parent.top
            anchors.topMargin: Root.Theme.shelfHeight
            anchors.horizontalCenter: parent.horizontalCenter

            Item {
                id: osdClip
                anchors.fill: parent
                clip: true

                Item {
                    id: osdCard
                    property real _opacity: 0
                    property real _slideY: -height

                    width: 360
                    height: 56
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: _slideY
                    opacity: _opacity

                    // Unified Dynamic Island Shape with concave shoulder fillets
                    Shape {
                        id: osdShape
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: parent.width + 56
                        layer.enabled: true
                        layer.samples: 4

                        // 1. Unified glass surface fill
                        ShapePath {
                            strokeWidth: 0
                            strokeColor: "transparent"
                            fillColor: Qt.rgba(Root.Theme.panelBg.r,
                                               Root.Theme.panelBg.g,
                                               Root.Theme.panelBg.b, 0.88)

                            startX: 0
                            startY: 0

                            PathArc {
                                x: 28; y: 28
                                radiusX: 28; radiusY: 28
                                direction: PathArc.Clockwise
                            }
                            PathLine { x: 28; y: Math.max(28, osdShape.height - 28) }
                            PathArc {
                                x: 56; y: osdShape.height
                                radiusX: 28; radiusY: 28
                                direction: PathArc.Counterclockwise
                            }
                            PathLine { x: Math.max(56, osdShape.width - 56); y: osdShape.height }
                            PathArc {
                                x: osdShape.width - 28; y: Math.max(28, osdShape.height - 28)
                                radiusX: 28; radiusY: 28
                                direction: PathArc.Counterclockwise
                            }
                            PathLine { x: osdShape.width - 28; y: 28 }
                            PathArc {
                                x: osdShape.width; y: 0
                                radiusX: 28; radiusY: 28
                                direction: PathArc.Clockwise
                            }
                            PathLine { x: 0; y: 0 }
                        }

                        // 2. Continuous accent border (open along Waybar shelf)
                        ShapePath {
                            strokeWidth: 2
                            strokeColor: statusOsd.accentColor
                            fillColor: "transparent"
                            capStyle: ShapePath.FlatCap
                            joinStyle: ShapePath.RoundJoin

                            Behavior on strokeColor { ColorAnimation { duration: 180 } }

                            startX: 0
                            startY: 0

                            PathArc {
                                x: 28; y: 28
                                radiusX: 28; radiusY: 28
                                direction: PathArc.Clockwise
                            }
                            PathLine { x: 28; y: Math.max(28, osdShape.height - 28) }
                            PathArc {
                                x: 56; y: osdShape.height
                                radiusX: 28; radiusY: 28
                                direction: PathArc.Counterclockwise
                            }
                            PathLine { x: Math.max(56, osdShape.width - 56); y: osdShape.height }
                            PathArc {
                                x: osdShape.width - 28; y: Math.max(28, osdShape.height - 28)
                                radiusX: 28; radiusY: 28
                                direction: PathArc.Counterclockwise
                            }
                            PathLine { x: osdShape.width - 28; y: 28 }
                            PathArc {
                                x: osdShape.width; y: 0
                                radiusX: 28; radiusY: 28
                                direction: PathArc.Clockwise
                            }
                        }
                    }

                    // Content layout
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        spacing: 12

                        // Icon badge
                        Rectangle {
                            Layout.preferredWidth: 34
                            Layout.preferredHeight: 34
                            Layout.alignment: Qt.AlignVCenter
                            radius: 17
                            color: statusOsd.badgeBgColor

                            Behavior on color { ColorAnimation { duration: 180 } }

                            Text {
                                anchors.centerIn: parent
                                text: statusOsd.currentIcon
                                font.family: Root.Theme.fontFamily
                                font.pixelSize: 18
                                color: statusOsd.accentColor

                                Behavior on color { ColorAnimation { duration: 180 } }
                            }
                        }

                        // Title text
                        Text {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            text: statusOsd.currentTitle
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: Root.Theme.fontSizeSmall
                            font.letterSpacing: 0.8
                            font.bold: true
                            color: Root.Theme.textPrimary
                            elide: Text.ElideRight
                        }

                        // Status pill badge
                        Rectangle {
                            Layout.alignment: Qt.AlignVCenter
                            Layout.preferredHeight: 24
                            Layout.preferredWidth: Math.max(52, statusText.implicitWidth + 18)
                            radius: 12
                            color: statusOsd.badgeBgColor
                            border.width: 1
                            border.color: Qt.rgba(statusOsd.accentColor.r,
                                                  statusOsd.accentColor.g,
                                                  statusOsd.accentColor.b, 0.45)

                            Behavior on color { ColorAnimation { duration: 180 } }
                            Behavior on border.color { ColorAnimation { duration: 180 } }

                            Text {
                                id: statusText
                                anchors.centerIn: parent
                                text: statusOsd.currentStatus
                                font.family: Root.Theme.fontFamily
                                font.pixelSize: Root.Theme.fontSizeSmall - 1
                                font.bold: true
                                color: statusOsd.accentColor

                                Behavior on color { ColorAnimation { duration: 180 } }
                            }
                        }
                    }
                }
            }
        }
    }
}
