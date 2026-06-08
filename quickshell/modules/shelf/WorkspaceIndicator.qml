import QtQuick
import Quickshell.Hyprland
import "../.." as Root

Row {
    spacing: 6
    height: 10

    Repeater {
        model: Hyprland.workspaces

        delegate: Rectangle {
            height: 10
            radius: 5

            property bool isActive: Hyprland.focusedMonitor !== null && modelData.id === Hyprland.focusedMonitor.activeWorkspace.id

            width: isActive ? 28 : 10
            color: isActive ? Root.Theme.accent : Root.Theme.textDisabled

            Behavior on width {
                NumberAnimation {
                    duration: Root.Theme.animDurationFast
                    easing.type: Easing.InOutQuad
                }
            }

            Behavior on color {
                ColorAnimation {
                    duration: Root.Theme.animDurationFast
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: modelData.activate()
            }
        }
    }
}
