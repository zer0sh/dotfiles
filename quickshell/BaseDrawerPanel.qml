import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import "." as Root

// BaseDrawerPanel — Shared base configuration for top-right drawers (Clipboard, Notifications)
PanelWindow {
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

    WlrLayershell.namespace: windowNamespace
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    property string windowNamespace: "quickshell:drawer"
    property real contentWidth: Root.Theme.drawerWidth
    property string iconText: ""
    property string titleText: ""
    property string countText: ""
    property bool showClearAll: false
    property string clearAllText: "Clear all"

    signal clearAllClicked()
    signal closed()

    default property alias content: bodySlot.data
    property alias headerExtra: headerExtraSlot.data
    property alias edgePanelRef: edgePanelWrapper

    Shortcut {
        sequence: "Escape"
        onActivated: edgePanelWrapper.close()
    }

    Root.EdgePanel {
        id: edgePanelWrapper
        edge: "top-right"
        panelWidth: panelWindow.contentWidth + 28
        panelHeight: Math.min(panelContent.implicitHeight + 16, panelWindow.height - Root.Theme.shelfHeight - 40)
        shoulderRadius: 28
        showDim: false

        onCloseRequested: edgePanelWrapper.close()
        onClosed: {
            panelWindow.closed()
        }

        Item {
            id: panel
            width: panelWindow.contentWidth
            height: parent.height
            anchors.right: parent.right

            // Block click-through to overlay close area
            MouseArea {
                anchors.fill: parent
            }

            ColumnLayout {
                id: panelContent
                width: panel.width
                spacing: 0

                // ── Shared Header ─────────────────────────────────
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 52
                    Layout.leftMargin: Root.Theme.paddingLarge
                    Layout.rightMargin: Root.Theme.paddingLarge
                    Layout.topMargin: 4
                    spacing: 10

                    Rectangle {
                        width: 32
                        height: 32
                        radius: 9
                        color: Qt.rgba(Root.Theme.primary.r, Root.Theme.primary.g,
                                       Root.Theme.primary.b, 0.18)
                        Layout.alignment: Qt.AlignVCenter

                        Text {
                            anchors.centerIn: parent
                            text: panelWindow.iconText
                            color: Root.Theme.primary
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: 16
                        }
                    }

                    Text {
                        text: panelWindow.titleText
                        color: Root.Theme.textPrimary
                        font.family: Root.Theme.fontFamily
                        font.pixelSize: Root.Theme.fontSizeNormal
                        font.weight: Font.DemiBold
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Text {
                        text: panelWindow.countText
                        color: Root.Theme.textSecondary
                        font.family: Root.Theme.fontFamily
                        font.pixelSize: Root.Theme.fontSizeXS
                        opacity: 0.7
                        Layout.alignment: Qt.AlignVCenter
                    }
                }

                // ── Optional Header Extra Slot (e.g. Search Input) ─
                ColumnLayout {
                    id: headerExtraSlot
                    Layout.fillWidth: true
                    spacing: 0
                    visible: children.length > 0
                }

                // ── Body Slot ─────────────────────────────────────
                ColumnLayout {
                    id: bodySlot
                    Layout.fillWidth: true
                    spacing: 0
                }

                // ── Shared Footer — Clear All ─────────────────────
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 52
                    Layout.topMargin: 0
                    Layout.bottomMargin: 10
                    visible: panelWindow.showClearAll

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
                            text: panelWindow.clearAllText
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
                            onClicked: panelWindow.clearAllClicked()
                        }
                    }
                }
            }
        }
    }
}
