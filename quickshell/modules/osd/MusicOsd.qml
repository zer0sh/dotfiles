import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Mpris
import "../.." as Root

Scope {
    id: musicOsd

    property MprisPlayer _player: null
    property QtObject miniPlayerRef: null
    property int _lastUniqueId: -1

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

    Component.onCompleted: _refreshPlayer()

    function _refreshPlayer() {
        var oldPlayer = _player
        var list = Mpris.players ? Mpris.players.values : null
        var newPlayer = null

        if (list && list.length > 0) {
            for (var i = 0; i < list.length; i++) {
                var p = list[i]
                if (p.isPlaying) {
                    newPlayer = p
                    break
                }
            }
            if (!newPlayer) newPlayer = list[0]
        }

        var miniBlocked = miniPlayerRef && miniPlayerRef.panelVisible

        if (newPlayer !== oldPlayer) {
            _player = newPlayer
            _lastUniqueId = -1
            if (newPlayer && !miniBlocked) osdWin.showOsd()
        } else if (newPlayer && newPlayer.uniqueId !== _lastUniqueId) {
            _lastUniqueId = newPlayer.uniqueId
            if (!miniBlocked) osdWin.showOsd()
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
        implicitHeight: 120

        function showOsd() {
            dismissAnim.stop()
            if (!visible) {
                osdCard._opacity = 0
                osdCard._slideY = -28
                visible = true
                appearAnim.start()
            }
            dismissTimer.restart()
        }

        Timer {
            id: dismissTimer
            interval: 3000
            repeat: false
            onTriggered: dismissAnim.start()
        }

        // Appear: slide down + fade in
        ParallelAnimation {
            id: appearAnim
            NumberAnimation {
                target: osdCard; property: "_opacity"
                from: 0; to: 1; duration: 220; easing.type: Easing.OutQuad
            }
            NumberAnimation {
                target: osdCard; property: "_slideY"
                from: -28; to: 0; duration: 260; easing.type: Easing.OutCubic
            }
        }

        // Dismiss: slide up + fade out, then hide window
        SequentialAnimation {
            id: dismissAnim
            ParallelAnimation {
                NumberAnimation {
                    target: osdCard; property: "_opacity"
                    to: 0; duration: 180; easing.type: Easing.InQuad
                }
                NumberAnimation {
                    target: osdCard; property: "_slideY"
                    to: -20; duration: 180; easing.type: Easing.InQuad
                }
            }
            ScriptAction { script: osdWin.visible = false }
        }

        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top:              parent.top
            anchors.topMargin:        46
            width: 360
            height: 56

            Rectangle {
                id: osdCard
                property real _opacity: 0
                property real _slideY: -28

                width: parent.width
                height: parent.height
                y: _slideY
                opacity: _opacity

                radius: 27
                color: Qt.rgba(Root.Theme.panelBg.r, Root.Theme.panelBg.g, Root.Theme.panelBg.b, 0.80)
                border.width: 1
                border.color: Qt.rgba(Root.Theme.panelBorder.r, Root.Theme.panelBorder.g, Root.Theme.panelBorder.b, 0.45)

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 12
                    spacing: 10

                    Rectangle {
                        Layout.preferredWidth: 36
                        Layout.preferredHeight: 36
                        radius: 8
                        color: _player && _player.trackArtUrl !== "" ? "transparent" : Root.Theme.surfaceContainerHigh

                        Image {
                            anchors.fill: parent
                            source: _player ? _player.trackArtUrl : ""
                            fillMode: Image.PreserveAspectCrop
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "󰝚"
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: 16
                            color: Root.Theme.textSecondary
                            visible: !_player || _player.trackArtUrl === ""
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        Text {
                            text: "Playing now..."
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: Root.Theme.fontSizeNormal
                            font.weight: Font.DemiBold
                            color: Root.Theme.textPrimary
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Text {
                            text: _player && _player.trackArtist !== "" ? _player.trackArtist : (_player ? _player.identity : "")
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: Root.Theme.fontSizeSmall
                            color: Root.Theme.textSecondary
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    Text {
                        visible: false
                        text: _player && _player.playbackState === MprisPlaybackState.Playing ? "󰏤" : "󰐊"
                        font.family: Root.Theme.fontFamily
                        font.pixelSize: 20
                        color: Root.Theme.primary
                        Layout.alignment: Qt.AlignVCenter
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        dismissTimer.stop()
                        dismissAnim.start()
                    }
                }
            }
        }
    }
}
