import QtQuick
import "../.." as Root

Item {
    id: root

    property bool isSelected: false
    property color accentColor: Root.Theme.primary
    property real cardRadius: 18

    // Métricas centralizadas para todas las tarjetas del carrusel
    property real baseWidth: 224
    property real baseHeight: 214
    property real scaleSelected: 1.25
    property real scaleSelectedHover: 1.28
    property real scaleUnselected: 0.84
    property real scaleUnselectedHover: 0.95
    property real opacitySelected: 1.0
    property real opacityUnselected: 0.45
    property real opacityUnselectedHover: 0.75
    property real elevatedY: -8
    property int elevatedZ: 50

    readonly property bool isHovered: mouseArea.containsMouse

    signal activated()

    default property alias content: innerContent.data

    width: baseWidth
    height: baseHeight

    // Escala, opacidad, elevación y profundidad centralizadas
    scale: isSelected ? (mouseArea.containsMouse ? scaleSelectedHover : scaleSelected) : (mouseArea.containsMouse ? scaleUnselectedHover : scaleUnselected)
    opacity: isSelected ? opacitySelected : (mouseArea.containsMouse ? opacityUnselectedHover : opacityUnselected)
    y: isSelected ? elevatedY : (mouseArea.containsMouse ? -2 : 0)
    z: isSelected ? elevatedZ : (mouseArea.containsMouse ? 20 : 1)

    Behavior on scale { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
    Behavior on opacity { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
    Behavior on y { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }

    // ── Concentric Halo Glow Effect ──
    Rectangle {
        id: haloGlow
        anchors.centerIn: parent
        width: parent.width + 16
        height: parent.height + 16
        radius: root.cardRadius + 8
        color: root.isSelected
            ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.28)
            : (mouseArea.containsMouse
                ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.16)
                : "transparent")
        border.width: 1.5
        border.color: root.isSelected
            ? root.accentColor
            : (mouseArea.containsMouse
                ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.40)
                : "transparent")
        z: 0
        scale: root.isSelected ? 1.0 : (mouseArea.containsMouse ? 0.98 : 0.88)
        opacity: root.isSelected ? 1.0 : (mouseArea.containsMouse ? 0.85 : 0.0)

        Behavior on opacity { NumberAnimation { duration: 180 } }
        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: 160 } }
        Behavior on border.color { ColorAnimation { duration: 160 } }
    }

    Rectangle {
        id: bgCard
        anchors.fill: parent
        z: 1
        radius: root.cardRadius

        color: root.isSelected
            ? Root.Theme.surfaceContainerHigh
            : (mouseArea.containsMouse
                ? Qt.rgba(Root.Theme.surfaceBright.r, Root.Theme.surfaceBright.g, Root.Theme.surfaceBright.b, 0.95)
                : Qt.rgba(Root.Theme.surfaceContainer.r, Root.Theme.surfaceContainer.g, Root.Theme.surfaceContainer.b, 0.75))

        // Borde continuo alineado con el tema
        border.width: root.isSelected ? 2 : (mouseArea.containsMouse ? 1.5 : 1)
        border.color: root.isSelected
            ? root.accentColor
            : (mouseArea.containsMouse
                ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.5)
                : Qt.rgba(Root.Theme.panelBorder.r, Root.Theme.panelBorder.g, Root.Theme.panelBorder.b, 0.35))

        Behavior on color { ColorAnimation { duration: 180 } }
        Behavior on border.color { ColorAnimation { duration: 180 } }
        Behavior on border.width { NumberAnimation { duration: 180 } }

        Item {
            id: innerContent
            anchors.fill: parent
            anchors.margins: 10
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated()
    }
}
