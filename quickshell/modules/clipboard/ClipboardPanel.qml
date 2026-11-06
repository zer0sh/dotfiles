import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../.." as Root

// Clipboard history panel — bottom-sliding panel (ChromeOS / MD3 style).
// Shows copied text entries and image previews from cliphist, with instant search,
// one-click re-copying, and individual or full history purging.
Scope {
    id: clipPanel

    property bool panelVisible: false
    property bool _showing: false
    property bool _panelOpen: false
    property var _edgePanelRef: null

    property var history: []
    property bool loading: false
    property string searchQuery: ""

    onPanelVisibleChanged: {
        if (panelVisible) {
            _showing = true
            searchQuery = ""
            refresh()
        } else {
            if (_edgePanelRef) {
                _edgePanelRef.close()
            } else {
                _showing = false
                _panelOpen = false
            }
        }
    }

    Timer {
        id: searchDebounceTimer
        interval: 140
        repeat: false
        onTriggered: clipPanel.refresh()
    }

    // ── Load history ─────────────────────────────────────────────
    function refresh() {
        loading = true
        listProc.command = ["/usr/bin/python3", "/home/zero/.config/quickshell/scripts/clipboard-manager.py", "list", clipPanel.searchQuery, "50"]
        listProc.running = true
    }

    function copyItem(clipId) {
        copyProc.command = ["/usr/bin/python3", "/home/zero/.config/quickshell/scripts/clipboard-manager.py", "copy", clipId]
        copyProc.running = true
    }

    function deleteItem(clipId) {
        deleteProc.command = ["/usr/bin/python3", "/home/zero/.config/quickshell/scripts/clipboard-manager.py", "delete", clipId]
        deleteProc.running = true
    }

    function clearAll() {
        wipeProc.running = true
    }

    // ── IPC Handler ───────────────────────────────────────────────
    IpcHandler {
        target: "clipboard"

        function toggle(): void { clipPanel.panelVisible = !clipPanel.panelVisible; }
        function show(): void { clipPanel.panelVisible = true; }
        function hide(): void { clipPanel.panelVisible = false; }
    }

    Process {
        id: listProc
        command: ["/usr/bin/python3", "/home/zero/.config/quickshell/scripts/clipboard-manager.py", "list", "", "50"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    clipPanel.history = JSON.parse(text.trim())
                } catch (e) {
                    clipPanel.history = []
                }
                clipPanel.loading = false
            }
        }
    }

    Process {
        id: copyProc
    }

    Process {
        id: deleteProc
        onExited: function(code) {
            clipPanel.refresh()
        }
    }

    Process {
        id: wipeProc
        command: ["/usr/bin/python3", "/home/zero/.config/quickshell/scripts/clipboard-manager.py", "wipe"]
        onExited: function(code) {
            clipPanel.refresh()
        }
    }

    // ── Overlay window / panel ────────────────────────────────────
    Loader {
        active: clipPanel._showing

        sourceComponent: PanelWindow {
            id: panelWindow
            visible: true

            anchors { top: true; bottom: true; left: true; right: true }

            color: "transparent"
            exclusionMode: ExclusionMode.Ignore

            WlrLayershell.namespace: "quickshell:clipboard"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            Shortcut {
                sequence: "Escape"
                onActivated: if (_edgePanelRef) _edgePanelRef.close(); else clipPanel.panelVisible = false
            }

            Root.EdgePanel {
                id: edgePanelWrapper
                edge: "top-right"
                panelWidth: Math.round(Root.Theme.panelWidth * 0.7) + 28
                panelHeight: Math.min(panelContent.implicitHeight + 16, panelWindow.height - Root.Theme.shelfHeight - 40)
                shoulderRadius: 28
                showDim: false

                Component.onCompleted: clipPanel._edgePanelRef = edgePanelWrapper
                onCloseRequested: edgePanelWrapper.close()
                onClosed: {
                    clipPanel._edgePanelRef = null
                    clipPanel.panelVisible = false
                    clipPanel._showing = false
                    clipPanel._panelOpen = false
                }

                Item {
                    id: panel
                    width: Math.round(Root.Theme.panelWidth * 0.7)
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

                        // ── Header ────────────────────────────────
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 52
                            Layout.leftMargin: Root.Theme.paddingLarge
                            Layout.rightMargin: Root.Theme.paddingLarge
                            Layout.topMargin: 4
                            spacing: 10

                            Rectangle {
                                width: 32; height: 32; radius: 9
                                color: Qt.rgba(Root.Theme.primary.r, Root.Theme.primary.g,
                                               Root.Theme.primary.b, 0.18)
                                Layout.alignment: Qt.AlignVCenter
                                Text {
                                    anchors.centerIn: parent
                                    text: "󰅌"
                                    color: Root.Theme.primary
                                    font.family: Root.Theme.fontFamily
                                    font.pixelSize: 16
                                }
                            }

                            Text {
                                text: "Clipboard"
                                color: Root.Theme.textPrimary
                                font.family: Root.Theme.fontFamily
                                font.pixelSize: Root.Theme.fontSizeNormal
                                font.weight: Font.DemiBold
                                Layout.alignment: Qt.AlignVCenter
                            }

                            Item { Layout.fillWidth: true }

                            Text {
                                text: clipPanel.history.length + " items"
                                color: Root.Theme.textSecondary
                                font.family: Root.Theme.fontFamily
                                font.pixelSize: Root.Theme.fontSizeXS
                                opacity: 0.7
                                Layout.alignment: Qt.AlignVCenter
                            }
                        }

                        // ── Search Input Field ────────────────────
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 38
                            Layout.leftMargin: Root.Theme.paddingLarge
                            Layout.rightMargin: Root.Theme.paddingLarge
                            Layout.topMargin: 2
                            Layout.bottomMargin: 8
                            radius: 12
                            color: Root.Theme.surfaceContainer
                            border.width: searchInput.activeFocus ? 1.5 : 1
                            border.color: searchInput.activeFocus
                                ? Root.Theme.primary
                                : Qt.rgba(255, 255, 255, 0.08)

                            Behavior on border.color { ColorAnimation { duration: 150 } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 10
                                spacing: 8

                                Text {
                                    text: "󰍉"
                                    font.family: Root.Theme.fontFamily
                                    font.pixelSize: 16
                                    color: searchInput.activeFocus ? Root.Theme.primary : Root.Theme.textSecondary
                                }

                                TextInput {
                                    id: searchInput
                                    Layout.fillWidth: true
                                    font.family: Root.Theme.fontFamily
                                    font.pixelSize: Root.Theme.fontSizeSmall
                                    color: Root.Theme.textPrimary
                                    selectByMouse: true
                                    selectionColor: Root.Theme.primary
                                    selectedTextColor: Root.Theme.tileActiveText
                                    text: clipPanel.searchQuery

                                    onTextChanged: {
                                        clipPanel.searchQuery = text
                                        searchDebounceTimer.restart()
                                    }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "Search history..."
                                        font.family: Root.Theme.fontFamily
                                        font.pixelSize: Root.Theme.fontSizeSmall
                                        color: Root.Theme.textSecondary
                                        opacity: 0.6
                                        visible: searchInput.text === ""
                                    }
                                }

                                Rectangle {
                                    visible: searchInput.text !== ""
                                    Layout.preferredWidth: 22
                                    Layout.preferredHeight: 22
                                    radius: 11
                                    color: clearSearchMA.containsMouse ? Root.Theme.surfaceContainerHigh : "transparent"

                                    Text {
                                        anchors.centerIn: parent
                                        text: "✕"
                                        font.family: Root.Theme.fontFamily
                                        font.pixelSize: 11
                                        font.weight: Font.Bold
                                        color: Root.Theme.textSecondary
                                    }

                                    MouseArea {
                                        id: clearSearchMA
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            searchInput.text = ""
                                            clipPanel.searchQuery = ""
                                            clipPanel.refresh()
                                        }
                                    }
                                }
                            }
                        }

                        // ── Clipboard List ────────────────────────
                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: clipPanel.history.length > 0
                                ? Math.min(clipListView.contentHeight + 24, 480)
                                : 200

                            // Empty state
                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 14
                                visible: clipPanel.history.length === 0 && !clipPanel.loading

                                Text {
                                    text: "󰅌"
                                    color: Root.Theme.textPrimary
                                    font.family: Root.Theme.fontFamily
                                    font.pixelSize: 60
                                    opacity: 0.3
                                    Layout.alignment: Qt.AlignHCenter
                                }
                                Text {
                                    text: clipPanel.searchQuery !== ""
                                        ? "No matching clips found"
                                        : "Clipboard is empty"
                                    color: Root.Theme.textPrimary
                                    font.family: Root.Theme.fontFamily
                                    font.pixelSize: Root.Theme.fontSizeNormal
                                    opacity: 0.5
                                    Layout.alignment: Qt.AlignHCenter
                                }
                            }

                            // Loading spinner
                            Text {
                                anchors.centerIn: parent
                                text: "Loading…"
                                color: Root.Theme.textPrimary
                                font.family: Root.Theme.fontFamily
                                font.pixelSize: Root.Theme.fontSizeNormal
                                opacity: 0.5
                                visible: clipPanel.loading
                            }

                            ListView {
                                id: clipListView
                                anchors.fill: parent
                                anchors.topMargin: 2
                                anchors.bottomMargin: 8
                                clip: true
                                visible: clipPanel.history.length > 0
                                spacing: 0
                                boundsMovement: Flickable.StopAtBounds

                                model: clipPanel.history

                                delegate: ClipboardItem {
                                    width: clipListView.width
                                    clipId: modelData.id
                                    preview: modelData.preview
                                    isImage: modelData.is_image
                                    thumb: modelData.thumb

                                    onClickedItem: function(id) {
                                        clipPanel.copyItem(id)
                                    }

                                    onDeleteItem: function(id) {
                                        clipPanel.deleteItem(id)
                                    }
                                }

                                ScrollBar.vertical: ScrollBar {
                                    active: true
                                    policy: ScrollBar.AsNeeded
                                }
                            }
                        }

                        // ── Footer — Clear All ─────────────────────
                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 52
                            Layout.topMargin: 0
                            Layout.bottomMargin: 10
                            visible: clipPanel.history.length > 0

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
                                    onClicked: clipPanel.clearAll()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
