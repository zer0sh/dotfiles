import QtQuick
import QtQuick.Layouts
import "../.." as Root

Item {
    id: rootItem

    required property var modelData
    property bool isSelected: false
    signal activated()

    readonly property string actionName: modelData ? (modelData.name || "") : ""
    readonly property string actionDesc: modelData ? (modelData.desc || "") : ""
    readonly property string actionIcon: modelData ? (modelData.icon || "󰘳") : "󰘳"

    height: 48
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

            // Contenedor del icono
            Rectangle {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                radius: 8
                color: rootItem.isSelected
                    ? Qt.rgba(Root.Theme.primary.r, Root.Theme.primary.g, Root.Theme.primary.b, 0.2)
                    : Root.Theme.surfaceContainerHigh

                Text {
                    anchors.centerIn: parent
                    text: rootItem.actionIcon
                    font.family: Root.Theme.fontFamily
                    font.pixelSize: 18
                    color: Root.Theme.primary
                }
            }

            // Textos: Nombre y descripción
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    text: rootItem.actionName
                    font.family: Root.Theme.fontFamily
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    color: rootItem.isSelected ? Root.Theme.primary : Root.Theme.textPrimary
                }

                Text {
                    text: rootItem.actionDesc
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
