import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../.." as Root

Scope {
    id: indicator

    property bool recording: false
    property int startedAt: 0
    property int elapsedSeconds: 0

    function formatTime(totalSeconds) {
        var minutes = Math.floor(totalSeconds / 60)
        var seconds = totalSeconds % 60
        return (minutes < 10 ? "0" : "") + minutes + ":" +
               (seconds < 10 ? "0" : "") + seconds
    }

    Process {
        id: statusProc
        command: ["sh", "-c",
            "if [ -f /tmp/hypr-wf-recorder.pid ] && " +
            "kill -0 $(cat /tmp/hypr-wf-recorder.pid) 2>/dev/null && " +
            "[ -f /tmp/hypr-wf-recorder.started ]; then " +
            "cat /tmp/hypr-wf-recorder.started; fi"]

        stdout: StdioCollector {
            onStreamFinished: {
                var value = parseInt(text.trim())
                if (!isNaN(value) && value > 0) {
                    indicator.startedAt = value
                    indicator.recording = true
                    indicator.elapsedSeconds = Math.max(0, Math.floor(Date.now() / 1000) - value)
                } else {
                    indicator.recording = false
                    indicator.startedAt = 0
                    indicator.elapsedSeconds = 0
                }
            }
        }
    }

    Timer {
        interval: 500
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            statusProc.running = true
            if (indicator.recording && indicator.startedAt > 0)
                indicator.elapsedSeconds = Math.max(0, Math.floor(Date.now() / 1000) - indicator.startedAt)
        }
    }

    PanelWindow {
        id: recordingWindow
        visible: indicator.recording
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore

        anchors {
            top: true
            left: true
            right: true
        }

        // Keep the indicator below the shelf/Waybar with a 22px gap.
        implicitHeight: Root.Theme.shelfHeight + 22 + 52
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell:recording-indicator"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: Root.Theme.shelfHeight + 22
            width: 174
            height: 36
            radius: height / 2
            color: Qt.rgba(Root.Theme.panelBg.r, Root.Theme.panelBg.g,
                           Root.Theme.panelBg.b, 0.94)
            border.width: 1
            border.color: Qt.rgba(Root.Theme.error.r, Root.Theme.error.g,
                                  Root.Theme.error.b, 0.65)

            Row {
                anchors.centerIn: parent
                spacing: 8

                Rectangle {
                    width: 9
                    height: 9
                    radius: width / 2
                    anchors.verticalCenter: parent.verticalCenter
                    color: Root.Theme.error

                    SequentialAnimation on opacity {
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.35; duration: 650 }
                        NumberAnimation { to: 1.0; duration: 650 }
                    }
                }

                Text {
                    text: "REC  " + indicator.formatTime(indicator.elapsedSeconds)
                    font.family: Root.Theme.fontFamily
                    font.pixelSize: Root.Theme.fontSizeSmall
                    font.weight: Font.DemiBold
                    color: Root.Theme.textPrimary
                }
            }
        }
    }
}
