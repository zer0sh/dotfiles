import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../.." as Root

// Calendar — calendario simple en el "escritorio".
// Va en una capa Bottom (detrás de las ventanas) y no captura input.
Scope {
    id: calendar

    property int year: 2026
    property int month: 0      // 0-based, enero = 0
    property int today: 1
    property bool isCurrentMonth: true   // true si se está mostrando el mes real actual

    property var dayNames: ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"]
    property var monthNames: ["January","February","March","April","May","June",
                              "July","August","September","October","November","December"]
    property int daysInMonth: 30
    property int leadingBlanks: 0   // celdas vacías antes del día 1 (semana empieza en domingo)
    property bool panelVisible: Root.GadgetsManager.isEnabled("calendar")
    property int posX: Root.GadgetsManager.getPosition("calendar", 100, 700).x
    property int posY: Root.GadgetsManager.getPosition("calendar", 100, 700).y

    Connections {
        target: Root.GadgetsManager
        function onStateChanged() {
            calendar.panelVisible = Root.GadgetsManager.isEnabled("calendar");
            var pos = Root.GadgetsManager.getPosition("calendar", 100, 700);
            calendar.posX = pos.x;
            calendar.posY = pos.y;
        }
    }

    // ── Toggle por IPC: `qs ipc call calendar toggle` ─────────────
    IpcHandler {
        target: "calendar"
        function toggle(): void { Root.GadgetsManager.toggle("calendar") }
        function show(): void { Root.GadgetsManager.setEnabled("calendar", true) }
        function hide(): void { Root.GadgetsManager.setEnabled("calendar", false) }
        function move(x: int, y: int): void {
            Root.GadgetsManager.setPosition("calendar", x, y);
        }
    }

    function setNow() {
        var d = new Date()
        calendar.year  = d.getFullYear()
        calendar.month = d.getMonth()
        calendar.today = d.getDate()
        calendar.recalc()
    }

    function recalc() {
        calendar.daysInMonth = new Date(calendar.year, calendar.month + 1, 0).getDate()
        calendar.leadingBlanks = new Date(calendar.year, calendar.month, 1).getDay()
        var now = new Date()
        calendar.isCurrentMonth = (calendar.year === now.getFullYear()
                                   && calendar.month === now.getMonth())
    }

    function prevMonth() {
        calendar.month--
        if (calendar.month < 0) { calendar.month = 11; calendar.year-- }
        calendar.recalc()
    }

    function nextMonth() {
        calendar.month++
        if (calendar.month > 11) { calendar.month = 0; calendar.year++ }
        calendar.recalc()
    }

    Component.onCompleted: calendar.setNow()

    // ── Escritorio: detrás de las ventanas, sin capturar input ────
    PanelWindow {
        id: win
        visible: calendar.panelVisible
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer:    WlrLayer.Bottom
        WlrLayershell.namespace: "quickshell:calendar"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        mask: Region {
            item: mainCard
        }

        // Contenedor principal sin fondo ni bordes — arrastrable directamente
        Item {
            id: mainCard
            x: calendar.posX
            y: calendar.posY
            width: 400
            height: 400
            property bool isDragging: false

            Binding {
                target: mainCard
                property: "x"
                value: calendar.posX
                when: !mainCard.isDragging
            }
            Binding {
                target: mainCard
                property: "y"
                value: calendar.posY
                when: !mainCard.isDragging
            }

            // Arrastre libre desde cualquier punto del calendario
            MouseArea {
                id: dragArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: pressed ? Qt.ClosedHandCursor : (containsMouse ? Qt.OpenHandCursor : Qt.ArrowCursor)
                drag.target: mainCard
                drag.axis: Drag.XAndYAxis

                onPressed: {
                    mainCard.isDragging = true
                }

                onReleased: {
                    var fx = Math.round(mainCard.x)
                    var fy = Math.round(mainCard.y)
                    calendar.posX = fx
                    calendar.posY = fy
                    Root.GadgetsManager.setPosition("calendar", fx, fy)
                    mainCard.isDragging = false
                }
            }

            // Botón sutil de cierre al pasar el cursor
            Text {
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: 6
                z: 100
                text: "✕"
                font.family: Root.Theme.fontFamily
                font.pixelSize: 13
                font.weight: Font.Bold
                color: closeHover.hovered ? Root.Theme.error : Qt.rgba(Root.Theme.textSecondary.r, Root.Theme.textSecondary.g, Root.Theme.textSecondary.b, 0.45)
                opacity: dragArea.containsMouse ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 180 } }

                HoverHandler { id: closeHover }
                TapHandler {
                    onTapped: Root.GadgetsManager.setEnabled("calendar", false)
                }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 12

                // Encabezado:  ‹ August ›  (funcional)
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    z: 10

                    Item {
                        width: 28
                        height: 28
                        z: 10
                        Text {
                            anchors.centerIn: parent
                            text: "‹"
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: 20
                            color: Qt.rgba(Root.Theme.primary.r,
                                           Root.Theme.primary.g,
                                           Root.Theme.primary.b, 0.9)
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: calendar.prevMonth()
                        }
                    }
                    Text {
                        Layout.fillWidth: true
                        text: calendar.monthNames[calendar.month] + " " + calendar.year
                        font.family: Root.Theme.fontFamily
                        font.pixelSize: 22
                        font.weight: Font.Bold
                        color: Qt.lighter(Root.Theme.primary, 1.2)
                        horizontalAlignment: Text.AlignHCenter
                    }
                    Item {
                        width: 28
                        height: 28
                        z: 10
                        Text {
                            anchors.centerIn: parent
                            text: "›"
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: 20
                            color: Qt.rgba(Root.Theme.primary.r,
                                           Root.Theme.primary.g,
                                           Root.Theme.primary.b, 0.9)
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: calendar.nextMonth()
                        }
                    }
                }

                // Nombres de días
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    Repeater {
                        model: calendar.dayNames
                        delegate: Text {
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            text: modelData
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: 16
                            font.weight: Font.DemiBold
                            color: Qt.rgba(Root.Theme.primary.r,
                                           Root.Theme.primary.g,
                                           Root.Theme.primary.b, 0.55)
                        }
                    }
                }

                // Días del mes en cuadrícula de 7 columnas
                Grid {
                    id: grid
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    columns: 7
                    spacing: 4
                    horizontalItemAlignment: Grid.AlignHCenter
                    verticalItemAlignment: Grid.AlignVCenter

                    // celdas vacías de compensación (para que el día 1 caiga en su columna)
                    Repeater {
                        model: calendar.leadingBlanks
                        delegate: Item {
                            width: 48
                            height: 42
                        }
                    }

                    Repeater {
                        model: calendar.daysInMonth
                        delegate: Item {
                            width: 48
                            height: 42

                            property bool isToday: calendar.isCurrentMonth
                                                   && (modelData + 1 === calendar.today)

                            // Círculo resaltando el día de hoy
                            Rectangle {
                                anchors.centerIn: parent
                                width: 34
                                height: 34
                                radius: 17
                                visible: parent.isToday
                                color: Root.Theme.primary
                            }

                            Text {
                                anchors.centerIn: parent
                                text: modelData + 1
                                font.family: Root.Theme.fontFamily
                                font.pixelSize: 16
                                color: parent.isToday
                                       ? "black"
                                       : Qt.rgba(Root.Theme.primary.r,
                                                 Root.Theme.primary.g,
                                                 Root.Theme.primary.b, 1)
                                font.weight: parent.isToday ? Font.Bold : Font.Normal
                            }
                        }
                    }
                }
            }
        }
    }
}
