import QtQuick
import QtQuick.Layouts
import "../.." as Root

Item {
    id: cardRoot

    property string gadgetId: ""
    property string gadgetTitle: ""
    property string gadgetSubtitle: ""
    property string gadgetIcon: "󱂬"
    property bool isEnabled: true
    property bool isSelected: false

    readonly property bool isHovered: mouseArea.containsMouse

    signal activated()

    function alpha(c, a, fallback) {
        if (!c || c.r === undefined) return fallback || "transparent";
        return Qt.rgba(c.r, c.g, c.b, a);
    }

    width: 224
    height: 214

    // Escala dinámica y elevación
    scale: mouseArea.containsMouse ? 1.05 : (isSelected ? 1.03 : 1.0)
    y: mouseArea.containsMouse ? -5 : (isSelected ? -2 : 0)
    z: mouseArea.containsMouse ? 100 : (isSelected ? 20 : 1)

    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

    Rectangle {
        id: bgCard
        anchors.fill: parent
        radius: 18
        color: cardRoot.isSelected
            ? Root.Theme.surfaceContainerHigh
            : (mouseArea.containsMouse ? Root.Theme.surfaceContainer : Root.Theme.surface)
        border.color: cardRoot.isSelected
            ? Root.Theme.primary
            : (mouseArea.containsMouse ? Root.Theme.outlineVariant : Root.Theme.panelBorder)
        border.width: cardRoot.isSelected ? 2 : 1
        clip: true

        Behavior on color { ColorAnimation { duration: 180 } }
        Behavior on border.color { ColorAnimation { duration: 180 } }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 8

            // ── Área de Previsualización Gráfica (120 px) ────────────
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 120
                radius: 12
                color: Qt.rgba(0.04, 0.04, 0.06, 0.85)
                border.color: cardRoot.isEnabled
                    ? cardRoot.alpha(Root.Theme.primary, 0.45, "#C7BFFF")
                    : cardRoot.alpha(Root.Theme.outline, 0.25, "#47464F")
                border.width: 1
                clip: true

                // Mockup visual según el tipo de gadget
                Item {
                    anchors.fill: parent
                    anchors.margins: 8

                    // Previsualización DeskClock
                    ColumnLayout {
                        visible: cardRoot.gadgetId === "deskclock"
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "20:45"
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: 22
                            font.weight: Font.Bold
                            color: cardRoot.isEnabled ? Root.Theme.primary : Root.Theme.textSecondary
                        }

                        // Barra de progreso del día
                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            width: 110
                            height: 6
                            radius: 3
                            color: cardRoot.alpha(Root.Theme.outline, 0.3, "#47464F")

                            Rectangle {
                                width: parent.width * 0.72
                                height: parent.height
                                radius: 3
                                color: cardRoot.isEnabled ? Root.Theme.primary : Root.Theme.textSecondary
                            }
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "Evening mode: ON"
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: 9
                            color: Root.Theme.textSecondary
                        }
                    }

                    // Previsualización Calendar
                    ColumnLayout {
                        visible: cardRoot.gadgetId === "calendar"
                        anchors.centerIn: parent
                        spacing: 3

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "OCTOBER 2026"
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: 10
                            font.weight: Font.Bold
                            color: cardRoot.isEnabled ? Root.Theme.primary : Root.Theme.textSecondary
                        }

                        // Cuadrícula simulada de días
                        Grid {
                            Layout.alignment: Qt.AlignHCenter
                            columns: 7
                            spacing: 4

                            Repeater {
                                model: 14
                                Rectangle {
                                    width: 10
                                    height: 10
                                    radius: 3
                                    color: index === 6
                                        ? (cardRoot.isEnabled ? Root.Theme.primary : Root.Theme.textSecondary)
                                        : cardRoot.alpha(Root.Theme.outline, 0.25, "#47464F")

                                    Text {
                                        anchors.centerIn: parent
                                        text: index + 1
                                        font.pixelSize: 7
                                        color: index === 6 ? Root.Theme.tileActiveText : Root.Theme.textSecondary
                                    }
                                }
                            }
                        }
                    }

                    // Icono fallback para otros gadgets futuros
                    Text {
                        visible: cardRoot.gadgetId !== "deskclock" && cardRoot.gadgetId !== "calendar"
                        anchors.centerIn: parent
                        text: cardRoot.gadgetIcon
                        font.family: Root.Theme.fontFamily
                        font.pixelSize: 36
                        color: cardRoot.isEnabled ? Root.Theme.primary : Root.Theme.textSecondary
                    }
                }

                // Insignia de Estado Activo / Inactivo en esquina superior derecha
                Rectangle {
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.margins: 6
                    height: 20
                    radius: 10
                    width: statusRow.implicitWidth + 12
                    color: cardRoot.isEnabled
                        ? cardRoot.alpha(Root.Theme.primary, 0.22, "#C7BFFF")
                        : cardRoot.alpha(Root.Theme.outline, 0.25, "#47464F")
                    border.color: cardRoot.isEnabled
                        ? Root.Theme.primary
                        : cardRoot.alpha(Root.Theme.outline, 0.4, "#47464F")
                    border.width: 1

                    RowLayout {
                        id: statusRow
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            text: cardRoot.isEnabled ? "✓" : "✕"
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: 9
                            font.weight: Font.Bold
                            color: cardRoot.isEnabled ? Root.Theme.primary : Root.Theme.textSecondary
                        }
                        Text {
                            text: cardRoot.isEnabled ? "Active" : "Hidden"
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: 9
                            font.weight: Font.Bold
                            color: cardRoot.isEnabled ? Root.Theme.primary : Root.Theme.textSecondary
                        }
                    }
                }
            }

            // ── Información Inferior ─────────────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        text: cardRoot.gadgetIcon
                        font.family: Root.Theme.fontFamily
                        font.pixelSize: 15
                        color: cardRoot.isEnabled ? Root.Theme.primary : Root.Theme.textSecondary
                    }

                    Text {
                        Layout.fillWidth: true
                        text: cardRoot.gadgetTitle
                        font.family: Root.Theme.fontFamily
                        font.pixelSize: 13
                        font.weight: Font.Bold
                        color: cardRoot.isSelected ? Root.Theme.primary : Root.Theme.textPrimary
                        elide: Text.ElideRight
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: cardRoot.gadgetSubtitle
                    font.family: Root.Theme.fontFamily
                    font.pixelSize: 10
                    color: Root.Theme.textSecondary
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }

                Text {
                    Layout.fillWidth: true
                    text: cardRoot.isEnabled ? "Click to disable" : "Click to enable"
                    font.family: Root.Theme.fontFamily
                    font.pixelSize: 9
                    font.weight: Font.DemiBold
                    color: cardRoot.isEnabled ? Root.Theme.primary : Root.Theme.outline
                    elide: Text.ElideRight
                }
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
