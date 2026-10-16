import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../.." as Root

// Calendar — calendario simple en el "escritorio".
// Va en una capa Background (detrás de las ventanas) y no captura input.
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
    property bool panelVisible: true

    // ── Toggle por IPC: `qs ipc call calendar toggle` ─────────────
    IpcHandler {
        target: "calendar"
        function toggle(): void { calendar.panelVisible = !calendar.panelVisible }
        function show(): void { calendar.panelVisible = true }
        function hide(): void { calendar.panelVisible = false }
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
        visible: calendar.panelVisible
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer:    WlrLayer.Bottom
        WlrLayershell.namespace: "quickshell:calendar"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        anchors.bottom: true
        anchors.left:   true
        margins.bottom: 100
        margins.left:   100
        implicitWidth:  400
        implicitHeight: 400

        // Panel con estilo neon
        Rectangle {
            anchors.fill: parent
            radius: 18
            color: Qt.rgba(0.05, 0.05, 0.08, 0.55)
            border.color: Root.Theme.primary
            border.width: 2

            Rectangle {
                anchors.fill: parent
                anchors.margins: -6
                radius: 24
                color: "transparent"
                border.color: Qt.rgba(Root.Theme.primary.r,
                                      Root.Theme.primary.g,
                                      Root.Theme.primary.b, 0.5)
                border.width: 2
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 12

                // Encabezado:  ‹ August ›  (funcional)
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Item {
                        width: 28
                        height: 28
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
