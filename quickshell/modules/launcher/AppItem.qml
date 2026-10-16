import QtQuick
import QtQuick.Layouts
import "../.." as Root

Item {
    id: rootItem

    required property var modelData
    property string iconPath: ""
    property bool isSelected: false
    signal activated()

    readonly property string appName: modelData ? (modelData.name || "") : ""
    readonly property string appComment: modelData ? (modelData.comment || "Application") : "Application"

    height: 50
    anchors.left: parent ? parent.left : undefined
    anchors.right: parent ? parent.right : undefined

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: 12
        color: rootItem.isSelected
            ? Root.Theme.surfaceContainerHigh
            : (mouseArea.containsMouse ? Root.Theme.surfaceContainer : "transparent")
        border.width: rootItem.isSelected ? 1 : 0
        border.color: Root.Theme.primary

        Behavior on color { ColorAnimation { duration: 120 } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 12

            // Icono de la aplicación
            Item {
                Layout.preferredWidth: 34
                Layout.preferredHeight: 34

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
                    font.weight: Font.DemiBold
                    color: rootItem.isSelected ? Root.Theme.primary : Root.Theme.textPrimary
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Text {
                    text: rootItem.appComment
                    font.family: Root.Theme.fontFamily
                    font.pixelSize: 11
                    color: Root.Theme.textSecondary
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }

            // Indicador de selección / Enter
            Text {
                visible: rootItem.isSelected
                text: "󰌑"
                font.family: Root.Theme.fontFamily
                font.pixelSize: 14
                color: Root.Theme.primary
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
