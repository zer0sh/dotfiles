import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Services.Pipewire
import "../.." as Root

// Circular Microphone Controller (Material You Pixel style)
Item {
    id: root

    signal openAudio()

    implicitWidth: 94
    implicitHeight: 94

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
        command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle"]
    }

    Timer {
        id: micVolThrottler
        interval: 30
        repeat: false
        property real targetVol: 0
        onTriggered: {
            setVolProc.command = ["wpctl", "set-volume", "--limit", "1.0", "@DEFAULT_AUDIO_SOURCE@", targetVol.toFixed(2)];
            setVolProc.running = true;
        }
    }

    function setVolume(value) {
        var clamped = Math.min(Math.max(value, 0.0), 1.0);
        if (audio && audio.audio) {
            audio.audio.volume = clamped;
        }
        micVolThrottler.targetVol = clamped;
        if (!micVolThrottler.running)
            micVolThrottler.restart();
    }

    function toggleMute() {
        if (audio && audio.audio) {
            audio.audio.muted = !audio.audio.muted;
        }
        muteProc.running = true;
    }

    function micIcon(level, muted) {
        if (muted || level === 0) return "mic_off";
        return "mic";
    }

    CircularSlider {
        anchors.centerIn: parent
        value: root.currentVolume
        muted: root.currentMuted
        icon: root.micIcon(root.currentVolume, root.currentMuted)
        label: "Mic"
        onValueModified: (val) => root.setVolume(val)
        onIconClicked: root.toggleMute()
        onLabelClicked: root.openAudio()
    }
}
