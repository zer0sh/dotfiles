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

        // Auto-dismiss
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
            ScriptAction { script: osdWin.visible = false }
        }

        // ── Card container anchored directly to Waybar shelf ─────────
        Item {
            id: osdWrapper
            width: 416
            height: 56
            anchors.top: parent.top
            anchors.topMargin: Root.Theme.shelfHeight
            anchors.horizontalCenter: parent.horizontalCenter

            // Clipping container so the island drops smoothly from behind Waybar
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

                            // Concave shoulder fillet (left)
                            PathArc {
                                x: 28; y: 28
                                radiusX: 28; radiusY: 28
                                direction: PathArc.Clockwise
                            }
                            // Left flank
                            PathLine { x: 28; y: Math.max(28, osdShape.height - 28) }
                            // Bottom-left rounded corner
                            PathArc {
                                x: 56; y: osdShape.height
                                radiusX: 28; radiusY: 28
                                direction: PathArc.Counterclockwise
                            }
                            // Bottom horizontal base
                            PathLine { x: Math.max(56, osdShape.width - 56); y: osdShape.height }
                            // Bottom-right rounded corner
                            PathArc {
                                x: osdShape.width - 28; y: Math.max(28, osdShape.height - 28)
                                radiusX: 28; radiusY: 28
                                direction: PathArc.Counterclockwise
                            }
                            // Right flank
                            PathLine { x: osdShape.width - 28; y: 28 }
                            // Concave shoulder fillet (right)
                            PathArc {
                                x: osdShape.width; y: 0
                                radiusX: 28; radiusY: 28
                                direction: PathArc.Clockwise
                            }
                            // Top close against Waybar
                            PathLine { x: 0; y: 0 }
                        }

                        // 2. Continuous accent border (open along Waybar shelf)
                        ShapePath {
                            strokeWidth: 2
                            strokeColor: volumeOsd.currentMuted
                                ? Qt.rgba(Root.Theme.error.r, Root.Theme.error.g, Root.Theme.error.b, 0.85)
                                : Root.Theme.primary
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
}
