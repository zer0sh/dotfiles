import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../.." as Root

Scope {
    id: brightnessOsd

    property real brightness: 1.0
    readonly property int brightnessPercent: Math.round(brightness * 100)
    property real _maxBrightness: -1

    Process {
        id: maxProc
        command: ["brightnessctl", "--class=backlight", "max"]
        stdout: StdioCollector {
            onStreamFinished: {
                var val = parseFloat(text.trim());
                if (!isNaN(val) && val > 0)
                    brightnessOsd._maxBrightness = val;
            }
        }
        Component.onCompleted: running = true
    }

    Process {
        id: readProc
        command: ["brightnessctl", "--class=backlight", "get"]
        stdout: StdioCollector {
            onStreamFinished: {
                var val = parseFloat(text.trim());
                if (!isNaN(val) && brightnessOsd._maxBrightness > 0) {
                    var newBrightness = val / brightnessOsd._maxBrightness;
                    if (Math.abs(newBrightness - brightnessOsd.brightness) > 0.001) {
                        brightnessOsd.brightness = newBrightness;
                        osdWin.showOsd();
                    }
                }
            }
        }
    }

    Timer {
        interval: 300
        running: true
        repeat: true
        onTriggered: {
            readProc.running = true
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
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell:brightness-osd"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        anchors.top:   true
        anchors.left:  true
        anchors.right: true
        implicitHeight: 120

        function showOsd() {
            dismissAnim.stop()
            if (!visible) {
                osdCard._opacity = 0
                osdCard._slideY = -28
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

        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top:              parent.top
            anchors.topMargin:        46
            width: 360
            height: 56

            Rectangle {
                id: osdCard
                property real _opacity: 0
                property real _slideY: -28

                width: parent.width
                height: parent.height
                y: _slideY
                opacity: _opacity

                radius: 27
                color: Qt.rgba(Root.Theme.panelBg.r, Root.Theme.panelBg.g, Root.Theme.panelBg.b, 0.80)
                border.width: 1
                border.color: Qt.rgba(Root.Theme.panelBorder.r, Root.Theme.panelBorder.g, Root.Theme.panelBorder.b, 0.45)

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 20
                    anchors.rightMargin: 20
                    spacing: 12

                    Text {
                        text: brightnessOsd.brightnessIcon(brightnessOsd.brightness)
                        font.family: Root.Theme.fontFamily
                        font.pixelSize: 20
                        color: Root.Theme.primary
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        height: 7
                        radius: 4
                        color: Root.Theme.sliderTrack

                        Rectangle {
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            width: Math.max(parent.height, parent.width * brightnessOsd.brightness)
                            radius: parent.radius
                            color: Root.Theme.sliderActiveTrack
                            Behavior on width { NumberAnimation { duration: 80 } }
                        }
                    }

                    Text {
                        text: brightnessOsd.brightnessPercent + "%"
                        font.family: Root.Theme.fontFamily
                        font.pixelSize: Root.Theme.fontSizeNormal
                        color: Root.Theme.textPrimary
                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredWidth: 52
                        horizontalAlignment: Text.AlignRight
                    }
                }
            }
        }
    }
}
