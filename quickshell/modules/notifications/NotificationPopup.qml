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

    readonly property color currentBorderColor: (root.urgency === "CRITICAL")
        ? Root.Theme.error
        : Root.Theme.primary

    readonly property color cardBgColor: Qt.rgba(Root.Theme.panelBg.r,
                                                 Root.Theme.panelBg.g,
                                                 Root.Theme.panelBg.b, 0.85)

    Item {
        id: card
        anchors.left: parent.left
        anchors.right: parent.right
        y:       root._slideY
        opacity: root._opacity
        height:  cardContent.implicitHeight + 24

        // ── Silueta unificada superior: cuerpo + hombros cóncavos con borde continuo ──
        Shape {
            id: topIslandShape
            visible: root.isTop
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width + 56
            height: parent.height
            layer.enabled: true
            layer.samples: 4

            // 1. Relleno continuo sin costuras
            ShapePath {
                strokeWidth: 0
                strokeColor: "transparent"
                fillColor: root.cardBgColor

                startX: 0
                startY: 0

                // Curva cóncava hombro izquierdo
                PathArc {
                    x: 28; y: 28
                    radiusX: 28; radiusY: 28
                    direction: PathArc.Clockwise
                }
                // Lateral izquierdo
                PathLine { x: 28; y: Math.max(28, topIslandShape.height - 28) }
                // Esquina inferior izquierda
                PathArc {
                    x: 56; y: topIslandShape.height
                    radiusX: 28; radiusY: 28
                    direction: PathArc.Counterclockwise
                }
                // Base horizontal
                PathLine { x: Math.max(56, topIslandShape.width - 56); y: topIslandShape.height }
                // Esquina inferior derecha
                PathArc {
                    x: topIslandShape.width - 28; y: Math.max(28, topIslandShape.height - 28)
                    radiusX: 28; radiusY: 28
                    direction: PathArc.Counterclockwise
                }
                // Lateral derecho
                PathLine { x: topIslandShape.width - 28; y: 28 }
                // Curva cóncava hombro derecho
                PathArc {
                    x: topIslandShape.width; y: 0
                    radiusX: 28; radiusY: 28
                    direction: PathArc.Clockwise
                }
                // Cierre superior contra Waybar
                PathLine { x: 0; y: 0 }
            }

            // 2. Borde perimetral estilo ventana (cubre hombros, laterales y base; abierto hacia Waybar)
            ShapePath {
                strokeWidth: 2
                strokeColor: root.currentBorderColor
                fillColor: "transparent"
                capStyle: ShapePath.FlatCap
                joinStyle: ShapePath.RoundJoin

                Behavior on strokeColor { ColorAnimation { duration: 150 } }

                startX: 0
                startY: 0

                // Curva cóncava hombro izquierdo
                PathArc {
                    x: 28; y: 28
                    radiusX: 28; radiusY: 28
                    direction: PathArc.Clockwise
                }
                // Lateral izquierdo
                PathLine { x: 28; y: Math.max(28, topIslandShape.height - 28) }
                // Esquina inferior izquierda
                PathArc {
                    x: 56; y: topIslandShape.height
                    radiusX: 28; radiusY: 28
                    direction: PathArc.Counterclockwise
                }
                // Base horizontal
                PathLine { x: Math.max(56, topIslandShape.width - 56); y: topIslandShape.height }
                // Esquina inferior derecha
                PathArc {
                    x: topIslandShape.width - 28; y: Math.max(28, topIslandShape.height - 28)
                    radiusX: 28; radiusY: 28
                    direction: PathArc.Counterclockwise
                }
                // Lateral derecho
                PathLine { x: topIslandShape.width - 28; y: 28 }
                // Curva cóncava hombro derecho
                PathArc {
                    x: topIslandShape.width; y: 0
                    radiusX: 28; radiusY: 28
                    direction: PathArc.Clockwise
                }
            }
        }

        // ── Notificación posterior (cápsula independiente redondeada con borde de ventana) ──
        Rectangle {
            id: bottomIslandRect
            visible: !root.isTop
            anchors.fill: parent
            radius: 28
            color: root.cardBgColor
            border.width: 2
            border.color: root.currentBorderColor
            Behavior on border.color { ColorAnimation { duration: 150 } }
        }

        Rectangle {
            visible: root.urgency === "CRITICAL"
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.topMargin: root.isTop ? 0 : 6
            anchors.bottomMargin: 6
            anchors.leftMargin: 2
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
