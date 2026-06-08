import QtQuick
import Quickshell.Io
import "../.." as Root

Item {
    width: 50
    height: 50

    Rectangle {
        anchors.fill: parent
        radius: 25
        color: Root.Theme.surfaceHigh

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: Root.Theme.hoverOverlay
            opacity: mouseArea.containsMouse ? 1 : 0

            Behavior on opacity {
                NumberAnimation {
                    duration: Root.Theme.animDurationFast
                }
            }
        }

        Text {
            anchors.centerIn: parent
            text: "\uf002"
            font.family: Root.Theme.fontFamily
            font.pixelSize: 22
            color: Root.Theme.textPrimary
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: rofiProc.startDetached()
    }

    Process {
        id: rofiProc
        command: ["rofi", "-show", "drun", "-theme", "/home/mcx/.config/rofi/themes/launcher.rasi"]
    }
}
