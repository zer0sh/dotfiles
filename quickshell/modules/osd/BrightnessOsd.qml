import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../.." as Root

// BrightnessOsd — Dynamic Island style anchored directly beneath Waybar
Scope {
    id: brightnessOsd

    property real brightness: 1.0
    readonly property int brightnessPercent: Math.round(brightness * 100)
    property bool _ready: false

    Process {
        id: readProc
        command: ["brightnessctl", "--class=backlight", "-m"]
        stdout: StdioCollector {
            onStreamFinished: {
                var parts = text.trim().split(",");
                if (parts.length >= 5) {
                    var current = parseFloat(parts[2]);
                    var max = parseFloat(parts[4]);
                    if (!isNaN(current) && !isNaN(max) && max > 0) {
                        var newBrightness = Math.min(1.0, Math.max(0.0, current / max));
                        if (brightnessOsd._ready) {
                            if (Math.abs(newBrightness - brightnessOsd.brightness) > 0.005) {
                                brightnessOsd.brightness = newBrightness;
                                osdWin.showOsd();
                            }
                        } else {
                            brightnessOsd.brightness = newBrightness;
                            brightnessOsd._ready = true;
                        }
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "brightness"

        function check(): void {
            if (!readProc.running) {
                readProc.running = true;
            }
        }
    }

    Component.onCompleted: {
        if (!readProc.running) {
            readProc.running = true;
        }
    }

    function brightnessIcon(level) {
        if (level < 0.33) return "󰃝";
        if (level < 0.66) return "󰃞";
        return "󰃠";
    }

    PanelWindow {
        id: osdWin
        visible: false
        color:   "transparent"
        exclusionMode:               ExclusionMode.Ignore
        WlrLayershell.layer:         WlrLayer.Overlay
        WlrLayershell.namespace:     "quickshell:brightness-osd"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        anchors.top:   true
        anchors.left:  true
        anchors.right: true
        implicitHeight: Root.Theme.shelfHeight + 70

        mask: Region {
            item: osdWrapper
        }

        function showOsd() {
            var wasDismissing = dismissAnim.running
            dismissAnim.stop()
            if (!visible || wasDismissing) {
                appearAnim.stop()
                osdCard._translateY = -35
                osdCard._scaleY = 0.50
                osdCard._scaleX = 0.85
                osdCard._opacity = 0
                cardContent.opacity = 0
                visible = true
                appearAnim.start()
            }
            dismissTimer.restart()
        }

        Timer {
            id: dismissTimer
            interval: 2000
            repeat: false
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
            ScriptAction { script: osdWin.visible = false }
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
                            color: Qt.rgba(Root.Theme.primary.r, Root.Theme.primary.g, Root.Theme.primary.b, 0.14)

                            Text {
                                anchors.centerIn: parent
                                text: brightnessOsd.brightnessIcon(brightnessOsd.brightness)
                                font.family: Root.Theme.fontFamily
                                font.pixelSize: 18
                                color: Root.Theme.primary
                            }
                        }

                        // Progress bar track
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            height: 8
                            radius: 4
                            color: Root.Theme.sliderTrack

                            // Active progress fill
                            Rectangle {
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                anchors.left: parent.left
                                width: Math.max(parent.height, parent.width * Math.min(1.0, brightnessOsd.brightness))
                                radius: parent.radius
                                color: Root.Theme.sliderActiveTrack

                                Behavior on width { NumberAnimation { duration: 90; easing.type: Easing.OutQuad } }
                            }
                        }

                        // Percentage badge
                        Text {
                            text: brightnessOsd.brightnessPercent + "%"
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: Root.Theme.fontSizeNormal
                            font.bold: true
                            color: Root.Theme.textPrimary
                            Layout.alignment: Qt.AlignVCenter
                            Layout.preferredWidth: 54
                            horizontalAlignment: Text.AlignRight
                        }
                    }
                }
            }
        }
    }
