import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../.." as Root

Scope {
    id: shortcuts

    property bool visible: false
    property var binds: []
    property var filteredBinds: []
    property var variables: ({})
    property string searchQuery: ""
    property string currentCategory: "all"

    readonly property var categories: [
        { id: "all", label: "Todos", icon: "grid_view" },
        { id: "apps", label: "Aplicaciones", icon: "apps" },
        { id: "windows", label: "Ventanas", icon: "splitscreen" },
        { id: "workspaces", label: "Espacios", icon: "view_carousel" },
        { id: "system", label: "Sistema", icon: "tune" }
    ]

    readonly property var translations: ({
        "open terminal": "Abrir terminal",
        "open file manager": "Abrir gestor de archivos",
        "close active window": "Cerrar ventana activa",
        "reload hyprland config": "Recargar configuración de Hyprland",
        "open app launcher": "Abrir lanzador de aplicaciones",
        "open monitor layout editor": "Editor de pantallas y monitores",
        "lock screen": "Bloquear pantalla",
        "screenshot full screen (save + clipboard)": "Capturar pantalla completa",
        "screenshot selected area (save + clipboard)": "Capturar área seleccionada",
        "ocr selected area": "Reconocimiento OCR de texto en pantalla",
        "toggle screen recording": "Grabar pantalla (iniciar / detener)",
        "raise volume": "Subir volumen",
        "lower volume": "Bajar volumen",
        "toggle mute": "Silenciar o restaurar audio",
        "increase brightness": "Aumentar brillo de pantalla",
        "decrease brightness": "Reducir brillo de pantalla",
        "toggle floating mode": "Alternar modo flotante",
        "toggle fullscreen": "Alternar pantalla completa",
        "launch an app as root (requires the sudo-launcher script)": "Ejecutar app como root (sudo)",
        "power off menu": "Menú de apagado y sesión",
        "wallpaper picker": "Selector de fondos de pantalla",
        "help menu": "Menú de ayuda y atajos (F1)",
        "mini music player": "Mini reproductor de música",
        "screen shader controls": "Selector de filtros y shaders",
        "open screen shader menu carousel": "Selector de filtros y shaders",
        "apply sepia shader": "Aplicar filtro Sepia",
        "apply black and white shader": "Aplicar filtro Blanco y Negro",
        "apply noir shader": "Aplicar filtro Film Noir",
        "apply vintage shader": "Aplicar filtro Vintage",
        "apply vivid shader": "Aplicar filtro Vívido",
        "disable screen shader": "Desactivar filtros de pantalla",
        "move window with mouse drag": "Mover ventana flotante",
        "resize window with mouse right-click drag": "Redimensionar ventana flotante",
        "next workspace": "Siguiente espacio de trabajo",
        "previous workspace": "Espacio de trabajo anterior"
    })

    function initVars() {
        variables = {}
        variables["$mainMod"] = "SUPER"
    }

    function updateFilter() {
        var q = searchQuery.toLowerCase().trim()
        var cat = currentCategory
        var res = []

        for (var i = 0; i < binds.length; i++) {
            var item = binds[i]
            if (cat !== "all" && item.category !== cat) continue

            if (q !== "") {
                var inDesc = item.desc.toLowerCase().indexOf(q) !== -1
                var inKey = item.key.toLowerCase().indexOf(q) !== -1
                if (!inDesc && !inKey) continue
            }

            res.push(item)
        }
        filteredBinds = res
    }

    onCurrentCategoryChanged: updateFilter()
    onSearchQueryChanged: updateFilter()

    function parseBinds(output) {
        var lines = output.split("\n")
        var result = []
        var lastComment = ""
        initVars()

        var seenWorkspaceNav = false
        var seenWorkspaceMove = false
        var seenFocusNav = false
        var seenWindowMove = false
        var seenResize = false
        var seenMouseWs = false

        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim()

            if (line.charAt(0) === "#") {
                lastComment = line.substring(1).trim()
                continue
            }

            if (line === "") { lastComment = ""; continue }

            if (line.indexOf("=") !== -1 && line.indexOf("bind") !== 0 && line.indexOf("bindm") !== 0) {
                var eq = line.indexOf("=")
                var varname = line.substring(0, eq).trim()
                var varval = line.substring(eq + 1).trim()
                if (varname.charAt(0) === "$" && varname !== "$mainMod") {
                    variables[varname] = varval
                }
                lastComment = ""
                continue
            }

            if (line.indexOf("bind =") === 0 || line.indexOf("bind ") === 0 || line.indexOf("bindm =") === 0 || line.indexOf("bindm ") === 0) {
                var isMouse = line.indexOf("bindm") === 0
                var rest = line.indexOf("=") !== -1 ? line.substring(line.indexOf("=") + 1).trim() : line.substring(5).trim()
                if (rest === "") { lastComment = ""; continue }

                var parts = []
                var current = ""
                for (var j = 0; j < rest.length; j++) {
                    var ch = rest.charAt(j)
                    if (ch === ",") {
                        parts.push(current.trim())
                        current = ""
                    } else {
                        current += ch
                    }
                }
                if (current.trim() !== "") parts.push(current.trim())

                if (parts.length >= 2) {
                    var mods = resolveVar(parts[0]).trim()
                    var key = resolveVar(parts[1]).trim()
                    var dispatcher = parts.length >= 3 ? parts[2].trim() : ""
                    var args = parts.length >= 4 ? parts.slice(3).join(", ").trim() : ""

                    if (dispatcher === "workspace") {
                        if (key.indexOf("mouse") !== -1) {
                            if (!seenMouseWs) {
                                seenMouseWs = true
                                result.push({
                                    key: "SUPER + Rueda Ratón",
                                    desc: "Navegar entre espacios de trabajo",
                                    category: "workspaces"
                                })
                            }
                        } else if (!seenWorkspaceNav) {
                            seenWorkspaceNav = true
                            result.push({
                                key: "SUPER + 1..9, 0",
                                desc: "Cambiar a espacio de trabajo (1 al 10)",
                                category: "workspaces"
                            })
                        }
                        lastComment = ""
                        continue
                    }

                    if (dispatcher === "movetoworkspace") {
                        if (!seenWorkspaceMove) {
                            seenWorkspaceMove = true
                            result.push({
                                key: "SUPER + SHIFT + 1..9, 0",
                                desc: "Mover ventana a espacio (1 al 10)",
                                category: "workspaces"
                            })
                        }
                        lastComment = ""
                        continue
                    }

                    if (dispatcher === "movefocus") {
                        if (!seenFocusNav) {
                            seenFocusNav = true
                            result.push({
                                key: "SUPER + Flechas",
                                desc: "Cambiar foco entre ventanas",
                                category: "windows"
                            })
                        }
                        lastComment = ""
                        continue
                    }

                    if (dispatcher === "movewindow") {
                        if (isMouse) {
                            result.push({
                                key: "SUPER + Clic Izq.",
                                desc: "Mover ventana flotante (arrastrar)",
                                category: "windows"
                            })
                        } else if (!seenWindowMove) {
                            seenWindowMove = true
                            result.push({
                                key: "SUPER + SHIFT + Flechas",
                                desc: "Mover posición de ventana",
                                category: "windows"
                            })
                        }
                        lastComment = ""
                        continue
                    }

                    if (dispatcher === "resizewindow") {
                        result.push({
                            key: "SUPER + Clic Der.",
                            desc: "Redimensionar ventana (arrastrar)",
                            category: "windows"
                        })
                        lastComment = ""
                        continue
                    }

                    if (dispatcher === "resizeactive") {
                        if (!seenResize) {
                            seenResize = true
                            result.push({
                                key: "SUPER + ALT + Flechas",
                                desc: "Redimensionar tamaño de ventana",
                                category: "windows"
                            })
                        }
                        lastComment = ""
                        continue
                    }

                    var modParts = mods ? mods.split(/\s+/).filter(Boolean) : []
                    var displayKeys = []
                    for (var m = 0; m < modParts.length; m++) {
                        var mod = modParts[m]
                        if (mod === "SUPER") displayKeys.push("SUPER")
                        else if (mod === "SHIFT") displayKeys.push("SHIFT")
                        else if (mod === "ALT") displayKeys.push("ALT")
                        else if (mod === "CTRL") displayKeys.push("CTRL")
                        else displayKeys.push(mod)
                    }

                    if (key) {
                        var cleanKey = key
                        if (cleanKey === "space") cleanKey = "Espacio"
                        else if (cleanKey === "Return") cleanKey = "Enter"
                        else if (cleanKey === "Print") cleanKey = "Impr Pant"
                        else if (cleanKey === "Delete") cleanKey = "Supr"
                        else if (cleanKey === "mouse_down") cleanKey = "Rueda Abajo"
                        else if (cleanKey === "mouse_up") cleanKey = "Rueda Arriba"
                        else if (cleanKey === "XF86AudioRaiseVolume") cleanKey = "Volumen +"
                        else if (cleanKey === "XF86AudioLowerVolume") cleanKey = "Volumen -"
                        else if (cleanKey === "XF86AudioMute") cleanKey = "Silenciar"
                        else if (cleanKey === "XF86MonBrightnessUp") cleanKey = "Brillo +"
                        else if (cleanKey === "XF86MonBrightnessDown") cleanKey = "Brillo -"
                        displayKeys.push(cleanKey)
                    }

                    var rawDesc = lastComment !== "" ? lastComment : (dispatcher + (args !== "" ? " " + args : ""))
                    var trans = translations[rawDesc.toLowerCase()]
                    var desc = trans !== undefined ? trans : rawDesc

                    var cat = "system"
                    var lowerDesc = desc.toLowerCase()

                    if (lowerDesc.indexOf("terminal") !== -1 || lowerDesc.indexOf("archivos") !== -1 ||
                        lowerDesc.indexOf("lanzador") !== -1 || (lowerDesc.indexOf("pantalla") !== -1 && lowerDesc.indexOf("editor") !== -1) ||
                        lowerDesc.indexOf("música") !== -1 || lowerDesc.indexOf("wallpaper") !== -1 || lowerDesc.indexOf("fondo") !== -1 ||
                        lowerDesc.indexOf("root") !== -1 || lowerDesc.indexOf("sudo") !== -1) {
                        cat = "apps"
                    } else if (lowerDesc.indexOf("ventana") !== -1 || dispatcher === "killactive" ||
                               dispatcher === "togglefloating" || dispatcher === "fullscreen") {
                        cat = "windows"
                    } else if (lowerDesc.indexOf("espacio") !== -1 || dispatcher === "workspace") {
                        cat = "workspaces"
                    } else {
                        cat = "system"
                    }

                    result.push({
                        key: displayKeys.join(" + "),
                        desc: desc,
                        category: cat
                    })
                }
                lastComment = ""
            }
        }

        binds = result
        updateFilter()
    }

    function resolveVar(val) {
        return val.replace(/\$[A-Za-z_][A-Za-z0-9_]*/g, function(m) {
            return variables[m] !== undefined ? variables[m] : m
        })
    }

    Process {
        id: bindReader
        command: ["cat", "/home/zero/.config/hypr/binds.conf"]
        stdout: StdioCollector {
            onStreamFinished: {
                shortcuts.parseBinds(text)
            }
        }
    }

    onVisibleChanged: {
        if (visible) {
            searchQuery = ""
            currentCategory = "all"
            bindReader.running = true
        }
    }

    Component.onCompleted: bindReader.running = true

    Loader {
        active: shortcuts.visible

        sourceComponent: PanelWindow {
            id: overlay
            visible: true
            anchors.top: true
            anchors.bottom: true
            anchors.left: true
            anchors.right: true
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "quickshell:shortcuts"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            Shortcut {
                sequence: "Escape"
                onActivated: shortcuts.visible = false
            }

            Shortcut {
                sequence: "F1"
                onActivated: shortcuts.visible = false
            }

            // Fondo translúcido con desenfoque de Hyprland y cierre al hacer clic fuera
            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(0, 0, 0, 0.45)

                MouseArea {
                    anchors.fill: parent
                    onClicked: shortcuts.visible = false
                }
            }

            // Ventana modal de atajos con estética Glassmorphism del Control Center
            Rectangle {
                id: modalPanel
                anchors.centerIn: parent
                width: Math.min(920, overlay.width - 40)
                height: Math.min(660, overlay.height - 60)
                radius: 28

                color: Qt.rgba(Root.Theme.surface.r, Root.Theme.surface.g, Root.Theme.surface.b, 0.78)
                border.width: 1.5
                border.color: Qt.rgba(255, 255, 255, 0.16)
                clip: true

                // Detener propagación de clics
                MouseArea {
                    anchors.fill: parent
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 24
                    spacing: 16

                    // ── Encabezado principal ──────────────────────────
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 14

                        Rectangle {
                            Layout.preferredWidth: 44
                            Layout.preferredHeight: 44
                            radius: 22
                            color: Root.Theme.surfaceContainerHigh
                            border.width: 1
                            border.color: Qt.rgba(255, 255, 255, 0.10)

                            Text {
                                anchors.centerIn: parent
                                text: "keyboard"
                                font.family: Root.Theme.iconFont
                                font.pixelSize: 24
                                color: Root.Theme.primary
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                text: "Atajos de Teclado"
                                font.family: Root.Theme.fontFamily
                                font.pixelSize: 22
                                font.weight: Font.Bold
                                color: Root.Theme.textPrimary
                            }

                            Text {
                                text: "Hyprland • Guía visual y referencias rápidas"
                                font.family: Root.Theme.fontFamily
                                font.pixelSize: Root.Theme.fontSizeSmall
                                color: Root.Theme.textSecondary
                            }
                        }

                        // Botón de cierre
                        Rectangle {
                            Layout.preferredWidth: 36
                            Layout.preferredHeight: 36
                            radius: 18
                            color: closeBtnArea.containsMouse ? Root.Theme.surfaceContainerHigh : "transparent"

                            Behavior on color {
                                ColorAnimation { duration: Root.Theme.animDurationFast }
                            }

                            Text {
                                anchors.centerIn: parent
                                text: "close"
                                font.family: Root.Theme.iconFont
                                font.pixelSize: 20
                                color: Root.Theme.textPrimary
                            }

                            MouseArea {
                                id: closeBtnArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: shortcuts.visible = false
                            }
                        }
                    }

                    // ── Barra de búsqueda y categorías ────────────────
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        // Campo de búsqueda integrado
                        Rectangle {
                            Layout.preferredWidth: 280
                            Layout.preferredHeight: 40
                            radius: 12
                            color: Root.Theme.surfaceContainer
                            border.width: searchInput.activeFocus ? 1.5 : 1
                            border.color: searchInput.activeFocus
                                ? Root.Theme.primary
                                : Qt.rgba(255, 255, 255, 0.08)

                            Behavior on border.color {
                                ColorAnimation { duration: Root.Theme.animDurationFast }
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 10
                                spacing: 8

                                Text {
                                    text: "search"
                                    font.family: Root.Theme.iconFont
                                    font.pixelSize: 18
                                    color: searchInput.activeFocus ? Root.Theme.primary : Root.Theme.textSecondary
                                }

                                TextInput {
                                    id: searchInput
                                    Layout.fillWidth: true
                                    font.family: Root.Theme.fontFamily
                                    font.pixelSize: Root.Theme.fontSizeSmall
                                    color: Root.Theme.textPrimary
                                    selectByMouse: true
                                    selectionColor: Root.Theme.primary
                                    selectedTextColor: Root.Theme.tileActiveText
                                    text: shortcuts.searchQuery

                                    onTextChanged: {
                                        shortcuts.searchQuery = text
                                    }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "Buscar atajo..."
                                        font.family: Root.Theme.fontFamily
                                        font.pixelSize: Root.Theme.fontSizeSmall
                                        color: Root.Theme.textSecondary
                                        visible: searchInput.text === ""
                                    }
                                }

                                Rectangle {
                                    visible: searchInput.text !== ""
                                    Layout.preferredWidth: 20
                                    Layout.preferredHeight: 20
                                    radius: 10
                                    color: clearHover.containsMouse ? Root.Theme.surfaceContainerHigh : "transparent"

                                    Text {
                                        anchors.centerIn: parent
                                        text: "close"
                                        font.family: Root.Theme.iconFont
                                        font.pixelSize: 14
                                        color: Root.Theme.textSecondary
                                    }

                                    MouseArea {
                                        id: clearHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: searchInput.text = ""
                                    }
                                }
                            }
                        }

                        // Píldoras de Categorías
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Repeater {
                                model: shortcuts.categories

                                Rectangle {
                                    id: catPill
                                    Layout.preferredHeight: 40
                                    Layout.preferredWidth: pillRow.implicitWidth + 24
                                    radius: 12

                                    readonly property bool isSelected: shortcuts.currentCategory === modelData.id

                                    color: isSelected
                                        ? Root.Theme.primary
                                        : (pillArea.containsMouse ? Root.Theme.surfaceContainerHigh : Root.Theme.surfaceContainer)

                                    border.width: 1
                                    border.color: isSelected ? "transparent" : Qt.rgba(255, 255, 255, 0.05)

                                    Behavior on color {
                                        ColorAnimation { duration: Root.Theme.animDurationFast }
                                    }

                                    RowLayout {
                                        id: pillRow
                                        anchors.centerIn: parent
                                        spacing: 6

                                        Text {
                                            text: modelData.icon
                                            font.family: Root.Theme.iconFont
                                            font.pixelSize: 16
                                            color: catPill.isSelected ? Root.Theme.tileActiveText : Root.Theme.textSecondary
                                        }

                                        Text {
                                            text: modelData.label
                                            font.family: Root.Theme.fontFamily
                                            font.pixelSize: Root.Theme.fontSizeSmall
                                            font.weight: catPill.isSelected ? Font.DemiBold : Font.Normal
                                            color: catPill.isSelected ? Root.Theme.tileActiveText : Root.Theme.textPrimary
                                        }
                                    }

                                    MouseArea {
                                        id: pillArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: shortcuts.currentCategory = modelData.id
                                    }
                                }
                            }

                            Item { Layout.fillWidth: true }
                        }
                    }

                    // Línea divisoria elegante
                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: Qt.rgba(Root.Theme.panelBorder.r, Root.Theme.panelBorder.g, Root.Theme.panelBorder.b, 0.4)
                    }

                    // ── Rejilla de Atajos de Teclado (2 Columnas) ─────
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        // Estado vacío cuando no hay coincidencias
                        ColumnLayout {
                            anchors.centerIn: parent
                            visible: shortcuts.filteredBinds.length === 0
                            spacing: 8

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: "search_off"
                                font.family: Root.Theme.iconFont
                                font.pixelSize: 44
                                color: Root.Theme.textSecondary
                            }

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: "No se encontraron atajos"
                                font.family: Root.Theme.fontFamily
                                font.pixelSize: Root.Theme.fontSizeNormal
                                font.weight: Font.Medium
                                color: Root.Theme.textPrimary
                            }

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: "Intenta con otra palabra clave o selecciona otra categoría"
                                font.family: Root.Theme.fontFamily
                                font.pixelSize: Root.Theme.fontSizeSmall
                                color: Root.Theme.textSecondary
                            }
                        }

                        Flickable {
                            id: cardsFlickable
                            anchors.fill: parent
                            visible: shortcuts.filteredBinds.length > 0
                            contentHeight: cardsGrid.implicitHeight
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds

                            ScrollBar.vertical: ScrollBar {
                                id: vScroll
                                width: 6
                                policy: cardsFlickable.contentHeight > cardsFlickable.height ? ScrollBar.AlwaysOn : ScrollBar.AsNeeded
                                contentItem: Rectangle {
                                    radius: 3
                                    color: Qt.rgba(Root.Theme.primary.r, Root.Theme.primary.g, Root.Theme.primary.b, 0.45)
                                }
                            }

                            Flow {
                                id: cardsGrid
                                width: cardsFlickable.width - (vScroll.visible ? 10 : 0)
                                spacing: 10

                                Repeater {
                                    model: shortcuts.filteredBinds

                                    Rectangle {
                                        id: card
                                        width: Math.floor((cardsGrid.width - 10) / 2)
                                        height: 48
                                        radius: 14

                                        color: cardHover.containsMouse
                                            ? Root.Theme.surfaceContainerHigh
                                            : Root.Theme.surfaceContainer

                                        border.width: 1
                                        border.color: cardHover.containsMouse
                                            ? Qt.rgba(255, 255, 255, 0.12)
                                            : Qt.rgba(255, 255, 255, 0.04)

                                        Behavior on color {
                                            ColorAnimation { duration: Root.Theme.animDurationFast }
                                        }

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 14
                                            anchors.rightMargin: 12
                                            spacing: 10

                                            // Indicador de categoría
                                            Rectangle {
                                                Layout.preferredWidth: 4
                                                Layout.preferredHeight: 18
                                                radius: 2
                                                color: {
                                                    if (modelData.category === "apps") return Root.Theme.primary
                                                    if (modelData.category === "windows") return Root.Theme.connected
                                                    if (modelData.category === "workspaces") return Root.Theme.accent
                                                    return Root.Theme.textSecondary
                                                }
                                            }

                                            // Descripción de la acción
                                            Text {
                                                Layout.fillWidth: true
                                                text: modelData.desc
                                                font.family: Root.Theme.fontFamily
                                                font.pixelSize: 13
                                                font.weight: Font.Medium
                                                color: Root.Theme.textPrimary
                                                elide: Text.ElideRight
                                            }

                                            // Fila de teclas con estilo keycap
                                            RowLayout {
                                                spacing: 4

                                                Repeater {
                                                    model: modelData.key.split(" + ")

                                                    Rectangle {
                                                        Layout.preferredHeight: 26
                                                        Layout.preferredWidth: keyCapText.implicitWidth + 14
                                                        radius: 7

                                                        color: Qt.rgba(Root.Theme.primary.r, Root.Theme.primary.g, Root.Theme.primary.b, 0.14)
                                                        border.width: 1
                                                        border.color: Qt.rgba(Root.Theme.primary.r, Root.Theme.primary.g, Root.Theme.primary.b, 0.32)

                                                        Text {
                                                            id: keyCapText
                                                            anchors.centerIn: parent
                                                            text: modelData
                                                            font.family: Root.Theme.fontFamily
                                                            font.pixelSize: 11
                                                            font.weight: Font.DemiBold
                                                            color: Root.Theme.primary
                                                        }
                                                    }
                                                }
                                            }
                                        }

                                        MouseArea {
                                            id: cardHover
                                            anchors.fill: parent
                                            hoverEnabled: true
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Línea divisoria inferior
                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: Qt.rgba(Root.Theme.panelBorder.r, Root.Theme.panelBorder.g, Root.Theme.panelBorder.b, 0.4)
                    }

                    // ── Pie de información y atajos ──────────────────
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: "description"
                            font.family: Root.Theme.iconFont
                            font.pixelSize: 15
                            color: Root.Theme.textSecondary
                        }

                        Text {
                            text: "~/.config/hypr/binds.conf"
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: Root.Theme.fontSizeXS
                            color: Root.Theme.textSecondary
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: shortcuts.filteredBinds.length + " atajos disponibles"
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: Root.Theme.fontSizeXS
                            color: Root.Theme.textSecondary
                        }

                        Rectangle {
                            Layout.preferredHeight: 22
                            Layout.preferredWidth: hintText.implicitWidth + 14
                            radius: 6
                            color: Root.Theme.surfaceContainerHigh
                            border.width: 1
                            border.color: Qt.rgba(255, 255, 255, 0.08)

                            Text {
                                id: hintText
                                anchors.centerIn: parent
                                text: "F1 o Esc para salir"
                                font.family: Root.Theme.fontFamily
                                font.pixelSize: Root.Theme.fontSizeXS
                                color: Root.Theme.textSecondary
                            }
                        }
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "shortcuts"
        function toggle(): void { shortcuts.visible = !shortcuts.visible; }
        function open(): void   { shortcuts.visible = true; }
        function close(): void  { shortcuts.visible = false; }
    }
}
