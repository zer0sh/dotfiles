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

    // Discovery poll to catch media players starting/closing
    Timer {
        interval: 8000
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
                osdCard._translateY = -35
                osdCard._scaleY = 0.50
                osdCard._scaleX = 0.85
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

        // Appear: dots-hyprland Expressive Default Spatial spring bounce
        ParallelAnimation {
            id: appearAnim
            NumberAnimation {
                target: osdCard; property: "_translateY"
                from: -35; to: 0.0; duration: Root.Theme.animDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Root.Theme.curvePanelOpen
            }
            NumberAnimation {
                target: osdCard; property: "_scaleY"
                from: 0.50; to: 1.0; duration: Root.Theme.animDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Root.Theme.curvePanelOpen
            }
            NumberAnimation {
                target: osdCard; property: "_scaleX"
                from: 0.85; to: 1.0; duration: Root.Theme.animDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Root.Theme.curvePanelOpen
            }
            NumberAnimation {
                target: osdCard; property: "_opacity"
                from: 0.0; to: 1.0; duration: 200
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Root.Theme.curveEmphasizedDecel
            }
            SequentialAnimation {
                PauseAnimation { duration: 25 }
                NumberAnimation {
                    target: cardContent; property: "opacity"
                    from: 0.0; to: 1.0; duration: 200
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Root.Theme.curveEmphasizedDecel
                }
            }
        }

        // Dismiss: dots-hyprland Emphasized Accel close
        SequentialAnimation {
            id: dismissAnim
            ParallelAnimation {
                NumberAnimation {
                    target: cardContent; property: "opacity"
                    to: 0.0; duration: 120
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Root.Theme.curvePanelClose
                }
                NumberAnimation {
                    target: osdCard; property: "_translateY"
                    to: -35; duration: Root.Theme.animDurationFast
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Root.Theme.curvePanelClose
                }
                NumberAnimation {
                    target: osdCard; property: "_scaleY"
                    to: 0.50; duration: Root.Theme.animDurationFast
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Root.Theme.curvePanelClose
                }
                NumberAnimation {
                    target: osdCard; property: "_scaleX"
                    to: 0.85; duration: Root.Theme.animDurationFast
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Root.Theme.curvePanelClose
                }
                NumberAnimation {
                    target: osdCard; property: "_opacity"
                    to: 0.0; duration: Root.Theme.animDurationFast
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Root.Theme.curvePanelClose
                }
            }
            ScriptAction { script: osdWin.visible = false }
        }

        // ── Card container anchored directly to Waybar shelf ─────────
        Item {
            id: osdWrapper
            width: 380
            height: osdCard.implicitHeight
            anchors.top: parent.top
            anchors.topMargin: Root.Theme.shelfHeight + 14
            anchors.horizontalCenter: parent.horizontalCenter

            Item {
                id: osdCard
                property real _opacity: 0
                property real _scaleX: 1.0
                property real _scaleY: 1.0
                property real _translateY: 0.0

                width: 380
                height: implicitHeight
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                opacity: _opacity
                implicitHeight: cardContent.implicitHeight + 24

                transformOrigin: Item.Top
                transform: [
                    Translate {
                        y: osdCard._translateY
                    },
                    Scale {
                        origin.x: osdCard.width / 2
                        origin.y: 0
                        xScale: osdCard._scaleX
                        yScale: osdCard._scaleY
                    }
                ]

                // Fondo flotante unificado con esquinas redondeadas simétricas
                Rectangle {
                    id: osdCardBg
                    anchors.fill: parent
                    radius: 24
                    color: Qt.rgba(Root.Theme.panelBg.r, Root.Theme.panelBg.g, Root.Theme.panelBg.b, 0.90)
                    border.width: 1.5
                    border.color: Qt.rgba(Root.Theme.panelBorder.r, Root.Theme.panelBorder.g, Root.Theme.panelBorder.b, 0.60)
                }

                RowLayout {
                    id: cardContent
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    anchors.topMargin: 12
                    anchors.bottomMargin: 12
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
