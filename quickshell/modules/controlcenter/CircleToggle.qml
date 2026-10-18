import QtQuick
import QtQuick.Layouts
import "../.." as Root

// Material You Pixel Glassmorphism Quick Toggle
Item {
    id: control

    property bool active: false
    property string icon: ""
    property string label: ""
    property bool hasDetail: false

    signal clicked()
    signal detailClicked()

    implicitWidth: 96
    implicitHeight: 104
    Layout.preferredWidth: 96
    Layout.fillWidth: true

    FontLoader {
        id: materialSymbolsLoader
        source: "../../fonts/MaterialSymbolsRounded.ttf"
    }

    // Main circular button
    Rectangle {
        id: button
        width: 66
        height: 66
        anchors.horizontalCenter: parent.horizontalCenter
        radius: width / 2

        color: control.active
            ? Root.Theme.primary
            : (btnMouse.containsMouse
                ? (Root.Theme.isLightMode ? Qt.darker(Root.Theme.surfaceContainerHigh, 1.06) : Qt.lighter(Root.Theme.surfaceContainerHigh, 1.15))
                : Root.Theme.surfaceContainerHigh)

        border.width: control.active ? 0 : 1.5
        border.color: control.active
            ? "transparent"
            : (btnMouse.containsMouse
                ? Root.Theme.primary
                : (Root.Theme.isLightMode ? Qt.rgba(Root.Theme.panelBorder.r, Root.Theme.panelBorder.g, Root.Theme.panelBorder.b, 0.55) : Qt.rgba(255, 255, 255, 0.20)))

        scale: btnMouse.pressed ? 0.93 : (btnMouse.containsMouse ? 1.04 : 1.0)

        Behavior on color {
            ColorAnimation { duration: Root.Theme.animDurationFast }
        }
        Behavior on scale {
            NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
        }

        // Material Symbols Rounded Icon
        Text {
            anchors.centerIn: parent
            text: control.icon
            font.family: materialSymbolsLoader.name !== "" ? materialSymbolsLoader.name : Root.Theme.iconFont
            font.pixelSize: 28
            color: control.active
                ? Root.Theme.tileActiveText
                : (Root.Theme.isLightMode ? Root.Theme.textPrimary : Qt.rgba(255, 255, 255, 0.85))

            Behavior on color {
                ColorAnimation { duration: Root.Theme.animDurationFast }
            }
        }

        MouseArea {
            id: btnMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: control.clicked()
        }
    }

    // Label and integrated chevron below the circular button
    RowLayout {
        id: labelRow
        anchors.top: button.bottom
        anchors.topMargin: 8
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 2

        Text {
            id: labelText
            text: control.label
            font.family: Root.Theme.fontFamily
            font.pixelSize: 12
            font.weight: control.active ? Font.Medium : Font.Normal
            color: control.active ? Root.Theme.textPrimary : Root.Theme.textSecondary
            elide: Text.ElideRight
            width: Math.min(implicitWidth, control.hasDetail ? (control.width - 20) : control.width)
        }

        Text {
            visible: control.hasDetail
            text: "expand_more"
            font.family: materialSymbolsLoader.name !== "" ? materialSymbolsLoader.name : Root.Theme.iconFont
            font.pixelSize: 16
            font.weight: Font.Bold
            color: control.active ? Root.Theme.primary : Root.Theme.textSecondary
            Layout.alignment: Qt.AlignVCenter
        }
    }

    MouseArea {
        anchors.fill: labelRow
        anchors.margins: -4
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (control.hasDetail)
                control.detailClicked()
            else
                control.clicked()
        }
    }
}
