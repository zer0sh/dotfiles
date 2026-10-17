import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../.." as Root

Scope {
    id: launcher

    property bool panelVisible: false
    property bool _showing: false
    property string searchText: ""
    property int selectedIndex: 0
    property var backgroundRef: null

    // ── Icon Cache ───────────────────────────────────────────────
    property var iconCache: ({})

    Process {
        id: iconResolveProc
        command: ["/bin/sh", "-c", "~/.config/quickshell/scripts/resolve-icons.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                var cache = {};
                var lines = text.trim().split("\n");
                for (var i = 0; i < lines.length; i++) {
                    var parts = lines[i].split("\t");
                    if (parts.length === 2 && parts[1] !== "") {
                        cache[parts[0]] = parts[1];
                    }
                }
                launcher.iconCache = cache;
            }
        }
    }

    function resolveIcon(iconName) {
        if (!iconName) return "";
        if (iconName.startsWith("/")) return "file://" + iconName;
        var p = iconCache[iconName];
        if (p) return "file://" + p;
        try {
            var qp = Quickshell.iconPath(iconName, "");
            if (qp) return qp;
        } catch (e) {}
        return "";
    }

    // ── Wallpapers Model & State ─────────────────────────────────
    property string wallpaperDir: "/home/zero/Pictures/walls/"
    property string cacheDir: "/home/zero/.cache/wallpapers/"
    property string currentWallpaper: ""
    property var wallpapers: []

    Process {
        id: readCurrentWallProc
        command: ["/bin/sh", "-c", "cat ~/.config/themes/current/wallpaper 2>/dev/null || echo '/home/zero/Pictures/walls/wa1.png'"]
        stdout: StdioCollector {
            onStreamFinished: {
                var w = text.trim();
                if (w !== "") launcher.currentWallpaper = w;
            }
        }
    }

    Process {
        id: listWallsProc
        command: ["find", "/home/zero/Pictures/walls", "-maxdepth", "1", "-type", "f",
            "(", "-iname", "*.jpg", "-o", "-iname", "*.jpeg", "-o", "-iname", "*.png",
            "-o", "-iname", "*.gif", "-o", "-iname", "*.bmp", "-o", "-iname", "*.webp", ")"]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.trim().split("\n");
                var items = [];
                for (var i = 0; i < lines.length; i++) {
                    var file = lines[i].trim();
                    if (file !== "") {
                        var base = file.split("/").pop();
                        items.push({
                            path: file,
                            title: base,
                            thumb: launcher.cacheDir + base + ".jpg"
                        });
                    }
                }
                // Ordenar alfabéticamente
                items.sort(function(a, b) {
                    return a.title.localeCompare(b.title);
                });
                launcher.wallpapers = items;
            }
        }
    }

    Process {
        id: browseWallProc
        command: ["/home/zero/.config/quickshell/scripts/browse-wallpaper.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                var newPath = text.trim();
                if (newPath !== "") {
                    applyWallpaper(newPath);
                    refreshWallpapers();
                }
            }
        }
    }

    function refreshWallpapers() {
        readCurrentWallProc.running = true;
        listWallsProc.running = true;
    }

    function applyWallpaper(path) {
        if (!path || path === "") return;
        if (launcher.backgroundRef && launcher.backgroundRef.changeWallpaper) {
            launcher.backgroundRef.changeWallpaper(path);
        } else {
            wallSetIpcProc.command = ["quickshell", "ipc", "call", "wallpaper", "set", path];
            wallSetIpcProc.running = true;
        }
        launcher.currentWallpaper = path;
        launcher.panelVisible = false;
    }

    Process { id: wallSetIpcProc }
    Process { id: actionExecProc }

    // ── Lista de Aplicaciones Desktop ────────────────────────────
    property var allApps: []

    Process {
        id: appsReadProc
        command: ["/home/zero/.config/quickshell/scripts/list-apps.py"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    launcher.allApps = JSON.parse(text);
                } catch (e) {
                    launcher.allApps = [];
                }
            }
        }
    }

    function launchApp(app) {
        if (!app || !app.exec) return;
        var cmd = app.exec.replace(/%[a-zA-Z]/g, "").trim();
        actionExecProc.command = ["/bin/sh", "-c", cmd + " >/dev/null 2>&1 &"];
        actionExecProc.running = true;
        launcher.panelVisible = false;
    }

    function activateCurrentSelection() {
        if (!launcher.panelVisible) return;

        if (launcher.currentMode === "wallpaper") {
            if (launcher.selectedIndex === launcher.filteredWallpapers.length) {
                launcher.panelVisible = false;
                browseWallProc.running = true;
            } else if (launcher.selectedIndex >= 0 && launcher.selectedIndex < launcher.filteredWallpapers.length) {
                var selectedWall = launcher.filteredWallpapers[launcher.selectedIndex];
                if (selectedWall && selectedWall.path) {
                    launcher.applyWallpaper(selectedWall.path);
                }
            }
        } else if (launcher.currentMode === "actions") {
            if (launcher.selectedIndex >= 0 && launcher.selectedIndex < launcher.filteredActions.length) {
                launcher.executeAction(launcher.filteredActions[launcher.selectedIndex]);
            }
        } else if (launcher.currentMode === "apps") {
            if (launcher.selectedIndex >= 0 && launcher.selectedIndex < launcher.filteredApps.length) {
                launcher.launchApp(launcher.filteredApps[launcher.selectedIndex]);
            }
        }
    }

    property var filteredApps: {
        if (currentMode !== "apps") return [];
        if (searchText === "") return allApps;
        var query = searchText.toLowerCase();
        return allApps.filter(function(app) {
            if (app.name.toLowerCase().indexOf(query) >= 0) return true;
            if (app.comment && app.comment.toLowerCase().indexOf(query) >= 0) return true;
            return false;
        });
    }

    // ── Lista de Comandos / Acciones ─────────────────────────────
    readonly property var allActions: [
        { id: "wallpaper", name: "Wallpaper Carousel", desc: "Explorar y cambiar fondo de pantalla con animación", icon: "󰸉" },
        { id: "theme", name: "Cambiar Tema", desc: "Alternar paleta de color (Matugen / Cobalt / Amethyst / Cyberpunk)", icon: "󰏤" },
        { id: "light", name: "Modo Claro", desc: "Cambiar esquema Matugen a modo claro", icon: "󰚝" },
        { id: "dark", name: "Modo Oscuro", desc: "Cambiar esquema Matugen a modo oscuro", icon: "󰖔" },
        { id: "lock", name: "Bloquear Pantalla", desc: "Bloquear la sesión con Hyprlock", icon: "󰌾" },
        { id: "sleep", name: "Suspender", desc: "Suspender el sistema a RAM", icon: "󰒲" },
        { id: "reboot", name: "Reiniciar Sistema", desc: "Reiniciar el equipo", icon: "󰜉" },
        { id: "shutdown", name: "Apagar Equipo", desc: "Apagar el sistema", icon: "󰐥" }
    ]

    property var filteredActions: {
        if (currentMode !== "actions") return [];
        var query = searchText.slice(1).trim().toLowerCase();
        if (query === "") return allActions;
        return allActions.filter(function(a) {
            return a.name.toLowerCase().indexOf(query) >= 0 ||
                   a.desc.toLowerCase().indexOf(query) >= 0 ||
                   a.id.toLowerCase().indexOf(query) >= 0;
        });
    }

    // ── Modo Activo ──────────────────────────────────────────────
    readonly property string currentMode: {
        if (searchText.startsWith(">wallpaper") || searchText.startsWith(">fondo") || searchText.startsWith(">wall")) {
            return "wallpaper";
        } else if (searchText.startsWith(">")) {
            return "actions";
        } else {
            return "apps";
        }
    }

    // ── Filtrado de Wallpapers en Modo Carrusel ──────────────────
    property var filteredWallpapers: {
        if (currentMode !== "wallpaper") return [];
        var prefix = searchText.startsWith(">wallpaper") ? ">wallpaper" : ">fondo";
        var query = searchText.slice(prefix.length).trim().toLowerCase();
        if (query === "") return wallpapers;
        return wallpapers.filter(function(w) {
            return w.title.toLowerCase().indexOf(query) >= 0;
        });
    }

    function executeAction(act) {
        if (!act) return;
        if (act.id === "wallpaper") {
            searchText = ">wallpaper ";
            selectedIndex = 0;
            return;
        }

        launcher.panelVisible = false;

        if (act.id === "theme") {
            var themes = ["matugen", "md3-cobalt-night", "md3-amethyst", "md3-arctic-mist", "cyberpunk"];
            var currentIdx = themes.indexOf(Root.Theme.currentTheme);
            var nextTheme = themes[(currentIdx + 1) % themes.length];
            Root.Theme.currentTheme = nextTheme;
            actionExecProc.command = ["/bin/sh", "-c", "printf '%s\\n' '" + nextTheme + "' > ~/.config/quickshell/current-theme"];
            actionExecProc.running = true;
        } else if (act.id === "light") {
            actionExecProc.command = ["/bin/sh", "-c", "matugen image \"$(cat ~/.config/themes/current/wallpaper)\" --mode light --quiet && hyprctl reload"];
            actionExecProc.running = true;
        } else if (act.id === "dark") {
            actionExecProc.command = ["/bin/sh", "-c", "matugen image \"$(cat ~/.config/themes/current/wallpaper)\" --mode dark --quiet && hyprctl reload"];
            actionExecProc.running = true;
        } else if (act.id === "lock") {
            actionExecProc.command = ["hyprlock"];
            actionExecProc.running = true;
        } else if (act.id === "sleep") {
            actionExecProc.command = ["systemctl", "suspend"];
            actionExecProc.running = true;
        } else if (act.id === "reboot") {
            actionExecProc.command = ["reboot"];
            actionExecProc.running = true;
        } else if (act.id === "shutdown") {
            actionExecProc.command = ["poweroff"];
            actionExecProc.running = true;
        }
    }

    function openWallpapers() {
        searchText = ">wallpaper ";
        panelVisible = true;
        var curIdx = 0;
        for (var i = 0; i < wallpapers.length; i++) {
            if (wallpapers[i].path === currentWallpaper) {
                curIdx = i;
                break;
            }
        }
        selectedIndex = curIdx;
        refreshWallpapers();
    }

    onPanelVisibleChanged: {
        if (panelVisible) {
            _showing = true;
            if (currentMode !== "wallpaper") {
                selectedIndex = 0;
            }
            if (allApps.length === 0) appsReadProc.running = true;
            refreshWallpapers();
        } else {
            searchText = "";
        }
    }

    Component.onCompleted: {
        iconResolveProc.running = true;
        appsReadProc.running = true;
        refreshWallpapers();
    }

    // ── IPC Handlers ─────────────────────────────────────────────
    IpcHandler {
        target: "launcher"
        function toggle(): void {
            launcher.panelVisible = !launcher.panelVisible;
            if (launcher.panelVisible) launcher.searchText = "";
        }
        function wallpaper(): void {
            launcher.openWallpapers();
        }
        function search(query: string): void {
            launcher.panelVisible = true;
            launcher.searchText = query;
        }
        function show(): void {
            launcher.panelVisible = true;
            launcher.searchText = "";
        }
        function hide(): void {
            launcher.panelVisible = false;
        }
        function next(): void {
            if (launcher.currentMode === "wallpaper") {
                if (launcher.selectedIndex < launcher.filteredWallpapers.length) launcher.selectedIndex++;
            } else if (launcher.currentMode === "actions") {
                if (launcher.selectedIndex < launcher.filteredActions.length - 1) launcher.selectedIndex++;
                else launcher.selectedIndex = 0;
            } else if (launcher.currentMode === "apps") {
                if (launcher.selectedIndex < launcher.filteredApps.length - 1) launcher.selectedIndex++;
                else launcher.selectedIndex = 0;
            }
        }
        function prev(): void {
            if (launcher.selectedIndex > 0) launcher.selectedIndex--;
        }
        function activate(): void {
            launcher.activateCurrentSelection();
        }
    }

    // Compatibilidad adicional con atajo SUPER + W
    IpcHandler {
        target: "wallpaperpicker"
        function toggle(): void { launcher.openWallpapers(); }
        function show(): void { launcher.openWallpapers(); }
        function hide(): void { launcher.panelVisible = false; }
    }

    // ── Ventana Flotante Caelestia ───────────────────────────────
    Loader {
        active: launcher.panelVisible

        sourceComponent: PanelWindow {
            id: panelWindow
            visible: true

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            color: "transparent"
            exclusionMode: ExclusionMode.Ignore

            WlrLayershell.namespace: "quickshell:launcher"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            // Fondo semitransparente oscuro con clic exterior para cerrar
            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(0, 0, 0, 0.4)

                MouseArea {
                    anchors.fill: parent
                    onClicked: launcher.panelVisible = false
                }
            }

            // ── Contenedor Flotante Inferior Central ──────────────────
            Rectangle {
                id: floatingCard
                z: 10

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 28

                width: {
                    if (launcher.currentMode === "wallpaper") return Math.min(1080, parent.width - 60);
                    return 580;
                }

                height: {
                    if (launcher.currentMode === "wallpaper") return 340;
                    if (launcher.currentMode === "actions") {
                        var actCount = launcher.filteredActions.length;
                        return Math.min(460, Math.max(140, actCount * 50 + 76));
                    }
                    var appCount = launcher.filteredApps.length;
                    return Math.min(480, Math.max(140, appCount * 52 + 76));
                }

                radius: 24
                color: Qt.rgba(Root.Theme.surface.r, Root.Theme.surface.g, Root.Theme.surface.b, 0.88)
                border.width: 1
                border.color: Qt.rgba(Root.Theme.panelBorder.r, Root.Theme.panelBorder.g, Root.Theme.panelBorder.b, 0.35)
                clip: true

                focus: true
                Keys.forwardTo: [searchInput]

                Behavior on width {
                    NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                }
                Behavior on height {
                    NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                }

                // Resplandor exterior sutil
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -3
                    radius: 26
                    color: "transparent"
                    border.width: 1
                    border.color: Qt.rgba(Root.Theme.primary.r, Root.Theme.primary.g, Root.Theme.primary.b, 0.2)
                }

                // ── Área de Contenido Superior ─────────────────────────
                Item {
                    id: contentArea
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: searchContainer.top
                    anchors.margins: 16
                    anchors.bottomMargin: 6
                    clip: true

                    // --- VISTA 1: Carrusel de Wallpapers (Horizontal) ---
                    Item {
                        id: wallpaperView
                        visible: launcher.currentMode === "wallpaper"
                        anchors.fill: parent
                        clip: true

                        function scrollToCard(index, immediate) {
                            var itemWidth = 236 + 16;
                            var targetX = index * itemWidth + 118 - (wallCarousel.width / 2);
                            var maxX = Math.max(0, wallCarousel.contentWidth - wallCarousel.width);
                            targetX = Math.max(0, Math.min(maxX, targetX));
                            if (immediate) {
                                scrollAnim.stop();
                                wallCarousel.contentX = targetX;
                            } else {
                                scrollAnim.to = targetX;
                                scrollAnim.restart();
                            }
                        }

                        NumberAnimation {
                            id: scrollAnim
                            target: wallCarousel
                            property: "contentX"
                            duration: 160
                            easing.type: Easing.OutCubic
                        }

                        ListView {
                            id: wallCarousel
                            anchors.fill: parent
                            anchors.topMargin: 8
                            anchors.bottomMargin: 4
                            orientation: ListView.Horizontal
                            spacing: 16
                            clip: true

                            flickDeceleration: 1800
                            maximumFlickVelocity: 3000
                            boundsBehavior: Flickable.StopAtBounds
                            highlightRangeMode: ListView.NoHighlightRange

                            model: launcher.filteredWallpapers.length + 1
                            currentIndex: launcher.selectedIndex

                            delegate: Item {
                                width: 236
                                height: 226
                                z: (cardItem && cardItem.isHovered) ? 100 : (launcher.selectedIndex === index ? 20 : 1)

                                readonly property bool isAdd: index === launcher.filteredWallpapers.length
                                readonly property var wallData: !isAdd ? launcher.filteredWallpapers[index] : null

                                WallpaperCard {
                                    id: cardItem
                                    anchors.centerIn: parent
                                    width: 224
                                    height: 214
                                    isAddCard: isAdd
                                    wallPath: wallData ? wallData.path : ""
                                    wallTitle: wallData ? wallData.title : ""
                                    wallThumb: wallData ? wallData.thumb : ""
                                    isCurrentWall: wallData ? (wallData.path === launcher.currentWallpaper) : false
                                    isSelected: launcher.selectedIndex === index

                                    onActivated: {
                                        launcher.selectedIndex = index;
                                        if (isAdd) {
                                            browseWallProc.running = true;
                                        } else if (wallData) {
                                            launcher.applyWallpaper(wallData.path);
                                        }
                                    }
                                }
                            }

                            // Desplazamiento horizontal fluido y directo sin saltos de índice
                            WheelHandler {
                                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                                onWheel: function(event) {
                                    var delta = event.angleDelta.y !== 0 ? event.angleDelta.y : event.angleDelta.x;
                                    var step = delta * 1.8;
                                    var targetX = wallCarousel.contentX - step;
                                    var maxX = Math.max(0, wallCarousel.contentWidth - wallCarousel.width);
                                    wallCarousel.contentX = Math.max(0, Math.min(maxX, targetX));
                                }
                            }

                            Component.onCompleted: {
                                if (launcher.currentMode === "wallpaper") {
                                    wallpaperView.scrollToCard(launcher.selectedIndex, true);
                                }
                            }
                        }

                        // Degradado de desvanecimiento lateral izquierdo estilo Caelestia
                        Rectangle {
                            id: leftFade
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: 32
                            z: 50
                            enabled: false
                            visible: wallCarousel.contentX > 6
                            opacity: visible ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: Qt.rgba(Root.Theme.surface.r, Root.Theme.surface.g, Root.Theme.surface.b, 0.95) }
                                GradientStop { position: 1.0; color: "transparent" }
                            }
                        }

                        // Degradado de desvanecimiento lateral derecho estilo Caelestia
                        Rectangle {
                            id: rightFade
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: 32
                            z: 50
                            enabled: false
                            visible: wallCarousel.contentX < (wallCarousel.contentWidth - wallCarousel.width - 6)
                            opacity: visible ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: "transparent" }
                                GradientStop { position: 1.0; color: Qt.rgba(Root.Theme.surface.r, Root.Theme.surface.g, Root.Theme.surface.b, 0.95) }
                            }
                        }

                        Connections {
                            target: launcher
                            function onSelectedIndexChanged() {
                                if (launcher.currentMode === "wallpaper" && wallCarousel) {
                                    wallpaperView.scrollToCard(launcher.selectedIndex, false);
                                }
                            }
                        }

                        // Estado vacío si la búsqueda de fondos no coincide
                        Text {
                            visible: launcher.filteredWallpapers.length === 0
                            anchors.centerIn: parent
                            text: "No wallpapers match your query"
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: 13
                            color: Root.Theme.textSecondary
                        }
                    }

                    // --- VISTA 2: Lista de Acciones / Comandos (Vertical) ---
                    Item {
                        id: actionsView
                        visible: launcher.currentMode === "actions"
                        anchors.fill: parent

                        ListView {
                            id: actionsList
                            anchors.fill: parent
                            spacing: 4
                            clip: true
                            model: launcher.filteredActions
                            currentIndex: launcher.selectedIndex

                            delegate: ActionItem {
                                width: actionsList.width
                                isSelected: launcher.selectedIndex === index
                                onActivated: launcher.executeAction(modelData)
                            }
                        }

                        Connections {
                            target: launcher
                            function onSelectedIndexChanged() {
                                if (launcher.currentMode === "actions" && actionsList) {
                                    actionsList.positionViewAtIndex(launcher.selectedIndex, ListView.Contain);
                                }
                            }
                        }

                        Text {
                            visible: launcher.filteredActions.length === 0
                            anchors.centerIn: parent
                            text: "No commands found"
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: 13
                            color: Root.Theme.textSecondary
                        }
                    }

                    // --- VISTA 3: Lista de Aplicaciones (Vertical) ---
                    Item {
                        id: appsView
                        visible: launcher.currentMode === "apps"
                        anchors.fill: parent

                        ListView {
                            id: appsList
                            anchors.fill: parent
                            spacing: 4
                            clip: true
                            model: launcher.filteredApps
                            currentIndex: launcher.selectedIndex

                            delegate: AppItem {
                                width: appsList.width
                                iconPath: launcher.resolveIcon(modelData.icon)
                                isSelected: launcher.selectedIndex === index
                                onActivated: launcher.launchApp(modelData)
                            }
                        }

                        Connections {
                            target: launcher
                            function onSelectedIndexChanged() {
                                if (launcher.currentMode === "apps" && appsList) {
                                    appsList.positionViewAtIndex(launcher.selectedIndex, ListView.Contain);
                                }
                            }
                        }

                        Text {
                            visible: launcher.filteredApps.length === 0
                            anchors.centerIn: parent
                            text: "No applications found"
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: 13
                            color: Root.Theme.textSecondary
                        }
                    }
                }

                // ── Barra de Búsqueda Inferior Estilo Caelestia ────────
                Rectangle {
                    id: searchContainer

                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 12
                    height: 48

                    radius: 14
                    color: Root.Theme.surfaceContainer
                    border.width: searchInput.activeFocus ? 1.5 : 1
                    border.color: searchInput.activeFocus
                        ? Root.Theme.primary
                        : Qt.rgba(Root.Theme.panelBorder.r, Root.Theme.panelBorder.g, Root.Theme.panelBorder.b, 0.3)

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        spacing: 10

                        // Icono indicador de modo
                        Text {
                            text: {
                                if (launcher.currentMode === "wallpaper") return "󰸉";
                                if (launcher.currentMode === "actions") return "󰘳";
                                return "󰍉";
                            }
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: 18
                            color: launcher.currentMode === "apps" ? Root.Theme.textSecondary : Root.Theme.primary
                        }

                        // Campo de texto principal
                        TextInput {
                            id: searchInput
                            Layout.fillWidth: true
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: 14
                            color: Root.Theme.textPrimary
                            selectByMouse: true
                            selectionColor: Root.Theme.primary
                            selectedTextColor: Root.Theme.tileActiveText
                            text: launcher.searchText
                            focus: true

                            Keys.priority: Keys.BeforeItem

                            onTextChanged: {
                                launcher.searchText = text;
                                if (launcher.currentMode !== "wallpaper" || (text !== ">wallpaper " && text !== ">wallpaper")) {
                                    launcher.selectedIndex = 0;
                                }
                            }

                            Component.onCompleted: forceActiveFocus()

                            Connections {
                                target: launcher
                                function onPanelVisibleChanged() {
                                    if (launcher.panelVisible) {
                                        searchInput.forceActiveFocus();
                                    }
                                }
                            }

                            // Placeholder
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: {
                                    if (launcher.currentMode === "wallpaper") return "Filter wallpapers or press Enter...";
                                    if (launcher.currentMode === "actions") return "Type command name or press Enter...";
                                    return "Type \">\" for commands...";
                                }
                                font.family: Root.Theme.fontFamily
                                font.pixelSize: 14
                                color: Root.Theme.textSecondary
                                visible: searchInput.text === ""
                            }

                            // ── Atajos de Teclado y Navegación ──────────
                            Keys.onEscapePressed: function(event) {
                                launcher.panelVisible = false;
                                event.accepted = true;
                            }

                            Keys.onLeftPressed: function(event) {
                                if (launcher.currentMode === "wallpaper") {
                                    if (launcher.selectedIndex > 0) launcher.selectedIndex--;
                                    event.accepted = true;
                                } else {
                                    event.accepted = false;
                                }
                            }

                            Keys.onRightPressed: function(event) {
                                if (launcher.currentMode === "wallpaper") {
                                    if (launcher.selectedIndex < launcher.filteredWallpapers.length) {
                                        launcher.selectedIndex++;
                                    }
                                    event.accepted = true;
                                } else {
                                    event.accepted = false;
                                }
                            }

                            Keys.onUpPressed: function(event) {
                                if (launcher.currentMode === "wallpaper") {
                                    if (launcher.selectedIndex > 0) launcher.selectedIndex--;
                                } else if (launcher.currentMode === "actions") {
                                    if (launcher.selectedIndex > 0) {
                                        launcher.selectedIndex--;
                                    } else if (launcher.filteredActions.length > 0) {
                                        launcher.selectedIndex = launcher.filteredActions.length - 1;
                                    }
                                } else if (launcher.currentMode === "apps") {
                                    if (launcher.selectedIndex > 0) {
                                        launcher.selectedIndex--;
                                    } else if (launcher.filteredApps.length > 0) {
                                        launcher.selectedIndex = launcher.filteredApps.length - 1;
                                    }
                                }
                                event.accepted = true;
                            }

                            Keys.onDownPressed: function(event) {
                                if (launcher.currentMode === "wallpaper") {
                                    if (launcher.selectedIndex < launcher.filteredWallpapers.length) {
                                        launcher.selectedIndex++;
                                    }
                                } else if (launcher.currentMode === "actions") {
                                    if (launcher.selectedIndex < launcher.filteredActions.length - 1) {
                                        launcher.selectedIndex++;
                                    } else {
                                        launcher.selectedIndex = 0;
                                    }
                                } else if (launcher.currentMode === "apps") {
                                    if (launcher.selectedIndex < launcher.filteredApps.length - 1) {
                                        launcher.selectedIndex++;
                                    } else {
                                        launcher.selectedIndex = 0;
                                    }
                                }
                                event.accepted = true;
                            }

                            Keys.onTabPressed: function(event) {
                                if (launcher.currentMode === "actions") {
                                    if (launcher.selectedIndex < launcher.filteredActions.length - 1) {
                                        launcher.selectedIndex++;
                                    } else {
                                        launcher.selectedIndex = 0;
                                    }
                                } else if (launcher.currentMode === "apps") {
                                    if (launcher.selectedIndex < launcher.filteredApps.length - 1) {
                                        launcher.selectedIndex++;
                                    } else {
                                        launcher.selectedIndex = 0;
                                    }
                                } else if (launcher.currentMode === "wallpaper") {
                                    if (launcher.selectedIndex < launcher.filteredWallpapers.length) {
                                        launcher.selectedIndex++;
                                    } else {
                                        launcher.selectedIndex = 0;
                                    }
                                }
                                event.accepted = true;
                            }

                            Keys.onBacktabPressed: function(event) {
                                if (launcher.currentMode === "actions") {
                                    if (launcher.selectedIndex > 0) {
                                        launcher.selectedIndex--;
                                    } else if (launcher.filteredActions.length > 0) {
                                        launcher.selectedIndex = launcher.filteredActions.length - 1;
                                    }
                                } else if (launcher.currentMode === "apps") {
                                    if (launcher.selectedIndex > 0) {
                                        launcher.selectedIndex--;
                                    } else if (launcher.filteredApps.length > 0) {
                                        launcher.selectedIndex = launcher.filteredApps.length - 1;
                                    }
                                } else if (launcher.currentMode === "wallpaper") {
                                    if (launcher.selectedIndex > 0) {
                                        launcher.selectedIndex--;
                                    } else {
                                        launcher.selectedIndex = launcher.filteredWallpapers.length;
                                    }
                                }
                                event.accepted = true;
                            }

                            Keys.onReturnPressed: function(event) {
                                launcher.activateCurrentSelection();
                                event.accepted = true;
                            }

                            Keys.onEnterPressed: function(event) {
                                launcher.activateCurrentSelection();
                                event.accepted = true;
                            }

                            onAccepted: {
                                launcher.activateCurrentSelection();
                            }
                        }

                        // Botón de limpiar o badge de modo
                        Rectangle {
                            visible: searchInput.text !== ""
                            width: 22
                            height: 22
                            radius: 11
                            color: Root.Theme.surfaceContainerHigh

                            Text {
                                anchors.centerIn: parent
                                text: "󰅖"
                                font.family: Root.Theme.fontFamily
                                font.pixelSize: 12
                                color: Root.Theme.textSecondary
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    searchInput.text = "";
                                    launcher.searchText = "";
                                    launcher.selectedIndex = 0;
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
