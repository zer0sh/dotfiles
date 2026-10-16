import QtQuick
import QtQuick.Layouts
import "../.." as Root

// Clipboard history card — one copied text entry.
// Used by ClipboardPanel's ListView.
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
        color: Qt.rgba(0x0D/255, 0x11/255, 0x1F/255, 0.9)
        border.width: 1
        border.color: Qt.rgba(Root.Theme.primary.r, Root.Theme.primary.g,
                              Root.Theme.primary.b, 0.55)

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
                color: "#E5E1E9"
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

        // Hover overlay
        Rectangle {
            anchors.fill: parent
            color: Root.Theme.textPrimary
            opacity: cardHover.containsMouse ? 0.05 : 0
            radius: parent.radius
            Behavior on opacity { NumberAnimation { duration: 120 } }
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
