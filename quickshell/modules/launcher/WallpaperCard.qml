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

    readonly property bool isHovered: mouseArea.containsMouse

    signal activated()

    width: 224
    height: 214

    // Escala dinámica y elevación: sutil y pulida estilo Caelestia
    scale: mouseArea.containsMouse ? 1.05 : (isSelected ? 1.03 : 1.0)
    y: mouseArea.containsMouse ? -5 : (isSelected ? -2 : 0)
    z: mouseArea.containsMouse ? 100 : (isSelected ? 20 : 1)

    Behavior on scale {
        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
    }
    Behavior on y {
        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
    }

    Rectangle {
        id: bgCard
        anchors.fill: parent
        radius: 18
        color: cardRoot.isSelected
            ? Root.Theme.surfaceContainerHigh
            : (mouseArea.containsMouse
                ? Qt.rgba(Root.Theme.surfaceBright.r, Root.Theme.surfaceBright.g, Root.Theme.surfaceBright.b, 0.95)
                : Qt.rgba(Root.Theme.surfaceContainer.r, Root.Theme.surfaceContainer.g, Root.Theme.surfaceContainer.b, 0.65))

        border.width: 2
        border.color: Root.Theme.primary

        Behavior on color { ColorAnimation { duration: 180 } }
        Behavior on border.color { ColorAnimation { duration: 180 } }

        // Halo de resplandor exterior dinámico
        Rectangle {
            anchors.fill: parent
            anchors.margins: mouseArea.containsMouse ? -8 : -5
            radius: 24
            color: "transparent"
            border.width: mouseArea.containsMouse ? 2 : 1
            border.color: (mouseArea.containsMouse || cardRoot.isSelected)
                ? Qt.rgba(Root.Theme.primary.r, Root.Theme.primary.g, Root.Theme.primary.b, mouseArea.containsMouse ? 0.6 : 0.35)
                : "transparent"
            visible: mouseArea.containsMouse || cardRoot.isSelected

            Behavior on anchors.margins { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            Behavior on border.color { ColorAnimation { duration: 200 } }
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
                id: addThumbBox
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 120
                radius: 12
                color: mouseArea.containsMouse
                    ? Qt.rgba(Root.Theme.primary.r, Root.Theme.primary.g, Root.Theme.primary.b, 0.16)
                    : Qt.rgba(Root.Theme.primary.r, Root.Theme.primary.g, Root.Theme.primary.b, 0.08)
                border.width: 1
                border.color: mouseArea.containsMouse
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
                        scale: mouseArea.containsMouse ? 1.15 : 1.0

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
                font.weight: (mouseArea.containsMouse || cardRoot.isSelected) ? Font.Bold : Font.Medium
                color: (mouseArea.containsMouse || cardRoot.isSelected) ? Root.Theme.primary : Root.Theme.textPrimary
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
                    scale: mouseArea.containsMouse ? 1.08 : 1.0
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
                font.weight: (mouseArea.containsMouse || cardRoot.isSelected) ? Font.Bold : Font.Medium
                color: (mouseArea.containsMouse || cardRoot.isSelected) ? Root.Theme.primary : Root.Theme.textPrimary
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
