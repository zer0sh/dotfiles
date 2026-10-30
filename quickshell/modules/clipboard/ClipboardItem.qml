import QtQuick
import QtQuick.Layouts
import "../.." as Root

// Clipboard history card — MD3 style aligned with NotificationItem
Item {
    id: clipItem

    property string clipId: ""
    property string preview: ""

    signal clickedItem(string clipId)

    width: parent ? parent.width : 440
    height: card.height + 8

    Rectangle {
        id: card
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: Root.Theme.paddingNormal
        anchors.rightMargin: Root.Theme.paddingNormal
        height: cardContent.implicitHeight + 24
        radius: 16
        color: Qt.rgba(Root.Theme.surfaceContainer.r,
                       Root.Theme.surfaceContainer.g,
                       Root.Theme.surfaceContainer.b, 0.95)
        border.width: 2
        border.color: cardHover.containsMouse
            ? Root.Theme.primary
            : Qt.rgba(Root.Theme.primary.r, Root.Theme.primary.g, Root.Theme.primary.b, 0.70)
        Behavior on border.color { ColorAnimation { duration: 150 } }

        RowLayout {
            id: cardContent
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            anchors.topMargin: 14
            anchors.bottomMargin: 14
            spacing: 14

            // Clip icon
            Rectangle {
                width: 36; height: 36; radius: 10
                color: Qt.rgba(Root.Theme.primary.r, Root.Theme.primary.g,
                               Root.Theme.primary.b, 0.18)
                Layout.alignment: Qt.AlignVCenter

                Text {
                    anchors.centerIn: parent
                    text: "󰅌"
                    color: Root.Theme.primary
                    font.family: Root.Theme.fontFamily
                    font.pixelSize: 18
                }
            }

            // Preview (2 lines max)
            Text {
                text: clipItem.preview
                color: Root.Theme.textPrimary
                font.family: Root.Theme.fontFamily
                font.pixelSize: Root.Theme.fontSizeNormal
                wrapMode: Text.Wrap
                elide: Text.ElideRight
                maximumLineCount: 2
                lineHeight: 1.25
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
            }
        }

        MouseArea {
            id: cardHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: clipItem.clickedItem(clipItem.clipId)
        }
    }
}
