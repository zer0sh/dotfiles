import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../.." as Root

Scope {
    id: root

    property bool menuOpen: false
    property int selectedIndex: -1
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
            selectedIndex = -1;
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
                appearAnim.start();
            }

            function closeMenu(): void {
                if (!dismissAnim.running) {
                    appearAnim.stop();
                    dismissAnim.start();
                }
            }

            Shortcut {
                sequence: "Escape"
                onActivated: menuWindow.closeMenu()
            }

            // Dim overlay — dismisses on click-outside
            Rectangle {
                id: dimOverlay
                anchors.fill: parent
                color: Qt.rgba(0, 0, 0, 0.40)
                opacity: 0.0

                MouseArea {
                    anchors.fill: parent
                    onClicked: menuWindow.closeMenu()
                }
            }

            // dots-hyprland Expressive Spatial spring slide and bounce (identical to ControlCenter)
            ParallelAnimation {
                id: appearAnim
                NumberAnimation {
                    target: dimOverlay; property: "opacity"
                    from: 0.0; to: 1.0; duration: Root.Theme.animDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Root.Theme.curveEmphasizedDecel
                }
                NumberAnimation {
                    target: sidePanel; property: "_slideX"
                    from: sidePanel.width + 60; to: 0; duration: Root.Theme.animDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Root.Theme.curvePanelOpen
                }
                NumberAnimation {
                    target: sidePanel; property: "_scalePrimary"
                    from: 0.74; to: 1.0; duration: Root.Theme.animDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Root.Theme.curvePanelOpen
                }
                NumberAnimation {
                    target: sidePanel; property: "_scaleSecondary"
                    from: 0.86; to: 1.0; duration: Root.Theme.animDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Root.Theme.curvePanelOpen
                }
                NumberAnimation {
                    target: sidePanel; property: "opacity"
                    from: 0.0; to: 1.0; duration: 200
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Root.Theme.curveEmphasizedDecel
                }
                NumberAnimation {
                    target: sidePanel; property: "_contentScale"
                    from: 0.92; to: 1.0; duration: Root.Theme.animDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Root.Theme.curvePanelOpen
                }
            }

            // dots-hyprland Emphasized Accel close
            SequentialAnimation {
                id: dismissAnim
                ParallelAnimation {
                    NumberAnimation {
                        target: dimOverlay; property: "opacity"
                        to: 0.0; duration: Root.Theme.animDurationFast
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Root.Theme.curvePanelClose
                    }
                    NumberAnimation {
                        target: sidePanel; property: "_slideX"
                        to: sidePanel.width + 60; duration: Root.Theme.animDurationFast
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Root.Theme.curvePanelClose
                    }
                    NumberAnimation {
                        target: sidePanel; property: "_scalePrimary"
                        to: 0.74; duration: Root.Theme.animDurationFast
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Root.Theme.curvePanelClose
                    }
                    NumberAnimation {
                        target: sidePanel; property: "_scaleSecondary"
                        to: 0.86; duration: Root.Theme.animDurationFast
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Root.Theme.curvePanelClose
                    }
                    NumberAnimation {
                        target: sidePanel; property: "_contentScale"
                        to: 0.92; duration: Root.Theme.animDurationFast
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Root.Theme.curvePanelClose
                    }
                    NumberAnimation {
                        target: sidePanel; property: "opacity"
                        to: 0.0; duration: Root.Theme.animDurationFast
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Root.Theme.curvePanelClose
                    }
                }
                ScriptAction {
                    script: {
                        root.menuOpen = false;
                        root.menuWindowRef = null;
                    }
                }
            }

            // Floating power menu container with concentric geometry
            Item {
                id: sidePanel
                property real _slideX: width + 50
                property real _scalePrimary: 0.74
                property real _scaleSecondary: 0.86
                property real _contentScale: 0.92

                anchors.right: parent.right
                anchors.rightMargin: 20
                anchors.verticalCenter: parent.verticalCenter
                width: 72
                height: contentCol.implicitHeight + 20
                opacity: 0.0

                transformOrigin: Item.Right
                transform: [
                    Translate {
                        x: sidePanel._slideX
                    },
                    Scale {
                        origin.x: sidePanel.width
                        origin.y: sidePanel.height / 2
                        xScale: sidePanel._scalePrimary
                        yScale: sidePanel._scaleSecondary
                    }
                ]

                // Interactive action label pill floating to the left of the active button
                Rectangle {
                    id: actionPill
                    visible: root.activeIndex >= 0
                    opacity: root.activeIndex >= 0 ? 1 : 0
                    y: (root.activeIndex >= 0) ? (14 + root.activeIndex * 62) : 0
                    anchors.right: panelCard.left
                    anchors.rightMargin: 12
                    height: 44
                    width: pillText.implicitWidth + 24
                    radius: 22
                    color: Qt.rgba(Root.Theme.panelBg.r,
                                   Root.Theme.panelBg.g,
                                   Root.Theme.panelBg.b, 0.90)
                    border.color: (root.activeIndex >= 0 && root.menuItems[root.activeIndex].isDanger)
                                  ? Root.Theme.error
                                  : Qt.rgba(Root.Theme.primary.r,
                                            Root.Theme.primary.g,
                                            Root.Theme.primary.b, 0.60)
                    border.width: 1.5

                    Behavior on opacity { NumberAnimation { duration: 150 } }
                    Behavior on y { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    Text {
                        id: pillText
                        anchors.centerIn: parent
                        text: (root.activeIndex >= 0 && root.activeIndex < root.menuItems.length) ? root.menuItems[root.activeIndex].label : ""
                        font.family: Root.Theme.fontFamily
                        font.pixelSize: 13
                        font.weight: Font.Medium
                        color: (root.activeIndex >= 0 && root.menuItems[root.activeIndex].isDanger) ? Root.Theme.error : Root.Theme.textPrimary
                    }
                }

                // Main floating rounded card
                Rectangle {
                    id: panelCard
                    anchors.fill: parent
                    radius: 28
                    color: Qt.rgba(Root.Theme.panelBg.r,
                                   Root.Theme.panelBg.g,
                                   Root.Theme.panelBg.b, 0.88)
                    border.color: Qt.rgba(Root.Theme.panelBorder.r,
                                          Root.Theme.panelBorder.g,
                                          Root.Theme.panelBorder.b, 0.60)
                    border.width: 1.5

                    MouseArea {
                        anchors.fill: parent
                    }

                    ColumnLayout {
                        id: contentCol
                        anchors.centerIn: parent
                        spacing: 10

                        Repeater {
                            model: root.menuItems

                            delegate: Item {
                                id: actionItem
                                Layout.preferredWidth: 52
                                Layout.preferredHeight: 52
                                width: 52
                                height: 52

                                readonly property bool isSelected: root.activeIndex === index
                                readonly property bool isHovered: tileMouse.containsMouse
                                readonly property bool isDanger: modelData.isDanger

                                // ── Concentric Halo Glow Effect ──
                                Rectangle {
                                    id: haloGlow
                                    anchors.centerIn: parent
                                    width: parent.width + 12
                                    height: parent.height + 12
                                    radius: (actionItem.isSelected || actionItem.isHovered) ? (width / 2) : 23
                                    color: actionItem.isSelected
                                        ? (actionItem.isDanger
                                            ? Qt.rgba(Root.Theme.error.r, Root.Theme.error.g, Root.Theme.error.b, 0.35)
                                            : Qt.rgba(Root.Theme.primary.r, Root.Theme.primary.g, Root.Theme.primary.b, 0.35))
                                        : (actionItem.isHovered
                                            ? (actionItem.isDanger
                                                ? Qt.rgba(Root.Theme.error.r, Root.Theme.error.g, Root.Theme.error.b, 0.22)
                                                : Qt.rgba(Root.Theme.primary.r, Root.Theme.primary.g, Root.Theme.primary.b, 0.20))
                                            : "transparent")
                                    border.width: 1
                                    border.color: actionItem.isSelected
                                        ? (actionItem.isDanger ? Root.Theme.error : Root.Theme.primary)
                                        : (actionItem.isHovered
                                            ? (actionItem.isDanger
                                                ? Qt.rgba(Root.Theme.error.r, Root.Theme.error.g, Root.Theme.error.b, 0.40)
                                                : Qt.rgba(Root.Theme.primary.r, Root.Theme.primary.g, Root.Theme.primary.b, 0.35))
                                            : "transparent")
                                    z: 0
                                    scale: (actionItem.isSelected || actionItem.isHovered) ? 1.0 : 0.80
                                    opacity: (actionItem.isSelected || actionItem.isHovered) ? 1.0 : 0.0

                                    Behavior on opacity { NumberAnimation { duration: 160 } }
                                    Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                                    Behavior on radius { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                                    Behavior on color { ColorAnimation { duration: 140 } }
                                    Behavior on border.color { ColorAnimation { duration: 140 } }
                                }

                                // ── Main Morphing Action Tile ──
                                Rectangle {
                                    id: actionTile
                                    anchors.fill: parent
                                    z: 1
                                    radius: (actionItem.isSelected || actionItem.isHovered) ? (width / 2) : 18

                                    color: actionItem.isSelected
                                        ? (actionItem.isDanger ? Root.Theme.error : Root.Theme.primary)
                                        : (actionItem.isHovered
                                            ? (actionItem.isDanger
                                                ? Qt.rgba(Root.Theme.error.r, Root.Theme.error.g, Root.Theme.error.b, 0.22)
                                                : Qt.rgba(Root.Theme.primary.r, Root.Theme.primary.g, Root.Theme.primary.b, 0.20))
                                            : Qt.rgba(Root.Theme.surfaceContainer.r, Root.Theme.surfaceContainer.g, Root.Theme.surfaceContainer.b, 0.75))

                                    border.width: actionItem.isSelected || actionItem.isHovered ? 1.5 : 1
                                    border.color: actionItem.isSelected
                                        ? (actionItem.isDanger ? Root.Theme.error : Root.Theme.primary)
                                        : (actionItem.isHovered
                                            ? (actionItem.isDanger ? Root.Theme.error : Root.Theme.primary)
                                            : Qt.rgba(Root.Theme.panelBorder.r, Root.Theme.panelBorder.g, Root.Theme.panelBorder.b, 0.45))

                                    scale: tileMouse.pressed ? 0.92 : (actionItem.isHovered || actionItem.isSelected ? 1.05 : 1.0)
                                    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                                    Behavior on radius { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                                    Behavior on color { ColorAnimation { duration: Root.Theme.animDurationFast } }
                                    Behavior on border.color { ColorAnimation { duration: Root.Theme.animDurationFast } }

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.icon
                                        font.family: Root.Theme.iconFont
                                        font.pixelSize: 24
                                        color: actionItem.isSelected
                                            ? (actionItem.isDanger ? "#38000A" : Root.Theme.tileActiveText)
                                            : (actionItem.isDanger ? Root.Theme.error : (actionItem.isHovered ? Root.Theme.primary : Root.Theme.textPrimary))

                                        scale: actionItem.isSelected || actionItem.isHovered ? 1.08 : 1.0
                                        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                                        Behavior on color { ColorAnimation { duration: Root.Theme.animDurationFast } }
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
                    } else if (event.key === Qt.Key_Up || event.key === Qt.Key_Left ||
                               (event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier))) {
                        if (root.selectedIndex <= 0) {
                            root.selectedIndex = root.buttonCount - 1;
                        } else {
                            root.selectedIndex = root.selectedIndex - 1;
                        }
                        root.hoveredIndex = -1;
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Down || event.key === Qt.Key_Right || event.key === Qt.Key_Tab) {
                        if (root.selectedIndex < 0 || root.selectedIndex >= root.buttonCount - 1) {
                            root.selectedIndex = 0;
                        } else {
                            root.selectedIndex = root.selectedIndex + 1;
                        }
                        root.hoveredIndex = -1;
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter ||
                               event.key === Qt.Key_Space) {
                        if (root.selectedIndex >= 0 && root.selectedIndex < root.menuItems.length) {
                            root.menuItems[root.selectedIndex].action();
                        }
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
