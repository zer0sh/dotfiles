import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Mpris
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
        { id: "custom", name: "Custom", desc: "Deep onyx surfaces with personalized accent tone" },
        { id: "md3-cobalt-night", name: "Cobalt Night", desc: "Deep cobalt blue and midnight sapphire" },
        { id: "md3-amethyst", name: "Amethyst", desc: "Deep amethyst purple and lavender" },
        { id: "md3-arctic-mist", name: "Arctic Mist", desc: "Polar cyan and frosted ice blue" },
        { id: "md3-crimson-night", name: "Crimson Night", desc: "Vivid crimson red on deep onyx black surfaces" },
        { id: "cyberpunk", name: "Cyberpunk", desc: "Neon turquoise, magenta and electric violet" }
    ]

    property string activeMatugenScheme: "scheme-vibrant"

    readonly property var matugenModesList: [
        { id: "scheme-vibrant", name: "Vibrant", icon: "auto_awesome" },
        { id: "scheme-fruit-salad", name: "Fruit Salad", icon: "nutrition" },
        { id: "scheme-monochrome", name: "Monochrome", icon: "contrast" },
        { id: "scheme-tonal-spot", name: "Tonal Spot", icon: "palette" },
        { id: "scheme-expressive", name: "Expressive", icon: "brush" },
        { id: "scheme-rainbow", name: "Rainbow", icon: "looks" },
        { id: "scheme-fidelity", name: "Fidelity", icon: "center_focus_strong" },
        { id: "scheme-content", name: "Content", icon: "image" },
        { id: "scheme-neutral", name: "Neutral", icon: "lens" }
    ]

    readonly property var customAccentsList: [
        { id: "#FF2B44", name: "Carmesí", color: "#FF2B44" },
        { id: "#FF5722", name: "Lava", color: "#FF5722" },
        { id: "#FFB300", name: "Ámbar", color: "#FFB300" },
        { id: "#10B981", name: "Esmeralda", color: "#10B981" },
        { id: "#00F5D4", name: "Turquesa", color: "#00F5D4" },
        { id: "#06B6D4", name: "Cyan", color: "#06B6D4" },
        { id: "#3B82F6", name: "Cobalto", color: "#3B82F6" },
        { id: "#8B5CF6", name: "Amatista", color: "#8B5CF6" },
        { id: "#EC4899", name: "Fucsia", color: "#EC4899" },
        { id: "#F43F5E", name: "Rosa", color: "#F43F5E" }
    ]

    readonly property bool isMatugenSelected: {
        if (currentMode !== "theme") return false;
        if (filteredThemes.length === 0) return false;
        if (selectedIndex >= 0 && selectedIndex < filteredThemes.length) {
            return filteredThemes[selectedIndex].id === "matugen";
        }
        return Root.Theme.currentTheme === "matugen";
    }

    readonly property bool isCustomSelected: {
        if (currentMode !== "theme") return false;
        if (filteredThemes.length === 0) return false;
        if (selectedIndex >= 0 && selectedIndex < filteredThemes.length) {
            return filteredThemes[selectedIndex].id === "custom";
        }
        return Root.Theme.currentTheme === "custom";
    }

    Process {
        id: customAccentReadProc
        command: ["/bin/sh", "-c", "cat ~/.config/quickshell/custom-accent 2>/dev/null || echo '#FF2B44'"]
        stdout: StdioCollector {
            onStreamFinished: {
                var c = text.trim();
                if (c !== "" && c.charAt(0) === "#") {
                    Root.Theme.customAccent = c;
                }
            }
        }
    }

    Process {
        id: customAccentApplyProc
    }

    function applyCustomAccent(colorHex) {
        if (!colorHex || colorHex === "") return;
        Root.Theme.customAccent = colorHex;
        if (Root.Theme.currentTheme !== "custom") {
            Root.Theme.currentTheme = "custom";
            actionExecProc.command = ["/bin/sh", "-c", "printf '%s\\n' 'custom' > ~/.config/quickshell/current-theme"];
            actionExecProc.running = true;
        }
        customAccentApplyProc.command = ["/bin/sh", "-c", "printf '%s\\n' '" + colorHex + "' > ~/.config/quickshell/custom-accent && /home/zero/.config/quickshell/scripts/apply-theme.sh custom"];
        customAccentApplyProc.running = true;
    }

    Process {
        id: matugenSchemeReadProc
        command: ["/bin/sh", "-c", "cat ~/.config/themes/current/scheme_type 2>/dev/null || echo 'scheme-vibrant'"]
        stdout: StdioCollector {
            onStreamFinished: {
                var s = text.trim();
                if (s !== "") {
                    launcher.activeMatugenScheme = s;
                }
            }
        }
    }

    Process {
        id: matugenApplySchemeProc
    }

    function applyMatugenScheme(schemeId) {
        if (!schemeId || schemeId === "") return;
        launcher.activeMatugenScheme = schemeId;

        if (Root.Theme.currentTheme !== "matugen") {
            Root.Theme.currentTheme = "matugen";
            actionExecProc.command = ["/bin/sh", "-c", "printf '%s\\n' 'matugen' > ~/.config/quickshell/current-theme"];
            actionExecProc.running = true;
        }

        matugenApplySchemeProc.command = ["/home/zero/.config/themes/apply-matugen.sh", "", "", schemeId];
        matugenApplySchemeProc.running = true;
    }

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
        matugenSchemeReadProc.running = true;
        customAccentReadProc.running = true;
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
                    if (selectedTheme.id === "matugen") {
                        launcher.applyMatugenScheme(launcher.activeMatugenScheme);
                        launcher.panelVisible = false;
                    } else {
                        launcher.applyTheme(selectedTheme.id);
                    }
                }
            }
        } else if (launcher.currentMode === "gadgets") {
            if (launcher.selectedIndex >= 0 && launcher.selectedIndex < launcher.filteredGadgets.length) {
                var selectedGadget = launcher.filteredGadgets[launcher.selectedIndex];
                if (selectedGadget && selectedGadget.id) {
                    Root.GadgetsManager.toggle(selectedGadget.id);
                }
            }
        } else if (launcher.currentMode === "music") {
            if (launcher._mprisPlayer) {
                launcher._mprisPlayer.togglePlaying();
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
        { id: "music", name: "Music Player", desc: "Media controls, track details and playback", icon: "󰎆", aliases: ["music", "musica", "player", "reproductor"] },
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
        } else if (searchText.startsWith("/music") || searchText.startsWith("/musica") ||
                   searchText.startsWith(">music") || searchText.startsWith(">musica")) {
            return "music";
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

    // ── MPRIS Music Player State ────────────────────────────────
    property MprisPlayer _mprisPlayer: null

    function _refreshMpris() {
        var list = Mpris.players ? Mpris.players.values : null;
        if (!list || list.length === 0) {
            _mprisPlayer = null;
            return;
        }
        for (var i = 0; i < list.length; i++) {
            var p = list[i];
            if (p && p.isPlaying) {
                _mprisPlayer = p;
                return;
            }
        }
        _mprisPlayer = list[0];
    }

    Timer {
        interval: 1200
        running: launcher.panelVisible && launcher.currentMode === "music"
        repeat: true
        onTriggered: launcher._refreshMpris()
    }

    function formatTime(sec) {
        if (!sec || isNaN(sec) || sec < 0) return "0:00";
        var m = Math.floor(sec / 60);
        var s = Math.floor(sec % 60);
        return m + ":" + (s < 10 ? "0" : "") + s;
    }

    function playerAppTarget() {
        if (!_mprisPlayer) return "";
        var entry = (_mprisPlayer.desktopEntry || "").toLowerCase().replace(/\.desktop$/, "");
        var ident = (_mprisPlayer.identity || "").toLowerCase();
        if (entry) return entry;
        if (ident.indexOf("zen") !== -1) return "zen";
        if (ident.indexOf("spotify") !== -1) return "spotify";
        if (ident.indexOf("firefox") !== -1) return "firefox";
        if (ident.indexOf("chrome") !== -1 || ident.indexOf("chromium") !== -1) return "google-chrome";
        if (ident.indexOf("vlc") !== -1) return "vlc";
        return ident.split(" ")[0];
    }

    function openPlayerApp() {
        if (!_mprisPlayer) return;
        try {
            if (_mprisPlayer.canRaise) _mprisPlayer.raise();
        } catch (e) {}
        var target = playerAppTarget();
        var title = _mprisPlayer.trackTitle || "";
        actionExecProc.command = [
            "/home/zero/.config/quickshell/scripts/focus-player.sh",
            target,
            title
        ];
        actionExecProc.running = true;
        launcher.panelVisible = false;
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
        if (act.id === "music") {
            launcher.openMusic();
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

    function openMusic() {
        searchText = "/music ";
        panelVisible = true;
        selectedIndex = 0;
        _refreshMpris();
    }

    function toggleMusic() {
        if (launcher.panelVisible && launcher.currentMode === "music") {
            launcher.panelVisible = false;
        } else {
            launcher.openMusic();
        }
    }

    onPanelVisibleChanged: {
        if (panelVisible) {
            _showing = true;
            if (currentMode !== "wallpaper" && currentMode !== "theme" && currentMode !== "gadgets" && currentMode !== "shader" && currentMode !== "music") {
                selectedIndex = 0;
            }
            if (allApps.length === 0) appsReadProc.running = true;
            refreshWallpapers();
            shaderCurrentProc.running = true;
            if (currentMode === "music") _refreshMpris();
        } else {
            searchText = "";
        }
    }

    Component.onCompleted: {
        iconResolveProc.running = true;
        appsReadProc.running = true;
        refreshWallpapers();
        shaderCurrentProc.running = true;
        matugenSchemeReadProc.running = true;
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
        function music(): void {
            launcher.openMusic();
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

    IpcHandler {
        target: "musicpicker"
        function toggle(): void { launcher.toggleMusic(); }
        function show(): void { launcher.openMusic(); }
        function hide(): void { launcher.panelVisible = false; }
    }

    IpcHandler {
        target: "miniplayer"
        function toggle(): void { launcher.toggleMusic(); }
        function show(): void { launcher.openMusic(); }
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
            WlrLayershell.keyboardFocus: launcher.currentMode === "music" ? WlrKeyboardFocus.None : WlrKeyboardFocus.Exclusive

            mask: Region {
                item: launcher.currentMode === "music" ? musicRegionItem : panelWindow
            }

            // Fondo semitransparente oscuro con clic exterior para cerrar (oculto en modo música para no opacar el escritorio)
            Rectangle {
                anchors.fill: parent
                visible: launcher.currentMode !== "music"
                color: Qt.rgba(0, 0, 0, 0.4)

                MouseArea {
                    anchors.fill: parent
                    enabled: launcher.currentMode !== "music"
                    onClicked: launcher.panelVisible = false
                }
            }

            // Región interactiva exclusiva para modo música (permite clics pasantes en el resto del escritorio)
            Item {
                id: musicRegionItem
                anchors.top: floatingCard.top
                anchors.bottom: floatingCard.bottom
                anchors.left: launcherLeftFillet.left
                anchors.right: launcherRightFillet.right
            }

            // Concave fillet left (Dynamic Island bottom curve connecting to screen bottom)
            Shape {
                id: launcherLeftFillet
                z: 10
                width: 28
                height: 28
                anchors.bottom: floatingCard.bottom
                anchors.right: floatingCard.left
                layer.enabled: true
                layer.samples: 4

                ShapePath {
                    strokeWidth: 0
                    strokeColor: "transparent"
                    fillColor: floatingCard.color

                    startX: 0
                    startY: 28
                    PathLine { x: 28; y: 28 }
                    PathLine { x: 28; y: 0 }
                    PathArc {
                        x: 0
                        y: 28
                        radiusX: 28
                        radiusY: 28
                        direction: PathArc.Clockwise
                    }
                }
            }

            // Concave fillet right (Dynamic Island bottom curve connecting to screen bottom)
            Shape {
                id: launcherRightFillet
                z: 10
                width: 28
                height: 28
                anchors.bottom: floatingCard.bottom
                anchors.left: floatingCard.right
                layer.enabled: true
                layer.samples: 4

                ShapePath {
                    strokeWidth: 0
                    strokeColor: "transparent"
                    fillColor: floatingCard.color

                    startX: 28
                    startY: 28
                    PathLine { x: 0; y: 28 }
                    PathLine { x: 0; y: 0 }
                    PathArc {
                        x: 28
                        y: 28
                        radiusX: 28
                        radiusY: 28
                        direction: PathArc.Counterclockwise
                    }
                }
            }

            // ── Contenedor Inferior Central (Dynamic Island) ───────────
            Rectangle {
                id: floatingCard
                z: 10

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 0

                width: {
                    if (launcher.currentMode === "wallpaper" || launcher.currentMode === "shader" || launcher.currentMode === "theme" || launcher.currentMode === "gadgets") return Math.min(1080, parent.width - 60);
                    if (launcher.currentMode === "music") return Math.min(680, parent.width - 60);
                    return 580;
                }

                height: {
                    if (launcher.currentMode === "wallpaper" || launcher.currentMode === "shader" || launcher.currentMode === "gadgets") return 340;
                    if (launcher.currentMode === "theme") return (launcher.isMatugenSelected || launcher.isCustomSelected) ? 392 : 340;
                    if (launcher.currentMode === "music") return 250;
                    if (launcher.currentMode === "actions") {
                        var actCount = launcher.filteredActions.length;
                        return Math.min(460, Math.max(140, actCount * 50 + 76));
                    }
                    var appCount = launcher.filteredApps.length;
                    return Math.min(480, Math.max(140, appCount * 52 + 76));
                }

                radius: 28
                topLeftRadius: 28
                topRightRadius: 28
                bottomLeftRadius: 0
                bottomRightRadius: 0

                color: Qt.rgba(Root.Theme._shelfBgColor.r, Root.Theme._shelfBgColor.g, Root.Theme._shelfBgColor.b, 0.80)
                border.width: 0
                clip: true

                focus: true
                Keys.forwardTo: [searchInput]

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

                        // Barra superior de modos Matugen
                        Rectangle {
                            id: matugenModesBar
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: launcher.isMatugenSelected ? 40 : 0
                            visible: height > 0
                            opacity: launcher.isMatugenSelected ? 1.0 : 0.0
                            color: "transparent"
                            clip: true

                            Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                            Behavior on opacity { NumberAnimation { duration: 180 } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 4
                                anchors.rightMargin: 4
                                spacing: 10

                                // Etiqueta de sección
                                Row {
                                    Layout.alignment: Qt.AlignVCenter
                                    spacing: 6

                                    Text {
                                        text: "󰏘"
                                        font.family: Root.Theme.fontFamily
                                        font.pixelSize: 15
                                        color: Root.Theme.primary
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    Text {
                                        text: "Modo:"
                                        font.family: Root.Theme.fontFamily
                                        font.pixelSize: 12
                                        font.weight: Font.DemiBold
                                        color: Root.Theme.textSecondary
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }

                                // Carrusel de pastillas de modo
                                ListView {
                                    id: modesCarousel
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    orientation: ListView.Horizontal
                                    spacing: 6
                                    clip: true
                                    boundsBehavior: Flickable.StopAtBounds
                                    model: launcher.matugenModesList

                                    delegate: Rectangle {
                                        id: modeChip
                                        readonly property var modeData: modelData
                                        readonly property bool isActive: launcher.activeMatugenScheme === modeData.id
                                        readonly property bool isHovered: chipMouse.containsMouse

                                        width: chipRow.implicitWidth + 22
                                        height: 30
                                        anchors.verticalCenter: parent.verticalCenter
                                        radius: 15

                                        color: isActive
                                            ? Root.Theme.primary
                                            : (isHovered ? Root.Theme.surfaceBright : Root.Theme.surfaceContainer)
                                        border.width: 1
                                        border.color: isActive
                                            ? Root.Theme.primary
                                            : (isHovered
                                                ? Qt.rgba(Root.Theme.primary.r, Root.Theme.primary.g, Root.Theme.primary.b, 0.45)
                                                : Qt.rgba(Root.Theme.panelBorder.r, Root.Theme.panelBorder.g, Root.Theme.panelBorder.b, 0.35))

                                        Behavior on color { ColorAnimation { duration: 140 } }
                                        Behavior on border.color { ColorAnimation { duration: 140 } }

                                        Row {
                                            id: chipRow
                                            anchors.centerIn: parent
                                            spacing: 6

                                            Text {
                                                text: modeData.icon
                                                font.family: Root.Theme.iconFont
                                                font.pixelSize: 15
                                                color: modeChip.isActive
                                                    ? Root.Theme.tileActiveText
                                                    : (modeChip.isHovered ? Root.Theme.textPrimary : Root.Theme.textSecondary)
                                                anchors.verticalCenter: parent.verticalCenter
                                                Behavior on color { ColorAnimation { duration: 140 } }
                                            }

                                            Text {
                                                text: modeData.name
                                                font.family: Root.Theme.fontFamily
                                                font.pixelSize: 12
                                                font.weight: modeChip.isActive ? Font.Bold : Font.Normal
                                                color: modeChip.isActive
                                                    ? Root.Theme.tileActiveText
                                                    : (modeChip.isHovered ? Root.Theme.textPrimary : Root.Theme.textSecondary)
                                                anchors.verticalCenter: parent.verticalCenter
                                                Behavior on color { ColorAnimation { duration: 140 } }
                                            }
                                        }

                                        MouseArea {
                                            id: chipMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                launcher.applyMatugenScheme(modeData.id);
                                            }
                                        }
                                    }

                                    WheelHandler {
                                        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                                        onWheel: function(event) {
                                            var delta = event.angleDelta.y !== 0 ? event.angleDelta.y : event.angleDelta.x;
                                            var step = delta * 1.5;
                                            var targetX = modesCarousel.contentX - step;
                                            var maxX = Math.max(0, modesCarousel.contentWidth - modesCarousel.width);
                                            modesCarousel.contentX = Math.max(0, Math.min(maxX, targetX));
                                        }
                                    }
                                }
                            }
                        }

                        Rectangle {
                            id: customAccentsBar
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: launcher.isCustomSelected ? 40 : 0
                            visible: height > 0
                            opacity: launcher.isCustomSelected ? 1.0 : 0.0
                            color: "transparent"
                            clip: true

                            Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                            Behavior on opacity { NumberAnimation { duration: 180 } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 4
                                anchors.rightMargin: 4
                                spacing: 10

                                // Etiqueta de sección
                                Row {
                                    Layout.alignment: Qt.AlignVCenter
                                    spacing: 6

                                    Text {
                                        text: "format_paint"
                                        font.family: Root.Theme.iconFont
                                        font.pixelSize: 16
                                        color: Root.Theme.primary
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    Text {
                                        text: "Acento:"
                                        font.family: Root.Theme.fontFamily
                                        font.pixelSize: 12
                                        font.weight: Font.DemiBold
                                        color: Root.Theme.textSecondary
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }

                                // Carrusel de pastillas de color de acento
                                ListView {
                                    id: accentsCarousel
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    orientation: ListView.Horizontal
                                    spacing: 6
                                    clip: true
                                    boundsBehavior: Flickable.StopAtBounds
                                    model: launcher.customAccentsList

                                    delegate: Rectangle {
                                        id: accentChip
                                        readonly property var accentData: modelData
                                        readonly property bool isActive: (Root.Theme.customAccent.toUpperCase() === accentData.color.toUpperCase())
                                        readonly property bool isHovered: accentChipMouse.containsMouse

                                        width: accentChipRow.implicitWidth + 24
                                        height: 30
                                        anchors.verticalCenter: parent.verticalCenter
                                        radius: 15

                                        color: isActive
                                            ? Qt.rgba(Qt.color(accentData.color).r, Qt.color(accentData.color).g, Qt.color(accentData.color).b, 0.22)
                                            : (isHovered ? Root.Theme.surfaceBright : Root.Theme.surfaceContainer)
                                        border.width: isActive ? 2 : 1
                                        border.color: isActive
                                            ? Qt.color(accentData.color)
                                            : (isHovered
                                                ? Qt.rgba(Qt.color(accentData.color).r, Qt.color(accentData.color).g, Qt.color(accentData.color).b, 0.45)
                                                : Qt.rgba(Root.Theme.panelBorder.r, Root.Theme.panelBorder.g, Root.Theme.panelBorder.b, 0.35))

                                        Behavior on color { ColorAnimation { duration: 140 } }
                                        Behavior on border.color { ColorAnimation { duration: 140 } }

                                        Row {
                                            id: accentChipRow
                                            anchors.centerIn: parent
                                            spacing: 7

                                            Rectangle {
                                                width: 12
                                                height: 12
                                                radius: 6
                                                color: accentData.color
                                                anchors.verticalCenter: parent.verticalCenter
                                                border.width: 1
                                                border.color: Qt.rgba(1, 1, 1, 0.3)
                                            }

                                            Text {
                                                text: accentData.name
                                                font.family: Root.Theme.fontFamily
                                                font.pixelSize: 12
                                                font.weight: accentChip.isActive ? Font.Bold : Font.Normal
                                                color: accentChip.isActive
                                                    ? Root.Theme.textPrimary
                                                    : (accentChip.isHovered ? Root.Theme.textPrimary : Root.Theme.textSecondary)
                                                anchors.verticalCenter: parent.verticalCenter
                                                Behavior on color { ColorAnimation { duration: 140 } }
                                            }
                                        }

                                        MouseArea {
                                            id: accentChipMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                launcher.applyCustomAccent(accentData.color);
                                            }
                                        }
                                    }

                                    WheelHandler {
                                        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                                        onWheel: function(event) {
                                            var delta = event.angleDelta.y !== 0 ? event.angleDelta.y : event.angleDelta.x;
                                            var step = delta * 1.5;
                                            var targetX = accentsCarousel.contentX - step;
                                            var maxX = Math.max(0, accentsCarousel.contentWidth - accentsCarousel.width);
                                            accentsCarousel.contentX = Math.max(0, Math.min(maxX, targetX));
                                        }
                                    }
                                }
                            }
                        }

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
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: launcher.isCustomSelected ? customAccentsBar.bottom : matugenModesBar.bottom
                            anchors.bottom: parent.bottom
                            anchors.topMargin: (launcher.isMatugenSelected || launcher.isCustomSelected) ? 6 : 8
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
                                            if (itemData.id === "matugen") {
                                                if (Root.Theme.currentTheme === "matugen") {
                                                    launcher.panelVisible = false;
                                                } else {
                                                    launcher.applyMatugenScheme(launcher.activeMatugenScheme);
                                                }
                                            } else {
                                                launcher.applyTheme(itemData.id);
                                            }
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
                            anchors.top: matugenModesBar.bottom
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
                            anchors.top: matugenModesBar.bottom
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

                    // --- VISTA 5: Reproductor de Música (Desde abajo) ---
                    Item {
                        id: musicView
                        visible: launcher.currentMode === "music"
                        anchors.fill: parent
                        clip: true

                        // Botón de cerrar en estado vacío
                        Rectangle {
                            anchors.top: parent.top
                            anchors.right: parent.right
                            width: 26
                            height: 26
                            radius: 13
                            visible: !launcher._mprisPlayer
                            color: closeEmptyMA.containsMouse ? Qt.rgba(255, 255, 255, 0.18) : Qt.rgba(255, 255, 255, 0.06)
                            Behavior on color { ColorAnimation { duration: 120 } }

                            Text {
                                anchors.centerIn: parent
                                text: "󰅖"
                                font.family: Root.Theme.fontFamily
                                font.pixelSize: 14
                                color: Root.Theme.textSecondary
                            }

                            MouseArea {
                                id: closeEmptyMA
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: launcher.panelVisible = false
                            }
                        }

                        // Estado vacío cuando no hay reproductor
                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 8
                            visible: !launcher._mprisPlayer

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: "󰎆"
                                font.family: Root.Theme.fontFamily
                                font.pixelSize: 42
                                color: Root.Theme.textSecondary
                                opacity: 0.5
                            }

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: "No active media player"
                                font.family: Root.Theme.fontFamily
                                font.pixelSize: 15
                                font.weight: Font.DemiBold
                                color: Root.Theme.textPrimary
                            }

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: "Launch Spotify, Zen or any media player to control playback here"
                                font.family: Root.Theme.fontFamily
                                font.pixelSize: 12
                                color: Root.Theme.textSecondary
                                opacity: 0.7
                            }
                        }

                        // Reproductor activo
                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 4
                            spacing: 18
                            visible: launcher._mprisPlayer !== null

                            // Portada del Álbum
                            Rectangle {
                                Layout.preferredWidth: 140
                                Layout.preferredHeight: 140
                                radius: 18
                                clip: true
                                color: launcher._mprisPlayer && launcher._mprisPlayer.trackArtUrl !== ""
                                    ? "transparent"
                                    : Root.Theme.surfaceContainerHigh

                                Image {
                                    anchors.fill: parent
                                    source: launcher._mprisPlayer ? launcher._mprisPlayer.trackArtUrl : ""
                                    fillMode: Image.PreserveAspectCrop
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰎆"
                                    font.family: Root.Theme.fontFamily
                                    font.pixelSize: 40
                                    color: Root.Theme.textSecondary
                                    visible: !launcher._mprisPlayer || launcher._mprisPlayer.trackArtUrl === ""
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    radius: parent.radius
                                    color: Qt.rgba(0, 0, 0, 0.35)
                                    opacity: artHover.containsMouse ? 1.0 : 0.0
                                    Behavior on opacity { NumberAnimation { duration: 150 } }

                                    Text {
                                        anchors.centerIn: parent
                                        text: "open_in_new"
                                        font.family: Root.Theme.iconFont
                                        font.pixelSize: 26
                                        color: "#FFFFFF"
                                    }
                                }

                                MouseArea {
                                    id: artHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: launcher.openPlayerApp()
                                }
                            }

                            // Columna de Información y Controles
                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                spacing: 6
                                Layout.alignment: Qt.AlignVCenter

                                // Fila superior: Badge de Aplicación y botones
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    Rectangle {
                                        Layout.preferredHeight: 24
                                        Layout.preferredWidth: appBadgeText.implicitWidth + 18
                                        radius: 12
                                        color: Qt.rgba(255, 255, 255, 0.08)

                                        RowLayout {
                                            anchors.centerIn: parent
                                            spacing: 6

                                            Text {
                                                text: "󰎈"
                                                font.family: Root.Theme.fontFamily
                                                font.pixelSize: 12
                                                color: Root.Theme.primary
                                            }

                                            Text {
                                                id: appBadgeText
                                                text: launcher._mprisPlayer ? launcher._mprisPlayer.identity : "Media"
                                                font.family: Root.Theme.fontFamily
                                                font.pixelSize: 11
                                                font.weight: Font.DemiBold
                                                color: Root.Theme.textSecondary
                                            }
                                        }
                                    }

                                    Item { Layout.fillWidth: true }

                                    // Botón para saltar a la ventana de la app
                                    Rectangle {
                                        Layout.preferredWidth: 26
                                        Layout.preferredHeight: 26
                                        radius: 13
                                        color: focusMA.containsMouse ? Qt.rgba(255, 255, 255, 0.15) : Qt.rgba(255, 255, 255, 0.06)
                                        Behavior on color { ColorAnimation { duration: 120 } }

                                        Text {
                                            anchors.centerIn: parent
                                            text: "open_in_new"
                                            font.family: Root.Theme.iconFont
                                            font.pixelSize: 15
                                            color: focusMA.containsMouse ? Root.Theme.primary : Root.Theme.textSecondary
                                        }

                                        MouseArea {
                                            id: focusMA
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: launcher.openPlayerApp()
                                        }
                                    }

                                    // Botón para cerrar el reproductor
                                    Rectangle {
                                        Layout.preferredWidth: 26
                                        Layout.preferredHeight: 26
                                        radius: 13
                                        color: closePlayerMA.containsMouse ? Qt.rgba(Root.Theme.error.r, Root.Theme.error.g, Root.Theme.error.b, 0.3) : Qt.rgba(255, 255, 255, 0.06)
                                        Behavior on color { ColorAnimation { duration: 120 } }

                                        Text {
                                            anchors.centerIn: parent
                                            text: "󰅖"
                                            font.family: Root.Theme.fontFamily
                                            font.pixelSize: 14
                                            color: closePlayerMA.containsMouse ? "#FFFFFF" : Root.Theme.textSecondary
                                        }

                                        MouseArea {
                                            id: closePlayerMA
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: launcher.panelVisible = false
                                        }
                                    }
                                }

                                // Título de la pista
                                Text {
                                    text: launcher._mprisPlayer && launcher._mprisPlayer.trackTitle !== "" ? launcher._mprisPlayer.trackTitle : "No track playing"
                                    font.family: Root.Theme.fontFamily
                                    font.pixelSize: 17
                                    font.weight: Font.Bold
                                    color: Root.Theme.textPrimary
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                // Artista / Álbum
                                Text {
                                    text: launcher._mprisPlayer && launcher._mprisPlayer.trackArtist !== "" ? launcher._mprisPlayer.trackArtist : (launcher._mprisPlayer && launcher._mprisPlayer.trackAlbum !== "" ? launcher._mprisPlayer.trackAlbum : "Unknown artist")
                                    font.family: Root.Theme.fontFamily
                                    font.pixelSize: 13
                                    color: Root.Theme.textSecondary
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                // Barra de Progreso
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 3

                                    Rectangle {
                                        id: progressTrack
                                        Layout.fillWidth: true
                                        height: 5
                                        radius: 3
                                        color: Qt.rgba(255, 255, 255, 0.12)

                                        Rectangle {
                                            anchors.top: parent.top
                                            anchors.bottom: parent.bottom
                                            anchors.left: parent.left
                                            width: parent.width * (launcher._mprisPlayer && launcher._mprisPlayer.length > 0 ? Math.min(launcher._mprisPlayer.position / launcher._mprisPlayer.length, 1.0) : 0)
                                            radius: parent.radius
                                            color: Root.Theme.primary
                                            Behavior on width { NumberAnimation { duration: 150 } }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: function(mouse) {
                                                if (launcher._mprisPlayer && launcher._mprisPlayer.length > 0 && launcher._mprisPlayer.canSeek) {
                                                    var frac = Math.max(0, Math.min(1, mouse.x / width));
                                                    launcher._mprisPlayer.position = frac * launcher._mprisPlayer.length;
                                                }
                                            }
                                        }
                                    }

                                    // Fila de tiempos (posición / duración)
                                    RowLayout {
                                        Layout.fillWidth: true
                                        visible: launcher._mprisPlayer && launcher._mprisPlayer.length > 0

                                        Text {
                                            text: launcher.formatTime(launcher._mprisPlayer ? launcher._mprisPlayer.position : 0)
                                            font.family: Root.Theme.fontFamily
                                            font.pixelSize: 11
                                            color: Root.Theme.textSecondary
                                        }

                                        Item { Layout.fillWidth: true }

                                        Text {
                                            text: launcher.formatTime(launcher._mprisPlayer ? launcher._mprisPlayer.length : 0)
                                            font.family: Root.Theme.fontFamily
                                            font.pixelSize: 11
                                            color: Root.Theme.textSecondary
                                        }
                                    }
                                }

                                // Botones de Control (Prev, Play/Pause, Next)
                                RowLayout {
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignHCenter
                                    spacing: 16

                                    Rectangle {
                                        Layout.preferredWidth: 36
                                        Layout.preferredHeight: 36
                                        radius: 18
                                        color: prevLauncherMA.containsMouse ? Qt.rgba(255, 255, 255, 0.12) : "transparent"
                                        Behavior on color { ColorAnimation { duration: 120 } }

                                        Text {
                                            anchors.centerIn: parent
                                            text: "󰒫"
                                            font.family: Root.Theme.fontFamily
                                            font.pixelSize: 20
                                            color: launcher._mprisPlayer && launcher._mprisPlayer.canGoPrevious ? Root.Theme.textPrimary : Root.Theme.textDisabled
                                        }

                                        MouseArea {
                                            id: prevLauncherMA
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: if (launcher._mprisPlayer) launcher._mprisPlayer.previous()
                                        }
                                    }

                                    Rectangle {
                                        Layout.preferredWidth: 42
                                        Layout.preferredHeight: 42
                                        radius: 21
                                        color: playLauncherMA.containsMouse ? Root.Theme.primaryContainer : Root.Theme.primary
                                        Behavior on color { ColorAnimation { duration: 120 } }

                                        Text {
                                            anchors.centerIn: parent
                                            text: launcher._mprisPlayer && launcher._mprisPlayer.playbackState === MprisPlaybackState.Playing ? "󰏤" : "󰐊"
                                            font.family: Root.Theme.fontFamily
                                            font.pixelSize: 20
                                            color: Root.Theme.tileActiveText
                                        }

                                        MouseArea {
                                            id: playLauncherMA
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: if (launcher._mprisPlayer) launcher._mprisPlayer.togglePlaying()
                                        }
                                    }

                                    Rectangle {
                                        Layout.preferredWidth: 36
                                        Layout.preferredHeight: 36
                                        radius: 18
                                        color: nextLauncherMA.containsMouse ? Qt.rgba(255, 255, 255, 0.12) : "transparent"
                                        Behavior on color { ColorAnimation { duration: 120 } }

                                        Text {
                                            anchors.centerIn: parent
                                            text: "󰒬"
                                            font.family: Root.Theme.fontFamily
                                            font.pixelSize: 20
                                            color: launcher._mprisPlayer && launcher._mprisPlayer.canGoNext ? Root.Theme.textPrimary : Root.Theme.textDisabled
                                        }

                                        MouseArea {
                                            id: nextLauncherMA
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: if (launcher._mprisPlayer) launcher._mprisPlayer.next()
                                        }
                                    }
                                }
                            }
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
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    anchors.bottomMargin: 14
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
                                if (launcher.currentMode === "music") return "󰎆";
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
                                    && (launcher.currentMode !== "gadgets" || (!text.startsWith("/gadgets") && !text.startsWith(">gadgets")))
                                    && (launcher.currentMode !== "music" || (!text.startsWith("/music") && !text.startsWith(">music")))) {
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
                                    if (launcher.currentMode === "music") return "Media controls (Space: Play/Pause, Enter: Toggle)...";
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

                            Keys.onSpacePressed: function(event) {
                                if (launcher.currentMode === "music" && launcher.searchText.trim() === "/music") {
                                    if (launcher._mprisPlayer) launcher._mprisPlayer.togglePlaying();
                                    event.accepted = true;
                                    return;
                                }
                                event.accepted = false;
                            }

                            Keys.onLeftPressed: function(event) {
                                if (launcher.currentMode === "music") {
                                    if (launcher._mprisPlayer && launcher._mprisPlayer.canGoPrevious) launcher._mprisPlayer.previous();
                                    event.accepted = true;
                                } else if (launcher.currentMode === "wallpaper" || launcher.currentMode === "shader" || launcher.currentMode === "theme" || launcher.currentMode === "gadgets") {
                                    if (launcher.selectedIndex > 0) launcher.selectedIndex--;
                                    event.accepted = true;
                                } else {
                                    event.accepted = false;
                                }
                            }

                            Keys.onRightPressed: function(event) {
                                if (launcher.currentMode === "music") {
                                    if (launcher._mprisPlayer && launcher._mprisPlayer.canGoNext) launcher._mprisPlayer.next();
                                    event.accepted = true;
                                } else if (launcher.currentMode === "wallpaper") {
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
                                    if (launcher.currentMode === "music") {
                                        launcher.panelVisible = false;
                                    } else {
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
}
