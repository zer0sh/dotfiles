import QtQuick
import QtQuick.Layouts
import "../.." as Root

Item {
    id: root

    property int    notifId:  0
    property string appName:  ""
    property string summary:  ""
    property string body:     ""
    property string urgency:  "NORMAL"

    signal dismissed(int notifId)

    width:  parent ? parent.width : 360
    height: card.height

    property real _slideY:  -28
    property real _opacity: 0

    Component.onCompleted: appearAnim.start()

    ParallelAnimation {
        id: appearAnim
        NumberAnimation {
            target: root; property: "_slideY"
            from: -28
            to: 0; duration: 280; easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: root; property: "_opacity"
            from: 0
            to: 1; duration: 220; easing.type: Easing.OutQuad
        }
    }

    ParallelAnimation {
        id: disappearAnim
        NumberAnimation {
            target: root; property: "_slideY"
            to: -20; duration: 180; easing.type: Easing.InQuad
        }
        NumberAnimation {
            target: root; property: "_opacity"
            to: 0; duration: 160; easing.type: Easing.InQuad
        }
        onFinished: root.dismissed(root.notifId)
    }

    function dismiss() {
        if (!disappearAnim.running) {
            appearAnim.stop()
            disappearAnim.start()
        }
    }

    Rectangle {
        id: card
        anchors.left: parent.left
        anchors.right: parent.right
        y:       root._slideY
        opacity: root._opacity
        height:  cardContent.implicitHeight + 28
        radius:  27
        color:   Qt.rgba(Root.Theme.panelBg.r,
                         Root.Theme.panelBg.g,
                         Root.Theme.panelBg.b, 0.92)
        border.width: 1
        border.color: root.urgency === "CRITICAL"
            ? Root.Theme.error
            : Qt.rgba(Root.Theme.primary.r, Root.Theme.primary.g,
                     Root.Theme.primary.b, 0.55)

        Rectangle {
            visible: root.urgency === "CRITICAL"
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 4
            radius: 2
            color: Root.Theme.error
        }

        ColumnLayout {
            id: cardContent
            anchors.fill: parent
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            anchors.topMargin: 14
            anchors.bottomMargin: 14
            spacing: 4

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Rectangle {
                    visible: root.urgency === "CRITICAL"
                    width: 6; height: 6; radius: 3
                    color: Root.Theme.error
                    Layout.alignment: Qt.AlignVCenter
                }

                Text {
                    text: root.appName !== "" ? root.appName : "Notification"
                    color: Root.Theme.primary
                    font.family: Root.Theme.fontFamily
                    font.pixelSize: Root.Theme.fontSizeXS
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Rectangle {
                    visible: false
                    width: 24; height: 24; radius: 12
                    color: dismissArea.containsMouse
                        ? Qt.rgba(Root.Theme.textSecondary.r, Root.Theme.textSecondary.g, Root.Theme.textSecondary.b, 0.15)
                        : "transparent"
                    Behavior on color { ColorAnimation { duration: 100 } }

                    Text {
                        anchors.centerIn: parent
                        text: "󰅖"
                        color: Root.Theme.textSecondary
                        font.family: Root.Theme.fontFamily
                        font.pixelSize: 12
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

            Text {
                text: root.summary
                color: Root.Theme.textPrimary
                font.family: Root.Theme.fontFamily
                font.pixelSize: Root.Theme.fontSizeNormal
                font.weight: Font.DemiBold
                elide: Text.ElideRight
                Layout.fillWidth: true
                visible: root.summary !== ""
            }

            Text {
                text: root.body
                color: Root.Theme.textSecondary
                font.family: Root.Theme.fontFamily
                font.pixelSize: Root.Theme.fontSizeSmall
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                elide: Text.ElideRight
                Layout.fillWidth: true
                visible: root.body !== ""
                lineHeight: 1.3
            }
        }

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
            acceptedButtons: Qt.LeftButton
            onClicked: root.dismiss()
        }
    }
}
