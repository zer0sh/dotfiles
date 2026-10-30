import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../.." as Root

// Notification Center — bottom-sliding panel (ChromeOS / MD3 style)
// Displays notification history in a scrollable card list.
Scope {
    id: notifCenter

    property bool panelVisible: false
    property bool _showing: false
    property bool _panelOpen: false

    onPanelVisibleChanged: {
        if (panelVisible) {
            _showing = true;
        } else {
            _panelOpen = false;
        }
    }

    // ── IPC Handler ──────────────────────────────────────────────
    IpcHandler {
        target: "notifications"

        function toggle(): void { notifCenter.panelVisible = !notifCenter.panelVisible; }
        function show(): void { notifCenter.panelVisible = true; }
        function hide(): void { notifCenter.panelVisible = false; }
    }

    // ── Overlay window / panel ──────────────────────────────────
    Loader {
        active: notifCenter._showing

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

            WlrLayershell.namespace: "quickshell:notifications"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            Component.onCompleted: openDelayTimer.start()

            Timer {
                id: openDelayTimer
                interval: 16
                repeat: false
                onTriggered: if (notifCenter.panelVisible) notifCenter._panelOpen = true
            }

            Shortcut {
                sequence: "Escape"
                onActivated: notifCenter.panelVisible = false
            }

            // Click-outside close
            MouseArea {
                anchors.fill: parent
                onClicked: notifCenter.panelVisible = false
            }

            // Clip region: top edge below the shelf
            Item {
                id: panelClip
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.topMargin: Root.Theme.shelfHeight

                Shape {
                    id: panelShape
                    anchors.top: panel.top
                    anchors.bottom: panel.bottom
                    anchors.left: panel.left
                    anchors.right: panel.right
                    anchors.leftMargin: -28
                    layer.enabled: true
                    layer.samples: 4

                    // 1. Relleno unificado (hombro cóncavo izquierdo + cuerpo del panel)
                    ShapePath {
                        strokeWidth: 0
                        strokeColor: "transparent"
                        fillColor: Qt.rgba(Root.Theme.panelBg.r, Root.Theme.panelBg.g, Root.Theme.panelBg.b, 0.85)

                        startX: 0
                        startY: 0

                        // Curva cóncava hombro izquierdo
                        PathArc {
                            x: 28; y: 28
                            radiusX: 28; radiusY: 28
                            direction: PathArc.Clockwise
                        }
                        // Lateral izquierdo
                        PathLine { x: 28; y: Math.max(28, panelShape.height - 28) }
                        // Esquina inferior izquierda redondeada
                        PathArc {
                            x: 56; y: panelShape.height
                            radiusX: 28; radiusY: 28
                            direction: PathArc.Counterclockwise
                        }
                        // Base horizontal
                        PathLine { x: Math.max(56, panelShape.width - 28); y: panelShape.height }
                        // Esquina inferior derecha redondeada
                        PathArc {
                            x: panelShape.width; y: Math.max(28, panelShape.height - 28)
                            radiusX: 28; radiusY: 28
                            direction: PathArc.Counterclockwise
                        }
                        // Lateral derecho
                        PathLine { x: panelShape.width; y: 0 }
                        // Cierre superior contra Waybar
                        PathLine { x: 0; y: 0 }
                    }

                    // 2. Borde exterior continuo estilo ventana
                    ShapePath {
                        strokeWidth: 2
                        strokeColor: Root.Theme.primary
                        fillColor: "transparent"
                        capStyle: ShapePath.FlatCap
                        joinStyle: ShapePath.RoundJoin

                        startX: 0
                        startY: 0

                        // Curva cóncava hombro izquierdo
                        PathArc {
                            x: 28; y: 28
                            radiusX: 28; radiusY: 28
                            direction: PathArc.Clockwise
                        }
                        // Lateral izquierdo
                        PathLine { x: 28; y: Math.max(28, panelShape.height - 28) }
                        // Esquina inferior izquierda redondeada
                        PathArc {
                            x: 56; y: panelShape.height
                            radiusX: 28; radiusY: 28
                            direction: PathArc.Counterclockwise
                        }
                        // Base horizontal
                        PathLine { x: Math.max(56, panelShape.width - 28); y: panelShape.height }
                        // Esquina inferior derecha redondeada
                        PathArc {
                            x: panelShape.width; y: Math.max(28, panelShape.height - 28)
                            radiusX: 28; radiusY: 28
                            direction: PathArc.Counterclockwise
                        }
                        // Lateral derecho
                        PathLine { x: panelShape.width; y: 0 }
                        // Abierto hacia Waybar arriba
                    }
                }

                Rectangle {
                    id: panel

                    width: Root.Theme.panelWidth
                    anchors.right: parent.right
                    anchors.rightMargin: 0

                    height: Math.min(panelContent.implicitHeight, panelClip.height - Root.Theme.spacingSmall * 2)

                    states: [
                        State {
                            name: "visible"
                            when: notifCenter._panelOpen
                            PropertyChanges {
                                target: panel
                                y: 0
                            }
                        },
                        State {
                            name: "hidden"
                            when: !notifCenter._panelOpen
                            PropertyChanges {
                                target: panel
                                y: -panel.height - 28
                            }
                        }
                    ]

                    transitions: [
                        Transition {
                            from: "hidden"
                            to: "visible"
                            NumberAnimation {
                                property: "y"
                                duration: Root.Theme.animDuration
                                easing.type: Easing.OutCubic
                            }
                        },
                        Transition {
                            from: "visible"
                            to: "hidden"
                            SequentialAnimation {
                                NumberAnimation {
                                    property: "y"
                                    duration: Root.Theme.animDuration
                                    easing.type: Easing.OutCubic
                                }
                                ScriptAction {
                                    script: notifCenter._showing = false
                                }
                            }
                        }
                    ]

                    color: "transparent"
                    border.width: 0
                    clip: true

                    // Block click-through
                    MouseArea {
                        anchors.fill: parent
                    }

                    ColumnLayout {
                        id: panelContent
                        width: panel.width
                        spacing: 0

                        // ── Notification List ───────────────────────
                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: NotificationService.count > 0
                                ? Math.min(notifListView.contentHeight + 24, 480)
                                : 200

                            // Empty state
                            ColumnLayout {
                                anchors.centerIn: parent
                            spacing: 14
                            visible: NotificationService.count === 0

                            Text {
                                text: "󰂚"
                                color: "#E5E1E9"
                                font.family: Root.Theme.fontFamily
                                font.pixelSize: 60
                                    opacity: 0.3
                                    Layout.alignment: Qt.AlignHCenter
                                }

                                Text {
                                    text: "No notifications"
                                    color: "#E5E1E9"
                                    font.family: Root.Theme.fontFamily
                                    font.pixelSize: Root.Theme.fontSizeNormal
                                    opacity: 0.5
                                    Layout.alignment: Qt.AlignHCenter
                                }
                            }

                            // Scrollable notification list
                            ListView {
                                id: notifListView
                                anchors.fill: parent
                                anchors.topMargin: 12
                                anchors.bottomMargin: 8
                                clip: true
                                visible: NotificationService.count > 0
                                spacing: 0
                                boundsMovement: Flickable.StopAtBounds

                                model: NotificationService.notifications

                                delegate: NotificationItem {
                                    width: notifListView.width
                                    notifId: modelData.id
                                    appName: modelData.appName
                                    summary: modelData.summary
                                    body: modelData.body
                                    urgency: modelData.urgency
                                    timestamp: modelData.timestamp
                                    timeAgo: NotificationService.relativeTime(modelData.timestamp)

                                    onDismissed: function(id) {
                                        NotificationService.removeNotification(id);
                                    }
                                }

                                ScrollBar.vertical: ScrollBar {
                                    active: true
                                    policy: ScrollBar.AsNeeded
                                }
                            }
                        }

                        // ── Footer — Clear All ──────────────────────
                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 52
                            Layout.topMargin: 0
                            Layout.bottomMargin: 10
                            visible: NotificationService.count > 0

                            // Clear all — text button, right-aligned
                            Rectangle {
                                anchors.right: parent.right
                                anchors.rightMargin: Root.Theme.paddingLarge
                                anchors.verticalCenter: parent.verticalCenter
                                width: clearAllLabel.implicitWidth + 28
                                height: 44
                                radius: 22
                                color: clearAllMA.containsMouse
                                    ? Qt.rgba(Root.Theme.error.r, Root.Theme.error.g, Root.Theme.error.b, 0.15)
                                    : Qt.rgba(Root.Theme.surfaceContainerHigh.r, Root.Theme.surfaceContainerHigh.g, Root.Theme.surfaceContainerHigh.b, 0.60)
                                border.width: 1
                                border.color: clearAllMA.containsMouse
                                    ? Root.Theme.error
                                    : Qt.rgba(Root.Theme.outline.r, Root.Theme.outline.g, Root.Theme.outline.b, 0.30)
                                Behavior on color { ColorAnimation { duration: 120 } }
                                Behavior on border.color { ColorAnimation { duration: 120 } }

                                Text {
                                    id: clearAllLabel
                                    anchors.centerIn: parent
                                    text: "Clear all"
                                    color: clearAllMA.containsMouse ? Root.Theme.error : Root.Theme.textPrimary
                                    font.family: Root.Theme.fontFamily
                                    font.pixelSize: Root.Theme.fontSizeNormal
                                    font.weight: Font.DemiBold
                                }

                                MouseArea {
                                    id: clearAllMA
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: NotificationService.clearAll()
                                }
                            }
                        }
                    }
                }  // end Rectangle (panel)
            }  // end Item (panelClip)
        }
    }
}
