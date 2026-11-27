import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
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

    // dots-hyprland Expressive Spatial spring slide
    ParallelAnimation {
        id: appearAnim
        NumberAnimation {
            target: root; property: "_slideY"
            from: -Math.max(60, card.height)
            to: 0; duration: Root.Theme.animDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Root.Theme.curvePanelOpen
        }
        NumberAnimation {
            target: root; property: "_opacity"
            from: 0
            to: 1; duration: 200
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Root.Theme.curveEmphasizedDecel
        }
    }

    // dots-hyprland Emphasized Accel close
    ParallelAnimation {
        id: disappearAnim
        NumberAnimation {
            target: root; property: "_slideY"
            to: -Math.max(60, card.height)
            duration: Root.Theme.animDurationFast
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Root.Theme.curvePanelClose
        }
        NumberAnimation {
            target: root; property: "_opacity"
            to: 0
            duration: 140
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Root.Theme.curvePanelClose
        }
        onFinished: root.dismissed(root.notifId)
    }

    function dismiss() {
        if (!disappearAnim.running) {
            appearAnim.stop()
            disappearAnim.start()
        }
    }

    readonly property color currentBorderColor: (root.urgency === "CRITICAL")
        ? Root.Theme.error
        : Root.Theme.panelBorder

    readonly property color cardBgColor: Root.Theme.panelBg

    Item {
        id: card
        anchors.left: parent.left
        anchors.right: parent.right
        y:       root._slideY
        opacity: root._opacity
        height:  cardContent.implicitHeight + 24

        // ── Fondo flotante unificado independiente ──
        Rectangle {
            id: floatingCardBg
            anchors.fill: parent
            radius: 24
            color: root.cardBgColor
            border.width: 1.5
            border.color: root.currentBorderColor
            Behavior on border.color { ColorAnimation { duration: 150 } }
        }

        Rectangle {
            visible: root.urgency === "CRITICAL"
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.topMargin: 6
            anchors.bottomMargin: 6
            anchors.leftMargin: 4
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
                    width: 6; height: 6; radius: 3
                    color: root.urgency === "CRITICAL" ? Root.Theme.error : Root.Theme.primary
                    Layout.alignment: Qt.AlignVCenter
                }

                Text {
                    text: root.appName !== "" ? root.appName : "Notification"
                    color: Root.Theme.primary
                    font.family: Root.Theme.fontFamily
                    font.pixelSize: Root.Theme.fontSizeXS
                    font.weight: Font.DemiBold
                    font.capitalization: Font.AllUppercase
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

        MouseArea {
            id: cardHover
            anchors.fill: parent
            anchors.leftMargin: root.isTop ? -28 : 0
            anchors.rightMargin: root.isTop ? -28 : 0
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton
            onClicked: root.dismiss()
        }
    }
}
