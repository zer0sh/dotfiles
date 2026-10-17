import QtQuick
import QtQuick.Layouts
import "../.." as Root

Item {
    id: rootItem

    required property var modelData
    required property int index
    property string iconPath: ""
    property bool isSelected: false
    signal activated()

    readonly property string appName: modelData ? (modelData.name || "") : ""
    readonly property string appComment: modelData ? (modelData.comment || "Application") : "Application"

    height: 52
    width: parent ? parent.width : undefined

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: 12

        // Contraste elevado y distinguible: tinte primario vibrante en selección
        color: rootItem.isSelected
            ? Qt.rgba(Root.Theme.primary.r, Root.Theme.primary.g, Root.Theme.primary.b, 0.22)
            : (mouseArea.containsMouse ? Qt.rgba(Root.Theme.primary.r, Root.Theme.primary.g, Root.Theme.primary.b, 0.08) : "transparent")

        border.width: rootItem.isSelected ? 1.5 : (mouseArea.containsMouse ? 1 : 0)
        border.color: rootItem.isSelected
            ? Root.Theme.primary
            : (mouseArea.containsMouse ? Qt.rgba(Root.Theme.primary.r, Root.Theme.primary.g, Root.Theme.primary.b, 0.4) : "transparent")

        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on border.color { ColorAnimation { duration: 120 } }

        // Indicador lateral de selección activa (pill vertical)
        Rectangle {
            anchors.left: parent.left
            anchors.leftMargin: 3
            anchors.verticalCenter: parent.verticalCenter
            width: 4
            height: 26
            radius: 2
            color: Root.Theme.primary
            visible: rootItem.isSelected
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: rootItem.isSelected ? 14 : 12
            anchors.rightMargin: 12
            spacing: 12

            Behavior on anchors.leftMargin { NumberAnimation { duration: 120 } }

            // Icono de la aplicación
            Item {
                Layout.preferredWidth: 34
                Layout.preferredHeight: 34
                scale: rootItem.isSelected ? 1.08 : (mouseArea.containsMouse ? 1.04 : 1.0)
                Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

                // Imagen de icono si existe ruta
                Image {
                    id: iconImg
                    anchors.fill: parent
                    source: rootItem.iconPath
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    asynchronous: true
                    visible: rootItem.iconPath !== "" && status !== Image.Error
                }

                // Fallback: Círculo coloreado con inicial
                Rectangle {
                    anchors.fill: parent
                    radius: 17
                    visible: rootItem.iconPath === "" || iconImg.status === Image.Error
                    color: {
                        var code = rootItem.appName.length > 0 ? rootItem.appName.charCodeAt(0) : 0;
                        var colors = [
                            Root.Theme.primary,
                            Root.Theme.surfaceBright,
                            Root.Theme.secondaryContainer,
                            Root.Theme.connected
                        ];
                        return colors[code % colors.length];
                    }

                    Text {
                        anchors.centerIn: parent
                        text: rootItem.appName.length > 0 ? rootItem.appName.charAt(0).toUpperCase() : "?"
                        font.family: Root.Theme.fontFamily
                        font.pixelSize: 16
                        font.weight: Font.Bold
                        color: "#ffffff"
                    }
                }
            }

            // Nombre y descripción
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    text: rootItem.appName
                    font.family: Root.Theme.fontFamily
                    font.pixelSize: 13
                    font.weight: rootItem.isSelected ? Font.Bold : Font.DemiBold
                    color: rootItem.isSelected ? Root.Theme.primary : Root.Theme.textPrimary
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Text {
                    text: rootItem.appComment
                    font.family: Root.Theme.fontFamily
                    font.pixelSize: 11
                    color: rootItem.isSelected
                        ? Qt.rgba(Root.Theme.textPrimary.r, Root.Theme.textPrimary.g, Root.Theme.textPrimary.b, 0.85)
                        : Root.Theme.textSecondary
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }

            // Badge indicador de Enter al estar seleccionado
            Rectangle {
                visible: rootItem.isSelected
                Layout.preferredWidth: 62
                Layout.preferredHeight: 24
                radius: 6
                color: Qt.rgba(Root.Theme.primary.r, Root.Theme.primary.g, Root.Theme.primary.b, 0.28)
                border.width: 1
                border.color: Root.Theme.primary

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        text: "󰌑"
                        font.family: Root.Theme.fontFamily
                        font.pixelSize: 12
                        color: Root.Theme.primary
                    }

                    Text {
                        text: "Enter"
                        font.family: Root.Theme.fontFamily
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        color: Root.Theme.primary
                    }
                }
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: rootItem.activated()
    }
}
