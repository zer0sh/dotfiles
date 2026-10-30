import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Mpris
import "../.." as Root

// Media Source Selector — Dynamic Island style anchored to Waybar center
Scope {
    id: mediaSelector

    property bool panelVisible: false
    property bool _showing: false
    property bool _panelOpen: false
    property string currentSelectedPlayer: "auto"

    onPanelVisibleChanged: {
        if (panelVisible) {
            readPlayerProc.running = true;
            _showing = true;
        } else {
            _panelOpen = false;
        }
    }

    // ── Processes for player state persistence ──────────────────────
    Process {
        id: readPlayerProc
        command: ["/bin/sh", "-c", "cat ~/.cache/waybar-selected-player 2>/dev/null || echo 'auto'"]
        stdout: StdioCollector {
            onStreamFinished: {
                mediaSelector.currentSelectedPlayer = text.trim() || "auto";
            }
        }
    }

    Process {
        id: setPlayerProc
    }

    function selectPlayer(target) {
        if (target === "auto") {
            setPlayerProc.command = ["/bin/sh", "-c", "rm -f ~/.cache/waybar-selected-player; pkill -f 'scripts/mediaplayer' 2>/dev/null || true"];
        } else {
            setPlayerProc.command = ["/bin/sh", "-c", "echo '" + target + "' > ~/.cache/waybar-selected-player; pkill -f 'scripts/mediaplayer' 2>/dev/null || true"];
        }
        setPlayerProc.running = true;
        mediaSelector.panelVisible = false;
    }

    // ── IPC Handler ──────────────────────────────────────────────
    IpcHandler {
        target: "mediaselector"

        function toggle(): void { mediaSelector.panelVisible = !mediaSelector.panelVisible; }
        function show(): void { mediaSelector.panelVisible = true; }
        function hide(): void { mediaSelector.panelVisible = false; }
    }

    // ── Overlay window ───────────────────────────────────────────
    Loader {
        active: mediaSelector._showing

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

            WlrLayershell.namespace: "quickshell:mediaselector"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            Component.onCompleted: openDelayTimer.start()

            Timer {
                id: openDelayTimer
                interval: 16
                repeat: false
                onTriggered: if (mediaSelector.panelVisible) mediaSelector._panelOpen = true
            }

            Shortcut {
                sequence: "Escape"
                onActivated: mediaSelector.panelVisible = false
            }

            // Click outside to dismiss
            MouseArea {
                anchors.fill: parent
                onClicked: mediaSelector.panelVisible = false
            }

            // Clip region starting at the bottom edge of Waybar shelf
            Item {
                id: panelClip
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.topMargin: Root.Theme.shelfHeight

                Item {
                    id: islandWrapper
                    width: 360
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    height: panel.height

                    Shape {
                        id: panelShape
                        anchors.top: panel.top
                        anchors.bottom: panel.bottom
                        anchors.horizontalCenter: panel.horizontalCenter
                        width: panel.width + 56
                        layer.enabled: true
                        layer.samples: 4

                        // 1. Relleno unificado (hombro izquierdo + cuerpo + hombro derecho)
                        ShapePath {
                            strokeWidth: 0
                            strokeColor: "transparent"
                            fillColor: Qt.rgba(Root.Theme.panelBg.r, Root.Theme.panelBg.g, Root.Theme.panelBg.b, 0.95)

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
                            PathLine { x: Math.max(56, panelShape.width - 56); y: panelShape.height }
                            // Esquina inferior derecha redondeada
                            PathArc {
                                x: panelShape.width - 28; y: Math.max(28, panelShape.height - 28)
                                radiusX: 28; radiusY: 28
                                direction: PathArc.Counterclockwise
                            }
                            // Lateral derecho
                            PathLine { x: panelShape.width - 28; y: 28 }
                            // Curva cóncava hombro derecho
                            PathArc {
                                x: panelShape.width; y: 0
                                radiusX: 28; radiusY: 28
                                direction: PathArc.Clockwise
                            }
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
                            PathLine { x: Math.max(56, panelShape.width - 56); y: panelShape.height }
                            // Esquina inferior derecha redondeada
                            PathArc {
                                x: panelShape.width - 28; y: Math.max(28, panelShape.height - 28)
                                radiusX: 28; radiusY: 28
                                direction: PathArc.Counterclockwise
                            }
                            // Lateral derecho
                            PathLine { x: panelShape.width - 28; y: 28 }
                            // Curva cóncava hombro derecho
                            PathArc {
                                x: panelShape.width; y: 0
                                radiusX: 28; radiusY: 28
                                direction: PathArc.Clockwise
                            }
                        }
                    }

                    Rectangle {
                        id: panel
                        width: islandWrapper.width
                        anchors.horizontalCenter: parent.horizontalCenter

                        height: Math.min(panelContent.implicitHeight, 460)

                        states: [
                            State {
                                name: "visible"
                                when: mediaSelector._panelOpen
                                PropertyChanges {
                                    target: panel
                                    y: 0
                                }
                            },
                            State {
                                name: "hidden"
                                when: !mediaSelector._panelOpen
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
                                        script: mediaSelector._showing = false
                                    }
                                }
                            }
                        ]

                        // Dynamic Island geometry: top edge flat against Waybar, bottom rounded
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
                            spacing: 8

                            // ── Header ──────────────────────────────
                            Item {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 48
                                Layout.topMargin: 6

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 20
                                    anchors.rightMargin: 20
                                    spacing: 10

                                    Text {
                                        text: "󰝚"
                                        color: Root.Theme.primary
                                        font.family: Root.Theme.fontFamily
                                        font.pixelSize: 20
                                        Layout.alignment: Qt.AlignVCenter
                                    }

                                    Text {
                                        text: "Media Source"
                                        color: Root.Theme.textPrimary
                                        font.family: Root.Theme.fontFamily
                                        font.pixelSize: Root.Theme.fontSizeNormal
                                        font.weight: Font.DemiBold
                                        Layout.fillWidth: true
                                        Layout.alignment: Qt.AlignVCenter
                                    }
                                }
                            }

                            // ── Player List or Empty State ───────────
                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.bottomMargin: 14
                                spacing: 4

                                // Option: Automatic (Follow active)
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 46
                                    Layout.leftMargin: 12
                                    Layout.rightMargin: 12
                                    radius: 14
                                    color: mediaSelector.currentSelectedPlayer === "auto"
                                        ? Qt.rgba(Root.Theme.primary.r, Root.Theme.primary.g, Root.Theme.primary.b, 0.16)
                                        : (autoMA.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(Root.Theme.surfaceContainer.r, Root.Theme.surfaceContainer.g, Root.Theme.surfaceContainer.b, 0.60))
                                    border.width: 1
                                    border.color: mediaSelector.currentSelectedPlayer === "auto"
                                        ? Root.Theme.primary
                                        : (autoMA.containsMouse ? Qt.rgba(1, 1, 1, 0.18) : Qt.rgba(1, 1, 1, 0.08))

                                    Behavior on color { ColorAnimation { duration: 120 } }
                                    Behavior on border.color { ColorAnimation { duration: 120 } }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 14
                                        anchors.rightMargin: 14
                                        spacing: 12

                                        Text {
                                            text: "󰓇"
                                            color: mediaSelector.currentSelectedPlayer === "auto" ? Root.Theme.primary : Root.Theme.textSecondary
                                            font.family: Root.Theme.fontFamily
                                            font.pixelSize: 18
                                            Layout.alignment: Qt.AlignVCenter
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            Layout.alignment: Qt.AlignVCenter
                                            spacing: 1

                                            Text {
                                                text: "Automatic"
                                                color: Root.Theme.textPrimary
                                                font.family: Root.Theme.fontFamily
                                                font.pixelSize: 13
                                                font.weight: Font.DemiBold
                                            }

                                            Text {
                                                text: "Follow active player"
                                                color: Root.Theme.textSecondary
                                                font.family: Root.Theme.fontFamily
                                                font.pixelSize: 11
                                            }
                                        }

                                        Text {
                                            text: "󰄲"
                                            color: Root.Theme.primary
                                            font.family: Root.Theme.fontFamily
                                            font.pixelSize: 16
                                            visible: mediaSelector.currentSelectedPlayer === "auto"
                                            Layout.alignment: Qt.AlignVCenter
                                        }
                                    }

                                    MouseArea {
                                        id: autoMA
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: mediaSelector.selectPlayer("auto")
                                    }
                                }

                                // Separator
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 1
                                    Layout.leftMargin: 16
                                    Layout.rightMargin: 16
                                    Layout.topMargin: 4
                                    Layout.bottomMargin: 4
                                    color: Qt.rgba(255, 255, 255, 0.08)
                                }

                                // List of active MPRIS players
                                Repeater {
                                    model: Mpris.players ? Mpris.players.values : []

                                    delegate: Rectangle {
                                        required property var modelData

                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 52
                                        Layout.leftMargin: 12
                                        Layout.rightMargin: 12
                                        radius: 14

                                        readonly property string playerId: {
                                            var entry = (modelData.desktopEntry || "").toLowerCase().replace(/\.desktop$/, "");
                                            var ident = (modelData.identity || "").toLowerCase();
                                            return entry || ident.split(" ")[0];
                                        }

                                        readonly property bool isSelected: mediaSelector.currentSelectedPlayer === playerId || mediaSelector.currentSelectedPlayer === modelData.identity

                                        color: isSelected
                                            ? Qt.rgba(Root.Theme.primary.r, Root.Theme.primary.g, Root.Theme.primary.b, 0.16)
                                            : (itemMA.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(Root.Theme.surfaceContainer.r, Root.Theme.surfaceContainer.g, Root.Theme.surfaceContainer.b, 0.60))
                                        border.width: 1
                                        border.color: isSelected
                                            ? Root.Theme.primary
                                            : (itemMA.containsMouse ? Qt.rgba(1, 1, 1, 0.18) : Qt.rgba(1, 1, 1, 0.08))

                                        Behavior on color { ColorAnimation { duration: 120 } }
                                        Behavior on border.color { ColorAnimation { duration: 120 } }

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 14
                                            anchors.rightMargin: 14
                                            spacing: 12

                                            // Art or default icon
                                            Rectangle {
                                                Layout.preferredWidth: 32
                                                Layout.preferredHeight: 32
                                                radius: 8
                                                color: Qt.rgba(255, 255, 255, 0.08)
                                                clip: true
                                                Layout.alignment: Qt.AlignVCenter

                                                Image {
                                                    anchors.fill: parent
                                                    source: modelData.trackArtUrl || ""
                                                    fillMode: Image.PreserveAspectCrop
                                                    visible: modelData.trackArtUrl !== ""
                                                }

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: "󰝚"
                                                    color: Root.Theme.primary
                                                    font.family: Root.Theme.fontFamily
                                                    font.pixelSize: 16
                                                    visible: !modelData.trackArtUrl || modelData.trackArtUrl === ""
                                                }
                                            }

                                            // Info
                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                Layout.alignment: Qt.AlignVCenter
                                                spacing: 2

                                                RowLayout {
                                                    spacing: 6
                                                    Text {
                                                        text: modelData.identity || modelData.desktopEntry || "Player"
                                                        color: Root.Theme.textPrimary
                                                        font.family: Root.Theme.fontFamily
                                                        font.pixelSize: 13
                                                        font.weight: Font.DemiBold
                                                        elide: Text.ElideRight
                                                    }

                                                    Text {
                                                        text: modelData.isPlaying ? "• Playing" : "• Paused"
                                                        color: modelData.isPlaying ? Root.Theme.primary : Root.Theme.textSecondary
                                                        font.family: Root.Theme.fontFamily
                                                        font.pixelSize: 11
                                                    }
                                                }

                                                Text {
                                                    text: (modelData.trackTitle || "") !== "" ? (modelData.trackArtist ? modelData.trackArtist + " - " + modelData.trackTitle : modelData.trackTitle) : "No active track"
                                                    color: Root.Theme.textSecondary
                                                    font.family: Root.Theme.fontFamily
                                                    font.pixelSize: 11
                                                    elide: Text.ElideRight
                                                    Layout.fillWidth: true
                                                }
                                            }

                                            Text {
                                                text: "󰄲"
                                                color: Root.Theme.primary
                                                font.family: Root.Theme.fontFamily
                                                font.pixelSize: 16
                                                visible: isSelected
                                                Layout.alignment: Qt.AlignVCenter
                                            }
                                        }

                                        MouseArea {
                                            id: itemMA
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                var target = playerId || modelData.identity;
                                                mediaSelector.selectPlayer(target);
                                            }
                                        }
                                    }
                                }

                                // Empty state if no players
                                Item {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 70
                                    visible: !Mpris.players || Mpris.players.values.length === 0

                                    ColumnLayout {
                                        anchors.centerIn: parent
                                        spacing: 4

                                        Text {
                                            text: "󰝛"
                                            color: Root.Theme.textSecondary
                                            font.family: Root.Theme.fontFamily
                                            font.pixelSize: 24
                                            opacity: 0.5
                                            Layout.alignment: Qt.AlignHCenter
                                        }

                                        Text {
                                            text: "No active media players found"
                                            color: Root.Theme.textSecondary
                                            font.family: Root.Theme.fontFamily
                                            font.pixelSize: 12
                                            opacity: 0.7
                                            Layout.alignment: Qt.AlignHCenter
                                        }
                                    }
                                }
                            }
                        }
                    }  // end Rectangle (panel)
                }  // end Item (islandWrapper)
            }  // end Item (panelClip)
        }
    }
}
