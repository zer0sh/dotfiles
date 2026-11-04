import QtQuick
import QtQuick.Layouts
import "../.." as Root

BaseCarouselCard {
    id: cardRoot

    property bool isAddCard: false
    property string wallPath: ""
    property string wallTitle: ""
    property string wallThumb: ""
    property bool isCurrentWall: false

    Loader {
        anchors.fill: parent
        sourceComponent: cardRoot.isAddCard ? addCardComp : wallCardComp
    }

    // Componente: Tarjeta para agregar / explorar fondos locales
    Component {
        id: addCardComp
        Item {
            anchors.fill: parent

            Rectangle {
                id: addThumbBox
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 120
                radius: 12
                color: cardRoot.isHovered
                    ? Qt.rgba(Root.Theme.primary.r, Root.Theme.primary.g, Root.Theme.primary.b, 0.16)
                    : Qt.rgba(Root.Theme.primary.r, Root.Theme.primary.g, Root.Theme.primary.b, 0.08)
                border.width: 1
                border.color: cardRoot.isHovered
                    ? Root.Theme.primary
                    : Qt.rgba(Root.Theme.primary.r, Root.Theme.primary.g, Root.Theme.primary.b, 0.35)

                Behavior on color { ColorAnimation { duration: 180 } }
                Behavior on border.color { ColorAnimation { duration: 180 } }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "󰐕"
                        font.family: Root.Theme.fontFamily
                        font.pixelSize: 32
                        color: Root.Theme.primary
                        scale: cardRoot.isHovered ? 1.15 : 1.0

                        Behavior on scale {
                            NumberAnimation { duration: 200; easing.type: Easing.OutBack }
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Browse Local"
                        font.family: Root.Theme.fontFamily
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        color: Root.Theme.primary
                    }
                }
            }

            Text {
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 8
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Add Local File..."
                font.family: Root.Theme.fontFamily
                font.pixelSize: 14
                font.weight: (cardRoot.isHovered || cardRoot.isSelected) ? Font.Bold : Font.Medium
                color: (cardRoot.isHovered || cardRoot.isSelected) ? Root.Theme.primary : Root.Theme.textPrimary
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
                height: 120
                radius: 12
                clip: true
                color: Root.Theme.surface

                Image {
                    id: thumbImg
                    anchors.fill: parent
                    source: cardRoot.wallThumb !== "" ? "file://" + cardRoot.wallThumb : "file://" + cardRoot.wallPath
                    fillMode: Image.PreserveAspectCrop
                    smooth: true
                    asynchronous: true

                    // Zoom sutil interno de la imagen al hacer hover sobre la tarjeta
                    scale: cardRoot.isHovered ? 1.08 : 1.0
                    transformOrigin: Item.Center

                    Behavior on scale {
                        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                    }

                    onStatusChanged: {
                        if (status === Image.Error && cardRoot.wallPath !== "") {
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
                    width: 66
                    height: 22
                    radius: 11
                    color: Root.Theme.primary

                    Row {
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            text: "󰄬"
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: 11
                            color: Root.Theme.tileActiveText
                        }

                        Text {
                            text: "Active"
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: 11
                            font.weight: Font.Bold
                            color: Root.Theme.tileActiveText
                        }
                    }
                }

                // Insignia si está siendo previsualizado
                Rectangle {
                    visible: cardRoot.isSelected && !cardRoot.isCurrentWall
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.margins: 6
                    width: 76
                    height: 22
                    radius: 11
                    color: Qt.rgba(Root.Theme.surfaceBright.r, Root.Theme.surfaceBright.g, Root.Theme.surfaceBright.b, 0.92)
                    border.width: 1
                    border.color: Root.Theme.primary

                    Row {
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            text: "󰄬"
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: 11
                            color: Root.Theme.primary
                        }

                        Text {
                            text: "Preview"
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                            color: Root.Theme.textPrimary
                        }
                    }
                }
            }

            // Título / nombre del archivo
            Text {
                anchors.top: thumbContainer.bottom
                anchors.topMargin: 10
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - 4
                text: cardRoot.wallTitle
                font.family: Root.Theme.fontFamily
                font.pixelSize: 14
                font.weight: (cardRoot.isHovered || cardRoot.isSelected) ? Font.Bold : Font.Medium
                color: (cardRoot.isHovered || cardRoot.isSelected) ? Root.Theme.primary : Root.Theme.textPrimary
                elide: Text.ElideMiddle
                horizontalAlignment: Text.AlignHCenter
            }

            // Indicador de acción al estar seleccionada
            Text {
                visible: cardRoot.isSelected && !cardRoot.isCurrentWall
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 6
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Enter to apply"
                font.family: Root.Theme.fontFamily
                font.pixelSize: 11
                color: Root.Theme.textSecondary
            }
        }
    }
}
