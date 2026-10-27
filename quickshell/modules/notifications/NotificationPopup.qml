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
    property bool   isTop:    true

    signal dismissed(int notifId)

    width:  parent ? parent.width : 380
    height: card.height

    property real _slideY:  -80
    property real _opacity: 0

    Component.onCompleted: appearAnim.start()

    ParallelAnimation {
        id: appearAnim
        NumberAnimation {
            target: root; property: "_slideY"
            from: -Math.max(60, card.height)
            to: 0; duration: 280; easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: root; property: "_opacity"
            from: 0
            to: 1; duration: 200; easing.type: Easing.OutQuad
        }
    }

    ParallelAnimation {
        id: disappearAnim
        NumberAnimation {
            target: root; property: "_slideY"
            to: -Math.max(60, card.height); duration: 200; easing.type: Easing.InQuad
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
        height:  cardContent.implicitHeight + 24

        // Dynamic Island geometry: top edge flat against Waybar when top item, rounded capsule otherwise
        radius:            28
        topLeftRadius:     root.isTop ? 0 : 28
        topRightRadius:    root.isTop ? 0 : 28
        bottomLeftRadius:  28
        bottomRightRadius: 28

        // Matching Waybar and Control Center glass surface
        color: Qt.rgba(Root.Theme._shelfBgColor.r,
                       Root.Theme._shelfBgColor.g,
                       Root.Theme._shelfBgColor.b, 0.80)
        border.width: 0

        Rectangle {
            visible: root.urgency === "CRITICAL"
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.topMargin: root.isTop ? 0 : 6
            anchors.bottomMargin: 6
            width: 4
            radius: 2
            color: Root.Theme.error
        }

        ColumnLayout {
            id: cardContent
            anchors.fill: parent
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            anchors.topMargin: root.isTop ? 10 : 14
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
            topLeftRadius: parent.topLeftRadius
            topRightRadius: parent.topRightRadius
            bottomLeftRadius: parent.bottomLeftRadius
            bottomRightRadius: parent.bottomRightRadius
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
