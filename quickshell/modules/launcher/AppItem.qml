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

    height: 56
    width: parent ? parent.width : undefined

    // ── Concentric Halo Glow Effect (PowerMenu style, perfectly concentric) ──
    Rectangle {
        id: itemHalo
        anchors.centerIn: bg
        width: bg.width + 8
        height: bg.height + 8
        radius: height / 2

        color: rootItem.isSelected
            ? Qt.rgba(Root.Theme.primary.r, Root.Theme.primary.g, Root.Theme.primary.b, 0.28)
            : (mouseArea.containsMouse
                ? Qt.rgba(Root.Theme.primary.r, Root.Theme.primary.g, Root.Theme.primary.b, 0.16)
                : "transparent")
        border.width: 1.5
        border.color: rootItem.isSelected
            ? Root.Theme.primary
            : (mouseArea.containsMouse
                ? Qt.rgba(Root.Theme.primary.r, Root.Theme.primary.g, Root.Theme.primary.b, 0.40)
                : "transparent")
        z: 0
        opacity: (rootItem.isSelected || mouseArea.containsMouse) ? 1.0 : 0.0

        Behavior on opacity { NumberAnimation { duration: 160 } }
        Behavior on color { ColorAnimation { duration: 140 } }
        Behavior on border.color { ColorAnimation { duration: 140 } }
    }

    Rectangle {
        id: bg
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        anchors.topMargin: 4
        anchors.bottomMargin: 4
        z: 1
        radius: height / 2

        color: rootItem.isSelected
            ? Root.Theme.primary
            : (mouseArea.containsMouse
                ? Qt.rgba(Root.Theme.primary.r, Root.Theme.primary.g, Root.Theme.primary.b, 0.16)
                : Qt.rgba(Root.Theme.surfaceContainer.r, Root.Theme.surfaceContainer.g, Root.Theme.surfaceContainer.b, 0.65))

        border.width: rootItem.isSelected ? 0 : (mouseArea.containsMouse ? 1 : 0)
        border.color: mouseArea.containsMouse ? Qt.rgba(Root.Theme.panelBorder.r, Root.Theme.panelBorder.g, Root.Theme.panelBorder.b, 0.40) : "transparent"

        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on border.color { ColorAnimation { duration: 120 } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 12

            // Icono de la aplicación
            Item {
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                Layout.alignment: Qt.AlignVCenter

                // Imagen de icono si existe ruta
                Image {
                    id: iconImg
                    anchors.centerIn: parent
                    width: 32
                    height: 32
                    source: rootItem.iconPath
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    asynchronous: true
                    visible: rootItem.iconPath !== "" && status !== Image.Error
                }

                // Fallback: Círculo coloreado con inicial
                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
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
                Layout.alignment: Qt.AlignVCenter
                spacing: 2

                Text {
                    text: rootItem.appName
                    font.family: Root.Theme.fontFamily
                    font.pixelSize: 15
                    font.weight: rootItem.isSelected ? Font.Bold : Font.DemiBold
                    color: rootItem.isSelected ? Root.Theme.tileActiveText : Root.Theme.textPrimary
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Text {
                    text: rootItem.appComment
                    font.family: Root.Theme.fontFamily
                    font.pixelSize: 13
                    color: rootItem.isSelected
                        ? Qt.rgba(Root.Theme.tileActiveText.r, Root.Theme.tileActiveText.g, Root.Theme.tileActiveText.b, 0.82)
                        : Root.Theme.textSecondary
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }

            // Badge indicador 1:1 circular al estar seleccionado
            Rectangle {
                visible: rootItem.isSelected
                Layout.preferredWidth: 28
                Layout.preferredHeight: 28
                Layout.alignment: Qt.AlignVCenter
                radius: 14
                color: Qt.rgba(Root.Theme.tileActiveText.r, Root.Theme.tileActiveText.g, Root.Theme.tileActiveText.b, 0.16)
                border.width: 1
                border.color: Qt.rgba(Root.Theme.tileActiveText.r, Root.Theme.tileActiveText.g, Root.Theme.tileActiveText.b, 0.28)

                Text {
                    anchors.centerIn: parent
                    text: "󰌑"
                    font.family: Root.Theme.fontFamily
                    font.pixelSize: 14
                    color: Root.Theme.tileActiveText
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
