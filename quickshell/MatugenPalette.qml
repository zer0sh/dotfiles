pragma Singleton
import QtQuick
import Quickshell.Io

// Read-only bridge for the centralized palette. Theme.qml can use this as a
// generated-theme source while retaining its manual palettes as fallback.
QtObject {
    id: palette

    property var data: ({})
    readonly property bool available: Object.keys(data).length > 0

    readonly property color background: data.background || "#0F1117"
    readonly property color surface: data.surface || "#1A1C28"
    readonly property color surfaceContainer: data.surface_container || "#252740"
    readonly property color surfaceContainerHigh: data.surface_container_high || "#2E3148"
    readonly property color primary: data.primary || "#9BBDE8"
    readonly property color primaryContainer: data.primary_container || "#1E3058"
    readonly property color onPrimary: data.on_primary || "#0F1117"
    readonly property color onSurface: data.on_surface || "#E0E2F0"
    readonly property color onSurfaceVariant: data.on_surface_variant || "#8E90A8"
    readonly property color outline: data.outline || "#404460"
    readonly property color outlineVariant: data.outline_variant || "#2E3148"
    readonly property color error: data.error || "#F2A8B8"
    readonly property color tertiary: data.tertiary || "#86D5A0"

    function readPalette() {
        try {
            var parsed = JSON.parse(fileReader.text());
            if (parsed && parsed.primary && parsed.background) {
                data = parsed;
            }
        } catch (error) {
            console.warn("Matugen palette is unavailable:", error);
        }
    }

    property QtObject fileReader: FileView {
        path: "/home/zero/.config/themes/current/palette.json"
        blockLoading: true
        watchChanges: true
        onLoaded: palette.readPalette()
        onFileChanged: reload()
    }
}
