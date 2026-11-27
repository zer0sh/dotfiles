import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import "../.." as Root

// VolumeOsd — Dynamic Island style anchored directly beneath Waybar
// Auto-dismisses after 2 s of inactivity
Scope {
    id: volumeOsd

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    property var  audio:          Pipewire.defaultAudioSink
    readonly property real currentVolume: audio && audio.audio ? audio.audio.volume : 0
    readonly property bool currentMuted:  audio && audio.audio ? audio.audio.muted  : false
    readonly property int  volumePercent: Math.round(currentVolume * 100)

    // Ignore initial Pipewire property population on startup
    property bool _ready: false
    Component.onCompleted: readyTimer.start()
    Timer { id: readyTimer; interval: 600; repeat: false; onTriggered: volumeOsd._ready = true }

    onCurrentVolumeChanged: if (_ready) osdWin.showOsd()
    onCurrentMutedChanged:  if (_ready) osdWin.showOsd()

    function volumeIcon(vol, muted) {
        if (muted || vol === 0) return "󰖁"
        if (vol < 0.34)         return "󰕿"
        if (vol < 0.67)         return "󰖀"
        return "󰕾"
    }

    // ── Overlay window ──────────────────────────────────────────────
    PanelWindow {
        id: osdWin
        visible: false
        color:   "transparent"
        exclusionMode:               ExclusionMode.Ignore
        WlrLayershell.layer:         WlrLayer.Overlay
        WlrLayershell.namespace:     "quickshell:volume-osd"
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

        // Auto-dismiss
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
                    border.color: volumeOsd.currentMuted
                        ? Qt.rgba(Root.Theme.error.r, Root.Theme.error.g, Root.Theme.error.b, 0.70)
                        : Qt.rgba(Root.Theme.panelBorder.r, Root.Theme.panelBorder.g, Root.Theme.panelBorder.b, 0.60)

                    Behavior on border.color { ColorAnimation { duration: 180 } }
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
                            color: volumeOsd.currentMuted
                                ? Qt.rgba(Root.Theme.error.r, Root.Theme.error.g, Root.Theme.error.b, 0.16)
                                : Qt.rgba(Root.Theme.primary.r, Root.Theme.primary.g, Root.Theme.primary.b, 0.14)

                            Behavior on color { ColorAnimation { duration: 180 } }

                            Text {
                                anchors.centerIn: parent
                                text: volumeOsd.volumeIcon(volumeOsd.currentVolume, volumeOsd.currentMuted)
                                font.family: Root.Theme.fontFamily
                                font.pixelSize: 18
                                color: volumeOsd.currentMuted
                                    ? Root.Theme.error
                                    : Root.Theme.primary

                                Behavior on color { ColorAnimation { duration: 180 } }
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
                                width: volumeOsd.currentMuted
                                    ? 0
                                    : Math.max(parent.height, parent.width * Math.min(1.0, volumeOsd.currentVolume))
                                radius: parent.radius
                                color: volumeOsd.currentMuted
                                    ? Qt.rgba(Root.Theme.sliderActiveTrack.r, Root.Theme.sliderActiveTrack.g, Root.Theme.sliderActiveTrack.b, 0.3)
                                    : Root.Theme.sliderActiveTrack

                                Behavior on width { NumberAnimation { duration: 90; easing.type: Easing.OutQuad } }
                                Behavior on color { ColorAnimation { duration: 180 } }
                            }
                        }

                        // Percentage or Muted badge
                        Text {
                            text: volumeOsd.currentMuted ? "MUTED" : (volumeOsd.volumePercent + "%")
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: Root.Theme.fontSizeNormal
                            font.bold: true
                            color: volumeOsd.currentMuted
                                ? Root.Theme.error
                                : Root.Theme.textPrimary
                            Layout.alignment: Qt.AlignVCenter
                            Layout.preferredWidth: 54
                            horizontalAlignment: Text.AlignRight

                            Behavior on color { ColorAnimation { duration: 180 } }
                        }
                    }
                }
            }
        }
    }
