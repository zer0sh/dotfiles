import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../.." as Root

Scope {
    id: root

    property bool menuOpen: false
    property int selectedIndex: 0
    property int hoveredIndex: -1
    readonly property int buttonCount: menuItems.length

    property var menuWindowRef: null

    readonly property int activeIndex: hoveredIndex >= 0 ? hoveredIndex : selectedIndex

    // Material 3 Menu Actions
    readonly property var menuItems: [
        {
            icon: "power_settings_new",
            label: "Shut Down",
            desc: "Turn off computer safely",
            key: "S",
            isDanger: true,
            action: function() { shutdownProc.startDetached(); }
        },
        {
            icon: "restart_alt",
            label: "Restart",
            desc: "Reboot desktop system",
            key: "R",
            isDanger: false,
            action: function() { rebootProc.startDetached(); }
        },
        {
            icon: "logout",
            label: "Log Out",
            desc: "End current session",
            key: "E",
            isDanger: false,
            action: function() { logoutProc.startDetached(); }
        },
        {
            icon: "lock",
            label: "Lock Screen",
            desc: "Secure workstation",
            key: "L",
            isDanger: false,
            action: function() { lockProc.startDetached(); }
        },
        {
            icon: "refresh",
            label: "Reload Desktop",
            desc: "Restart Hyprland environment",
            key: "O",
            isDanger: false,
            action: function() { reloadProc.startDetached(); }
        }
    ]

    onMenuOpenChanged: {
        if (menuOpen) {
            selectedIndex = 0;
            hoveredIndex = -1;
        }
    }

    Loader {
        active: root.menuOpen

        sourceComponent: PanelWindow {
            id: menuWindow
            visible: true

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "quickshell:powermenu"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            color: "transparent"

            Component.onCompleted: {
                root.menuWindowRef = menuWindow;
            }

            function closeMenu(): void {
                edgePanelWrapper.close();
            }

            Shortcut {
                sequence: "Escape"
                onActivated: menuWindow.closeMenu()
            }

            // Centralized EdgePanel parent component (VolumeOSD physics)
            Root.EdgePanel {
                id: edgePanelWrapper
                edge: "right"
                panelWidth: 310
                panelHeight: contentCol.implicitHeight + 100
                shoulderRadius: 32
                onCloseRequested: menuWindow.closeMenu()
                onClosed: {
                    root.menuOpen = false;
                    root.menuWindowRef = null;
                }

                // Internal Content Column with comfortable padding
                ColumnLayout {
                    id: contentCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 22
                    anchors.rightMargin: 18
                    spacing: 16

                    // ── Material 3 Header ──
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 14

                        Rectangle {
                            Layout.preferredWidth: 44
                            Layout.preferredHeight: 44
                            radius: 22
                            color: Qt.rgba(Root.Theme.primary.r, Root.Theme.primary.g, Root.Theme.primary.b, 0.18)

                            Text {
                                anchors.centerIn: parent
                                text: "power_settings_new"
                                font.family: Root.Theme.iconFont
                                font.pixelSize: 24
                                color: Root.Theme.primary
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                text: "Power & Session"
                                font.family: Root.Theme.fontFamily
                                font.pixelSize: 18
                                font.weight: Font.Bold
                                color: Root.Theme.textPrimary
                            }

                            Text {
                                text: "Choose a system action"
                                font.family: Root.Theme.fontFamily
                                font.pixelSize: 12
                                color: Root.Theme.textSecondary
                            }
                        }
                    }

                    // Divider line
                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: Qt.rgba(255, 255, 255, 0.08)
                    }

                    // ── Action Buttons List ──
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Repeater {
                            model: root.menuItems

                            delegate: Rectangle {
                                id: actionTile
                                Layout.fillWidth: true
                                Layout.preferredHeight: 60
                                radius: 18

                                readonly property bool isSelected: root.activeIndex === index
                                readonly property bool isHovered: tileMouse.containsMouse
                                readonly property bool isDanger: modelData.isDanger

                                color: isSelected
                                    ? (isDanger ? Root.Theme.error : Root.Theme.primary)
                                    : (isHovered
                                        ? Qt.rgba(255, 255, 255, 0.12)
                                        : Qt.rgba(255, 255, 255, 0.05))

                                border.width: 1
                                border.color: isSelected
                                    ? (isDanger ? Root.Theme.error : Root.Theme.primary)
                                    : (isHovered ? Qt.rgba(255, 255, 255, 0.18) : Qt.rgba(255, 255, 255, 0.08))

                                scale: tileMouse.pressed ? 0.98 : (isHovered || isSelected ? 1.02 : 1.0)
                                Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                                Behavior on color { ColorAnimation { duration: Root.Theme.animDurationFast } }
                                Behavior on border.color { ColorAnimation { duration: Root.Theme.animDurationFast } }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 14
                                    anchors.rightMargin: 14
                                    spacing: 14

                                    // Leading icon badge
                                    Rectangle {
                                        Layout.preferredWidth: 40
                                        Layout.preferredHeight: 40
                                        radius: 20
                                        color: actionTile.isSelected
                                            ? Qt.rgba(0, 0, 0, 0.18)
                                            : (actionTile.isDanger
                                                ? Qt.rgba(Root.Theme.error.r, Root.Theme.error.g, Root.Theme.error.b, 0.18)
                                                : Qt.rgba(Root.Theme.primary.r, Root.Theme.primary.g, Root.Theme.primary.b, 0.15))

                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.icon
                                            font.family: Root.Theme.iconFont
                                            font.pixelSize: 22
                                            color: actionTile.isSelected
                                                ? (actionTile.isDanger ? "#FFFFFF" : Root.Theme.tileActiveText)
                                                : (actionTile.isDanger ? Root.Theme.error : Root.Theme.primary)
                                        }
                                    }

                                    // Title + Subtitle
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2

                                        Text {
                                            text: modelData.label
                                            font.family: Root.Theme.fontFamily
                                            font.pixelSize: 15
                                            font.weight: Font.DemiBold
                                            color: actionTile.isSelected
                                                ? (actionTile.isDanger ? "#FFFFFF" : Root.Theme.tileActiveText)
                                                : Root.Theme.textPrimary
                                        }

                                        Text {
                                            text: modelData.desc
                                            font.family: Root.Theme.fontFamily
                                            font.pixelSize: 12
                                            color: actionTile.isSelected
                                                ? (actionTile.isDanger ? Qt.rgba(1, 1, 1, 0.85) : Qt.rgba(Root.Theme.tileActiveText.r, Root.Theme.tileActiveText.g, Root.Theme.tileActiveText.b, 0.80))
                                                : Root.Theme.textSecondary
                                        }
                                    }

                                    // Trailing keyboard hint
                                    Rectangle {
                                        Layout.preferredWidth: 26
                                        Layout.preferredHeight: 26
                                        radius: 8
                                        color: actionTile.isSelected
                                            ? Qt.rgba(0, 0, 0, 0.20)
                                            : Qt.rgba(255, 255, 255, 0.08)

                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.key
                                            font.family: Root.Theme.fontFamily
                                            font.pixelSize: 12
                                            font.weight: Font.Bold
                                            color: actionTile.isSelected
                                                ? (actionTile.isDanger ? "#FFFFFF" : Root.Theme.tileActiveText)
                                                : Root.Theme.textSecondary
                                        }
                                    }
                                }

                                MouseArea {
                                    id: tileMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onEntered: root.hoveredIndex = index
                                    onExited: if (root.hoveredIndex === index) root.hoveredIndex = -1
                                    onClicked: {
                                        modelData.action();
                                        menuWindow.closeMenu();
                                    }
                                }
                            }
                        }
                    }

                    // ── Subtle Footer Hint ──
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 4
                        spacing: 6

                        Text {
                            text: "keyboard"
                            font.family: Root.Theme.iconFont
                            font.pixelSize: 14
                            color: Root.Theme.textSecondary
                        }

                        Text {
                            text: "Press Esc to dismiss"
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: 12
                            color: Root.Theme.textSecondary
                        }
                    }
                }
            }

            // Keyboard navigation handler
            Item {
                id: keyHandler
                focus: true
                Component.onCompleted: forceActiveFocus()

                Keys.onPressed: (event) => {
                    if (event.key === Qt.Key_Escape) {
                        menuWindow.closeMenu();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Up ||
                               (event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier))) {
                        root.selectedIndex = (root.selectedIndex - 1 + root.buttonCount) % root.buttonCount;
                        root.hoveredIndex = -1;
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab) {
                        root.selectedIndex = (root.selectedIndex + 1) % root.buttonCount;
                        root.hoveredIndex = -1;
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter ||
                               event.key === Qt.Key_Space) {
                        if (root.selectedIndex >= 0 && root.selectedIndex < root.menuItems.length) {
                            root.menuItems[root.selectedIndex].action();
                        }
                        menuWindow.closeMenu();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_S) {
                        shutdownProc.startDetached();
                        menuWindow.closeMenu();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_R) {
                        rebootProc.startDetached();
                        menuWindow.closeMenu();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_L) {
                        lockProc.startDetached();
                        menuWindow.closeMenu();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_E) {
                        logoutProc.startDetached();
                        menuWindow.closeMenu();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_O) {
                        reloadProc.startDetached();
                        menuWindow.closeMenu();
                        event.accepted = true;
                    }
                }
            }
        }
    }

    // Process definitions outside Loader so they persist for startDetached calls
    Process { id: shutdownProc; command: ["systemctl", "poweroff"] }
    Process { id: rebootProc;   command: ["systemctl", "reboot"] }
    Process { id: logoutProc;   command: ["hyprctl", "dispatch", "exit"] }
    Process { id: lockProc;     command: ["hyprlock"] }
    Process { id: reloadProc;   command: ["/bin/bash", "-c", "$HOME/.config/hypr/scripts/reload-hyprland"] }

    IpcHandler {
        target: "powermenu"
        function toggle(): void {
            if (root.menuOpen) {
                if (root.menuWindowRef) {
                    root.menuWindowRef.closeMenu();
                } else {
                    root.menuOpen = false;
                }
            } else {
                root.menuOpen = true;
            }
        }
        function open(): void   { root.menuOpen = true; }
        function close(): void  {
            if (root.menuWindowRef) {
                root.menuWindowRef.closeMenu();
            } else {
                root.menuOpen = false;
            }
        }
    }
}
