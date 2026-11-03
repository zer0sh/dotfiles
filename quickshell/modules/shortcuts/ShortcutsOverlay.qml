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
        { id: "all", label: "All", icon: "grid_view" },
        { id: "apps", label: "Applications", icon: "apps" },
        { id: "windows", label: "Windows", icon: "splitscreen" },
        { id: "workspaces", label: "Workspaces", icon: "view_carousel" },
        { id: "system", label: "System", icon: "tune" }
    ]

    readonly property var translations: ({
        "open terminal": "Open terminal",
        "open file manager": "Open file manager",
        "close active window": "Close active window",
        "reload hyprland config": "Reload Hyprland config",
        "open app launcher": "Open app launcher",
        "workspace overview next": "Next workspace overview",
        "workspace overview previous": "Previous workspace overview",
        "workspace overview & window switcher": "Workspace overview",
        "open monitor layout editor": "Display and monitor settings",
        "lock screen": "Lock screen",
        "capture full screen": "Capture full screen",
        "capture selected area": "Capture selected area",
        "screenshot full screen (save + clipboard)": "Capture full screen",
        "screenshot selected area (save + clipboard)": "Capture selected area",
        "ocr selected area": "OCR text recognition from screen",
        "toggle screen recording": "Toggle screen recording",
        "raise volume": "Raise volume",
        "lower volume": "Lower volume",
        "toggle mute": "Toggle audio mute",
        "toggle audio mute": "Toggle audio mute",
        "toggle microphone mute": "Toggle microphone mute",
        "toggle microphone mute (fallback)": "Toggle microphone mute (fallback)",
        "increase brightness": "Increase brightness",
        "decrease brightness": "Decrease brightness",
        "toggle airplane mode (rfkill)": "Toggle airplane mode (RFKill)",
        "toggle airplane mode (wlan)": "Toggle airplane mode (WLAN)",
        "toggle airplane mode": "Toggle airplane mode",
        "airplane mode toggle": "Toggle airplane mode",
        "cycle power profiles": "Cycle power profiles",
        "power profiles cycle (performance / balanced / power-saver)": "Cycle power profiles",
        "toggle do not disturb": "Toggle Do Not Disturb",
        "do not disturb toggle": "Toggle Do Not Disturb",
        "toggle caffeine (keep awake)": "Toggle Caffeine (keep awake)",
        "caffeine toggle (keep display awake)": "Toggle Caffeine (keep awake)",
        "toggle floating mode": "Toggle floating mode",
        "toggle fullscreen": "Toggle fullscreen",
        "launch application as root": "Launch application as root",
        "launch an app as root (requires the sudo-launcher script)": "Launch application as root",
        "open power menu": "Open power menu",
        "power off menu": "Open power menu",
        "open wallpaper picker": "Open wallpaper picker",
        "wallpaper picker": "Open wallpaper picker",
        "open keyboard shortcuts cheatsheet": "Keyboard shortcuts cheatsheet",
        "help menu": "Keyboard shortcuts cheatsheet",
        "open clipboard history": "Open clipboard history",
        "clipboard history": "Open clipboard history",
        "toggle mini music player": "Toggle mini music player",
        "mini music player": "Toggle mini music player",
        "open screen shader carousel": "Open screen shader carousel",
        "open screen shader menu carousel": "Open screen shader carousel",
        "screen shader controls": "Screen shader controls",
        "apply sepia shader": "Apply Sepia filter",
        "apply black and white shader": "Apply Black & White filter",
        "apply noir shader": "Apply Noir filter",
        "apply vintage shader": "Apply Vintage filter",
        "apply vivid shader": "Apply Vivid filter",
        "disable screen shader": "Disable screen filters",
        "move window with mouse drag": "Move floating window",
        "resize window with mouse right-click drag": "Resize floating window",
        "next workspace": "Next workspace",
        "previous workspace": "Previous workspace"
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

            if (line.match(/^bind[a-z]*\s*(=|\s)/)) {
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
                                    key: "SUPER + Mouse Wheel",
                                    desc: "Navigate between workspaces",
                                    category: "workspaces"
                                })
                            }
                        } else if (!seenWorkspaceNav) {
                            seenWorkspaceNav = true
                            result.push({
                                key: "SUPER + 1..9, 0",
                                desc: "Switch to workspace (1 to 10)",
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
                                desc: "Move window to workspace (1 to 10)",
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
                                key: "SUPER + Arrow Keys",
                                desc: "Switch focus between windows",
                                category: "windows"
                            })
                        }
                        lastComment = ""
                        continue
                    }

                    if (dispatcher === "movewindow") {
                        if (isMouse) {
                            result.push({
                                key: "SUPER + Left Click",
                                desc: "Move floating window (drag)",
                                category: "windows"
                            })
                        } else if (!seenWindowMove) {
                            seenWindowMove = true
                            result.push({
                                key: "SUPER + SHIFT + Arrow Keys",
                                desc: "Move window position",
                                category: "windows"
                            })
                        }
                        lastComment = ""
                        continue
                    }

                    if (dispatcher === "resizewindow") {
                        result.push({
                            key: "SUPER + Right Click",
                            desc: "Resize floating window (drag)",
                            category: "windows"
                        })
                        lastComment = ""
                        continue
                    }

                    if (dispatcher === "resizeactive") {
                        if (!seenResize) {
                            seenResize = true
                            result.push({
                                key: "SUPER + ALT + Arrow Keys",
                                desc: "Resize active window",
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
                        if (cleanKey === "space") cleanKey = "Space"
                        else if (cleanKey === "Return") cleanKey = "Enter"
                        else if (cleanKey === "Print") cleanKey = "Print"
                        else if (cleanKey === "Delete") cleanKey = "Delete"
                        else if (cleanKey === "mouse_down") cleanKey = "Wheel Down"
                        else if (cleanKey === "mouse_up") cleanKey = "Wheel Up"
                        else if (cleanKey === "XF86AudioRaiseVolume") cleanKey = "Volume +"
                        else if (cleanKey === "XF86AudioLowerVolume") cleanKey = "Volume -"
                        else if (cleanKey === "XF86AudioMute") cleanKey = "Mute"
                        else if (cleanKey === "XF86AudioMicMute") cleanKey = "Mic Mute"
                        else if (cleanKey === "XF86MonBrightnessUp") cleanKey = "Brightness +"
                        else if (cleanKey === "XF86MonBrightnessDown") cleanKey = "Brightness -"
                        displayKeys.push(cleanKey)
                    }

                    var rawDesc = lastComment !== "" ? lastComment : (dispatcher + (args !== "" ? " " + args : ""))
                    var trans = translations[rawDesc.toLowerCase()]
                    var desc = trans !== undefined ? trans : rawDesc

                    var cat = "system"
                    var lowerDesc = desc.toLowerCase()

                    if (lowerDesc.indexOf("terminal") !== -1 || lowerDesc.indexOf("file manager") !== -1 || lowerDesc.indexOf("archivos") !== -1 ||
                        lowerDesc.indexOf("launcher") !== -1 || lowerDesc.indexOf("lanzador") !== -1 ||
                        (lowerDesc.indexOf("display") !== -1 || lowerDesc.indexOf("monitor") !== -1 || lowerDesc.indexOf("pantalla") !== -1) ||
                        lowerDesc.indexOf("music") !== -1 || lowerDesc.indexOf("música") !== -1 ||
                        lowerDesc.indexOf("wallpaper") !== -1 || lowerDesc.indexOf("fondo") !== -1 ||
                        lowerDesc.indexOf("clipboard") !== -1 || lowerDesc.indexOf("portapapeles") !== -1 ||
                        lowerDesc.indexOf("root") !== -1 || lowerDesc.indexOf("sudo") !== -1) {
                        cat = "apps"
                    } else if (lowerDesc.indexOf("window") !== -1 || lowerDesc.indexOf("ventana") !== -1 || dispatcher === "killactive" ||
                               dispatcher === "togglefloating" || dispatcher === "fullscreen") {
                        cat = "windows"
                    } else if (lowerDesc.indexOf("workspace") !== -1 || lowerDesc.indexOf("espacio") !== -1 ||
                               lowerDesc.indexOf("overview") !== -1 || dispatcher === "workspace") {
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
                                text: "Keyboard Shortcuts"
                                font.family: Root.Theme.fontFamily
                                font.pixelSize: 22
                                font.weight: Font.Bold
                                color: Root.Theme.textPrimary
                            }

                            Text {
                                text: "Hyprland • Visual guide and quick reference"
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
                                        text: "Search shortcuts..."
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
                                text: "No shortcuts found"
                                font.family: Root.Theme.fontFamily
                                font.pixelSize: Root.Theme.fontSizeNormal
                                font.weight: Font.Medium
                                color: Root.Theme.textPrimary
                            }

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: "Try another keyword or select another category"
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
                            text: shortcuts.filteredBinds.length + (shortcuts.filteredBinds.length === 1 ? " shortcut available" : " shortcuts available")
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
                                text: "F1 or Esc to close"
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
