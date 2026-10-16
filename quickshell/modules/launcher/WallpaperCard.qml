import QtQuick
import QtQuick.Layouts
import "../.." as Root

Item {
    id: cardRoot

    property bool isAddCard: false
    property string wallPath: ""
    property string wallTitle: ""
    property string wallThumb: ""
    property bool isCurrentWall: false
    property bool isSelected: false

    signal activated()

    width: 190
    height: 180

    scale: isSelected ? 1.05 : (mouseArea.containsMouse ? 1.02 : 1.0)
    Behavior on scale {
        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
    }

    Rectangle {
        id: bgCard
        anchors.fill: parent
        radius: 16
        color: cardRoot.isSelected
            ? Root.Theme.surfaceContainerHigh
            : (mouseArea.containsMouse ? Root.Theme.surfaceContainer : Qt.rgba(Root.Theme.surfaceContainer.r, Root.Theme.surfaceContainer.g, Root.Theme.surfaceContainer.b, 0.6))

        border.width: cardRoot.isSelected ? 2 : (cardRoot.isCurrentWall ? 1.5 : 1)
        border.color: cardRoot.isSelected
            ? Root.Theme.primary
            : (cardRoot.isCurrentWall
                ? Qt.rgba(Root.Theme.primary.r, Root.Theme.primary.g, Root.Theme.primary.b, 0.6)
                : Qt.rgba(Root.Theme.panelBorder.r, Root.Theme.panelBorder.g, Root.Theme.panelBorder.b, 0.3))

        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }

        // Glow behind selected card
        Rectangle {
            anchors.fill: parent
            anchors.margins: -4
            radius: 20
            color: "transparent"
            border.width: 1
            border.color: cardRoot.isSelected
                ? Qt.rgba(Root.Theme.primary.r, Root.Theme.primary.g, Root.Theme.primary.b, 0.4)
                : "transparent"
            visible: cardRoot.isSelected
        }

        // --- Contenido según tipo de tarjeta ---
        Loader {
            anchors.fill: parent
            anchors.margins: 10
            sourceComponent: cardRoot.isAddCard ? addCardComp : wallCardComp
        }
    }

    // Componente: Tarjeta para agregar / explorar fondos locales
    Component {
        id: addCardComp
        Item {
            anchors.fill: parent

            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 100
                radius: 10
                color: Qt.rgba(Root.Theme.primary.r, Root.Theme.primary.g, Root.Theme.primary.b, 0.08)
                border.width: 1
                border.color: Qt.rgba(Root.Theme.primary.r, Root.Theme.primary.g, Root.Theme.primary.b, 0.3)

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "󰐕"
                        font.family: Root.Theme.fontFamily
                        font.pixelSize: 28
                        color: Root.Theme.primary
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Browse"
                        font.family: Root.Theme.fontFamily
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        color: Root.Theme.primary
                    }
                }
            }

            Text {
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 6
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Add Local File..."
                font.family: Root.Theme.fontFamily
                font.pixelSize: 12
                font.weight: Font.Medium
                color: cardRoot.isSelected ? Root.Theme.primary : Root.Theme.textPrimary
            }
        }
    }

    // Componente: Tarjeta con miniatura 16:9 de wallpaper
    Component {
        id: wallCardComp
        Item {
            anchors.fill: parent

            // Contenedor de la miniatura 16:9
            Rectangle {
                id: thumbContainer
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width
                height: 100
                radius: 10
                clip: true
                color: Root.Theme.surface

                Image {
                    id: thumbImg
                    anchors.fill: parent
                    source: cardRoot.wallThumb !== "" ? "file://" + cardRoot.wallThumb : "file://" + cardRoot.wallPath
                    fillMode: Image.PreserveAspectCrop
                    smooth: true
                    asynchronous: true

                    onStatusChanged: {
                        if (status === Image.Error && cardRoot.wallPath !== "") {
                            // Fallback al archivo original si la miniatura falla
                            source = "file://" + cardRoot.wallPath;
                        }
                    }
                }

                // Insignia si es el fondo activo actualmente
                Rectangle {
                    visible: cardRoot.isCurrentWall
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.margins: 6
                    width: 54
                    height: 18
                    radius: 9
                    color: Root.Theme.primary

                    Text {
                        anchors.centerIn: parent
                        text: "Active"
                        font.family: Root.Theme.fontFamily
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        color: Root.Theme.tileActiveText
                    }
                }
            }

            // Título / nombre del archivo
            Text {
                anchors.top: thumbContainer.bottom
                anchors.topMargin: 8
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - 4
                text: cardRoot.wallTitle
                font.family: Root.Theme.fontFamily
                font.pixelSize: 12
                font.weight: cardRoot.isSelected ? Font.Bold : Font.Normal
                color: cardRoot.isSelected ? Root.Theme.primary : Root.Theme.textPrimary
                elide: Text.ElideMiddle
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: cardRoot.activated()
    }
}
