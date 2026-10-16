import QtQuick
import "../.." as Root

// Large circular quick-setting button used by the first control row.
Item {
    id: control

    property bool active: false
    property string icon: ""
    property string label: ""
    property bool hasDetail: false

    signal clicked()
    signal detailClicked()

    implicitWidth: 68
    implicitHeight: 90

    Rectangle {
        id: button
        width: 60
        height: 60
        anchors.horizontalCenter: parent.horizontalCenter
        radius: width / 2
        color: control.active ? Root.Theme.tileActive : Root.Theme.tileInactive
        border.width: control.active ? 0 : 1
        border.color: Qt.rgba(Root.Theme.textPrimary.r, Root.Theme.textPrimary.g,
                              Root.Theme.textPrimary.b, 0.08)

        Behavior on color {
            ColorAnimation { duration: Root.Theme.animDurationFast }
        }

        Text {
            anchors.centerIn: parent
            text: control.icon
            font.family: Root.Theme.fontFamily
            font.pixelSize: 28
            color: control.active ? Root.Theme.tileActiveText : Root.Theme.tileInactiveText
        }

        // Detail affordance: the main circle toggles, while this small
        // three-dot button opens the secondary page (Wi-Fi/Bluetooth).
        Rectangle {
            visible: control.hasDetail
            width: 20
            height: 20
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: 2
            anchors.rightMargin: 2
            radius: width / 2
            color: Qt.rgba(1, 1, 1, 0.76)
            z: 2

            Text {
                anchors.centerIn: parent
                text: "⋯"
                y: -1
                font.family: Root.Theme.fontFamily
                font.pixelSize: 13
                font.weight: Font.Bold
                color: Root.Theme.panelBg
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: control.detailClicked()
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: control.clicked()
        }
    }

    Text {
        id: labelText
        anchors.top: button.bottom
        anchors.topMargin: 6
        anchors.left: parent.left
        anchors.right: parent.right
        text: control.label
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        font.family: Root.Theme.fontFamily
        font.pixelSize: Root.Theme.fontSizeXS
        color: control.active ? Root.Theme.textPrimary : Root.Theme.textSecondary

        MouseArea {
            anchors.fill: parent
            visible: control.hasDetail
            cursorShape: Qt.PointingHandCursor
            onClicked: control.detailClicked()
        }
    }
}
