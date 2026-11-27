import QtQuick
import QtQuick.Layouts
import "../.." as Root

Item {
    id: rootItem

    required property var modelData
    required property int index
    property bool isSelected: false
    signal activated()

    readonly property string actionName: modelData ? (modelData.name || "") : ""
    readonly property string actionDesc: modelData ? (modelData.desc || "") : ""
    readonly property string actionIcon: modelData ? (modelData.icon || "󰘳") : "󰘳"

    height: 54
    width: parent ? parent.width : undefined

    // ── Concentric Halo Glow Effect (PowerMenu style) ──
    Rectangle {
        id: itemHalo
        anchors.centerIn: parent
        width: parent.width + 10
        height: parent.height + 8
        radius: height / 2
        color: rootItem.isSelected
            ? Qt.rgba(Root.Theme.primary.r, Root.Theme.primary.g, Root.Theme.primary.b, 0.35)
            : (mouseArea.containsMouse
                ? Qt.rgba(Root.Theme.primary.r, Root.Theme.primary.g, Root.Theme.primary.b, 0.20)
                : "transparent")
        border.width: 1
        border.color: rootItem.isSelected
            ? Root.Theme.primary
            : (mouseArea.containsMouse
                ? Qt.rgba(Root.Theme.primary.r, Root.Theme.primary.g, Root.Theme.primary.b, 0.40)
                : "transparent")
        z: 0
        scale: (rootItem.isSelected || mouseArea.containsMouse) ? 1.0 : 0.82
        opacity: (rootItem.isSelected || mouseArea.containsMouse) ? 1.0 : 0.0

        Behavior on opacity { NumberAnimation { duration: 160 } }
        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: 140 } }
        Behavior on border.color { ColorAnimation { duration: 140 } }
    }

    Rectangle {
        id: bg
        anchors.fill: parent
        z: 1
        radius: height / 2

        color: rootItem.isSelected
            ? Qt.rgba(Root.Theme.surfaceContainerHigh.r, Root.Theme.surfaceContainerHigh.g, Root.Theme.surfaceContainerHigh.b, 0.95)
            : (mouseArea.containsMouse
                ? Qt.rgba(Root.Theme.surfaceContainer.r, Root.Theme.surfaceContainer.g, Root.Theme.surfaceContainer.b, 0.70)
                : "transparent")

        border.width: rootItem.isSelected ? 1.5 : (mouseArea.containsMouse ? 1 : 0)
        border.color: rootItem.isSelected
            ? Root.Theme.primary
            : (mouseArea.containsMouse ? Qt.rgba(Root.Theme.panelBorder.r, Root.Theme.panelBorder.g, Root.Theme.panelBorder.b, 0.40) : "transparent")

        scale: mouseArea.pressed ? 0.97 : (rootItem.isSelected || mouseArea.containsMouse ? 1.02 : 1.0)
        Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on border.color { ColorAnimation { duration: 120 } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 12

            // Contenedor 1:1 circular del icono con halo
            Rectangle {
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                radius: width / 2
                color: rootItem.isSelected
                    ? Qt.rgba(Root.Theme.primary.r, Root.Theme.primary.g, Root.Theme.primary.b, 0.25)
                    : Root.Theme.surfaceContainerHigh
                border.width: 1
                border.color: rootItem.isSelected
                    ? Root.Theme.primary
                    : Qt.rgba(Root.Theme.panelBorder.r, Root.Theme.panelBorder.g, Root.Theme.panelBorder.b, 0.40)
                scale: rootItem.isSelected ? 1.08 : (mouseArea.containsMouse ? 1.04 : 1.0)
                Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: 120 } }

                Text {
                    anchors.centerIn: parent
                    text: rootItem.actionIcon
                    font.family: Root.Theme.iconFont
                    font.pixelSize: 19
                    color: Root.Theme.primary
                }
            }

            // Textos: Nombre y descripción
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    text: rootItem.actionName
                    font.family: Root.Theme.fontFamily
                    font.pixelSize: 15
                    font.weight: rootItem.isSelected ? Font.Bold : Font.DemiBold
                    color: rootItem.isSelected ? Root.Theme.primary : Root.Theme.textPrimary
                }

                Text {
                    text: rootItem.actionDesc
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
