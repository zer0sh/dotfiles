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

    Timer {
        interval: 60
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!readProc.running) {
                readProc.running = true;
            }
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
                osdCard._scaleY = 0.0
                osdCard._scaleX = 0.82
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

        // Appear: organic dynamic island extrusion downwards + expansion
        ParallelAnimation {
            id: appearAnim
            NumberAnimation {
                target: osdCard; property: "_scaleY"
                from: 0.0; to: 1.0; duration: 280
                easing.type: Easing.OutBack
                easing.overshoot: 1.18
            }
            NumberAnimation {
                target: osdCard; property: "_scaleX"
                from: 0.82; to: 1.0; duration: 260
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: osdCard; property: "_opacity"
                from: 0.0; to: 1.0; duration: 160
                easing.type: Easing.OutQuad
            }
            SequentialAnimation {
                PauseAnimation { duration: 50 }
                NumberAnimation {
                    target: cardContent; property: "opacity"
                    from: 0.0; to: 1.0; duration: 180
                    easing.type: Easing.OutQuad
                }
            }
        }

        // Dismiss: retract back into Waybar
        SequentialAnimation {
            id: dismissAnim
            ParallelAnimation {
                NumberAnimation {
                    target: cardContent; property: "opacity"
                    to: 0.0; duration: 100; easing.type: Easing.InQuad
                }
                NumberAnimation {
                    target: osdCard; property: "_scaleY"
                    to: 0.0; duration: 190; easing.type: Easing.InBack
                    easing.overshoot: 1.1
                }
                NumberAnimation {
                    target: osdCard; property: "_scaleX"
                    to: 0.85; duration: 170; easing.type: Easing.InQuad
                }
                NumberAnimation {
                    target: osdCard; property: "_opacity"
                    to: 0.0; duration: 170; easing.type: Easing.InQuad
                }
            }
            ScriptAction { script: osdWin.visible = false }
        }

        // ── Card container anchored directly to Waybar shelf ─────────
        Item {
            id: osdWrapper
            width: 416
            height: 64
            anchors.top: parent.top
            anchors.topMargin: Root.Theme.shelfHeight - 4
            anchors.horizontalCenter: parent.horizontalCenter

            Item {
                id: osdCard
                property real _opacity: 0
                property real _scaleX: 1.0
                property real _scaleY: 1.0

                width: 360
                height: 64
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                opacity: _opacity

                transformOrigin: Item.Top
                transform: Scale {
                    origin.x: osdCard.width / 2
                    origin.y: 0
                    xScale: osdCard._scaleX
                    yScale: osdCard._scaleY
                }

                // Unified Dynamic Island Shape with G1 continuous Bezier fillets
                Shape {
                    id: osdShape
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width + 56
                    layer.enabled: true
                    layer.samples: 8
                    layer.smooth: true

                    // 1. Unified glass surface fill — covers from y=0 (screen y=32) to fully obscure Waybar's 2px border
                    ShapePath {
                        strokeWidth: 0
                        strokeColor: "transparent"
                        fillColor: Qt.rgba(Root.Theme.panelBg.r,
                                           Root.Theme.panelBg.g,
                                           Root.Theme.panelBg.b, 0.98)

                        startX: 0
                        startY: 0

                        PathLine { x: 0; y: 3 }

                        // Left concave shoulder fillet with zero horizontal tangent at y=3 (screen y=35)
                        PathCubic {
                            control1X: 14; control1Y: 3
                            control2X: 28; control2Y: 17
                            x: 28; y: 31
                        }
                        // Left flank
                        PathLine { x: 28; y: Math.max(31, osdShape.height - 28) }
                        // Bottom-left rounded corner
                        PathCubic {
                            control1X: 28; control1Y: osdShape.height - 14
                            control2X: 42; control2Y: osdShape.height
                            x: 56; y: osdShape.height
                        }
                        // Bottom horizontal base
                        PathLine { x: Math.max(56, osdShape.width - 56); y: osdShape.height }
                        // Bottom-right rounded corner
                        PathCubic {
                            control1X: osdShape.width - 42; control1Y: osdShape.height
                            control2X: osdShape.width - 28; control2Y: osdShape.height - 14
                            x: osdShape.width - 28; y: Math.max(31, osdShape.height - 28)
                        }
                        // Right flank
                        PathLine { x: osdShape.width - 28; y: 31 }
                        // Right concave shoulder fillet with zero horizontal exit tangent at y=3 (screen y=35)
                        PathCubic {
                            control1X: osdShape.width - 28; control1Y: 17
                            control2X: osdShape.width - 14; control2Y: 3
                            x: osdShape.width; y: 3
                        }
                        // Top bridge over Waybar border
                        PathLine { x: osdShape.width; y: 0 }
                        PathLine { x: 0; y: 0 }
                    }

                    // 2. Continuous accent border (perfect 2px match with Waybar's border at screen y=34..36)
                    ShapePath {
                        strokeWidth: 2
                        strokeColor: Root.Theme.primary
                        fillColor: "transparent"
                        capStyle: ShapePath.FlatCap
                        joinStyle: ShapePath.RoundJoin

                        startX: 0
                        startY: 3

                        PathCubic {
                            control1X: 14; control1Y: 3
                            control2X: 28; control2Y: 17
                            x: 28; y: 31
                        }
                        PathLine { x: 28; y: Math.max(31, osdShape.height - 28) }
                        PathCubic {
                            control1X: 28; control1Y: osdShape.height - 14
                            control2X: 42; control2Y: osdShape.height
                            x: 56; y: osdShape.height
                        }
                        PathLine { x: Math.max(56, osdShape.width - 56); y: osdShape.height }
                        PathCubic {
                            control1X: osdShape.width - 42; control1Y: osdShape.height
                            control2X: osdShape.width - 28; control2Y: osdShape.height - 14
                            x: osdShape.width - 28; y: Math.max(31, osdShape.height - 28)
                        }
                        PathLine { x: osdShape.width - 28; y: 31 }
                        PathCubic {
                            control1X: osdShape.width - 28; control1Y: 17
                            control2X: osdShape.width - 14; control2Y: 3
                            x: osdShape.width; y: 3
                        }
                    }
                }

                // Content layout
                RowLayout {
                    id: cardContent
                    anchors.fill: parent
                    anchors.topMargin: 8
                    anchors.bottomMargin: 4
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
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
