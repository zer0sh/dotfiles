import QtQuick
import QtQuick.Layouts
import "../.." as Root

// Clipboard history card — MD3 style supporting text, thumbnails, feedback, and deletion.
Item {
    id: clipItem

    property string clipId: ""
    property string preview: ""
    property bool isImage: false
    property string thumb: ""
    property bool copiedState: false

    signal clickedItem(string clipId)
    signal deleteItem(string clipId)

    width: parent ? parent.width : 440
    height: card.height + 8

    Timer {
        id: copyResetTimer
        interval: 800
        repeat: false
        onTriggered: clipItem.copiedState = false
    }

    Rectangle {
        id: card
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: Root.Theme.paddingNormal
        anchors.rightMargin: Root.Theme.paddingNormal
        height: clipItem.isImage ? 96 : Math.max(68, cardContent.implicitHeight + 22)
        radius: 16
        color: Qt.rgba(Root.Theme.surfaceContainer.r,
                       Root.Theme.surfaceContainer.g,
                       Root.Theme.surfaceContainer.b, 0.95)
        border.width: 2
        border.color: clipItem.copiedState
            ? Root.Theme.primary
            : (cardHover.containsMouse
                ? Root.Theme.primary
                : Qt.rgba(Root.Theme.primary.r, Root.Theme.primary.g, Root.Theme.primary.b, 0.50))
        Behavior on border.color { ColorAnimation { duration: 150 } }

        RowLayout {
            id: cardContent
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            anchors.topMargin: 10
            anchors.bottomMargin: 10
            spacing: 14

            // ── Image Thumbnail or Text Icon ─────────────────────
            Item {
                Layout.preferredWidth: clipItem.isImage ? 90 : 36
                Layout.preferredHeight: clipItem.isImage ? 68 : 36
                Layout.alignment: Qt.AlignVCenter

                // Text Clip Icon
                Rectangle {
                    anchors.fill: parent
                    visible: !clipItem.isImage
                    radius: 10
                    color: Qt.rgba(Root.Theme.primary.r, Root.Theme.primary.g,
                                   Root.Theme.primary.b, 0.18)

                    Text {
                        anchors.centerIn: parent
                        text: "󰅌"
                        color: Root.Theme.primary
                        font.family: Root.Theme.fontFamily
                        font.pixelSize: 18
                    }
                }

                // Image Thumbnail Preview
                Rectangle {
                    anchors.fill: parent
                    visible: clipItem.isImage
                    radius: 10
                    color: Qt.rgba(0, 0, 0, 0.35)
                    border.width: 1
                    border.color: Qt.rgba(255, 255, 255, 0.12)
                    clip: true

                    Image {
                        anchors.fill: parent
                        anchors.margins: 4
                        source: clipItem.thumb
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        smooth: true
                        mipmap: true
                    }
                }
            }

            // ── Content Info ──────────────────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 3

                Text {
                    text: clipItem.preview
                    color: Root.Theme.textPrimary
                    font.family: Root.Theme.fontFamily
                    font.pixelSize: Root.Theme.fontSizeNormal
                    font.weight: clipItem.isImage ? Font.DemiBold : Font.Normal
                    wrapMode: Text.Wrap
                    elide: Text.ElideRight
                    maximumLineCount: 2
                    lineHeight: 1.2
                    Layout.fillWidth: true
                }

                Text {
                    visible: clipItem.isImage
                    text: "Image • Click to copy"
                    color: Root.Theme.textSecondary
                    font.family: Root.Theme.fontFamily
                    font.pixelSize: Root.Theme.fontSizeXS
                    opacity: 0.7
                    Layout.fillWidth: true
                }
            }

            // ── Actions Right: Copied Feedback or Delete Button ──
            Item {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                Layout.alignment: Qt.AlignVCenter

                // Copied checkmark badge
                Rectangle {
                    anchors.fill: parent
                    radius: 16
                    visible: clipItem.copiedState
                    color: Qt.rgba(Root.Theme.primary.r, Root.Theme.primary.g, Root.Theme.primary.b, 0.22)
                    border.width: 1
                    border.color: Root.Theme.primary

                    Text {
                        anchors.centerIn: parent
                        text: "✓"
                        color: Root.Theme.primary
                        font.family: Root.Theme.fontFamily
                        font.pixelSize: 15
                        font.weight: Font.Bold
                    }
                }

                // Single item delete button
                Rectangle {
                    id: delBtn
                    anchors.fill: parent
                    radius: 16
                    visible: !clipItem.copiedState && (cardHover.containsMouse || delMA.containsMouse)
                    color: delMA.containsMouse
                        ? Qt.rgba(Root.Theme.error.r, Root.Theme.error.g, Root.Theme.error.b, 0.18)
                        : "transparent"
                    border.width: delMA.containsMouse ? 1 : 0
                    border.color: Root.Theme.error

                    Behavior on color { ColorAnimation { duration: 100 } }

                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        color: delMA.containsMouse ? Root.Theme.error : Root.Theme.textSecondary
                        font.family: Root.Theme.fontFamily
                        font.pixelSize: 13
                        font.weight: Font.Bold
                    }

                    MouseArea {
                        id: delMA
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: clipItem.deleteItem(clipItem.clipId)
                    }
                }
            }
        }

        MouseArea {
            id: cardHover
            anchors.fill: parent
            anchors.rightMargin: 40  // Prevent intercepting delete button clicks
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                clipItem.copiedState = true
                copyResetTimer.restart()
                clipItem.clickedItem(clipItem.clipId)
            }
        }
    }
}
