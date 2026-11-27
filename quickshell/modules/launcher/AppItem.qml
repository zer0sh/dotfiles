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

    // ── Concentric Halo Glow Effect ──
    Rectangle {
        id: itemHalo
        anchors.centerIn: parent
        width: parent.width + 4
        height: parent.height + 2
        radius: 18
        color: rootItem.isSelected
            ? Qt.rgba(Root.Theme.primary.r, Root.Theme.primary.g, Root.Theme.primary.b, 0.22)
            : (mouseArea.containsMouse
                ? Qt.rgba(Root.Theme.primary.r, Root.Theme.primary.g, Root.Theme.primary.b, 0.10)
                : "transparent")
        border.width: 1
        border.color: rootItem.isSelected
            ? Root.Theme.primary
            : (mouseArea.containsMouse
                ? Qt.rgba(Root.Theme.primary.r, Root.Theme.primary.g, Root.Theme.primary.b, 0.35)
                : "transparent")
        z: 0
        scale: rootItem.isSelected ? 1.0 : (mouseArea.containsMouse ? 0.99 : 0.96)
        opacity: rootItem.isSelected ? 1.0 : (mouseArea.containsMouse ? 0.70 : 0.0)

        Behavior on opacity { NumberAnimation { duration: 160 } }
        Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: 140 } }
        Behavior on border.color { ColorAnimation { duration: 140 } }
    }

    Rectangle {
        id: bg
        anchors.fill: parent
        z: 1
        radius: 16

        color: rootItem.isSelected
            ? Qt.rgba(Root.Theme.surfaceContainerHigh.r, Root.Theme.surfaceContainerHigh.g, Root.Theme.surfaceContainerHigh.b, 0.90)
            : (mouseArea.containsMouse
                ? Qt.rgba(Root.Theme.surfaceContainer.r, Root.Theme.surfaceContainer.g, Root.Theme.surfaceContainer.b, 0.60)
                : "transparent")

        border.width: rootItem.isSelected ? 1.5 : (mouseArea.containsMouse ? 1 : 0)
        border.color: rootItem.isSelected
            ? Root.Theme.primary
            : (mouseArea.containsMouse ? Qt.rgba(Root.Theme.panelBorder.r, Root.Theme.panelBorder.g, Root.Theme.panelBorder.b, 0.40) : "transparent")

        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on border.color { ColorAnimation { duration: 120 } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 12

            // Icono de la aplicación con halo sutil
            Item {
                Layout.preferredWidth: 38
                Layout.preferredHeight: 38
                scale: rootItem.isSelected ? 1.08 : (mouseArea.containsMouse ? 1.04 : 1.0)
                Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

                // Halo circular del icono
                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width + 6
                    height: parent.height + 6
                    radius: width / 2
                    color: rootItem.isSelected
                        ? Qt.rgba(Root.Theme.primary.r, Root.Theme.primary.g, Root.Theme.primary.b, 0.25)
                        : "transparent"
                    opacity: rootItem.isSelected ? 1.0 : 0.0
                    scale: rootItem.isSelected ? 1.0 : 0.8
                    Behavior on opacity { NumberAnimation { duration: 140 } }
                    Behavior on scale { NumberAnimation { duration: 140 } }
                }

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
                        font.pixelSize: 17
                        font.weight: Font.Bold
                        color: "#ffffff"
                    }
                }
            }

            // Nombre y descripción
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    text: rootItem.appName
                    font.family: Root.Theme.fontFamily
                    font.pixelSize: 15
                    font.weight: rootItem.isSelected ? Font.Bold : Font.DemiBold
                    color: rootItem.isSelected ? Root.Theme.primary : Root.Theme.textPrimary
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Text {
                    text: rootItem.appComment
                    font.family: Root.Theme.fontFamily
                    font.pixelSize: 13
                    color: rootItem.isSelected
                        ? Qt.rgba(Root.Theme.textPrimary.r, Root.Theme.textPrimary.g, Root.Theme.textPrimary.b, 0.85)
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
                radius: 14
                color: Qt.rgba(Root.Theme.primary.r, Root.Theme.primary.g, Root.Theme.primary.b, 0.28)
                border.width: 1
                border.color: Root.Theme.primary

                Text {
                    anchors.centerIn: parent
                    text: "󰌑"
                    font.family: Root.Theme.fontFamily
                    font.pixelSize: 14
                    color: Root.Theme.primary
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
