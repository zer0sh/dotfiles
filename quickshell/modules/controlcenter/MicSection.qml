import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Services.Pipewire
import "../.." as Root

// Vertical Glassmorphic Microphone Capsule (Material You Pixel style)
Rectangle {
    id: root

    signal openAudio()

    implicitWidth: 44
    implicitHeight: 310

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSource]
    }

    property var audio: Pipewire.defaultAudioSource
    readonly property real currentVolume: audio && audio.audio ? audio.audio.volume : 0
    readonly property bool currentMuted: audio && audio.audio ? audio.audio.muted : false
    readonly property string sourceName: audio && audio.description ? audio.description : "Microphone"
    readonly property int volumePercent: Math.round(currentVolume * 100)

    Process {
        id: setVolProc
    }

    Process {
        id: muteProc
    }

    function setVolume(value) {
        var clamped = Math.min(Math.max(value, 0.0), 1.0);
        if (audio && audio.audio) {
            audio.audio.volume = clamped;
        } else {
            setVolProc.command = ["wpctl", "set-volume", "@DEFAULT_SOURCE@", clamped.toFixed(2)];
            setVolProc.running = true;
        }
    }

    function toggleMute() {
        if (audio && audio.audio) {
            audio.audio.muted = !audio.audio.muted;
        } else {
            muteProc.command = ["wpctl", "set-mute", "@DEFAULT_SOURCE@", "toggle"];
            muteProc.running = true;
        }
    }

    function micIcon(level, muted) {
        if (muted || level === 0) return "mic_off";
        return "mic";
    }

    radius: width / 2
    color: Qt.rgba(0, 0, 0, 0.22)
    border.width: 1
    border.color: Qt.rgba(255, 255, 255, 0.08)
    clip: true

    // Vertical Progress Fill (bottom to top)
    Rectangle {
        id: progressFill
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: Math.max(0, parent.height * root.currentVolume)
        radius: parent.radius
        color: root.currentMuted
            ? Qt.rgba(Root.Theme.primary.r, Root.Theme.primary.g, Root.Theme.primary.b, 0.35)
            : Root.Theme.primary

        Behavior on height { NumberAnimation { duration: 60 } }
        Behavior on color { ColorAnimation { duration: Root.Theme.animDurationFast } }
    }

    // Top Percentage / "Mute" badge
    Text {
        id: percentText
        anchors.top: parent.top
        anchors.topMargin: 14
        anchors.horizontalCenter: parent.horizontalCenter
        text: root.currentMuted ? "Mute" : root.volumePercent + "%"
        font.family: Root.Theme.fontFamily
        font.pixelSize: 11
        font.weight: Font.DemiBold
        color: (root.currentVolume > 0.88 && !root.currentMuted)
            ? Root.Theme.tileActiveText
            : Root.Theme.textPrimary
        z: 2

        Behavior on color { ColorAnimation { duration: Root.Theme.animDurationFast } }
    }

    // Bottom Microphone Icon
    Text {
        id: iconText
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 14
        anchors.horizontalCenter: parent.horizontalCenter
        text: root.micIcon(root.currentVolume, root.currentMuted)
        font.family: Root.Theme.iconFont
        font.pixelSize: 20
        color: (root.currentVolume > 0.14 && !root.currentMuted)
            ? Root.Theme.tileActiveText
            : Root.Theme.textPrimary
        z: 2

        Behavior on color { ColorAnimation { duration: Root.Theme.animDurationFast } }
    }

    // Interaction
    MouseArea {
        anchors.fill: parent
        preventStealing: true
        cursorShape: Qt.PointingHandCursor
        onClicked: (mouse) => {
            if (mouse.y > height - 48) {
                root.toggleMute();
            } else if (mouse.y < 40) {
                root.openAudio();
            } else {
                updateVolume(mouse.y);
            }
        }
        onPressed: (mouse) => {
            if (mouse.y <= height - 48 && mouse.y >= 40) updateVolume(mouse.y);
        }
        onPositionChanged: (mouse) => {
            if (pressed) updateVolume(mouse.y);
        }
        function updateVolume(my) {
            var val = Math.min(Math.max((height - my) / height, 0.0), 1.0);
            root.setVolume(val);
        }
    }
}
