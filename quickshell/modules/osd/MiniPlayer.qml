import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Mpris
import "../.." as Root

Scope {
    id: miniPlayer

    property MprisPlayer _player: null
    property bool panelVisible: false

    Timer {
        interval: 1500
        running: true
        repeat: true
        onTriggered: miniPlayer._refreshPlayer()
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

    IpcHandler {
        target: "miniplayer"
        function toggle(): void { miniPlayer.panelVisible = !miniPlayer.panelVisible }
        function show(): void { miniPlayer.panelVisible = true }
        function hide(): void { miniPlayer.panelVisible = false }
    }

    Loader {
        active: miniPlayer.panelVisible

        sourceComponent: PanelWindow {
            id: osdWin
            visible: true
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "quickshell:miniplayer"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            anchors.bottom: true
            anchors.left: true
            anchors.right: true
            implicitHeight: 120

            MouseArea {
                anchors.fill: parent
                onClicked: miniPlayer.panelVisible = false
            }

            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 40
                width: 400
                height: 72

                MouseArea {
                    anchors.fill: parent
                    onClicked: miniPlayer.panelVisible = false
                }

                Rectangle {
                    id: osdCard
                    anchors.fill: parent
                    radius: 27
                    color: Qt.rgba(Root.Theme.panelBg.r, Root.Theme.panelBg.g, Root.Theme.panelBg.b, 0.80)
                    border.width: 1
                    border.color: Qt.rgba(Root.Theme.panelBorder.r, Root.Theme.panelBorder.g, Root.Theme.panelBorder.b, 0.45)

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        spacing: 12

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
                            Layout.alignment: Qt.AlignVCenter

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
                                text: _player && _player.trackArtist !== "" ? _player.trackArtist : (_player ? _player.identity : "")
                                font.family: Root.Theme.fontFamily
                                font.pixelSize: Root.Theme.fontSizeSmall
                                color: Root.Theme.textSecondary
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        RowLayout {
                            spacing: 4
                            Layout.alignment: Qt.AlignVCenter

                            Rectangle {
                                Layout.preferredWidth: 34
                                Layout.preferredHeight: 34
                                radius: 17
                                color: prevMA.containsMouse ? Root.Theme.surfaceContainerHigh : "transparent"
                                Behavior on color { ColorAnimation { duration: 100 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰒫"
                                    font.family: Root.Theme.fontFamily
                                    font.pixelSize: 18
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
                                Layout.preferredWidth: 38
                                Layout.preferredHeight: 38
                                radius: 19
                                color: playMA.containsMouse ? Root.Theme.primaryContainer : Root.Theme.primary
                                Behavior on color { ColorAnimation { duration: 100 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: _player && _player.playbackState === MprisPlaybackState.Playing ? "󰏤" : "󰐊"
                                    font.family: Root.Theme.fontFamily
                                    font.pixelSize: 18
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
                                color: nextMA.containsMouse ? Root.Theme.surfaceContainerHigh : "transparent"
                                Behavior on color { ColorAnimation { duration: 100 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰒬"
                                    font.family: Root.Theme.fontFamily
                                    font.pixelSize: 18
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
            }
        }
    }
}
