import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
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

    // MPRIS notifies track changes through postTrackChanged. This slow
    // discovery poll only detects players appearing/disappearing.
    Timer {
        interval: 10000
        running: true
        repeat: true
        onTriggered: musicOsd._refreshPlayer()
    }

    Connections {
        target: musicOsd._player

        function onPostTrackChanged() {
            musicOsd._refreshPlayer()
        }

        function onPlaybackStateChanged() {
            musicOsd._refreshPlayer()
        }
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

        anchors.top: true
        implicitWidth: 440
        implicitHeight: Math.max(120, Root.Theme.shelfHeight + osdCard.implicitHeight + 20)

        mask: Region {
            item: osdWrapper
        }

        function showOsd() {
            dismissAnim.stop()
            appearAnim.stop()
            if (!visible) {
                osdCard._slideY = -Math.max(60, osdCard.implicitHeight)
                osdCard._opacity = 0
                visible = true
            }
            appearAnim.start()
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

        ParallelAnimation {
            id: appearAnim
            NumberAnimation {
                target: osdCard; property: "_slideY"
                from: -Math.max(60, osdCard.implicitHeight)
                to: 0; duration: 280; easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: osdCard; property: "_opacity"
                from: 0
                to: 1; duration: 200; easing.type: Easing.OutQuad
            }
        }

        SequentialAnimation {
            id: dismissAnim
            ParallelAnimation {
                NumberAnimation {
                    target: osdCard; property: "_slideY"
                    to: -Math.max(60, osdCard.implicitHeight); duration: 200; easing.type: Easing.InQuad
                }
                NumberAnimation {
                    target: osdCard; property: "_opacity"
                    to: 0; duration: 160; easing.type: Easing.InQuad
                }
            }
            ScriptAction { script: osdWin.visible = false }
        }

        Item {
            id: osdWrapper
            width: 380
            height: osdCard.implicitHeight
            anchors.top: parent.top
            anchors.topMargin: Root.Theme.shelfHeight
            anchors.horizontalCenter: parent.horizontalCenter

            // Concave fillet left (Dynamic Island shoulder connecting to Waybar bottom edge)
            Shape {
                id: leftFillet
                width: 28
                height: 28
                anchors.top: parent.top
                anchors.right: parent.left
                layer.enabled: true
                layer.samples: 4

                ShapePath {
                    strokeWidth: 0
                    strokeColor: "transparent"
                    fillColor: Qt.rgba(Root.Theme._shelfBgColor.r, Root.Theme._shelfBgColor.g, Root.Theme._shelfBgColor.b, 0.80)

                    startX: 0
                    startY: 0
                    PathLine { x: 28; y: 0 }
                    PathLine { x: 28; y: 28 }
                    PathArc {
                        x: 0
                        y: 0
                        radiusX: 28
                        radiusY: 28
                        direction: PathArc.Counterclockwise
                    }
                }
            }

            // Concave fillet right (Dynamic Island shoulder connecting to Waybar bottom edge)
            Shape {
                id: rightFillet
                width: 28
                height: 28
                anchors.top: parent.top
                anchors.left: parent.right
                layer.enabled: true
                layer.samples: 4

                ShapePath {
                    strokeWidth: 0
                    strokeColor: "transparent"
                    fillColor: Qt.rgba(Root.Theme._shelfBgColor.r, Root.Theme._shelfBgColor.g, Root.Theme._shelfBgColor.b, 0.80)

                    startX: 28
                    startY: 0
                    PathLine { x: 0; y: 0 }
                    PathLine { x: 0; y: 28 }
                    PathArc {
                        x: 28
                        y: 0
                        radiusX: 28
                        radiusY: 28
                        direction: PathArc.Clockwise
                    }
                }
            }

            // Clipping container so the card slides out smoothly from behind Waybar
            Item {
                id: osdClip
                anchors.fill: parent
                clip: true

                Rectangle {
                    id: osdCard
                    property real _slideY: -height
                    property real _opacity: 0

                    width: parent.width
                    height: implicitHeight
                    y: _slideY
                    opacity: _opacity
                    implicitHeight: cardContent.implicitHeight + 24

                    // Dynamic Island geometry: top edge flat against Waybar, rounded bottom
                    radius: 28
                    topLeftRadius: 0
                    topRightRadius: 0
                    bottomLeftRadius: 28
                    bottomRightRadius: 28

                    color: Qt.rgba(Root.Theme._shelfBgColor.r,
                                   Root.Theme._shelfBgColor.g,
                                   Root.Theme._shelfBgColor.b, 0.80)
                    border.width: 0

                    RowLayout {
                        id: cardContent
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        anchors.topMargin: 10
                        anchors.bottomMargin: 14
                        spacing: 12

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

                    // Hover overlay
                    Rectangle {
                        anchors.fill: parent
                        color: Root.Theme.textPrimary
                        opacity: cardHover.containsMouse ? 0.04 : 0
                        radius: parent.radius
                        topLeftRadius: parent.topLeftRadius
                        topRightRadius: parent.topRightRadius
                        bottomLeftRadius: parent.bottomLeftRadius
                        bottomRightRadius: parent.bottomRightRadius
                        Behavior on opacity { NumberAnimation { duration: 120 } }
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
}
