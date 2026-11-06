import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Mpris
import "../.." as Root

Scope {
    id: musicOsd

    property MprisPlayer _player: null
    property QtObject miniPlayerRef: null
    property string _lastTrackKey: ""
    property bool _lastPlayingState: false
    property bool _isInitialized: false

    function show() {
        if (osdWin) osdWin.showOsd()
    }

    IpcHandler {
        target: "musicosd"
        function show(): void { musicOsd.show(); }
        function dismiss(): void { if (osdWin) osdWin.dismiss(); }
        function toggle(): void {
            if (osdWin && osdWin.visible) osdWin.dismiss();
            else musicOsd.show();
        }
    }

    // Fast discovery poll to catch media players starting/closing
    Timer {
        interval: 1500
        running: true
        repeat: true
        onTriggered: musicOsd._refreshPlayer()
    }

    Connections {
        target: musicOsd._player

        function onPostTrackChanged() { musicOsd._refreshPlayer() }
        function onTrackTitleChanged() { musicOsd._refreshPlayer() }
        function onTrackArtistChanged() { musicOsd._refreshPlayer() }
        function onTrackAlbumChanged() { musicOsd._refreshPlayer() }
        function onTrackArtUrlChanged() { musicOsd._refreshPlayer() }
        function onPlaybackStateChanged() { musicOsd._refreshPlayer() }
        function onIsPlayingChanged() { musicOsd._refreshPlayer() }
    }

    Component.onCompleted: {
        _refreshPlayer()
        _isInitialized = true
    }

    function _refreshPlayer() {
        var oldPlayer = _player
        var list = Mpris.players ? Mpris.players.values : null
        var newPlayer = null

        if (list && list.length > 0) {
            for (var i = 0; i < list.length; i++) {
                var p = list[i]
                if (p && p.isPlaying) {
                    newPlayer = p
                    break
                }
            }
            if (!newPlayer) newPlayer = list[0]
        }

        var miniBlocked = miniPlayerRef && miniPlayerRef.panelVisible && (miniPlayerRef.currentMode === undefined || miniPlayerRef.currentMode === "music")

        if (newPlayer !== oldPlayer) {
            _player = newPlayer
        }

        if (_player) {
            var trackTitle = _player.trackTitle || ""
            var trackArtist = _player.trackArtist || ""
            var isPlaying = _player.isPlaying || (_player.playbackState === MprisPlaybackState.Playing)
            var currentKey = (_player.identity || "") + "::" + trackTitle + "::" + trackArtist

            var trackChanged = (currentKey !== _lastTrackKey && trackTitle !== "")
            var resumedPlaying = (isPlaying && !_lastPlayingState && trackTitle !== "")

            _lastTrackKey = currentKey
            _lastPlayingState = isPlaying

            if (_isInitialized && !miniBlocked && (trackChanged || resumedPlaying) && isPlaying) {
                osdWin.showOsd()
            }
        }
    }

    PanelWindow {
        id: osdWin
        visible: false
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell:music-osd"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        anchors.top:   true
        anchors.left:  true
        anchors.right: true
        implicitHeight: Root.Theme.shelfHeight + 120

        mask: Region {
            item: osdWrapper
        }

        function showOsd() {
            var wasDismissing = dismissAnim.running
            dismissAnim.stop()
            if (!visible || wasDismissing) {
                appearAnim.stop()
                osdCard._scaleY = 0.0
                osdCard._scaleX = 0.82
                osdCard._opacity = 0
                cardContent.opacity = 0
                visible = true
                appearAnim.start()
            }
            dismissTimer.restart()
        }

        function dismiss() {
            dismissTimer.stop()
            if (!dismissAnim.running) {
                appearAnim.stop()
                dismissAnim.start()
            }
        }

        Timer {
            id: dismissTimer
            interval: 3500
            repeat: false
            onTriggered: osdWin.dismiss()
        }

        // Appear: organic dynamic island extrusion downwards + expansion
        ParallelAnimation {
            id: appearAnim
            NumberAnimation {
                target: osdCard; property: "_scaleY"
                from: 0.0; to: 1.0; duration: 280
                easing.type: Easing.OutBack
                easing.overshoot: 1.18
            }
            NumberAnimation {
                target: osdCard; property: "_scaleX"
                from: 0.82; to: 1.0; duration: 260
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: osdCard; property: "_opacity"
                from: 0.0; to: 1.0; duration: 160
                easing.type: Easing.OutQuad
            }
            SequentialAnimation {
                PauseAnimation { duration: 50 }
                NumberAnimation {
                    target: cardContent; property: "opacity"
                    from: 0.0; to: 1.0; duration: 180
                    easing.type: Easing.OutQuad
                }
            }
        }

        // Dismiss: retract back into Waybar
        SequentialAnimation {
            id: dismissAnim
            ParallelAnimation {
                NumberAnimation {
                    target: cardContent; property: "opacity"
                    to: 0.0; duration: 100; easing.type: Easing.InQuad
                }
                NumberAnimation {
                    target: osdCard; property: "_scaleY"
                    to: 0.0; duration: 190; easing.type: Easing.InBack
                    easing.overshoot: 1.1
                }
                NumberAnimation {
                    target: osdCard; property: "_scaleX"
                    to: 0.85; duration: 170; easing.type: Easing.InQuad
                }
                NumberAnimation {
                    target: osdCard; property: "_opacity"
                    to: 0.0; duration: 170; easing.type: Easing.InQuad
                }
            }
            ScriptAction { script: osdWin.visible = false }
        }

        // ── Card container anchored directly to Waybar shelf ─────────
        Item {
            id: osdWrapper
            width: 436
            height: osdCard.implicitHeight
            anchors.top: parent.top
            anchors.topMargin: Root.Theme.shelfHeight - 4
            anchors.horizontalCenter: parent.horizontalCenter

            Item {
                id: osdCard
                property real _opacity: 0
                property real _scaleX: 1.0
                property real _scaleY: 1.0

                width: 380
                height: implicitHeight
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                opacity: _opacity
                implicitHeight: cardContent.implicitHeight + 24

                transformOrigin: Item.Top
                transform: Scale {
                    origin.x: osdCard.width / 2
                    origin.y: 0
                    xScale: osdCard._scaleX
                    yScale: osdCard._scaleY
                }

                // Unified Dynamic Island Shape with G1 continuous Bezier fillets
                Shape {
                    id: osdShape
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width + 56
                    layer.enabled: true
                    layer.samples: 8
                    layer.smooth: true

                    // 1. Unified glass surface fill — covers from y=0 to fully obscure Waybar's 2px border
                    ShapePath {
                        strokeWidth: 0
                        strokeColor: "transparent"
                        fillColor: Qt.rgba(Root.Theme.panelBg.r,
                                           Root.Theme.panelBg.g,
                                           Root.Theme.panelBg.b, 0.98)

                        startX: 0
                        startY: 0

                        PathLine { x: 0; y: 3 }

                        // Left concave shoulder fillet with zero horizontal tangent at y=3
                        PathCubic {
                            control1X: 14; control1Y: 3
                            control2X: 28; control2Y: 17
                            x: 28; y: 31
                        }
                        // Left flank
                        PathLine { x: 28; y: Math.max(31, osdShape.height - 28) }
                        // Bottom-left rounded corner
                        PathCubic {
                            control1X: 28; control1Y: osdShape.height - 14
                            control2X: 42; control2Y: osdShape.height
                            x: 56; y: osdShape.height
                        }
                        // Bottom horizontal base
                        PathLine { x: Math.max(56, osdShape.width - 56); y: osdShape.height }
                        // Bottom-right rounded corner
                        PathCubic {
                            control1X: osdShape.width - 42; control1Y: osdShape.height
                            control2X: osdShape.width - 28; control2Y: osdShape.height - 14
                            x: osdShape.width - 28; y: Math.max(31, osdShape.height - 28)
                        }
                        // Right flank
                        PathLine { x: osdShape.width - 28; y: 31 }
                        // Right concave shoulder fillet with zero horizontal exit tangent at y=3
                        PathCubic {
                            control1X: osdShape.width - 28; control1Y: 17
                            control2X: osdShape.width - 14; control2Y: 3
                            x: osdShape.width; y: 3
                        }
                        // Top bridge over Waybar border
                        PathLine { x: osdShape.width; y: 0 }
                        PathLine { x: 0; y: 0 }
                    }

                    // 2. Continuous accent border (perfect 2px match with Waybar's border)
                    ShapePath {
                        strokeWidth: 2
                        strokeColor: Root.Theme.primary
                        fillColor: "transparent"
                        capStyle: ShapePath.FlatCap
                        joinStyle: ShapePath.RoundJoin

                        Behavior on strokeColor { ColorAnimation { duration: 180 } }

                        startX: 0
                        startY: 3

                        PathCubic {
                            control1X: 14; control1Y: 3
                            control2X: 28; control2Y: 17
                            x: 28; y: 31
                        }
                        PathLine { x: 28; y: Math.max(31, osdShape.height - 28) }
                        PathCubic {
                            control1X: 28; control1Y: osdShape.height - 14
                            control2X: 42; control2Y: osdShape.height
                            x: 56; y: osdShape.height
                        }
                        PathLine { x: Math.max(56, osdShape.width - 56); y: osdShape.height }
                        PathCubic {
                            control1X: osdShape.width - 42; control1Y: osdShape.height
                            control2X: osdShape.width - 28; control2Y: osdShape.height - 14
                            x: osdShape.width - 28; y: Math.max(31, osdShape.height - 28)
                        }
                        PathLine { x: osdShape.width - 28; y: 31 }
                        PathCubic {
                            control1X: osdShape.width - 28; control1Y: 17
                            control2X: osdShape.width - 14; control2Y: 3
                            x: osdShape.width; y: 3
                        }
                    }
                }

                RowLayout {
                    id: cardContent
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    anchors.topMargin: 10
                    anchors.bottomMargin: 14
                    spacing: 12
                    opacity: 0

                    // Album art thumbnail or music fallback icon
                    Rectangle {
                        Layout.preferredWidth: 46
                        Layout.preferredHeight: 46
                        Layout.alignment: Qt.AlignVCenter
                        radius: 12
                        color: Root.Theme.surfaceContainerHigh
                        clip: true

                        Image {
                            anchors.fill: parent
                            source: _player ? _player.trackArtUrl : ""
                            fillMode: Image.PreserveAspectCrop
                            visible: _player && _player.trackArtUrl !== ""
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "󰎆"
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: 22
                            color: Root.Theme.primary
                            visible: !_player || _player.trackArtUrl === ""
                        }
                    }

                    // Track info (Notification style)
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 2

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            Text {
                                text: {
                                    var app = (_player && _player.identity) ? _player.identity.toUpperCase() : "MUSIC"
                                    return app + " • NOW PLAYING"
                                }
                                color: Root.Theme.primary
                                font.family: Root.Theme.fontFamily
                                font.pixelSize: Root.Theme.fontSizeXS
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        Text {
                            text: (_player && _player.trackTitle !== "") ? _player.trackTitle : "Unknown Title"
                            color: Root.Theme.textPrimary
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: Root.Theme.fontSizeNormal
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Text {
                            text: {
                                if (!_player) return ""
                                var artist = _player.trackArtist || ""
                                var album = _player.trackAlbum || ""
                                if (artist !== "" && album !== "") return artist + " — " + album
                                if (artist !== "") return artist
                                if (album !== "") return album
                                return _player.identity || ""
                            }
                            color: Root.Theme.textSecondary
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: Root.Theme.fontSizeSmall
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                            visible: text !== ""
                        }
                    }
                }

                MouseArea {
                    id: cardHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton
                    onClicked: osdWin.dismiss()
                }
            }
        }
    }
}
