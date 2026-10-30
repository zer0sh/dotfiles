pragma Singleton
import QtQuick
import "." as Local

QtObject {
    // Generated palette is available for the next migration step. Manual
    // palettes remain the visual source until this flag is intentionally used.
    readonly property bool matugenPaletteAvailable: Local.MatugenPalette.available

    // ── Active theme name ──────────────────────────────────────────
    property string currentTheme: "matugen"
    property string customAccent: "#FF2B44"

    // ── Theme definitions ──────────────────────────────────────────
    readonly property var _themes: ({
        "md3-cobalt-night": {
            name: "Cobalt Night",
            panelBg: "#0A0A0C", panelBorder: "#26262C", surface: "#121215",
            surfaceContainer: "#18181C", surfaceContainerHigh: "#222226", surfaceBright: "#323238",
            primary: "#9BBDE8", primaryContainer: "#162238", onPrimaryContainer: "#EDEDF2",
            tileActive: "#9BBDE8", tileActiveText: "#0A0A0C",
            tileInactive: "#222226", tileInactiveText: "#EDEDF2",
            sliderTrack: "#222226", sliderActiveTrack: "#9BBDE8", sliderThumb: "#9BBDE8",
            textPrimary: "#EDEDF2", textSecondary: "#9B9BA6",
            toggleOff: "#35353C", connected: "#86D5A0", error: "#F28B82",
            secondaryContainer: "#162238", textOnSecondaryContainer: "#EDEDF2",
            shelfBg: "#0A0A0C"
        },
        "md3-amethyst": {
            name: "Amethyst",
            panelBg: "#0A0A0C", panelBorder: "#26262C", surface: "#121215",
            surfaceContainer: "#18181C", surfaceContainerHigh: "#222226", surfaceBright: "#323238",
            primary: "#C8B0F0", primaryContainer: "#2A1838", onPrimaryContainer: "#EDEDF2",
            tileActive: "#C8B0F0", tileActiveText: "#0A0A0C",
            tileInactive: "#222226", tileInactiveText: "#EDEDF2",
            sliderTrack: "#222226", sliderActiveTrack: "#C8B0F0", sliderThumb: "#C8B0F0",
            textPrimary: "#EDEDF2", textSecondary: "#9B9BA6",
            toggleOff: "#35353C", connected: "#86D0C0", error: "#F5A0A8",
            secondaryContainer: "#2A1838", textOnSecondaryContainer: "#EDEDF2",
            shelfBg: "#0A0A0C"
        },
        "md3-arctic-mist": {
            name: "Arctic Mist",
            panelBg: "#0A0A0C", panelBorder: "#26262C", surface: "#121215",
            surfaceContainer: "#18181C", surfaceContainerHigh: "#222226", surfaceBright: "#323238",
            primary: "#7ECCE8", primaryContainer: "#122A36", onPrimaryContainer: "#EDEDF2",
            tileActive: "#7ECCE8", tileActiveText: "#0A0A0C",
            tileInactive: "#222226", tileInactiveText: "#EDEDF2",
            sliderTrack: "#222226", sliderActiveTrack: "#7ECCE8", sliderThumb: "#7ECCE8",
            textPrimary: "#EDEDF2", textSecondary: "#9B9BA6",
            toggleOff: "#35353C", connected: "#90D4A8", error: "#F2A8A8",
            secondaryContainer: "#122A36", textOnSecondaryContainer: "#EDEDF2",
            shelfBg: "#0A0A0C"
        },
        "md3-crimson-night": {
            name: "Crimson Night",
            panelBg: "#0A0A0C", panelBorder: "#26262C", surface: "#121215",
            surfaceContainer: "#18181C", surfaceContainerHigh: "#222226", surfaceBright: "#323238",
            primary: "#FF2B44", primaryContainer: "#3E0D15", onPrimaryContainer: "#FFDADB",
            tileActive: "#FF2B44", tileActiveText: "#FFFFFF",
            tileInactive: "#222226", tileInactiveText: "#EDEDF2",
            sliderTrack: "#222226", sliderActiveTrack: "#FF2B44", sliderThumb: "#FF2B44",
            textPrimary: "#EDEDF2", textSecondary: "#9B9BA6",
            toggleOff: "#35353C", connected: "#70DF9A", error: "#FF5C6C",
            secondaryContainer: "#381016", textOnSecondaryContainer: "#FFDADB",
            shelfBg: "#0A0A0C"
        },
        "cyberpunk": {
            name: "Cyberpunk",
            panelBg: "#0A0A0C", panelBorder: "#26262C", surface: "#121215",
            surfaceContainer: "#18181C", surfaceContainerHigh: "#222226", surfaceBright: "#323238",
            primary: "#00F5D4", primaryContainer: "#08302A", onPrimaryContainer: "#EDEDF2",
            tileActive: "#00F5D4", tileActiveText: "#0A0A0C",
            tileInactive: "#222226", tileInactiveText: "#EDEDF2",
            sliderTrack: "#222226", sliderActiveTrack: "#00F5D4", sliderThumb: "#00F5D4",
            textPrimary: "#EDEDF2", textSecondary: "#9B9BA6",
            toggleOff: "#35353C", connected: "#B8FF6A", error: "#FF4D8D",
            secondaryContainer: "#08302A", textOnSecondaryContainer: "#EDEDF2",
            shelfBg: "#0A0A0C"
        },
        "matugen": {
            name: "Wallpaper (Matugen)",
            panelBg: "#141318", panelBorder: "#47464F", surface: "#141318",
            surfaceContainer: "#201F25", surfaceContainerHigh: "#2A292F", surfaceBright: "#3A383E",
            primary: "#C7BFFF", primaryContainer: "#463F77", onPrimaryContainer: "#E5DEFF",
            tileActive: "#C7BFFF", tileActiveText: "#2F295F",
            tileInactive: "#2A292F", tileInactiveText: "#E5E1E9",
            sliderTrack: "#2A292F", sliderActiveTrack: "#C7BFFF", sliderThumb: "#C7BFFF",
            textPrimary: "#E5E1E9", textSecondary: "#C9C5D0",
            toggleOff: "#47464F", connected: "#ECB8CE", error: "#FFB4AB",
            secondaryContainer: "#474459", textOnSecondaryContainer: "#E5DFF9",
            shelfBg: "#141318"
        },
        "custom": {
            name: "Custom Accent",
            panelBg: "#0A0A0C", panelBorder: "#26262C", surface: "#121215",
            surfaceContainer: "#18181C", surfaceContainerHigh: "#222226", surfaceBright: "#323238",
            primary: "#FF2B44", primaryContainer: "#2A1820", onPrimaryContainer: "#EDEDF2",
            tileActive: "#FF2B44", tileActiveText: "#FFFFFF",
            tileInactive: "#222226", tileInactiveText: "#EDEDF2",
            sliderTrack: "#222226", sliderActiveTrack: "#FF2B44", sliderThumb: "#FF2B44",
            textPrimary: "#EDEDF2", textSecondary: "#9B9BA6",
            toggleOff: "#35353C", connected: "#70DF9A", error: "#FF5C6C",
            secondaryContainer: "#2A1820", textOnSecondaryContainer: "#EDEDF2",
            shelfBg: "#0A0A0C"
        }
    })

    // ── Custom accent dynamic definition ───────────────────────────
    readonly property var _customTheme: ({
        name: "Custom Accent",
        panelBg: "#0A0A0C", panelBorder: "#26262C", surface: "#121215",
        surfaceContainer: "#18181C", surfaceContainerHigh: "#222226", surfaceBright: "#323238",
        primary: customAccent, primaryContainer: "#2A1820", onPrimaryContainer: "#EDEDF2",
        tileActive: customAccent, tileActiveText: "#FFFFFF",
        tileInactive: "#222226", tileInactiveText: "#EDEDF2",
        sliderTrack: "#222226", sliderActiveTrack: customAccent, sliderThumb: customAccent,
        textPrimary: "#EDEDF2", textSecondary: "#9B9BA6",
        toggleOff: "#35353C", connected: "#70DF9A", error: "#FF5C6C",
        secondaryContainer: "#2A1820", textOnSecondaryContainer: "#EDEDF2",
        shelfBg: "#0A0A0C"
    })

    // ── Active theme reference ─────────────────────────────────────
    readonly property var _generated: Local.MatugenPalette.available ? ({
        name: "Wallpaper (Matugen)",
        panelBg: Local.MatugenPalette.background,
        panelBorder: Local.MatugenPalette.outlineVariant,
        surface: Local.MatugenPalette.surface,
        surfaceContainer: Local.MatugenPalette.surfaceContainer,
        surfaceContainerHigh: Local.MatugenPalette.surfaceContainerHigh,
        surfaceBright: Local.MatugenPalette.surfaceContainerHigh,
        primary: Local.MatugenPalette.primary,
        primaryContainer: Local.MatugenPalette.primaryContainer,
        onPrimaryContainer: Local.MatugenPalette.onSurface,
        tileActive: Local.MatugenPalette.primary,
        // Keep active control labels/icons light, matching the manual themes.
        tileActiveText: Local.MatugenPalette.onPrimary,
        tileInactive: Local.MatugenPalette.surfaceContainerHigh,
        tileInactiveText: Local.MatugenPalette.onSurface,
        sliderTrack: Local.MatugenPalette.surfaceContainerHigh,
        sliderActiveTrack: Local.MatugenPalette.primary,
        sliderThumb: Local.MatugenPalette.primary,
        textPrimary: Local.MatugenPalette.onSurface,
        textSecondary: Local.MatugenPalette.onSurfaceVariant,
        toggleOff: Local.MatugenPalette.outlineVariant,
        connected: Local.MatugenPalette.tertiary,
        error: Local.MatugenPalette.error,
        secondaryContainer: Local.MatugenPalette.surfaceContainerHigh,
        textOnSecondaryContainer: Local.MatugenPalette.onSurface,
        shelfBg: Local.MatugenPalette.background
    }) : null
    readonly property var _t: (currentTheme === "matugen" && _generated)
        ? _generated
        : (currentTheme === "custom"
            ? _customTheme
            : (_themes[currentTheme] || _themes["md3-cobalt-night"]))

    // ── Themed color properties ────────────────────────────────────
    // Surface colors
    readonly property color panelBg: _t.panelBg
    readonly property color panelBorder: _t.panelBorder
    readonly property color surface: _t.surface
    readonly property color surfaceContainer: _t.surfaceContainer
    readonly property color surfaceContainerHigh: _t.surfaceContainerHigh
    readonly property color surfaceBright: _t.surfaceBright

    // Primary colors
    readonly property color primary: _t.primary
    readonly property color primaryContainer: _t.primaryContainer
    readonly property color textOnPrimaryContainer: currentTheme === "matugen"
        ? "#E5E1E9" : _t.onPrimaryContainer

    // Secondary colors
    readonly property color secondaryContainer: _t.secondaryContainer
    readonly property color textOnSecondaryContainer: currentTheme === "matugen"
        ? "#E5E1E9" : _t.textOnSecondaryContainer

    // Tile states
    readonly property color tileActive: _t.tileActive
    readonly property color tileActiveText: _t.tileActiveText
    readonly property color tileInactive: _t.tileInactive
    readonly property color tileInactiveText: currentTheme === "matugen"
        ? "#E5E1E9" : _t.tileInactiveText

    // Slider colors
    readonly property color sliderTrack: _t.sliderTrack
    readonly property color sliderActiveTrack: _t.sliderActiveTrack
    readonly property color sliderThumb: _t.sliderThumb

    // Text colors
    readonly property color textPrimary: currentTheme === "matugen"
        ? "#E5E1E9" : _t.textPrimary
    readonly property color textSecondary: currentTheme === "matugen"
        ? "#C9C5D0" : _t.textSecondary

    // Semantic colors
    readonly property color connected: _t.connected
    readonly property color error: _t.error
    readonly property color toggleOff: _t.toggleOff

    // Shelf
    readonly property color _shelfBgColor: _t.shelfBg
    readonly property color shelfBg: Qt.rgba(_shelfBgColor.r, _shelfBgColor.g, _shelfBgColor.b, 0.85)

    // ── Backward-compatible aliases ────────────────────────────────
    // Used by shelf, controlcenter, and other modules
    readonly property color bg: panelBg
    readonly property color accent: primary
    readonly property color surfaceHigh: surfaceBright
    readonly property color hoverOverlay: Qt.rgba(1, 1, 1, 0.08)
    readonly property color textDisabled: Qt.rgba(textSecondary.r, textSecondary.g, textSecondary.b, 0.35)
    readonly property color outline: panelBorder
    readonly property color outlineVariant: toggleOff

    // ── Font properties ────────────────────────────────────────────
    readonly property string fontFamily: "Google Sans"
    readonly property string iconFont: "Material Symbols Rounded"
    readonly property int fontSizeNormal: 15
    readonly property int fontSizeLarge: 19
    readonly property int fontSizeXL: 28
    readonly property int fontSizeSmall: 13
    readonly property int fontSizeXS: 11

    // ── Spacing ────────────────────────────────────────────────────
    // One UI-inspired geometry: generous spacing and pill-like surfaces.
    readonly property int radiusSmall: 16
    readonly property int radiusLarge: 24
    readonly property int paddingNormal: 14
    readonly property int paddingLarge: 20
    readonly property int padding: 18
    readonly property int paddingSmall: 10

    // ── Shelf-specific ─────────────────────────────────────────────
    readonly property int shelfHeight: 36

    // ── Layout constants ───────────────────────────────────────────
    readonly property int panelWidth: 880
    readonly property int panelRadius: 32
    readonly property int tileRadius: 22
    readonly property int tileHeight: 70
    readonly property int sliderHeight: 28

    // ── Spacing scale ──────────────────────────────────────────────
    readonly property int spacingSmall: 10
    readonly property int spacingMedium: 14
    readonly property int spacingLarge: 18

     // ── Animation durations (ms) ───────────────────────────────────
    readonly property int animDuration: 0
    readonly property int animDurationFast: 0

    // ── Theme metadata access ──────────────────────────────────────
    readonly property string themeName: _t.name
    readonly property var themeKeys: Object.keys(_themes)
}
