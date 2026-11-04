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
    readonly property int buttonCount: 5

    property var menuWindowRef: null

    readonly property int activeIndex: hoveredIndex >= 0 ? hoveredIndex : selectedIndex

    readonly property var buttonLabels: [
        "Shutdown",
        "Reboot",
        "Logout",
        "Lock",
        "Reload"
    ]

    readonly property string activeLabel: (activeIndex >= 0 && activeIndex < buttonLabels.length)
        ? buttonLabels[activeIndex]
        : ""

    readonly property bool activeIsError: activeIndex === 0

    // Reset selection whenever the menu opens
    onMenuOpenChanged: {
        if (menuOpen) {
            selectedIndex = 0
            hoveredIndex = -1
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
                root.menuWindowRef = menuWindow
                appearAnim.start()
            }

            function closeMenu(): void {
                if (!dismissAnim.running) {
                    appearAnim.stop()
                    dismissAnim.start()
                }
            }

            // Dim overlay — dismisses on click-outside
            Rectangle {
                id: dimOverlay
                anchors.fill: parent
                color: Qt.rgba(0, 0, 0, 0.35)
                opacity: 0

                ParallelAnimation {
                    id: appearAnim
                    NumberAnimation {
                        target: dimOverlay; property: "opacity"
                        from: 0.0; to: 1.0; duration: 200; easing.type: Easing.OutQuad
                    }
                    NumberAnimation {
                        target: sidePanel; property: "_slideX"
                        from: sidePanel.width + 40; to: 0; duration: 260
                        easing.type: Easing.OutCubic
                    }
                    NumberAnimation {
                        target: sidePanel; property: "opacity"
                        from: 0.0; to: 1.0; duration: 200; easing.type: Easing.OutQuad
                    }
                }

                SequentialAnimation {
                    id: dismissAnim
                    ParallelAnimation {
                        NumberAnimation {
                            target: dimOverlay; property: "opacity"
                            to: 0.0; duration: 180; easing.type: Easing.InQuad
                        }
                        NumberAnimation {
                            target: sidePanel; property: "_slideX"
                            to: sidePanel.width + 40; duration: 220
                            easing.type: Easing.InCubic
                        }
                        NumberAnimation {
                            target: sidePanel; property: "opacity"
                            to: 0.0; duration: 180; easing.type: Easing.InQuad
                        }
                    }
                    ScriptAction {
                        script: {
                            root.menuOpen = false
                            root.menuWindowRef = null
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: menuWindow.closeMenu()
                }
            }

            // Vertical power menu container exiting/entering from the right edge
            Item {
                id: sidePanel
                property real _slideX: width + 40

                anchors.right: parent.right
                anchors.rightMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                width: 72
                height: cardContent.implicitHeight + 20

                transform: Translate {
                    x: sidePanel._slideX
                }

                // Interactive action label pill floating to the left of the active button
                Rectangle {
                    id: labelPill
                    anchors.right: parent.left
                    anchors.rightMargin: 12
                    y: cardContent.y + (root.activeIndex * (52 + cardContent.spacing)) + (52 - height) / 2
                    width: pillText.implicitWidth + 24
                    height: 28
                    radius: 14
                    color: Qt.rgba(Root.Theme.surfaceContainerHigh.r,
                                   Root.Theme.surfaceContainerHigh.g,
                                   Root.Theme.surfaceContainerHigh.b, 0.95)
                    border.color: root.activeIsError ? Root.Theme.error : Root.Theme.panelBorder
                    border.width: 1
                    opacity: (root.activeLabel !== "" && sidePanel.opacity > 0.4) ? 1.0 : 0.0

                    Behavior on opacity { NumberAnimation { duration: 150 } }
                    Behavior on y { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                    Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    Text {
                        id: pillText
                        anchors.centerIn: parent
                        text: root.activeLabel
                        font.family: Root.Theme.fontFamily
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        color: root.activeIsError ? Root.Theme.error : Root.Theme.textPrimary
                    }
                }

                // Main vertical card
                Rectangle {
                    id: panelCard
                    anchors.fill: parent
                    radius: 24
                    color: Qt.rgba(Root.Theme.panelBg.r,
                                   Root.Theme.panelBg.g,
                                   Root.Theme.panelBg.b, 0.85)
                    border.color: Root.Theme.primary
                    border.width: 2

                    // Prevent click-through to dismiss overlay
                    MouseArea {
                        anchors.fill: parent
                    }

                    // Vertical button list
                    ColumnLayout {
                        id: cardContent
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8

                        PowerButton {
                            icon: "󰐥"
                            label: "Shutdown"
                            isError: true
                            selected: root.selectedIndex === 0
                            onHovered: root.hoveredIndex = 0
                            onUnhovered: if (root.hoveredIndex === 0) root.hoveredIndex = -1
                            onClicked: {
                                shutdownProc.startDetached()
                                menuWindow.closeMenu()
                            }
                        }

                        PowerButton {
                            icon: "󰜉"
                            label: "Reboot"
                            selected: root.selectedIndex === 1
                            onHovered: root.hoveredIndex = 1
                            onUnhovered: if (root.hoveredIndex === 1) root.hoveredIndex = -1
                            onClicked: {
                                rebootProc.startDetached()
                                menuWindow.closeMenu()
                            }
                        }

                        PowerButton {
                            icon: "󰍃"
                            label: "Logout"
                            selected: root.selectedIndex === 2
                            onHovered: root.hoveredIndex = 2
                            onUnhovered: if (root.hoveredIndex === 2) root.hoveredIndex = -1
                            onClicked: {
                                logoutProc.startDetached()
                                menuWindow.closeMenu()
                            }
                        }

                        PowerButton {
                            icon: "󰌾"
                            label: "Lock"
                            selected: root.selectedIndex === 3
                            onHovered: root.hoveredIndex = 3
                            onUnhovered: if (root.hoveredIndex === 3) root.hoveredIndex = -1
                            onClicked: {
                                lockProc.startDetached()
                                menuWindow.closeMenu()
                            }
                        }

                        PowerButton {
                            icon: "󰜈"
                            label: "Reload"
                            selected: root.selectedIndex === 4
                            onHovered: root.hoveredIndex = 4
                            onUnhovered: if (root.hoveredIndex === 4) root.hoveredIndex = -1
                            onClicked: {
                                reloadProc.startDetached()
                                menuWindow.closeMenu()
                            }
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
                        menuWindow.closeMenu()
                        event.accepted = true
                    } else if (event.key === Qt.Key_Up ||
                               (event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier))) {
                        root.selectedIndex = (root.selectedIndex - 1 + root.buttonCount) % root.buttonCount
                        root.hoveredIndex = -1
                        event.accepted = true
                    } else if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab) {
                        root.selectedIndex = (root.selectedIndex + 1) % root.buttonCount
                        root.hoveredIndex = -1
                        event.accepted = true
                    } else if (event.key === Qt.Key_Left) {
                        root.selectedIndex = (root.selectedIndex - 1 + root.buttonCount) % root.buttonCount
                        root.hoveredIndex = -1
                        event.accepted = true
                    } else if (event.key === Qt.Key_Right) {
                        root.selectedIndex = (root.selectedIndex + 1) % root.buttonCount
                        root.hoveredIndex = -1
                        event.accepted = true
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter ||
                               event.key === Qt.Key_Space) {
                        switch (root.selectedIndex) {
                            case 0: shutdownProc.startDetached(); break
                            case 1: rebootProc.startDetached(); break
                            case 2: logoutProc.startDetached(); break
                            case 3: lockProc.startDetached(); break
                            case 4: reloadProc.startDetached(); break
                        }
                        menuWindow.closeMenu()
                        event.accepted = true
                    } else if (event.key === Qt.Key_S) {
                        shutdownProc.startDetached()
                        menuWindow.closeMenu()
                        event.accepted = true
                    } else if (event.key === Qt.Key_R) {
                        rebootProc.startDetached()
                        menuWindow.closeMenu()
                        event.accepted = true
                    } else if (event.key === Qt.Key_L) {
                        lockProc.startDetached()
                        menuWindow.closeMenu()
                        event.accepted = true
                    } else if (event.key === Qt.Key_E) {
                        logoutProc.startDetached()
                        menuWindow.closeMenu()
                        event.accepted = true
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
    Process { id: reloadProc;   command: ["hyprctl", "reload"] }

    IpcHandler {
        target: "powermenu"
        function toggle(): void {
            if (root.menuOpen) {
                if (root.menuWindowRef) {
                    root.menuWindowRef.closeMenu()
                } else {
                    root.menuOpen = false
                }
            } else {
                root.menuOpen = true
            }
        }
        function open(): void   { root.menuOpen = true; }
        function close(): void  {
            if (root.menuWindowRef) {
                root.menuWindowRef.closeMenu()
            } else {
                root.menuOpen = false
            }
        }
    }
}
