import QtQuick
import QtQuick.Layouts
import "../.." as Root

Item {
    id: header
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    height: 38
    z: 250

    required property var windowRef
    required property string gadgetId
    required property var managerRef
    property bool parentHovered: false

    property bool isHovered: false
    property bool isDragging: false

    signal closed()

    function alpha(c, a, fallback) {
        if (!c || c.r === undefined) return fallback || "transparent";
        return Qt.rgba(c.r, c.g, c.b, a);
    }

    // Revelado suave al acercarse con el cursor o al estar arrastrando
    opacity: (isHovered || parentHovered || isDragging) ? 1.0 : 0.0
    Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 6
        radius: 12
        color: header.alpha(Root.Theme.surfaceContainer, 0.85, "#201F25")
        border.color: isDragging ? Root.Theme.primary : header.alpha(Root.Theme.outline, 0.4, "#47464F")
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 8
            spacing: 8

            // Título o indicador de arrastre
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6

                    // Asa de arrastre estilizada estilo Material You
                    Rectangle {
                        width: 38
                        height: 4
                        radius: 2
                        color: header.isDragging ? Root.Theme.primary : header.alpha(Root.Theme.textSecondary, 0.7, "#8E90A8")
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                }

                MouseArea {
                    id: dragArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor

                    property real startPressX: 0
                    property real startPressY: 0
                    property int startWinX: 0
                    property int startWinY: 0

                    onEntered: header.isHovered = true
                    onExited: if (!pressed) header.isHovered = false

                    onPressed: function(mouse) {
                        startPressX = mouse.x;
                        startPressY = mouse.y;
                        startWinX = header.windowRef.margins.left;
                        startWinY = header.windowRef.margins.top;
                        header.isDragging = true;
                    }

                    onPositionChanged: function(mouse) {
                        if (pressed) {
                            // mouse.x/y changes by delta relative to where we pressed within the item,
                            // even when the window itself translates under the cursor.
                            var dx = mouse.x - startPressX;
                            var dy = mouse.y - startPressY;
                            var targetX = Math.round(header.windowRef.margins.left + dx);
                            var targetY = Math.round(header.windowRef.margins.top + dy);

                            var newX = Math.max(10, Math.min(1920 - header.windowRef.implicitWidth - 10, targetX));
                            var newY = Math.max(10, Math.min(1200 - header.windowRef.implicitHeight - 10, targetY));

                            header.windowRef.margins.left = newX;
                            header.windowRef.margins.top = newY;
                        }
                    }

                    onReleased: {
                        header.isDragging = false;
                        if (header.managerRef && header.gadgetId) {
                            header.managerRef.setPosition(header.gadgetId, header.windowRef.margins.left, header.windowRef.margins.top);
                        }
                    }
                }
            }

            // Botón de cerrar (x) para ocultar del escritorio
            Rectangle {
                width: 24
                height: 24
                radius: 12
                color: closeBtnArea.containsMouse ? header.alpha(Root.Theme.error, 0.25, "#FFB4AB") : "transparent"
                border.color: closeBtnArea.containsMouse ? Root.Theme.error : header.alpha(Root.Theme.outline, 0.35, "#47464F")
                border.width: 1
                scale: closeBtnArea.pressed ? 0.9 : (closeBtnArea.containsMouse ? 1.1 : 1.0)
                Behavior on scale { NumberAnimation { duration: 120 } }
                Behavior on color { ColorAnimation { duration: 150 } }

                Text {
                    anchors.centerIn: parent
                    text: "✕"
                    font.family: Root.Theme.fontFamily
                    font.pixelSize: 11
                    font.weight: Font.Bold
                    color: closeBtnArea.containsMouse ? Root.Theme.error : Root.Theme.textSecondary
                }

                MouseArea {
                    id: closeBtnArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: header.isHovered = true
                    onClicked: {
                        if (header.managerRef && header.gadgetId) {
                            header.managerRef.setEnabled(header.gadgetId, false);
                        }
                        header.closed();
                    }
                }
            }
        }
    }
}
