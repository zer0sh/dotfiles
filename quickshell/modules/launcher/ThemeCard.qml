import QtQuick
import QtQuick.Layouts
import "../.." as Root

Item {
    id: cardRoot

    property string themeKey: ""
    property string themeTitle: ""
    property string themeSubtitle: ""
    property bool isCurrentTheme: false
    property bool isSelected: false

    readonly property bool isHovered: mouseArea.containsMouse

    signal activated()

    width: 224
    height: 214

    // Escala dinámica y elevación
    scale: mouseArea.containsMouse ? 1.05 : (isSelected ? 1.03 : 1.0)
    y: mouseArea.containsMouse ? -5 : (isSelected ? -2 : 0)
    z: mouseArea.containsMouse ? 100 : (isSelected ? 20 : 1)

    Behavior on scale {
        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
    }
    Behavior on y {
        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
    }

    readonly property var cardData: {
        if (themeKey === "matugen" && Root.Theme._generated) {
            return Root.Theme._generated;
        }
        if (themeKey === "custom" && Root.Theme._customTheme) {
            return Root.Theme._customTheme;
        }
        return (Root.Theme._themes && Root.Theme._themes[themeKey])
            ? Root.Theme._themes[themeKey]
            : (Root.Theme._themes ? Root.Theme._themes["md3-cobalt-night"] : null);
    }

    readonly property color themePrimary: cardData ? Qt.color(cardData.primary) : Root.Theme.primary
    readonly property color themePrimaryContainer: cardData ? Qt.color(cardData.primaryContainer) : Root.Theme.primaryContainer
    readonly property color themeSurface: cardData ? Qt.color(cardData.surface) : Root.Theme.surface
    readonly property color themeSurfaceContainer: cardData ? Qt.color(cardData.surfaceContainer) : Root.Theme.surfaceContainer
    readonly property color themeSurfaceContainerHigh: cardData ? Qt.color(cardData.surfaceContainerHigh) : Root.Theme.surfaceContainerHigh
    readonly property color themePanelBorder: cardData ? Qt.color(cardData.panelBorder) : Root.Theme.panelBorder
    readonly property color themeConnected: cardData ? Qt.color(cardData.connected) : Root.Theme.connected
    readonly property color themeTextPrimary: cardData ? Qt.color(cardData.textPrimary) : Root.Theme.textPrimary
    readonly property color themeTextSecondary: cardData ? Qt.color(cardData.textSecondary) : Root.Theme.textSecondary
    readonly property color themeSliderTrack: cardData ? Qt.color(cardData.sliderTrack) : Root.Theme.sliderTrack
    readonly property color themeSliderActiveTrack: cardData ? Qt.color(cardData.sliderActiveTrack) : Root.Theme.sliderActiveTrack
    readonly property color themeTileActiveText: cardData ? Qt.color(cardData.tileActiveText) : Root.Theme.tileActiveText

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

        // Contenedor principal de contenido
        Item {
            anchors.fill: parent
            anchors.margins: 10

            // Miniatura gráfica con paleta y preview del tema
            Rectangle {
                id: previewBox
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 120
                radius: 12
                clip: true
                color: cardRoot.themeSurface
                border.width: 1
                border.color: Qt.rgba(cardRoot.themePanelBorder.r, cardRoot.themePanelBorder.g, cardRoot.themePanelBorder.b, 0.6)

                // Mockup visual de interfaz en miniatura
                Item {
                    anchors.fill: parent
                    anchors.margins: 8

                    // Barra superior simulada
                    Rectangle {
                        id: mockHeader
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 14
                        radius: 7
                        color: cardRoot.themeSurfaceContainer

                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: 6
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 4

                            Rectangle {
                                width: 6
                                height: 6
                                radius: 3
                                color: cardRoot.themePrimary
                            }
                            Rectangle {
                                width: 22
                                height: 4
                                radius: 2
                                color: cardRoot.themeTextSecondary
                                opacity: 0.5
                            }
                        }
                    }

                    // Fila central con widgets simulados
                    RowLayout {
                        anchors.top: mockHeader.bottom
                        anchors.topMargin: 8
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 42
                        spacing: 8

                        // Widget primario activo
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 8
                            color: cardRoot.themePrimaryContainer
                            border.width: 1
                            border.color: Qt.rgba(cardRoot.themePrimary.r, cardRoot.themePrimary.g, cardRoot.themePrimary.b, 0.4)

                            Column {
                                anchors.centerIn: parent
                                spacing: 3

                                Rectangle {
                                    width: 12
                                    height: 12
                                    radius: 6
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    color: cardRoot.themePrimary
                                }
                                Rectangle {
                                    width: 32
                                    height: 3
                                    radius: 1.5
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    color: cardRoot.themeTextPrimary
                                }
                            }
                        }

                        // Widget secundario con slider simulado
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 8
                            color: cardRoot.themeSurfaceContainerHigh

                            Column {
                                anchors.centerIn: parent
                                spacing: 5
                                width: parent.width - 12

                                // Slider track
                                Rectangle {
                                    width: parent.width
                                    height: 6
                                    radius: 3
                                    color: cardRoot.themeSliderTrack

                                    Rectangle {
                                        width: parent.width * 0.65
                                        height: parent.height
                                        radius: 3
                                        color: cardRoot.themeSliderActiveTrack
                                    }
                                }

                                // Pill secundario de acento
                                Rectangle {
                                    width: 38
                                    height: 8
                                    radius: 4
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    color: Qt.rgba(cardRoot.themeConnected.r, cardRoot.themeConnected.g, cardRoot.themeConnected.b, 0.3)

                                    Rectangle {
                                        width: 18
                                        height: 3
                                        radius: 1.5
                                        anchors.centerIn: parent
                                        color: cardRoot.themeConnected
                                    }
                                }
                            }
                        }
                    }

                    // Fila inferior con muestras circulares de paleta de color
                    Row {
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 2
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 7

                        Rectangle {
                            width: 18; height: 18; radius: 9
                            color: cardRoot.themePrimary
                            border.width: 1; border.color: Qt.rgba(1, 1, 1, 0.15)
                        }
                        Rectangle {
                            width: 18; height: 18; radius: 9
                            color: cardRoot.themePrimaryContainer
                            border.width: 1; border.color: Qt.rgba(1, 1, 1, 0.15)
                        }
                        Rectangle {
                            width: 18; height: 18; radius: 9
                            color: cardRoot.themeSurfaceContainerHigh
                            border.width: 1; border.color: Qt.rgba(1, 1, 1, 0.15)
                        }
                        Rectangle {
                            width: 18; height: 18; radius: 9
                            color: cardRoot.themeConnected
                            border.width: 1; border.color: Qt.rgba(1, 1, 1, 0.15)
                        }
                        Rectangle {
                            width: 18; height: 18; radius: 9
                            color: cardRoot.themeTextPrimary
                            border.width: 1; border.color: Qt.rgba(1, 1, 1, 0.15)
                        }
                    }
                }

                // Insignia si es el tema activo actualmente
                Rectangle {
                    visible: cardRoot.isCurrentTheme
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.margins: 6
                    width: 66
                    height: 22
                    radius: 11
                    color: cardRoot.themePrimary

                    Row {
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            text: "󰄬"
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: 11
                            color: cardRoot.themeTileActiveText
                        }

                        Text {
                            text: "Active"
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: 11
                            font.weight: Font.Bold
                            color: cardRoot.themeTileActiveText
                        }
                    }
                }
            }

            // Título / nombre del tema
            Text {
                id: titleText
                anchors.top: previewBox.bottom
                anchors.topMargin: 10
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - 4
                text: cardRoot.themeTitle
                font.family: Root.Theme.fontFamily
                font.pixelSize: 14
                font.weight: (mouseArea.containsMouse || cardRoot.isSelected) ? Font.Bold : Font.Medium
                color: (mouseArea.containsMouse || cardRoot.isSelected) ? Root.Theme.primary : Root.Theme.textPrimary
                elide: Text.ElideMiddle
                horizontalAlignment: Text.AlignHCenter
            }

            // Subtítulo / descripción corta
            Text {
                anchors.top: titleText.bottom
                anchors.topMargin: 2
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - 4
                text: cardRoot.themeSubtitle
                font.family: Root.Theme.fontFamily
                font.pixelSize: 12
                color: Root.Theme.textSecondary
                elide: Text.ElideMiddle
                horizontalAlignment: Text.AlignHCenter
                visible: cardRoot.themeSubtitle !== ""
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
