import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../.." as Root

// Clipboard history panel — bottom-sliding panel (ChromeOS / MD3 style).
// Shows the last N copied text entries from cliphist and lets you
// re-copy one on click or wipe everything.
Scope {
    id: clipPanel

    property bool panelVisible: false
    property bool _showing: false
    property bool _panelOpen: false

    property var history: []
    property bool loading: false

    onPanelVisibleChanged: {
        if (panelVisible) {
            _showing = true
            refresh()
        } else {
            _panelOpen = false
        }
    }

    // ── Load history (last 10 text entries) ─────────────────────
    function refresh() {
        loading = true
        listProc.running = true
    }

    function copyItem(clipId) {
        getProc.command = ["/bin/sh", "-c", "cliphist decode '" + clipId + "' | wl-copy"]
        getProc.running = true
        copyNotifyProc.command = ["/usr/bin/notify-send", "Clipboard", "Copied to clipboard"]
        copyNotifyProc.running = true
    }

    function clearAll() {
        wipeProc.running = true
        refresh()
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
        command: ["/bin/sh", "-c", "cliphist list | head -n 10"]
        stdout: StdioCollector {
            onStreamFinished: {
                var out = []
                var lines = text.trim().split("\n")
                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i]
                    if (line === "") continue
                    var idx = line.indexOf("\t")
                    if (idx < 0) continue
                    var id = line.substring(0, idx)
                    var preview = line.substring(idx + 1)
                    if (preview.indexOf("binary data") >= 0 || preview.trim() === "") continue
                    out.push({ id: id, preview: preview })
                }
                clipPanel.history = out
                clipPanel.loading = false
            }
        }
    }

    Process {
        id: getProc
    }

    Process {
        id: copyNotifyProc
    }

    Process {
        id: wipeProc
        command: ["cliphist", "wipe"]
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

            Component.onCompleted: openDelayTimer.start()

            Timer {
                id: openDelayTimer
                interval: 16
                repeat: false
                onTriggered: if (clipPanel.panelVisible) clipPanel._panelOpen = true
            }

            Shortcut {
                sequence: "Escape"
                onActivated: clipPanel.panelVisible = false
            }

            // Click-outside close
            MouseArea {
                anchors.fill: parent
                onClicked: clipPanel.panelVisible = false
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
                    }
                }

                Rectangle {
                    id: panel

                    width: Math.round(Root.Theme.panelWidth * 0.7)
                    anchors.right: parent.right
                    anchors.rightMargin: 0

                    height: Math.min(panelContent.implicitHeight, panelClip.height - Root.Theme.spacingSmall * 2)

                    states: [
                        State {
                            name: "visible"
                            when: clipPanel._panelOpen
                            PropertyChanges {
                                target: panel
                                y: 0
                            }
                        },
                        State {
                            name: "hidden"
                            when: !clipPanel._panelOpen
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
                                    script: clipPanel._showing = false
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

                        // ── Header ────────────────────────────────
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 56
                            Layout.leftMargin: Root.Theme.paddingLarge
                            Layout.rightMargin: Root.Theme.paddingLarge
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
                                    text: "Clipboard is empty"
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
                                anchors.topMargin: 4
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

                                    onClickedItem: function(id) {
                                        clipPanel.copyItem(id)
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
                }  // end Rectangle (panel)
            }  // end Item (panelClip)
        }
    }
}
