import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../.." as Root

Scope {
    id: scratchpad

    property string configPath: "/home/zero/.config/quickshell/scratchpad.json"
    property var tasks: [
        { "id": 1, "text": "Refinar configuración de Hyprland & Waybar", "done": true },
        { "id": 2, "text": "Personalizar nuevos gadgets de Quickshell", "done": false }
    ]

    property bool panelVisible: Root.GadgetsManager.isEnabled("scratchpad")
    property int posX: Root.GadgetsManager.getPosition("scratchpad", 80, 650).x
    property int posY: Root.GadgetsManager.getPosition("scratchpad", 80, 650).y

    Connections {
        target: Root.GadgetsManager
        function onStateChanged() {
            scratchpad.panelVisible = Root.GadgetsManager.isEnabled("scratchpad");
            var pos = Root.GadgetsManager.getPosition("scratchpad", 80, 650);
            scratchpad.posX = pos.x;
            scratchpad.posY = pos.y;
        }
    }

    IpcHandler {
        target: "scratchpad"
        function toggle(): void { Root.GadgetsManager.toggle("scratchpad") }
        function show(): void { Root.GadgetsManager.setEnabled("scratchpad", true) }
        function hide(): void { Root.GadgetsManager.setEnabled("scratchpad", false) }
        function add(text: string): void {
            if (text && text.trim() !== "") scratchpad.addTask(text.trim());
        }
    }

    // ── Lectura persistente ──────────────────────────────────────
    Process {
        id: readProc
        command: ["/bin/sh", "-c", "cat " + scratchpad.configPath + " 2>/dev/null || cat /home/zero/dotfiles/quickshell/data/scratchpad.json 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                var raw = text.trim();
                if (raw !== "") {
                    try {
                        var parsed = JSON.parse(raw);
                        if (Array.isArray(parsed)) {
                            scratchpad.tasks = parsed;
                        }
                    } catch (e) {
                        console.log("[Scratchpad] Error al parsear scratchpad.json:", e);
                    }
                }
            }
        }
    }

    // ── Escritura persistente ────────────────────────────────────
    Process {
        id: saveProc
    }

    function saveTasks() {
        if (saveProc.running) saveProc.running = false;
        var jsonStr = JSON.stringify(scratchpad.tasks, null, 2);
        saveProc.command = [
            "/bin/sh", "-c",
            "mkdir -p ~/.config/quickshell && printf '%s\\n' '" +
            jsonStr.replace(/'/g, "'\\''") +
            "' > " + scratchpad.configPath
        ];
        saveProc.running = true;
    }

    function toggleTask(idx) {
        var copy = scratchpad.tasks.slice();
        if (copy[idx]) {
            copy[idx].done = !copy[idx].done;
            scratchpad.tasks = copy;
            saveTasks();
        }
    }

    function removeTask(idx) {
        var copy = scratchpad.tasks.slice();
        copy.splice(idx, 1);
        scratchpad.tasks = copy;
        saveTasks();
    }

    function addTask(txt) {
        if (!txt || txt.trim() === "") return;
        var copy = scratchpad.tasks.slice();
        copy.push({
            "id": Date.now(),
            "text": txt.trim(),
            "done": false
        });
        scratchpad.tasks = copy;
        saveTasks();
    }

    Component.onCompleted: {
        readProc.running = true;
    }

    PanelWindow {
        id: win
        visible: scratchpad.panelVisible
        color: "transparent"

        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.namespace: "quickshell:scratchpad"
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
            x: scratchpad.posX
            y: scratchpad.posY
            width: 310
            height: Math.max(160, 40 + (taskCol.children.length * 30) + 40)
            property bool isDragging: false

            Binding {
                target: mainCard
                property: "x"
                value: scratchpad.posX
                when: !mainCard.isDragging
            }
            Binding {
                target: mainCard
                property: "y"
                value: scratchpad.posY
                when: !mainCard.isDragging
            }

            MouseArea {
                id: dragArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: pressed ? Qt.ClosedHandCursor : (containsMouse ? Qt.OpenHandCursor : Qt.ArrowCursor)
                drag.target: mainCard
                drag.axis: Drag.XAndYAxis

                onPressed: {
                    mainCard.isDragging = true;
                }

                onReleased: {
                    var fx = Math.round(mainCard.x);
                    var fy = Math.round(mainCard.y);
                    scratchpad.posX = fx;
                    scratchpad.posY = fy;
                    Root.GadgetsManager.setPosition("scratchpad", fx, fy);
                    mainCard.isDragging = false;
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
                    onTapped: Root.GadgetsManager.setEnabled("scratchpad", false)
                }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                // Header
                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "SCRATCHPAD"
                        font.family: Root.Theme.fontFamily
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        font.letterSpacing: 1.5
                        color: Root.Theme.primary
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: scratchpad.tasks.filter(t => !t.done).length + " pendientes"
                        font.family: Root.Theme.fontFamily
                        font.pixelSize: 10
                        font.weight: Font.Medium
                        color: Root.Theme.textSecondary
                    }
                }

                // Lista de notas / tareas
                Column {
                    id: taskCol
                    Layout.fillWidth: true
                    spacing: 4

                    Repeater {
                        model: scratchpad.tasks

                        Item {
                            width: taskCol.width
                            height: 26

                            RowLayout {
                                anchors.fill: parent
                                spacing: 8

                                // Checkbox icon
                                Text {
                                    text: modelData.done ? "󰄵" : "󰄱"
                                    font.family: Root.Theme.iconFont
                                    font.pixelSize: 15
                                    color: modelData.done ? Root.Theme.primary : Root.Theme.textSecondary
                                }

                                // Texto
                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.text
                                    font.family: Root.Theme.fontFamily
                                    font.pixelSize: 12
                                    font.strikeout: modelData.done
                                    color: modelData.done ? Root.Theme.textSecondary : Root.Theme.textPrimary
                                    opacity: modelData.done ? 0.6 : 1.0
                                    elide: Text.ElideRight
                                }

                                // Botón eliminar al pasar el cursor sobre la tarea
                                Item {
                                    width: 18
                                    height: 18
                                    visible: rowHover.hovered

                                    Text {
                                        anchors.centerIn: parent
                                        text: "✕"
                                        font.pixelSize: 10
                                        font.weight: Font.Bold
                                        color: delHover.hovered ? Root.Theme.error : Root.Theme.textSecondary
                                    }

                                    HoverHandler { id: delHover }
                                    TapHandler {
                                        onTapped: scratchpad.removeTask(index)
                                    }
                                }
                            }

                            HoverHandler { id: rowHover }

                            MouseArea {
                                anchors.fill: parent
                                anchors.rightMargin: 24
                                cursorShape: Qt.PointingHandCursor
                                onClicked: scratchpad.toggleTask(index)
                            }
                        }
                    }
                }

                // Input para nueva nota
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        text: "+"
                        font.family: Root.Theme.fontFamily
                        font.pixelSize: 14
                        font.weight: Font.Bold
                        color: Root.Theme.primary
                    }

                    TextInput {
                        id: newNoteInput
                        Layout.fillWidth: true
                        font.family: Root.Theme.fontFamily
                        font.pixelSize: 12
                        color: Root.Theme.textPrimary
                        selectByMouse: true
                        clip: true

                        Text {
                            anchors.fill: parent
                            text: "Añadir nota y presionar Enter…"
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: 12
                            font.italic: true
                            color: Root.Theme.textSecondary
                            opacity: 0.5
                            visible: !newNoteInput.text && !newNoteInput.activeFocus
                        }

                        onAccepted: {
                            if (text.trim() !== "") {
                                scratchpad.addTask(text);
                                text = "";
                            }
                        }
                    }
                }
            }
        }
    }
}
