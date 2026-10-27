import Quickshell
import QtQuick
import Quickshell.Io

import "modules/powermenu" as PowerMenu
import "modules/controlcenter" as ControlCenter
import "modules/notifications" as Notifications
import "modules/clipboard" as Clipboard
import "modules/launcher" as Launcher
import "modules/osd" as Osd
import "modules/shortcuts" as Shortcuts
import "modules/deskclock" as DeskClock
import "modules/calendar" as Calendar
import "modules/background" as Background
import "modules/weathergadget" as WeatherGadget
import "modules/overview" as Overview
import "modules/mediaselector" as MediaSelector

ShellRoot {
    id: root

    // ── Theme persistence — read saved theme on startup ──────────
    Process {
        id: themeReadProc
        command: ["/bin/sh", "-c", "cat ~/.config/quickshell/current-theme 2>/dev/null || true"]
        stdout: StdioCollector {
            onStreamFinished: {
                var theme = text.trim();
                if (theme !== "" && Theme._themes[theme] !== undefined) {
                    Theme.currentTheme = theme;
                }
            }
        }
    }

    Process {
        id: customAccentReadProc
        command: ["/bin/sh", "-c", "cat ~/.config/quickshell/custom-accent 2>/dev/null || true"]
        stdout: StdioCollector {
            onStreamFinished: {
                var acc = text.trim();
                if (acc !== "" && acc.charAt(0) === "#") {
                    Theme.customAccent = acc;
                }
            }
        }
    }

    Component.onCompleted: {
        themeReadProc.running = true
        customAccentReadProc.running = true
        var _ = Notifications.NotificationService.count
        var _gm = GadgetsManager.availableGadgets
    }

    FontLoader {
        source: "fonts/MaterialSymbolsRounded.ttf"
    }

    // --- Module Instances ---
    // Each component manages its own visibility and IPC handler internally.
    // Nothing auto-opens on startup.

    Background.Background {
        id: desktopBackground
        onRequestWallpaperPicker: appLauncher.openWallpapers()
    }

    PowerMenu.PowerMenu {
        id: powerMenu
    }

    ControlCenter.ControlCenter {
        id: controlCenter
        powerMenuRef: powerMenu
    }

    // Eagerly instantiate NotificationService singleton
    readonly property var notifService: Notifications.NotificationService

    Notifications.NotificationToastLayer {
        id: notificationToasts
    }

    Clipboard.ClipboardPanel {
        id: clipboardPanel
    }

    Launcher.Launcher {
        id: appLauncher
        backgroundRef: desktopBackground
    }

    Osd.VolumeOsd {
        id: volumeOsd
    }

    Osd.BrightnessOsd {
        id: brightnessOsd
    }

    Osd.MusicOsd {
        id: musicOsd
        miniPlayerRef: appLauncher
    }

    Osd.RecordingIndicator {
        id: recordingIndicator
    }

    Shortcuts.ShortcutsOverlay {
        id: shortcutsOverlay
    }

    DeskClock.DeskClock {
        id: deskClock
    }

    Calendar.Calendar {
        id: calendar
    }

    WeatherGadget.WeatherGadget {
        id: weatherGadget
    }

    Overview.Overview {
        id: desktopOverview
    }

    MediaSelector.MediaSelector {
        id: mediaSelector
    }

    // --- Mutual Exclusivity ---

    Connections {
        target: powerMenu
        function onMenuOpenChanged() {
            if (powerMenu.menuOpen) {
                controlCenter.panelVisible = false;
                appLauncher.panelVisible = false;
                clipboardPanel.panelVisible = false;
                desktopOverview.visible = false;
            }
        }
    }

    Connections {
        target: controlCenter
        function onPanelVisibleChanged() {
            if (controlCenter.panelVisible) {
                powerMenu.menuOpen = false;
                appLauncher.panelVisible = false;
                clipboardPanel.panelVisible = false;
                desktopOverview.visible = false;
            }
        }
    }

    Connections {
        target: appLauncher
        function onPanelVisibleChanged() {
            if (appLauncher.panelVisible) {
                powerMenu.menuOpen = false;
                controlCenter.panelVisible = false;
                clipboardPanel.panelVisible = false;
                desktopOverview.visible = false;
            }
        }
    }

    Connections {
        target: clipboardPanel
        function onPanelVisibleChanged() {
            if (clipboardPanel.panelVisible) {
                powerMenu.menuOpen = false;
                controlCenter.panelVisible = false;
                appLauncher.panelVisible = false;
                desktopOverview.visible = false;
            }
        }
    }

    Connections {
        target: desktopOverview
        function onVisibleChanged() {
            if (desktopOverview.visible) {
                powerMenu.menuOpen = false;
                controlCenter.panelVisible = false;
                appLauncher.panelVisible = false;
                clipboardPanel.panelVisible = false;
            }
        }
    }

}
