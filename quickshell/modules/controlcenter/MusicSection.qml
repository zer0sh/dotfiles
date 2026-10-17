import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import "../.." as Root

Rectangle {
    id: root

    implicitHeight: 136
    implicitWidth: 320

    property MprisPlayer _player: null
    property bool panelVisible: false

    signal openAppRequested()

    radius: 24
    color: Root.Theme.glassCard
    border.width: 1
    border.color: Root.Theme.glassCardBorder
    clip: true

    Process {
        id: focusPlayerProc
    }

    Timer {
        interval: 2000
        running: root.panelVisible
        repeat: true
        onTriggered: root._refreshPlayer()
    }

    Component.onCompleted: _refreshPlayer()

    function _refreshPlayer() {
        var list = Mpris.players ? Mpris.players.values : null
        if (!list || list.length === 0) {
            _player = null
            return
        }
        for (var i = 0; i < list.length; i++) {
            var p = list[i]
            if (p && p.isPlaying) {
                _player = p
                return
            }
        }
        _player = list[0]
    }

    function playerAppTarget() {
        if (!_player) return ""
        var entry = (_player.desktopEntry || "").toLowerCase().replace(/\.desktop$/, "")
        var ident = (_player.identity || "").toLowerCase()
        if (entry) return entry
        if (ident.indexOf("zen") !== -1) return "zen"
        if (ident.indexOf("spotify") !== -1) return "spotify"
        if (ident.indexOf("firefox") !== -1) return "firefox"
        if (ident.indexOf("chrome") !== -1 || ident.indexOf("chromium") !== -1) return "google-chrome"
        if (ident.indexOf("vlc") !== -1) return "vlc"
        return ident.split(" ")[0]
    }

    function playerAppIcon() {
        if (!_player) return "open_in_new"
        var ident = (_player.identity || "").toLowerCase()
        var entry = (_player.desktopEntry || "").toLowerCase()
        if (ident.indexOf("spotify") !== -1 || entry.indexOf("spotify") !== -1) return "music_note"
        if (ident.indexOf("zen") !== -1 || entry.indexOf("zen") !== -1) return "public"
        if (ident.indexOf("firefox") !== -1 || entry.indexOf("firefox") !== -1) return "public"
        if (ident.indexOf("chrome") !== -1 || entry.indexOf("chrome") !== -1 || ident.indexOf("chromium") !== -1) return "public"
        if (ident.indexOf("vlc") !== -1 || entry.indexOf("vlc") !== -1) return "video_library"
        return "open_in_new"
    }

    function openPlayerApp() {
        if (!_player) return

        try {
            if (_player.canRaise) _player.raise()
        } catch (e) {}

        var target = playerAppTarget()
        var title = _player.trackTitle || ""

        focusPlayerProc.command = [
            "/home/zero/.config/quickshell/scripts/focus-player.sh",
            target,
            title
        ]
        focusPlayerProc.running = true

        root.openAppRequested()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 8

        // Top Row: Album Art + Track Info + App Link Button
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            // Album Art
            Rectangle {
                Layout.preferredWidth: 52
                Layout.preferredHeight: 52
                radius: 12
                clip: true
                color: _player && _player.trackArtUrl !== "" ? "transparent" : Qt.rgba(255, 255, 255, 0.1)

                Image {
                    anchors.fill: parent
                    source: _player ? _player.trackArtUrl : ""
                    fillMode: Image.PreserveAspectCrop
                }

                Text {
                    anchors.centerIn: parent
                    text: "music_note"
                    font.family: Root.Theme.iconFont
                    font.pixelSize: 26
                    color: Root.Theme.textSecondary
                    visible: !_player || _player.trackArtUrl === ""
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: root.openPlayerApp()
                }
            }

            // Track info (clickable to focus app)
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 48

                ColumnLayout {
                    anchors.fill: parent
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 3

                    Text {
                        text: _player && _player.trackTitle !== "" ? _player.trackTitle : "No track playing"
                        font.family: Root.Theme.fontFamily
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                        color: Root.Theme.textPrimary
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Text {
                        text: _player && _player.trackArtist !== "" ? _player.trackArtist : (_player ? _player.identity : "Media")
                        font.family: Root.Theme.fontFamily
                        font.pixelSize: 12
                        color: Root.Theme.textSecondary
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: root.openPlayerApp()
                }
            }

            // App Link / Open Button
            Rectangle {
                Layout.preferredWidth: 34
                Layout.preferredHeight: 34
                radius: 17
                visible: _player !== null
                color: linkMA.containsMouse ? Qt.rgba(255, 255, 255, 0.18) : Qt.rgba(255, 255, 255, 0.08)
                border.width: 1
                border.color: linkMA.containsMouse ? Root.Theme.primary : Qt.rgba(255, 255, 255, 0.14)

                Behavior on color { ColorAnimation { duration: Root.Theme.animDurationFast } }
                Behavior on border.color { ColorAnimation { duration: Root.Theme.animDurationFast } }

                Text {
                    anchors.centerIn: parent
                    text: "open_in_new"
                    font.family: Root.Theme.iconFont
                    font.pixelSize: 18
                    color: linkMA.containsMouse ? Root.Theme.primary : Root.Theme.textPrimary
                    Behavior on color { ColorAnimation { duration: Root.Theme.animDurationFast } }
                }

                MouseArea {
                    id: linkMA
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: root.openPlayerApp()
                }
            }
        }

        // Progress Bar
        Rectangle {
            Layout.fillWidth: true
            height: 4
            radius: 2
            color: Qt.rgba(255, 255, 255, 0.12)
            visible: _player !== null && _player.length > 0

            Rectangle {
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                width: parent.width * (_player && _player.length > 0 ? Math.min(_player.position / _player.length, 1) : 0)
                radius: parent.radius
                color: Root.Theme.primary
                Behavior on width { NumberAnimation { duration: 200 } }
            }
        }

        // Bottom Controls Row
        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            spacing: 16

            Rectangle {
                Layout.preferredWidth: 34
                Layout.preferredHeight: 34
                radius: 17
                color: prevMA.containsMouse ? Qt.rgba(255, 255, 255, 0.12) : "transparent"
                Behavior on color { ColorAnimation { duration: Root.Theme.animDurationFast } }

                Text {
                    anchors.centerIn: parent
                    text: "skip_previous"
                    font.family: Root.Theme.iconFont
                    font.pixelSize: 22
                    color: _player && _player.canGoPrevious ? Root.Theme.textPrimary : Root.Theme.textDisabled
                }

                MouseArea {
                    id: prevMA
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (_player) _player.previous()
                }
            }

            Rectangle {
                Layout.preferredWidth: 40
                Layout.preferredHeight: 40
                radius: 20
                color: playMA.containsMouse ? Root.Theme.primaryContainer : Root.Theme.primary
                Behavior on color { ColorAnimation { duration: Root.Theme.animDurationFast } }

                Text {
                    anchors.centerIn: parent
                    text: _player && _player.playbackState === MprisPlaybackState.Playing ? "pause" : "play_arrow"
                    font.family: Root.Theme.iconFont
                    font.pixelSize: 24
                    color: Root.Theme.tileActiveText
                }

                MouseArea {
                    id: playMA
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (_player) _player.togglePlaying()
                }
            }

            Rectangle {
                Layout.preferredWidth: 34
                Layout.preferredHeight: 34
                radius: 17
                color: nextMA.containsMouse ? Qt.rgba(255, 255, 255, 0.12) : "transparent"
                Behavior on color { ColorAnimation { duration: Root.Theme.animDurationFast } }

                Text {
                    anchors.centerIn: parent
                    text: "skip_next"
                    font.family: Root.Theme.iconFont
                    font.pixelSize: 22
                    color: _player && _player.canGoNext ? Root.Theme.textPrimary : Root.Theme.textDisabled
                }

                MouseArea {
                    id: nextMA
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (_player) _player.next()
                }
            }
        }
    }
}
