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

    Component.onCompleted: themeReadProc.running = true

    // --- Module Instances ---
    // Each component manages its own visibility and IPC handler internally.
    // Nothing auto-opens on startup.

    PowerMenu.PowerMenu {
        id: powerMenu
    }

    ControlCenter.ControlCenter {
        id: controlCenter
        powerMenuRef: powerMenu
    }

    Notifications.NotificationCenter {
        id: notificationCenter
    }

    Notifications.NotificationToastLayer {
        id: notificationToasts
    }

    Clipboard.ClipboardPanel {
        id: clipboardPanel
    }

    Launcher.Launcher {
        id: appLauncher
    }

    Osd.VolumeOsd {
        id: volumeOsd
    }

    Osd.BrightnessOsd {
        id: brightnessOsd
    }

    Osd.MusicOsd {
        id: musicOsd
        miniPlayerRef: miniPlayer
    }

    Osd.MiniPlayer {
        id: miniPlayer
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

    // --- Mutual Exclusivity ---

    Connections {
        target: powerMenu
        function onMenuOpenChanged() {
            if (powerMenu.menuOpen) {
                controlCenter.panelVisible = false;
                notificationCenter.panelVisible = false;
                appLauncher.panelVisible = false;
                clipboardPanel.panelVisible = false;
            }
        }
    }

    Connections {
        target: controlCenter
        function onPanelVisibleChanged() {
            if (controlCenter.panelVisible) {
                powerMenu.menuOpen = false;
                notificationCenter.panelVisible = false;
                appLauncher.panelVisible = false;
                clipboardPanel.panelVisible = false;
            }
        }
    }

    Connections {
        target: notificationCenter
        function onPanelVisibleChanged() {
            if (notificationCenter.panelVisible) {
                powerMenu.menuOpen = false;
                controlCenter.panelVisible = false;
                appLauncher.panelVisible = false;
                clipboardPanel.panelVisible = false;
            }
        }
    }

    Connections {
        target: appLauncher
        function onPanelVisibleChanged() {
            if (appLauncher.panelVisible) {
                powerMenu.menuOpen = false;
                controlCenter.panelVisible = false;
                notificationCenter.panelVisible = false;
                clipboardPanel.panelVisible = false;
            }
        }
    }

    Connections {
        target: clipboardPanel
        function onPanelVisibleChanged() {
            if (clipboardPanel.panelVisible) {
                powerMenu.menuOpen = false;
                controlCenter.panelVisible = false;
                notificationCenter.panelVisible = false;
                appLauncher.panelVisible = false;
            }
        }
    }

}
