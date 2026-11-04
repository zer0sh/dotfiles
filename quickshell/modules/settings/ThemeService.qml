pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../.." as Root

QtObject {
    id: themeService

    // Active mode: "matugen" | "preset" | "custom"
    readonly property string activeMode: {
        if (Root.Theme.currentTheme === "matugen") return "matugen";
        if (Root.Theme.currentTheme === "custom") return "custom";
        return "preset";
    }

    property string activeMatugenScheme: "scheme-vibrant"
    property string lastPreset: {
        if (Root.Theme.currentTheme !== "matugen" && Root.Theme.currentTheme !== "custom") {
            return Root.Theme.currentTheme;
        }
        return "md3-cobalt-night";
    }

    property string customAccent: Root.Theme.customAccent || "#FF2B44"

    readonly property var matugenSchemes: [
        { id: "scheme-vibrant", name: "Vibrant", icon: "auto_awesome", desc: "High contrast vivid tones" },
        { id: "scheme-tonal-spot", name: "Tonal Spot", icon: "palette", desc: "Default balanced Material 3" },
        { id: "scheme-expressive", name: "Expressive", icon: "brush", desc: "Rich complementary accents" },
        { id: "scheme-rainbow", name: "Rainbow", icon: "looks", desc: "Playful chroma distribution" },
        { id: "scheme-fruit-salad", name: "Fruit Salad", icon: "nutrition", desc: "Fresh dual-accent pop" },
        { id: "scheme-monochrome", name: "Monochrome", icon: "contrast", desc: "Clean grayscale tones" }
    ]

    readonly property var presetThemes: [
        {
            id: "md3-cobalt-night",
            name: "Cobalt Night",
            desc: "Deep cobalt blue on dark charcoal",
            primary: "#9BBDE8",
            surface: "#121215",
            container: "#162238"
        },
        {
            id: "md3-amethyst",
            name: "Amethyst",
            desc: "Rich amethyst purple and obsidian dark",
            primary: "#C8B0F0",
            surface: "#121215",
            container: "#2A1838"
        },
        {
            id: "md3-arctic-mist",
            name: "Arctic Mist",
            desc: "Polar cyan and frosted ice blue",
            primary: "#7ECCE8",
            surface: "#121215",
            container: "#122A36"
        },
        {
            id: "md3-crimson-night",
            name: "Crimson Night",
            desc: "Vivid crimson red on deep onyx black",
            primary: "#FF2B44",
            surface: "#121215",
            container: "#3E0D15"
        },
        {
            id: "cyberpunk",
            name: "Cyberpunk",
            desc: "Neon turquoise and electric violet",
            primary: "#00F5D4",
            surface: "#121215",
            container: "#08302A"
        }
    ]

    readonly property var quickAccents: [
        { name: "Crimson", hex: "#FF2B44" },
        { name: "Coral", hex: "#FF5722" },
        { name: "Amber", hex: "#FFA000" },
        { name: "Emerald", hex: "#00C853" },
        { name: "Mint", hex: "#00BFA5" },
        { name: "Cyan", hex: "#00B0FF" },
        { name: "Cobalt", hex: "#2979FF" },
        { name: "Purple", hex: "#7C4DFF" },
        { name: "Pink", hex: "#FF4081" }
    ]

    // ── Readers ──────────────────────────────────────────────────
    property Process schemeReadProc: Process {
        id: schemeReadProc
        command: ["/bin/sh", "-c", "cat ~/.config/themes/current/scheme_type 2>/dev/null || echo 'scheme-vibrant'"]
        stdout: StdioCollector {
            onStreamFinished: {
                var s = text.trim();
                if (s !== "") {
                    themeService.activeMatugenScheme = s;
                }
            }
        }
    }

    property Process accentReadProc: Process {
        id: accentReadProc
        command: ["/bin/sh", "-c", "cat ~/.config/quickshell/custom-accent 2>/dev/null || echo '#FF2B44'"]
        stdout: StdioCollector {
            onStreamFinished: {
                var acc = text.trim();
                if (acc !== "" && acc.charAt(0) === "#") {
                    themeService.customAccent = acc;
                    Root.Theme.customAccent = acc;
                }
            }
        }
    }

    // ── Executors ────────────────────────────────────────────────
    property Process actionProc: Process {
        id: actionProc
    }

    // Switch between modes. Rule: MUST KEEP AT LEAST ONE ACTIVE.
    // If clicking to toggle the currently active mode, it remains active.
    function setMode(mode) {
        if (mode === activeMode) {
            // Already active. Rule: keep at least one option active at all times.
            return;
        }

        if (mode === "matugen") {
            enableMatugen(activeMatugenScheme);
        } else if (mode === "preset") {
            enablePreset(lastPreset || "md3-cobalt-night");
        } else if (mode === "custom") {
            enableCustom(customAccent || "#FF2B44");
        }
    }

    function enableMatugen(schemeId) {
        if (schemeId && schemeId !== "") {
            activeMatugenScheme = schemeId;
        }
        Root.Theme.currentTheme = "matugen";
        actionProc.command = [
            "/bin/sh", "-c",
            "printf '%s\\n' 'matugen' > ~/.config/quickshell/current-theme && " +
            "/home/zero/.config/themes/apply-matugen.sh '' '' '" + activeMatugenScheme + "'"
        ];
        actionProc.running = true;
    }

    function enablePreset(presetId) {
        if (!presetId || presetId === "") return;
        lastPreset = presetId;
        Root.Theme.currentTheme = presetId;
        actionProc.command = [
            "/bin/sh", "-c",
            "printf '%s\\n' '" + presetId + "' > ~/.config/quickshell/current-theme && " +
            "/home/zero/.config/quickshell/scripts/apply-theme.sh '" + presetId + "'"
        ];
        actionProc.running = true;
    }

    function enableCustom(colorHex) {
        if (!colorHex || colorHex === "") return;
        customAccent = colorHex;
        Root.Theme.customAccent = colorHex;
        Root.Theme.currentTheme = "custom";
        actionProc.command = [
            "/bin/sh", "-c",
            "printf '%s\\n' '" + colorHex + "' > ~/.config/quickshell/custom-accent && " +
            "printf '%s\\n' 'custom' > ~/.config/quickshell/current-theme && " +
            "/home/zero/.config/quickshell/scripts/apply-theme.sh custom"
        ];
        actionProc.running = true;
    }

    // ── Live Matugen palette colors ─────────────────────────────
    property var matugenColors: ({
        primary: "#C7BFFF",
        primaryContainer: "#463F77",
        surfaceContainer: "#201F25",
        tertiary: "#ECB8CE"
    })

    function readPalette() {
        try {
            var raw = paletteReader.text();
            if (!raw || raw.trim() === "") return;
            var parsed = JSON.parse(raw);
            if (parsed && parsed.primary) {
                matugenColors = {
                    primary: parsed.primary,
                    primaryContainer: parsed.primary_container || "#463F77",
                    surfaceContainer: parsed.surface_container || "#201F25",
                    tertiary: parsed.tertiary || "#ECB8CE"
                };
            }
        } catch (e) {
            console.warn("[ThemeService] Error parsing palette.json:", e);
        }
    }

    property QtObject paletteReader: FileView {
        path: "/home/zero/.config/themes/current/palette.json"
        blockLoading: true
        watchChanges: true
        onLoaded: themeService.readPalette()
        onFileChanged: themeService.readPalette()
    }

    Component.onCompleted: {
        schemeReadProc.running = true;
        accentReadProc.running = true;
        readPalette();
    }
}
