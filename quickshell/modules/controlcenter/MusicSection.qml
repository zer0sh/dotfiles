import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import "../.." as Root

Item {
    id: root

    implicitHeight: contentColumn.implicitHeight
    implicitWidth: parent ? parent.width : 300

    property MprisPlayer _player: null
    property bool panelVisible: false

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

    ColumnLayout {
        id: contentColumn
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: Root.Theme.spacingSmall

        Text {
            text: _player ? _player.identity : "No media playing"
            font.family: Root.Theme.fontFamily
            font.pixelSize: Root.Theme.fontSizeSmall
            color: Root.Theme.textSecondary
            elide: Text.ElideRight
            Layout.fillWidth: true
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Root.Theme.spacingMedium

            Rectangle {
                Layout.preferredWidth: 56
                Layout.preferredHeight: 56
                radius: 12
                clip: true
                color: _player && _player.trackArtUrl !== "" ? "transparent" : Root.Theme.surfaceContainerHigh
                visible: _player !== null

                Image {
                    anchors.fill: parent
                    source: _player ? _player.trackArtUrl : ""
                    fillMode: Image.PreserveAspectCrop
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 12
                    color: "transparent"
                    border.width: 1
                    border.color: Qt.rgba(Root.Theme.panelBorder.r, Root.Theme.panelBorder.g, Root.Theme.panelBorder.b, 0.3)
                }

                Text {
                    anchors.centerIn: parent
                    text: "󰝚"
                    font.family: Root.Theme.fontFamily
                    font.pixelSize: 24
                    color: Root.Theme.textSecondary
                    visible: !_player || _player.trackArtUrl === ""
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    text: _player && _player.trackTitle !== "" ? _player.trackTitle : "No track"
                    font.family: Root.Theme.fontFamily
                    font.pixelSize: Root.Theme.fontSizeNormal
                    font.weight: Font.DemiBold
                    color: Root.Theme.textPrimary
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Text {
                    text: _player && _player.trackArtist !== "" ? _player.trackArtist : _player ? _player.identity : ""
                    font.family: Root.Theme.fontFamily
                    font.pixelSize: Root.Theme.fontSizeSmall
                    color: Root.Theme.textSecondary
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 6
            radius: 3
            color: Root.Theme.sliderTrack
            visible: _player !== null && _player.length > 0

            Rectangle {
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                width: parent.width * (_player && _player.length > 0 ? Math.min(_player.position / _player.length, 1) : 0)
                radius: parent.radius
                color: Root.Theme.sliderActiveTrack
                Behavior on width { NumberAnimation { duration: 200 } }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            spacing: Root.Theme.spacingLarge
            visible: _player !== null

            Rectangle {
                Layout.preferredWidth: 40
                Layout.preferredHeight: 40
                radius: 20
                color: prevMA.containsMouse ? Root.Theme.surfaceContainerHigh : "transparent"
                Behavior on color { ColorAnimation { duration: Root.Theme.animDurationFast } }

                Text {
                    anchors.centerIn: parent
                    text: "󰒫"
                    font.family: Root.Theme.fontFamily
                    font.pixelSize: Root.Theme.fontSizeLarge
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
                Layout.preferredWidth: 48
                Layout.preferredHeight: 48
                radius: 24
                color: playMA.containsMouse ? Root.Theme.primaryContainer : Root.Theme.primary
                Behavior on color { ColorAnimation { duration: Root.Theme.animDurationFast } }

                Text {
                    anchors.centerIn: parent
                    text: _player && _player.playbackState === MprisPlaybackState.Playing ? "󰏤" : "󰐊"
                    font.family: Root.Theme.fontFamily
                    font.pixelSize: Root.Theme.fontSizeLarge
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
                Layout.preferredWidth: 40
                Layout.preferredHeight: 40
                radius: 20
                color: nextMA.containsMouse ? Root.Theme.surfaceContainerHigh : "transparent"
                Behavior on color { ColorAnimation { duration: Root.Theme.animDurationFast } }

                Text {
                    anchors.centerIn: parent
                    text: "󰒬"
                    font.family: Root.Theme.fontFamily
                    font.pixelSize: Root.Theme.fontSizeLarge
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
