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

        var wasDismissing = dismissAnim.running
        dismissAnim.stop()
        if (!visible || wasDismissing) {
            appearAnim.stop()
            osdCard._scaleY = 0.35
            osdCard._scaleX = 0.78
            osdCard._opacity = 0
            cardContent.opacity = 0
            visible = true
            appearAnim.start()
        }
        dismissTimer.restart()
    }

    property bool visible: false

    // ── IPC Handler: `qs ipc call osd notify "󰀝|AIRPLANE|ON|error"` ──
    IpcHandler {
        target: "osd"

        function notify(payload: string): void {
            var parts = payload.split("|")
            if (parts.length >= 3) {
                statusOsd.show(parts[0], parts[1], parts[2], parts[3] || "primary")
            } else {
                statusOsd.show("󰋽", payload, "", "primary")
            }
        }

        function show(payload: string): void {
            notify(payload);
        }

        function checkCaps(): void {
            if (!capsProc.running)
                capsProc.running = true;
        }
    }

    // ── Caps Lock Watcher ───────────────────────────────────────────
    property bool capsLock: false
    property bool _capsReady: false

    Process {
        id: capsProc
        command: ["sh", "-c", "cat /sys/class/leds/*::capslock/brightness 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                var val = text.trim()
                if (val !== "") {
                    var active = (val === "1" || val.startsWith("1"))
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

    // Gentle fallback check (primary trigger is event-driven via Hyprland bindnl on Caps_Lock)
    Timer {
        interval: 5000
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

        // Appear: dots-hyprland Expressive Default Spatial spring bounce
        ParallelAnimation {
            id: appearAnim
            NumberAnimation {
                target: osdCard; property: "_translateY"
                from: -35; to: 0.0; duration: Root.Theme.animDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Root.Theme.curvePanelOpen
            }
            NumberAnimation {
                target: osdCard; property: "_scaleY"
                from: 0.50; to: 1.0; duration: Root.Theme.animDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Root.Theme.curvePanelOpen
            }
            NumberAnimation {
                target: osdCard; property: "_scaleX"
                from: 0.85; to: 1.0; duration: Root.Theme.animDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Root.Theme.curvePanelOpen
            }
            NumberAnimation {
                target: osdCard; property: "_opacity"
                from: 0.0; to: 1.0; duration: 200
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Root.Theme.curveEmphasizedDecel
            }
            SequentialAnimation {
                PauseAnimation { duration: 25 }
                NumberAnimation {
                    target: cardContent; property: "opacity"
                    from: 0.0; to: 1.0; duration: 200
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Root.Theme.curveEmphasizedDecel
                }
            }
        }

        // Dismiss: dots-hyprland Emphasized Accel close
        SequentialAnimation {
            id: dismissAnim
            ParallelAnimation {
                NumberAnimation {
                    target: cardContent; property: "opacity"
                    to: 0.0; duration: 120
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Root.Theme.curvePanelClose
                }
                NumberAnimation {
                    target: osdCard; property: "_translateY"
                    to: -35; duration: Root.Theme.animDurationFast
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Root.Theme.curvePanelClose
                }
                NumberAnimation {
                    target: osdCard; property: "_scaleY"
                    to: 0.50; duration: Root.Theme.animDurationFast
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Root.Theme.curvePanelClose
                }
                NumberAnimation {
                    target: osdCard; property: "_scaleX"
                    to: 0.85; duration: Root.Theme.animDurationFast
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Root.Theme.curvePanelClose
                }
                NumberAnimation {
                    target: osdCard; property: "_opacity"
                    to: 0.0; duration: Root.Theme.animDurationFast
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Root.Theme.curvePanelClose
                }
            }
            ScriptAction { script: statusOsd.visible = false }
        }

        // ── Card container anchored directly to Waybar shelf ─────────
        Item {
            id: osdWrapper
            width: 360
            height: 64
            anchors.top: parent.top
            anchors.topMargin: Root.Theme.shelfHeight + 14
            anchors.horizontalCenter: parent.horizontalCenter

            Item {
                id: osdCard
                property real _opacity: 0
                property real _scaleX: 1.0
                property real _scaleY: 1.0
                property real _translateY: 0.0

                width: 360
                height: 52
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                opacity: _opacity

                transformOrigin: Item.Top
                transform: [
                    Translate {
                        y: osdCard._translateY
                    },
                    Scale {
                        origin.x: osdCard.width / 2
                        origin.y: 0
                        xScale: osdCard._scaleX
                        yScale: osdCard._scaleY
                    }
                ]

                // Fondo flotante unificado en píldora
                Rectangle {
                    id: osdCardBg
                    anchors.fill: parent
                    radius: height / 2
                    color: Qt.rgba(Root.Theme.panelBg.r, Root.Theme.panelBg.g, Root.Theme.panelBg.b, 0.90)
                    border.width: 1.5
                    border.color: Qt.rgba(Root.Theme.panelBorder.r, Root.Theme.panelBorder.g, Root.Theme.panelBorder.b, 0.60)
                }

                // Content layout
                RowLayout {
                    id: cardContent
                    anchors.fill: parent
                    anchors.topMargin: 0
                    anchors.bottomMargin: 0
                    anchors.leftMargin: 16
                    anchors.rightMargin: 18
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
