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
    property var _edgePanelRef: null

    onPanelVisibleChanged: {
        if (panelVisible) {
            _showing = true;
        } else {
            if (_edgePanelRef) {
                _edgePanelRef.close();
            } else {
                _showing = false;
                _panelOpen = false;
            }
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

            Shortcut {
                sequence: "Escape"
                onActivated: if (_edgePanelRef) _edgePanelRef.close(); else notifCenter.panelVisible = false
            }

            Root.EdgePanel {
                id: edgePanelWrapper
                edge: "top-right"
                panelWidth: Root.Theme.panelWidth + 28
                panelHeight: Math.min(panelContent.implicitHeight + 16, panelWindow.height - Root.Theme.shelfHeight - 40)
                shoulderRadius: 28
                showDim: false

                Component.onCompleted: notifCenter._edgePanelRef = edgePanelWrapper
                onCloseRequested: edgePanelWrapper.close()
                onClosed: {
                    notifCenter._edgePanelRef = null
                    notifCenter.panelVisible = false
                    notifCenter._showing = false
                    notifCenter._panelOpen = false
                }

                Item {
                    id: panel
                    width: Root.Theme.panelWidth
                    height: parent.height
                    anchors.right: parent.right

                    // Block click-through
                    MouseArea {
                        anchors.fill: parent
                    }

                    ColumnLayout {
                        id: panelContent
                        anchors.fill: parent
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
                }
            }
        }
    }
}
