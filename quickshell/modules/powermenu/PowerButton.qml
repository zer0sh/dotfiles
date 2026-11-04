import QtQuick
import QtQuick.Layouts
import "../.." as Root

Rectangle {
    id: button

    required property string icon
    required property string label
    property bool selected: false
    property bool isError: false

    signal clicked()
    signal hovered()
    signal unhovered()

    width: 52
    height: 52
    radius: 16

    scale: mouseArea.pressed ? 0.92 : ((mouseArea.containsMouse || selected) ? 1.05 : 1.0)
    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

    readonly property color activeAccent: button.isError ? Root.Theme.error : Root.Theme.primary

    // Dynamic translucent surface
    color: (mouseArea.containsMouse || selected)
           ? (button.isError
               ? Qt.rgba(Root.Theme.error.r, Root.Theme.error.g, Root.Theme.error.b, 0.22)
               : Qt.rgba(Root.Theme.primary.r, Root.Theme.primary.g, Root.Theme.primary.b, 0.20))
           : Qt.rgba(255, 255, 255, 0.07)

    border.color: (mouseArea.containsMouse || selected)
                  ? button.activeAccent
                  : Qt.rgba(255, 255, 255, 0.12)
    border.width: (mouseArea.containsMouse || selected) ? 1.5 : 1

    Behavior on color        { ColorAnimation { duration: Root.Theme.animDurationFast } }
    Behavior on border.color { ColorAnimation { duration: Root.Theme.animDurationFast } }

    Text {
        anchors.centerIn: parent
        text: button.icon
        font.family: Root.Theme.fontFamily
        font.pixelSize: 22

        color: (mouseArea.containsMouse || selected)
               ? button.activeAccent
               : Root.Theme.textPrimary

        Behavior on color { ColorAnimation { duration: Root.Theme.animDurationFast } }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: button.clicked()
        onEntered: button.hovered()
        onExited: button.unhovered()
    }
}
