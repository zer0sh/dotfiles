import QtQuick
import QtQuick.Layouts
import "../.." as Root

// Notification card — MD3 / Android 16 style
// Used by NotificationCenter's ListView
Item {
    id: notifItem

    // Properties set by the ListView delegate
    property int notifId: 0
    property string appName: ""
    property string summary: ""
    property string body: ""
    property string urgency: "NORMAL"
    property int timestamp: 0
    property string timeAgo: ""

    signal dismissed(int notifId)

    width: parent ? parent.width : 440
    height: card.height + 8

    Rectangle {
        id: card
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: Root.Theme.paddingNormal
        anchors.rightMargin: Root.Theme.paddingNormal
        height: cardContent.implicitHeight + 24  // 12 top + 12 bottom
        radius: 16
        color: Qt.rgba(0x0D/255, 0x11/255, 0x1F/255, 0.9)
        border.width: 1
        border.color: urgency === "CRITICAL"
            ? Root.Theme.error
            : Qt.rgba(Root.Theme.primary.r, Root.Theme.primary.g,
                     Root.Theme.primary.b, 0.55)

        ColumnLayout {
            id: cardContent
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            anchors.topMargin: 18
            anchors.bottomMargin: 18
            spacing: 6

            // ── Header: app name · time · dismiss ────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                // Urgency dot
                Rectangle {
                    visible: urgency === "CRITICAL"
                    width: 8; height: 8; radius: 4
                    color: Root.Theme.error
                    Layout.alignment: Qt.AlignVCenter
                }

                // App name
                Text {
                    text: appName
                    color: "#E5E1E9"
                    font.family: Root.Theme.fontFamily
                    font.pixelSize: Root.Theme.fontSizeXS
                    font.weight: Font.Medium
                    font.capitalization: Font.AllUppercase
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                // Timestamp
                Text {
                    text: timeAgo
                    color: "#E5E1E9"
                    font.family: Root.Theme.fontFamily
                    font.pixelSize: Root.Theme.fontSizeXS
                    visible: timeAgo !== ""
                }

                // Dismiss button
                Rectangle {
                    width: 26; height: 26; radius: 13
                    color: dismissArea.containsMouse
                        ? Qt.rgba(Root.Theme.textSecondary.r, Root.Theme.textSecondary.g, Root.Theme.textSecondary.b, 0.15)
                        : "transparent"
                    Behavior on color { ColorAnimation { duration: 100 } }

                    Text {
                        anchors.centerIn: parent
                        text: "󰅖"
                        color: "#E5E1E9"
                        font.family: Root.Theme.fontFamily
                        font.pixelSize: 13
                    }

                    MouseArea {
                        id: dismissArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.dismissed(root.notifId)
                    }
                }
            }

            // ── Summary (title) ──────────────────────────────
            Text {
                text: summary
                color: "#E5E1E9"
                font.family: Root.Theme.fontFamily
                font.pixelSize: Root.Theme.fontSizeNormal
                font.weight: Font.DemiBold
                elide: Text.ElideRight
                Layout.fillWidth: true
                visible: summary !== ""
            }

            // ── Body text (3 lines max) ──────────────────────
            Text {
                text: root.body
                color: "#E5E1E9"
                font.family: Root.Theme.fontFamily
                font.pixelSize: 15
                wrapMode: Text.WordWrap
                maximumLineCount: 3
                elide: Text.ElideRight
                Layout.fillWidth: true
                visible: body !== ""
                lineHeight: 1.3
            }

            // Bottom spacing
            Item {
                height: 2
                Layout.fillWidth: true
            }
        }

        // Hover overlay
        Rectangle {
            anchors.fill: parent
            color: Root.Theme.textPrimary
            opacity: cardHover.containsMouse ? 0.04 : 0
            radius: parent.radius
            Behavior on opacity { NumberAnimation { duration: 120 } }
        }

        MouseArea {
            id: cardHover
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
        }
    }
}
