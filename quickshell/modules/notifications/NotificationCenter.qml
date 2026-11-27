import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../.." as Root

// Notification Center — top-right Dynamic Island drawer
// Displays notification history in a scrollable card list.
Scope {
    id: notifCenter

    property bool panelVisible: false
    property bool _showing: false
    property var _drawerRef: null

    onPanelVisibleChanged: {
        if (panelVisible) {
            _showing = true;
        } else {
            if (_drawerRef && _drawerRef.edgePanelRef) {
                _drawerRef.edgePanelRef.close();
            } else {
                _showing = false;
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

    // ── Overlay window / drawer panel ────────────────────────────
    Loader {
        active: notifCenter._showing

        sourceComponent: Root.BaseDrawerPanel {
            id: drawer
            windowNamespace: "quickshell:notifications"
            iconText: "󰂚"
            titleText: "Notifications"
            countText: NotificationService.count + (NotificationService.count === 1 ? " notification" : " notifications")
            showClearAll: NotificationService.count > 0
            contentWidth: Root.Theme.drawerWidth

            Component.onCompleted: notifCenter._drawerRef = drawer
            onPanelClosed: {
                notifCenter._drawerRef = null
                notifCenter.panelVisible = false
                notifCenter._showing = false
            }
            onClearAllClicked: NotificationService.clearAll()

            // ── Body ──────────────────────────────────────────────
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: NotificationService.count > 0
                    ? Math.min(notifListView.contentHeight + 24, 480)
                    : 200

                // Empty state
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 12
                    visible: NotificationService.count === 0

                    Text {
                        text: "󰂚"
                        color: Root.Theme.textSecondary
                        font.family: Root.Theme.fontFamily
                        font.pixelSize: 48
                        opacity: 0.35
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Text {
                        text: "No notifications"
                        color: Root.Theme.textSecondary
                        font.family: Root.Theme.fontFamily
                        font.pixelSize: Root.Theme.fontSizeNormal
                        opacity: 0.6
                        Layout.alignment: Qt.AlignHCenter
                    }
                }

                // Scrollable notification list
                ListView {
                    id: notifListView
                    anchors.fill: parent
                    anchors.topMargin: 4
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
        }
    }
}
