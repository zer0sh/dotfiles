import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import "../.." as Root

// VolumeOsd — bottom-center floating card, appears on any volume/mute change
// Auto-dismisses after 2 s of inactivity
Scope {
    id: volumeOsd

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    property var  audio:         Pipewire.defaultAudioSink
    readonly property real  currentVolume:  audio && audio.audio ? audio.audio.volume : 0
    readonly property bool  currentMuted:   audio && audio.audio ? audio.audio.muted  : false
    readonly property int   volumePercent:  Math.round(currentVolume * 100)

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

        // Full-width top strip
        anchors.top:   true
        anchors.left:  true
        anchors.right: true
        implicitHeight: 120

        function showOsd() {
            dismissAnim.stop()
            if (!visible) {
                osdCard._opacity = 0
                osdCard._slideY  = -28
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

        // Appear: slide down + fade in
        ParallelAnimation {
            id: appearAnim
            NumberAnimation {
                target: osdCard; property: "_opacity"
                from: 0; to: 1; duration: 220; easing.type: Easing.OutQuad
            }
            NumberAnimation {
                target: osdCard; property: "_slideY"
                from: -28; to: 0; duration: 260; easing.type: Easing.OutCubic
            }
        }

        // Dismiss: slide up + fade out, then hide window
        SequentialAnimation {
            id: dismissAnim
            ParallelAnimation {
                NumberAnimation {
                    target: osdCard; property: "_opacity"
                    to: 0; duration: 180; easing.type: Easing.InQuad
                }
                NumberAnimation {
                    target: osdCard; property: "_slideY"
                    to: -20; duration: 180; easing.type: Easing.InQuad
                }
            }
            ScriptAction { script: osdWin.visible = false }
        }

        // ── Card container — fixed position at top center below Waybar ────
        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top:              parent.top
            anchors.topMargin:        46
            width:  360
            height: 56

            // The animating card rectangle
            Rectangle {
                id: osdCard
                property real _opacity: 0
                property real _slideY:  -28

                width:   parent.width
                height:  parent.height
                y:       _slideY
                opacity: _opacity

                radius: 27
                color:  Qt.rgba(Root.Theme.panelBg.r,
                                Root.Theme.panelBg.g,
                                 Root.Theme.panelBg.b, 0.80)
                border.width: 2
                border.color: Root.Theme.primary

                RowLayout {
                    anchors.fill:        parent
                    anchors.leftMargin:  20
                    anchors.rightMargin: 20
                    spacing: 12

                    // ── Volume icon ────────────────────────────────
                    Text {
                        text:             volumeOsd.volumeIcon(volumeOsd.currentVolume,
                                                               volumeOsd.currentMuted)
                        font.family:      Root.Theme.fontFamily
                        font.pixelSize:   20
                        color:            volumeOsd.currentMuted
                                              ? Root.Theme.textSecondary
                                              : Root.Theme.primary
                        Layout.alignment: Qt.AlignVCenter

                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    // ── Progress bar ───────────────────────────────
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        height: 7
                        radius: 4
                        color:  Root.Theme.sliderTrack

                        // Active fill
                        Rectangle {
                            anchors.top:    parent.top
                            anchors.bottom: parent.bottom
                            anchors.left:   parent.left
                            width:  Math.max(parent.height,
                                            parent.width * (volumeOsd.currentMuted
                                                            ? 0
                                                            : volumeOsd.currentVolume))
                            radius: parent.radius
                            color:  volumeOsd.currentMuted
                                        ? Qt.rgba(Root.Theme.sliderActiveTrack.r,
                                                  Root.Theme.sliderActiveTrack.g,
                                                  Root.Theme.sliderActiveTrack.b, 0.35)
                                        : Root.Theme.sliderActiveTrack

                            Behavior on width { NumberAnimation { duration: 80 } }
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                    }

                    // ── Percentage / Muted label ───────────────────
                    Text {
                        text:             volumeOsd.currentMuted
                                              ? "Muted"
                                              : (volumeOsd.volumePercent + "%")
                        font.family:      Root.Theme.fontFamily
                        font.pixelSize:   Root.Theme.fontSizeNormal
                        color:            Root.Theme.textPrimary
                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredWidth: 52
                        horizontalAlignment: Text.AlignRight
                    }
                }
            }
        }
    }
}
