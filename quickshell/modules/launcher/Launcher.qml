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

    // ── Themes Model & State ─────────────────────────────────────
    readonly property var themesList: [
        { id: "matugen", name: "Wallpaper (Matugen)", desc: "Dynamic Material You generated from active wallpaper" },
        { id: "md3-cobalt-night", name: "Cobalt Night", desc: "Deep cobalt blue and midnight sapphire" },
        { id: "md3-amethyst", name: "Amethyst", desc: "Deep amethyst purple and lavender" },
        { id: "md3-arctic-mist", name: "Arctic Mist", desc: "Polar cyan and frosted ice blue" },
        { id: "cyberpunk", name: "Cyberpunk", desc: "Neon turquoise, magenta and electric violet" }
    ]

    function applyTheme(themeId) {
        if (!themeId || themeId === "") return;
        Root.Theme.currentTheme = themeId;
        actionExecProc.command = ["/bin/sh", "-c", "printf '%s\\n' '" + themeId + "' > ~/.config/quickshell/current-theme"];
        actionExecProc.running = true;
        launcher.panelVisible = false;
    }

    function openThemes() {
        searchText = "/theme ";
        panelVisible = true;
        var curIdx = 0;
        for (var i = 0; i < themesList.length; i++) {
            if (themesList[i].id === Root.Theme.currentTheme) {
                curIdx = i;
                break;
            }
        }
        selectedIndex = curIdx;
    }

    // ── Shaders Model & State ────────────────────────────────────
    property string currentShader: "Off"
    readonly property string shaderThumbDir: "/home/zero/.config/quickshell/assets/shaders/"

    readonly property var shadersList: [
        { id: "off", name: "Shader Off", filterName: "disabled", desc: "No active screen filter", thumb: shaderThumbDir + "off.png" },
        { id: "trinitron", name: "Sony Trinitron", filterName: "Sony Trinitron", desc: "Vertical aperture grille and damping wires", thumb: shaderThumbDir + "trinitron.png" },
        { id: "crt-soft", name: "CRT Soft", filterName: "CRT Soft", desc: "Fine scanlines and subtle chromatic aberration", thumb: shaderThumbDir + "crt-soft.png" },
        { id: "crt", name: "CRT Retro", filterName: "CRT Retro", desc: "Tube curvature, scanlines and phosphor glow", thumb: shaderThumbDir + "crt.png" },
        { id: "sepia", name: "Sepia Vintage", filterName: "Sepia Vintage", desc: "Warm 1930s vintage tone", thumb: shaderThumbDir + "sepia.png" },
        { id: "bw", name: "Black and White", filterName: "Black and White", desc: "Monochrome high-contrast grayscale", thumb: shaderThumbDir + "bw.png" },
        { id: "noir", name: "Film Noir", filterName: "Film Noir", desc: "Deep contrast with pronounced vignette", thumb: shaderThumbDir + "noir.png" },
        { id: "vintage", name: "Vintage", filterName: "Vintage", desc: "Aged tone with photographic film grain", thumb: shaderThumbDir + "vintage.png" },
        { id: "vivid", name: "Vivid", filterName: "Vivid", desc: "Enhanced color saturation and vibrance", thumb: shaderThumbDir + "vivid.png" }
    ]

    Process {
        id: shaderCurrentProc
        command: ["/home/zero/.config/hypr/scripts/filter", "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                var res = text.trim();
                if (res.indexOf("Active filter:") === 0) {
                    launcher.currentShader = res.substring("Active filter:".length).trim();
                } else if (res.indexOf("Filtro activo:") === 0) {
                    launcher.currentShader = res.substring("Filtro activo:".length).trim();
                } else {
                    launcher.currentShader = "Off";
                }
            }
        }
    }

    Process { id: shaderApplyProc }

    function isShaderActive(item) {
        if (!item) return false;
        if (item.filterName === launcher.currentShader || item.name === launcher.currentShader) return true;
        if (item.id === "off" && (launcher.currentShader === "Off" || launcher.currentShader === "disabled" || launcher.currentShader === "desactivado" || launcher.currentShader === "")) return true;
        if (item.id === "bw" && (launcher.currentShader === "Blanco y Negro" || launcher.currentShader === "Black and White")) return true;
        if (item.id === "crt-soft" && (launcher.currentShader === "CRT Suave" || launcher.currentShader === "CRT Soft")) return true;
        if (item.id === "vivid" && (launcher.currentShader === "Vívido" || launcher.currentShader === "Vivid")) return true;
        return false;
    }

    function applyShader(shaderId, filterName) {
        if (!shaderId) return;
        shaderApplyProc.command = ["/home/zero/.config/hypr/scripts/filter", shaderId];
        shaderApplyProc.running = true;
        launcher.currentShader = filterName || shaderId;
        launcher.panelVisible = false;
    }

    function openShaders() {
        shaderCurrentProc.running = true;
        searchText = "/shader ";
        panelVisible = true;
        var curIdx = 0;
        for (var i = 0; i < shadersList.length; i++) {
            if (isShaderActive(shadersList[i])) {
                curIdx = i;
                break;
            }
        }
        selectedIndex = curIdx;
    }

    function toggleShaders() {
        if (launcher.panelVisible && launcher.currentMode === "shader") {
            launcher.panelVisible = false;
        } else {
            launcher.openShaders();
        }
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
        } else if (launcher.currentMode === "shader") {
            if (launcher.selectedIndex >= 0 && launcher.selectedIndex < launcher.filteredShaders.length) {
                var selectedShader = launcher.filteredShaders[launcher.selectedIndex];
                if (selectedShader && selectedShader.id) {
                    launcher.applyShader(selectedShader.id, selectedShader.filterName);
                }
            }
        } else if (launcher.currentMode === "theme") {
            if (launcher.selectedIndex >= 0 && launcher.selectedIndex < launcher.filteredThemes.length) {
                var selectedTheme = launcher.filteredThemes[launcher.selectedIndex];
                if (selectedTheme && selectedTheme.id) {
                    launcher.applyTheme(selectedTheme.id);
                }
            }
        } else if (launcher.currentMode === "gadgets") {
            if (launcher.selectedIndex >= 0 && launcher.selectedIndex < launcher.filteredGadgets.length) {
                var selectedGadget = launcher.filteredGadgets[launcher.selectedIndex];
                if (selectedGadget && selectedGadget.id) {
                    Root.GadgetsManager.toggle(selectedGadget.id);
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

    // ── Commands & Actions List ──────────────────────────────────
    readonly property var allActions: [
        { id: "wallpaper", name: "Wallpaper Carousel", desc: "Browse and switch wallpapers with animated transitions", icon: "󰸉", aliases: ["wall", "fondo", "wallpaper"] },
        { id: "shader", name: "Shader Carousel", desc: "Browse and apply screen shaders and CRT effects", icon: "󱡄", aliases: ["shader", "shaders", "filtro", "crt", "trinitron"] },
        { id: "theme", name: "Theme Carousel", desc: "Explore and apply Material You visual palettes", icon: "󰏘", aliases: ["tema", "palette", "color"] },
        { id: "gadgets", name: "Desktop Gadgets", desc: "Toggle and manage desktop widgets", icon: "󱂬", aliases: ["widgets", "widget", "gadget", "clock", "calendar"] },
        { id: "lock", name: "Lock Screen", desc: "Lock desktop session with Hyprlock", icon: "󰌾", aliases: ["bloquear", "hyprlock"] },
        { id: "sleep", name: "Suspend", desc: "Suspend system to RAM", icon: "󰒲", aliases: ["suspender", "standby"] },
        { id: "reboot", name: "Restart System", desc: "Reboot computer", icon: "󰜉", aliases: ["reiniciar", "restart"] },
        { id: "shutdown", name: "Shut Down", desc: "Power off system", icon: "󰐥", aliases: ["apagar", "poweroff"] }
    ]

    property var filteredActions: {
        if (currentMode !== "actions") return [];
        var query = searchText.slice(1).trim().toLowerCase();
        if (query === "") return allActions;
        return allActions.filter(function(a) {
            var aliasMatch = a.aliases ? a.aliases.some(function(al) { return al.toLowerCase().indexOf(query) >= 0; }) : false;
            return a.name.toLowerCase().indexOf(query) >= 0 ||
                   a.desc.toLowerCase().indexOf(query) >= 0 ||
                   a.id.toLowerCase().indexOf(query) >= 0 ||
                   aliasMatch;
        });
    }

    // ── Modo Activo ──────────────────────────────────────────────
    readonly property string currentMode: {
        if (searchText.startsWith("/wallpaper") || searchText.startsWith("/fondo") || searchText.startsWith("/wall") ||
            searchText.startsWith(">wallpaper") || searchText.startsWith(">fondo") || searchText.startsWith(">wall")) {
            return "wallpaper";
        } else if (searchText.startsWith("/shader") || searchText.startsWith("/filter") ||
                   searchText.startsWith(">shader") || searchText.startsWith(">filter")) {
            return "shader";
        } else if (searchText.startsWith("/theme") || searchText.startsWith("/tema") ||
                   searchText.startsWith(">theme") || searchText.startsWith(">tema")) {
            return "theme";
        } else if (searchText.startsWith("/gadgets") || searchText.startsWith("/widgets") ||
                   searchText.startsWith("/gadget")  || searchText.startsWith("/widget") ||
                   searchText.startsWith(">gadgets") || searchText.startsWith(">widgets")) {
            return "gadgets";
        } else if (searchText.startsWith("/") || searchText.startsWith(">")) {
            return "actions";
        } else {
            return "apps";
        }
    }

    // ── Filtrado de Wallpapers en Modo Carrusel ──────────────────
    property var filteredWallpapers: {
        if (currentMode !== "wallpaper") return [];
        var prefixes = ["/wallpaper", "/fondo", "/wall", ">wallpaper", ">fondo", ">wall"];
        var prefix = "";
        for (var i = 0; i < prefixes.length; i++) {
            if (searchText.startsWith(prefixes[i])) {
                prefix = prefixes[i];
                break;
            }
        }
        var query = searchText.slice(prefix.length).trim().toLowerCase();
        if (query === "") return wallpapers;
        return wallpapers.filter(function(w) {
            return w.title.toLowerCase().indexOf(query) >= 0;
        });
    }

    // ── Filtrado de Shaders en Modo Carrusel ────────────────────
    property var filteredShaders: {
        if (currentMode !== "shader") return [];
        var prefixes = ["/shader", "/filter", ">shader", ">filter"];
        var prefix = "";
        for (var i = 0; i < prefixes.length; i++) {
            if (searchText.startsWith(prefixes[i])) {
                prefix = prefixes[i];
                break;
            }
        }
        var query = searchText.slice(prefix.length).trim().toLowerCase();
        if (query === "") return shadersList;
        return shadersList.filter(function(s) {
            return s.name.toLowerCase().indexOf(query) >= 0 ||
                   s.id.toLowerCase().indexOf(query) >= 0 ||
                   (s.desc && s.desc.toLowerCase().indexOf(query) >= 0);
        });
    }

    // ── Filtrado de Temas en Modo Carrusel ──────────────────────
    property var filteredThemes: {
        if (currentMode !== "theme") return [];
        var prefixes = ["/theme", "/tema", ">theme", ">tema"];
        var prefix = "";
        for (var i = 0; i < prefixes.length; i++) {
            if (searchText.startsWith(prefixes[i])) {
                prefix = prefixes[i];
                break;
            }
        }
        var query = searchText.slice(prefix.length).trim().toLowerCase();
        if (query === "") return themesList;
        return themesList.filter(function(t) {
            return t.name.toLowerCase().indexOf(query) >= 0 ||
                   t.id.toLowerCase().indexOf(query) >= 0 ||
                   (t.desc && t.desc.toLowerCase().indexOf(query) >= 0);
        });
    }

    // ── Filtrado de Gadgets en Modo Carrusel ─────────────────────
    property var filteredGadgets: {
        if (currentMode !== "gadgets") return [];
        var prefixes = ["/gadgets", "/widgets", "/gadget", "/widget", ">gadgets", ">widgets"];
        var prefix = "";
        for (var i = 0; i < prefixes.length; i++) {
            if (searchText.startsWith(prefixes[i])) {
                prefix = prefixes[i];
                break;
            }
        }
        var query = searchText.slice(prefix.length).trim().toLowerCase();
        var all = Root.GadgetsManager.availableGadgets;
        if (query === "") return all;
        return all.filter(function(g) {
            return g.name.toLowerCase().indexOf(query) >= 0 ||
                   g.id.toLowerCase().indexOf(query) >= 0 ||
                   (g.desc && g.desc.toLowerCase().indexOf(query) >= 0);
        });
    }

    function executeAction(act) {
        if (!act) return;
        if (act.id === "wallpaper") {
            searchText = "/wallpaper ";
            selectedIndex = 0;
            return;
        }
        if (act.id === "shader") {
            launcher.openShaders();
            return;
        }
        if (act.id === "theme") {
            searchText = "/theme ";
            selectedIndex = 0;
            return;
        }
        if (act.id === "gadgets") {
            searchText = "/gadgets ";
            selectedIndex = 0;
            return;
        }

        launcher.panelVisible = false;

        if (act.id === "lock") {
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
        searchText = "/wallpaper ";
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

    function openGadgets() {
        searchText = "/gadgets ";
        panelVisible = true;
        selectedIndex = 0;
    }

    onPanelVisibleChanged: {
        if (panelVisible) {
            _showing = true;
            if (currentMode !== "wallpaper" && currentMode !== "theme" && currentMode !== "gadgets" && currentMode !== "shader") {
                selectedIndex = 0;
            }
            if (allApps.length === 0) appsReadProc.running = true;
            refreshWallpapers();
            shaderCurrentProc.running = true;
        } else {
            searchText = "";
        }
    }

    Component.onCompleted: {
        iconResolveProc.running = true;
        appsReadProc.running = true;
        refreshWallpapers();
        shaderCurrentProc.running = true;
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
        function shader(): void {
            launcher.openShaders();
        }
        function theme(): void {
            launcher.openThemes();
        }
        function gadgets(): void {
            launcher.openGadgets();
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
            } else if (launcher.currentMode === "shader") {
                if (launcher.selectedIndex < launcher.filteredShaders.length - 1) launcher.selectedIndex++;
                else launcher.selectedIndex = 0;
            } else if (launcher.currentMode === "theme") {
                if (launcher.selectedIndex < launcher.filteredThemes.length - 1) launcher.selectedIndex++;
                else launcher.selectedIndex = 0;
            } else if (launcher.currentMode === "gadgets") {
                if (launcher.selectedIndex < launcher.filteredGadgets.length - 1) launcher.selectedIndex++;
                else launcher.selectedIndex = 0;
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
            else if (launcher.currentMode === "shader" && launcher.filteredShaders.length > 0) {
                launcher.selectedIndex = launcher.filteredShaders.length - 1;
            } else if (launcher.currentMode === "theme" && launcher.filteredThemes.length > 0) {
                launcher.selectedIndex = launcher.filteredThemes.length - 1;
            } else if (launcher.currentMode === "gadgets" && launcher.filteredGadgets.length > 0) {
                launcher.selectedIndex = launcher.filteredGadgets.length - 1;
            }
        }
        function activate(): void {
            launcher.activateCurrentSelection();
        }
    }

    IpcHandler {
        target: "shaderpicker"
        function toggle(): void { launcher.toggleShaders(); }
        function show(): void { launcher.openShaders(); }
        function hide(): void { launcher.panelVisible = false; }
    }

    IpcHandler {
        target: "gadgetpicker"
        function toggle(): void { launcher.openGadgets(); }
        function show(): void { launcher.openGadgets(); }
        function hide(): void { launcher.panelVisible = false; }
    }

    // Compatibilidad adicional con atajo SUPER + W
    IpcHandler {
        target: "wallpaperpicker"
        function toggle(): void { launcher.openWallpapers(); }
        function show(): void { launcher.openWallpapers(); }
        function hide(): void { launcher.panelVisible = false; }
    }

    IpcHandler {
        target: "themepicker"
        function toggle(): void { launcher.openThemes(); }
        function show(): void { launcher.openThemes(); }
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
                    if (launcher.currentMode === "wallpaper" || launcher.currentMode === "shader" || launcher.currentMode === "theme" || launcher.currentMode === "gadgets") return Math.min(1080, parent.width - 60);
                    return 580;
                }

                height: {
                    if (launcher.currentMode === "wallpaper" || launcher.currentMode === "shader" || launcher.currentMode === "theme" || launcher.currentMode === "gadgets") return 340;
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
                            font.pixelSize: 15
                            color: Root.Theme.textSecondary
                        }
                    }

                    // --- VISTA 2: Carrusel de Temas (Horizontal) ---
                    Item {
                        id: themeView
                        visible: launcher.currentMode === "theme"
                        anchors.fill: parent
                        clip: true

                        function scrollToCard(index, immediate) {
                            var itemWidth = 236 + 16;
                            var targetX = index * itemWidth + 118 - (themeCarousel.width / 2);
                            var maxX = Math.max(0, themeCarousel.contentWidth - themeCarousel.width);
                            targetX = Math.max(0, Math.min(maxX, targetX));
                            if (immediate) {
                                themeScrollAnim.stop();
                                themeCarousel.contentX = targetX;
                            } else {
                                themeScrollAnim.to = targetX;
                                themeScrollAnim.restart();
                            }
                        }

                        NumberAnimation {
                            id: themeScrollAnim
                            target: themeCarousel
                            property: "contentX"
                            duration: 160
                            easing.type: Easing.OutCubic
                        }

                        ListView {
                            id: themeCarousel
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

                            model: launcher.filteredThemes
                            currentIndex: launcher.selectedIndex

                            delegate: Item {
                                width: 236
                                height: 226
                                z: (cardItem && cardItem.isHovered) ? 100 : (launcher.selectedIndex === index ? 20 : 1)

                                readonly property var itemData: modelData

                                ThemeCard {
                                    id: cardItem
                                    anchors.centerIn: parent
                                    width: 224
                                    height: 214
                                    themeKey: itemData ? itemData.id : ""
                                    themeTitle: itemData ? itemData.name : ""
                                    themeSubtitle: itemData ? itemData.desc : ""
                                    isCurrentTheme: itemData ? (itemData.id === Root.Theme.currentTheme) : false
                                    isSelected: launcher.selectedIndex === index

                                    onActivated: {
                                        launcher.selectedIndex = index;
                                        if (itemData) {
                                            launcher.applyTheme(itemData.id);
                                        }
                                    }
                                }
                            }

                            // Desplazamiento horizontal fluido
                            WheelHandler {
                                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                                onWheel: function(event) {
                                    var delta = event.angleDelta.y !== 0 ? event.angleDelta.y : event.angleDelta.x;
                                    var step = delta * 1.8;
                                    var targetX = themeCarousel.contentX - step;
                                    var maxX = Math.max(0, themeCarousel.contentWidth - themeCarousel.width);
                                    themeCarousel.contentX = Math.max(0, Math.min(maxX, targetX));
                                }
                            }

                            Component.onCompleted: {
                                if (launcher.currentMode === "theme") {
                                    themeView.scrollToCard(launcher.selectedIndex, true);
                                }
                            }
                        }

                        // Degradado lateral izquierdo
                        Rectangle {
                            id: themeLeftFade
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: 32
                            z: 50
                            enabled: false
                            visible: themeCarousel.contentX > 6
                            opacity: visible ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: Qt.rgba(Root.Theme.surface.r, Root.Theme.surface.g, Root.Theme.surface.b, 0.95) }
                                GradientStop { position: 1.0; color: "transparent" }
                            }
                        }

                        // Degradado lateral derecho
                        Rectangle {
                            id: themeRightFade
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: 32
                            z: 50
                            enabled: false
                            visible: themeCarousel.contentX < (themeCarousel.contentWidth - themeCarousel.width - 6)
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
                                if (launcher.currentMode === "theme" && themeCarousel) {
                                    themeView.scrollToCard(launcher.selectedIndex, false);
                                }
                            }
                        }

                        Text {
                            visible: launcher.filteredThemes.length === 0
                            anchors.centerIn: parent
                            text: "No themes match your query"
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: 15
                            color: Root.Theme.textSecondary
                        }
                    }

                    // --- VISTA: Carrusel de Shaders (Horizontal) ---
                    Item {
                        id: shaderView
                        visible: launcher.currentMode === "shader"
                        anchors.fill: parent
                        clip: true

                        function scrollToCard(index, immediate) {
                            var itemWidth = 236 + 16;
                            var targetX = index * itemWidth + 118 - (shaderCarousel.width / 2);
                            var maxX = Math.max(0, shaderCarousel.contentWidth - shaderCarousel.width);
                            targetX = Math.max(0, Math.min(maxX, targetX));
                            if (immediate) {
                                shaderScrollAnim.stop();
                                shaderCarousel.contentX = targetX;
                            } else {
                                shaderScrollAnim.to = targetX;
                                shaderScrollAnim.restart();
                            }
                        }

                        NumberAnimation {
                            id: shaderScrollAnim
                            target: shaderCarousel
                            property: "contentX"
                            duration: 160
                            easing.type: Easing.OutCubic
                        }

                        ListView {
                            id: shaderCarousel
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

                            model: launcher.filteredShaders
                            currentIndex: launcher.selectedIndex

                            delegate: Item {
                                width: 236
                                height: 226
                                z: (cardItem && cardItem.isHovered) ? 100 : (launcher.selectedIndex === index ? 20 : 1)

                                readonly property var itemData: modelData

                                ShaderCard {
                                    id: cardItem
                                    anchors.centerIn: parent
                                    width: 224
                                    height: 214
                                    shaderKey: itemData ? itemData.id : ""
                                    shaderTitle: itemData ? itemData.name : ""
                                    shaderSubtitle: itemData ? itemData.desc : ""
                                    shaderThumb: itemData ? itemData.thumb : ""
                                    isCurrentShader: itemData ? launcher.isShaderActive(itemData) : false
                                    isSelected: launcher.selectedIndex === index

                                    onActivated: {
                                        launcher.selectedIndex = index;
                                        if (itemData) {
                                            launcher.applyShader(itemData.id, itemData.filterName);
                                        }
                                    }
                                }
                            }

                            WheelHandler {
                                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                                onWheel: function(event) {
                                    var delta = event.angleDelta.y !== 0 ? event.angleDelta.y : event.angleDelta.x;
                                    var step = delta * 1.8;
                                    var targetX = shaderCarousel.contentX - step;
                                    var maxX = Math.max(0, shaderCarousel.contentWidth - shaderCarousel.width);
                                    shaderCarousel.contentX = Math.max(0, Math.min(maxX, targetX));
                                }
                            }

                            Component.onCompleted: {
                                if (launcher.currentMode === "shader") {
                                    shaderView.scrollToCard(launcher.selectedIndex, true);
                                }
                            }
                        }

                        // Degradado lateral izquierdo
                        Rectangle {
                            id: shaderLeftFade
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: 32
                            z: 50
                            enabled: false
                            visible: shaderCarousel.contentX > 6
                            opacity: visible ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: Qt.rgba(Root.Theme.surface.r, Root.Theme.surface.g, Root.Theme.surface.b, 0.95) }
                                GradientStop { position: 1.0; color: "transparent" }
                            }
                        }

                        // Degradado lateral derecho
                        Rectangle {
                            id: shaderRightFade
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: 32
                            z: 50
                            enabled: false
                            visible: shaderCarousel.contentX < (shaderCarousel.contentWidth - shaderCarousel.width - 6)
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
                                if (launcher.currentMode === "shader" && shaderCarousel) {
                                    shaderView.scrollToCard(launcher.selectedIndex, false);
                                }
                            }
                        }

                        Text {
                            visible: launcher.filteredShaders.length === 0
                            anchors.centerIn: parent
                            text: "No shaders match your query"
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: 15
                            color: Root.Theme.textSecondary
                        }
                    }

                    // --- VISTA 3: Carrusel de Gadgets de Escritorio (Horizontal) ---
                    Item {
                        id: gadgetsView
                        visible: launcher.currentMode === "gadgets"
                        anchors.fill: parent
                        clip: true

                        function scrollToCard(index, immediate) {
                            var itemWidth = 236 + 16;
                            var targetX = Math.max(0, index * itemWidth - (gadgetsCarousel.width - 236) / 2);
                            var maxX = Math.max(0, gadgetsCarousel.contentWidth - gadgetsCarousel.width);
                            targetX = Math.min(maxX, targetX);
                            if (immediate) {
                                gadgetsCarousel.contentX = targetX;
                            } else {
                                gadgetsScrollAnim.to = targetX;
                                gadgetsScrollAnim.restart();
                            }
                        }

                        NumberAnimation {
                            id: gadgetsScrollAnim
                            target: gadgetsCarousel
                            property: "contentX"
                            duration: 160
                            easing.type: Easing.OutCubic
                        }

                        ListView {
                            id: gadgetsCarousel
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

                            model: launcher.filteredGadgets
                            currentIndex: launcher.selectedIndex

                            delegate: Item {
                                width: 236
                                height: 226
                                z: (cardItem && cardItem.isHovered) ? 100 : (launcher.selectedIndex === index ? 20 : 1)

                                readonly property var itemData: modelData

                                GadgetCard {
                                    id: cardItem
                                    anchors.centerIn: parent
                                    width: 224
                                    height: 214
                                    gadgetId: itemData ? itemData.id : ""
                                    gadgetTitle: itemData ? itemData.name : ""
                                    gadgetSubtitle: itemData ? itemData.desc : ""
                                    gadgetIcon: itemData ? itemData.icon : "󱂬"
                                    isEnabled: itemData ? Root.GadgetsManager.isEnabled(itemData.id) : true
                                    isSelected: launcher.selectedIndex === index

                                    onActivated: {
                                        launcher.selectedIndex = index;
                                        if (itemData) {
                                            Root.GadgetsManager.toggle(itemData.id);
                                        }
                                    }
                                }
                            }

                            // Desplazamiento horizontal fluido
                            WheelHandler {
                                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                                onWheel: function(event) {
                                    var delta = event.angleDelta.y !== 0 ? event.angleDelta.y : event.angleDelta.x;
                                    var step = delta * 1.8;
                                    var targetX = gadgetsCarousel.contentX - step;
                                    var maxX = Math.max(0, gadgetsCarousel.contentWidth - gadgetsCarousel.width);
                                    gadgetsCarousel.contentX = Math.max(0, Math.min(maxX, targetX));
                                }
                            }

                            Component.onCompleted: {
                                if (launcher.currentMode === "gadgets") {
                                    gadgetsView.scrollToCard(launcher.selectedIndex, true);
                                }
                            }
                        }

                        // Degradado lateral izquierdo
                        Rectangle {
                            id: gadgetsLeftFade
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: 32
                            z: 50
                            enabled: false
                            visible: gadgetsCarousel.contentX > 6
                            opacity: visible ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: Qt.rgba(Root.Theme.surface.r, Root.Theme.surface.g, Root.Theme.surface.b, 0.95) }
                                GradientStop { position: 1.0; color: "transparent" }
                            }
                        }

                        // Degradado lateral derecho
                        Rectangle {
                            id: gadgetsRightFade
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: 32
                            z: 50
                            enabled: false
                            visible: gadgetsCarousel.contentX < (gadgetsCarousel.contentWidth - gadgetsCarousel.width - 6)
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
                                if (launcher.currentMode === "gadgets" && gadgetsCarousel) {
                                    gadgetsView.scrollToCard(launcher.selectedIndex, false);
                                }
                            }
                        }

                        Text {
                            visible: launcher.filteredGadgets.length === 0
                            anchors.centerIn: parent
                            text: "No desktop gadgets found"
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: 15
                            color: Root.Theme.textSecondary
                        }
                    }

                    // --- VISTA 4: Lista de Acciones / Comandos (Vertical) ---
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
                            font.pixelSize: 15
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
                            font.pixelSize: 15
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
                    height: 52

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
                                if (launcher.currentMode === "shader") return "󱡄";
                                if (launcher.currentMode === "theme") return "󰏘";
                                if (launcher.currentMode === "gadgets") return "󱂬";
                                if (launcher.currentMode === "actions") return "󰘳";
                                return "󰍉";
                            }
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: 20
                            color: launcher.currentMode === "apps" ? Root.Theme.textSecondary : Root.Theme.primary
                        }

                        // Campo de texto principal
                        TextInput {
                            id: searchInput
                            Layout.fillWidth: true
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: 16
                            color: Root.Theme.textPrimary
                            selectByMouse: true
                            selectionColor: Root.Theme.primary
                            selectedTextColor: Root.Theme.tileActiveText
                            text: launcher.searchText
                            focus: true

                            Keys.priority: Keys.BeforeItem

                            onTextChanged: {
                                launcher.searchText = text;
                                if ((launcher.currentMode !== "wallpaper" || (!text.startsWith("/wallpaper") && !text.startsWith(">wallpaper")))
                                    && (launcher.currentMode !== "shader" || (!text.startsWith("/shader") && !text.startsWith(">shader")))
                                    && (launcher.currentMode !== "theme" || (!text.startsWith("/theme") && !text.startsWith(">theme")))
                                    && (launcher.currentMode !== "gadgets" || (!text.startsWith("/gadgets") && !text.startsWith(">gadgets")))) {
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
                                    if (launcher.currentMode === "shader") return "Filter shaders or press Enter...";
                                    if (launcher.currentMode === "theme") return "Filter themes or press Enter...";
                                    if (launcher.currentMode === "gadgets") return "Toggle desktop gadgets with Enter or click...";
                                    if (launcher.currentMode === "actions") return "Type command name or press Enter...";
                                    return "Type \"/\" for commands...";
                                }
                                font.family: Root.Theme.fontFamily
                                font.pixelSize: 16
                                color: Root.Theme.textSecondary
                                visible: searchInput.text === ""
                            }

                            // ── Atajos de Teclado y Navegación ──────────
                            Keys.onEscapePressed: function(event) {
                                launcher.panelVisible = false;
                                event.accepted = true;
                            }

                            Keys.onLeftPressed: function(event) {
                                if (launcher.currentMode === "wallpaper" || launcher.currentMode === "shader" || launcher.currentMode === "theme" || launcher.currentMode === "gadgets") {
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
                                } else if (launcher.currentMode === "shader") {
                                    if (launcher.selectedIndex < launcher.filteredShaders.length - 1) {
                                        launcher.selectedIndex++;
                                    }
                                    event.accepted = true;
                                } else if (launcher.currentMode === "theme") {
                                    if (launcher.selectedIndex < launcher.filteredThemes.length - 1) {
                                        launcher.selectedIndex++;
                                    }
                                    event.accepted = true;
                                } else if (launcher.currentMode === "gadgets") {
                                    if (launcher.selectedIndex < launcher.filteredGadgets.length - 1) {
                                        launcher.selectedIndex++;
                                    }
                                    event.accepted = true;
                                } else {
                                    event.accepted = false;
                                }
                            }

                            Keys.onUpPressed: function(event) {
                                if (launcher.currentMode === "wallpaper" || launcher.currentMode === "shader" || launcher.currentMode === "theme" || launcher.currentMode === "gadgets") {
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
                                } else if (launcher.currentMode === "shader") {
                                    if (launcher.selectedIndex < launcher.filteredShaders.length - 1) {
                                        launcher.selectedIndex++;
                                    }
                                } else if (launcher.currentMode === "theme") {
                                    if (launcher.selectedIndex < launcher.filteredThemes.length - 1) {
                                        launcher.selectedIndex++;
                                    }
                                } else if (launcher.currentMode === "gadgets") {
                                    if (launcher.selectedIndex < launcher.filteredGadgets.length - 1) {
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
                                } else if (launcher.currentMode === "shader") {
                                    if (launcher.selectedIndex < launcher.filteredShaders.length - 1) {
                                        launcher.selectedIndex++;
                                    } else {
                                        launcher.selectedIndex = 0;
                                    }
                                } else if (launcher.currentMode === "theme") {
                                    if (launcher.selectedIndex < launcher.filteredThemes.length - 1) {
                                        launcher.selectedIndex++;
                                    } else {
                                        launcher.selectedIndex = 0;
                                    }
                                } else if (launcher.currentMode === "gadgets") {
                                    if (launcher.selectedIndex < launcher.filteredGadgets.length - 1) {
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
                                } else if (launcher.currentMode === "shader") {
                                    if (launcher.selectedIndex > 0) {
                                        launcher.selectedIndex--;
                                    } else if (launcher.filteredShaders.length > 0) {
                                        launcher.selectedIndex = launcher.filteredShaders.length - 1;
                                    }
                                } else if (launcher.currentMode === "theme") {
                                    if (launcher.selectedIndex > 0) {
                                        launcher.selectedIndex--;
                                    } else if (launcher.filteredThemes.length > 0) {
                                        launcher.selectedIndex = launcher.filteredThemes.length - 1;
                                    }
                                } else if (launcher.currentMode === "gadgets") {
                                    if (launcher.selectedIndex > 0) {
                                        launcher.selectedIndex--;
                                    } else if (launcher.filteredGadgets.length > 0) {
                                        launcher.selectedIndex = launcher.filteredGadgets.length - 1;
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
