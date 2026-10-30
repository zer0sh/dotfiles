import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../.." as Root

// DeskClock — reloj flotante en el "escritorio" con mensaje dinámico
// por franja horaria y un medidor de progreso del día.
// Va en una capa Bottom (encima del wallpaper, debajo de las ventanas).

Scope {
    id: deskClock

    property string currentTime: ""
    property real dayProgress: 0      // 0.0 = 00:00, ~1.0 = 23:59
    property string progressText: "0%"
    property bool panelVisible: Root.GadgetsManager.isEnabled("deskclock")
    property int posX: Root.GadgetsManager.getPosition("deskclock", 1420, 100).x
    property int posY: Root.GadgetsManager.getPosition("deskclock", 1420, 100).y

    Connections {
        target: Root.GadgetsManager
        function onStateChanged() {
            deskClock.panelVisible = Root.GadgetsManager.isEnabled("deskclock");
            var pos = Root.GadgetsManager.getPosition("deskclock", 1420, 100);
            deskClock.posX = pos.x;
            deskClock.posY = pos.y;
        }
    }

    // ── Toggle por IPC: `qs ipc call deskclock toggle` ────────────
    IpcHandler {
        target: "deskclock"
        function toggle(): void { Root.GadgetsManager.toggle("deskclock") }
        function show(): void { Root.GadgetsManager.setEnabled("deskclock", true) }
        function hide(): void { Root.GadgetsManager.setEnabled("deskclock", false) }
        function move(x: int, y: int): void {
            Root.GadgetsManager.setPosition("deskclock", x, y);
        }
    }

    // ── Motor de mensajes (separado del renderizado) ────────────────
    // Franjas: nombre, hora de inicio (0-23), mensajes.
    property var slots: [
        { hour: 6,  messages: [
            "Good morning, have a great day.",
            "Rise and shine.",
            "Morning mode: ON.",
            "Good morning. Let's make it count."
        ]},
        { hour: 11, messages: [
            "Happy hour, almorzando como Dios manda.",
            "Lunch time, a comer como Dios manda.",
            "It's lunch o'clock. Buen provecho.",
            "Hora de almorzar, no sea animal."
        ]},
        { hour: 14, messages: [
            "Buenas tardes, keep going.",
            "Good afternoon. You got this.",
            "Buenas tardes, seguimos en la lucha.",
            "Afternoon mode: ON."
        ]},
        { hour: 18, messages: [
            "Good evening, you made it.",
            "Buenas noches. We survived another one.",
            "Good evening. Time to slow down.",
            "The day is winding down."
        ]},
        { hour: 22, messages: [
            "Bro, seriously? A mimir.",
            "Bro, it's bedtime. A mimir.",
            "Mano, ya. A mimir.",
            "It's 22:00. What are you doing?",
            "Sleep.exe should be running."
        ]},
        { hour: 3,  messages: [
            "¿Quién te hizo tanto daño?",
            "Bro... who hurt you?",
            "Who hurt you this badly?",
            "Mano, ¿todo bien en casa?",
            "It's 4 AM. We need to talk."
        ]}
    ]

    // Franja activa (índice) para no re-randomizar cada segundo.
    property int activeSlot: -1
    property string message: ""

    function refreshGreeting() {
        var d = new Date()
        var h = d.getHours()

        var index = -1
        if (h >= 22 || h < 3)      index = 4   // late-night (22–02)
        else if (h >= 3 && h < 6)  index = 5   // very-late (03–05)
        else if (h >= 6 && h < 11) index = 0   // morning   (06–10)
        else if (h >= 11 && h < 14) index = 1  // lunch     (11–13)
        else if (h >= 14 && h < 18) index = 2  // afternoon (14–17)
        else if (h >= 18 && h < 22) index = 3  // evening   (18–21)

        if (index !== activeSlot) {
            activeSlot = index
            var list = deskClock.slots[index].messages
            message = list[Math.floor(Math.random() * list.length)]
        }
    }

    function pad(n) {
        return n < 10 ? "0" + n : "" + n
    }

    function updateClock() {
        var d = new Date()
        var h = d.getHours()
        var m = d.getMinutes()
        var s = d.getSeconds()

        deskClock.currentTime = pad(h) + "•" + pad(m)

        // Progreso del día: 0.0 a las 00:00 → ~1.0 a las 23:59.
        var total = h * 3600 + m * 60 + s
        var progress = total / 86400
        deskClock.dayProgress = progress
        deskClock.progressText = Math.round(progress * 100) + "%"

        // Actualiza el mensaje solo cuando cambia la franja horaria.
        deskClock.refreshGreeting()
    }

    // Actualización cada segundo (suficiente para hora y progreso suave).
    Timer {
        interval: 1000
        repeat: true
        running: true
        onTriggered: deskClock.updateClock()
    }

    Component.onCompleted: deskClock.updateClock()

    // ── Escritorio: capa Bottom (encima del wallpaper, debajo de ventanas) ──
    PanelWindow {
        id: win
        visible: deskClock.panelVisible
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer:    WlrLayer.Bottom
        WlrLayershell.namespace: "quickshell:deskclock"
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
            x: deskClock.posX
            y: deskClock.posY
            width: 580
            height: 560
            property bool isDragging: false

            Binding {
                target: mainCard
                property: "x"
                value: deskClock.posX
                when: !mainCard.isDragging
            }
            Binding {
                target: mainCard
                property: "y"
                value: deskClock.posY
                when: !mainCard.isDragging
            }

            // Arrastre libre desde cualquier punto del gadget
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
                    deskClock.posX = fx
                    deskClock.posY = fy
                    Root.GadgetsManager.setPosition("deskclock", fx, fy)
                    mainCard.isDragging = false
                }
            }

            // Botón sutil de cierre al pasar el cursor
            Text {
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: 8
                z: 100
                text: "✕"
                font.family: Root.Theme.fontFamily
                font.pixelSize: 15
                font.weight: Font.Bold
                color: closeHover.hovered ? Root.Theme.error : Qt.rgba(Root.Theme.textSecondary.r, Root.Theme.textSecondary.g, Root.Theme.textSecondary.b, 0.45)
                opacity: dragArea.containsMouse ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 180 } }

                HoverHandler { id: closeHover }
                TapHandler {
                    onTapped: Root.GadgetsManager.setEnabled("deskclock", false)
                }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 20

                Item { Layout.fillHeight: true }

                // Hora grande (~40% más grande)
                Text {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    text: deskClock.currentTime
                    font.family: Root.Theme.fontFamily
                    font.pixelSize: 168
                    font.weight: Font.Bold
                    color: Qt.lighter(Root.Theme.primary, 1.2)
                    horizontalAlignment: Text.AlignHCenter
                    style: Text.Sunken
                    styleColor: Root.Theme.primary
                }

                // Medidor de progreso del día
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 10

                    // Barra
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 14
                        Layout.alignment: Qt.AlignHCenter
                        radius: 7
                        color: Qt.rgba(Root.Theme.primary.r,
                                      Root.Theme.primary.g,
                                      Root.Theme.primary.b, 0.15)

                        Rectangle {
                            id: fill
                            width: Math.max(14, parent.width * deskClock.dayProgress)
                            height: parent.height
                            radius: 7
                            color: Qt.lighter(Root.Theme.primary, 1.3)
                            Behavior on width {
                                NumberAnimation { duration: 1000; easing.type: Easing.OutCubic }
                            }
                        }
                    }

                    // Etiqueta: porcentaje del día transcurrido
                    Text {
                        Layout.fillWidth: true
                        text: deskClock.progressText
                        font.family: Root.Theme.fontFamily
                        font.pixelSize: 17
                        font.weight: Font.DemiBold
                        color: Qt.lighter(Root.Theme.primary, 1.2)
                        horizontalAlignment: Text.AlignHCenter
                    }
                }

                // Mensaje dinámico
                Text {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredHeight: 68
                    text: deskClock.message
                    font.family: Root.Theme.fontFamily
                    font.pixelSize: 21
                    color: Qt.lighter(Root.Theme.primary, 1.1)
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    wrapMode: Text.WordWrap
                    style: Text.Sunken
                    styleColor: Root.Theme.primary
                }

                Item { Layout.fillHeight: true }
            }
        }
    }
}
