import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import "../.." as Root

Item {
    id: root

    implicitHeight: contentColumn.implicitHeight
    implicitWidth: parent ? parent.width : 300

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    property var audio: Pipewire.defaultAudioSink
    readonly property real currentVolume: audio && audio.audio ? audio.audio.volume : 0
    readonly property bool currentMuted: audio && audio.audio ? audio.audio.muted : false
    readonly property string sinkName: audio && audio.description ? audio.description : "Audio Output"
    readonly property int volumePercent: Math.round(currentVolume * 100)

    function setVolume(value) {
        var clamped = Math.min(Math.max(value, 0.0), 1.0);
        if (audio && audio.audio)
            audio.audio.volume = clamped;
    }

    function toggleMute() {
        if (audio && audio.audio)
            audio.audio.muted = !audio.audio.muted;
    }

    function volumeIcon(level, muted) {
        if (muted || level === 0) return "󰖁";
        if (level < 0.34) return "󰕿";
        if (level < 0.67) return "󰖀";
        return "󰕾";
    }

    // ── UI Layout ──
    ColumnLayout {
        id: contentColumn
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: Root.Theme.spacingSmall

        // Sink name
        Text {
            text: root.sinkName
            font.family: Root.Theme.fontFamily
            font.pixelSize: Root.Theme.fontSizeSmall
            color: Root.Theme.textSecondary
            elide: Text.ElideRight
            Layout.fillWidth: true
        }

        // One UI-style volume capsule
        Rectangle {
            Layout.fillWidth: true
            height: 46
            radius: height / 2
            color: Root.Theme.surfaceContainerHigh
            clip: true

            // Active fill — dims when muted
            Rectangle {
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                width: Math.max(parent.height, parent.width * root.currentVolume)
                radius: parent.radius
                color: root.currentMuted
                    ? Qt.rgba(Root.Theme.sliderActiveTrack.r, Root.Theme.sliderActiveTrack.g, Root.Theme.sliderActiveTrack.b, 0.35)
                    : Root.Theme.sliderActiveTrack
                Behavior on width { NumberAnimation { duration: 80 } }
                Behavior on color { ColorAnimation { duration: Root.Theme.animDurationFast } }
            }

            // Circular icon control (left, click = mute toggle)
            Rectangle {
                id: volumeIconButton
                width: 36
                height: 36
                anchors.left: parent.left
                anchors.leftMargin: 5
                anchors.verticalCenter: parent.verticalCenter
                radius: width / 2
                color: root.currentMuted
                    ? Root.Theme.surfaceContainer
                    : Root.Theme.textPrimary
                z: 1

                Text {
                    anchors.centerIn: parent
                    text: root.volumeIcon(root.currentVolume, root.currentMuted)
                    font.family: Root.Theme.fontFamily
                    font.pixelSize: 21
                    color: root.currentMuted ? Root.Theme.textPrimary : Root.Theme.tileActiveText
                }
            }

            // Percentage or "Muted" (right)
            Text {
                anchors.right: parent.right
                anchors.rightMargin: 18
                anchors.verticalCenter: parent.verticalCenter
                text: root.currentMuted ? "Muted" : root.volumePercent + "%"
                font.family: Root.Theme.fontFamily
                font.pixelSize: Root.Theme.fontSizeSmall
                font.weight: Font.DemiBold
                color: root.currentVolume > 0.72 && !root.currentMuted
                    ? Root.Theme.tileActiveText : Root.Theme.textPrimary
                z: 1
            }

            MouseArea {
                anchors.fill: parent
                preventStealing: true
                cursorShape: Qt.PointingHandCursor
                onClicked: (mouse) => { if (mouse.x < 56) root.toggleMute() }
                onPressed: (mouse) => { if (mouse.x >= 56) updateVolume(mouse.x) }
                onPositionChanged: (mouse) => { if (pressed && mouse.x >= 56) updateVolume(mouse.x) }
                function updateVolume(mx) {
                    var val = Math.min(Math.max(mx / width, 0.0), 1.0);
                    root.setVolume(val);
                }
            }
        }

    }
}
