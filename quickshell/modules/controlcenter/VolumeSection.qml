import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Services.Pipewire
import "../.." as Root

// Circular Volume Controller (Material You Pixel style)
Item {
    id: root

    signal openAudio()

    implicitWidth: 94
    implicitHeight: 94

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    property var audio: Pipewire.defaultAudioSink
    readonly property real currentVolume: audio && audio.audio ? audio.audio.volume : 0
    readonly property bool currentMuted: audio && audio.audio ? audio.audio.muted : false
    readonly property string sinkName: audio && audio.description ? audio.description : "Audio Output"
    readonly property int volumePercent: Math.round(currentVolume * 100)

    Process {
        id: muteProc
        command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]
    }

    Process {
        id: setVolProc
    }

    Timer {
        id: volThrottler
        interval: 30
        repeat: false
        property real targetVol: 0
        onTriggered: {
            setVolProc.command = ["wpctl", "set-volume", "--limit", "1.0", "@DEFAULT_AUDIO_SINK@", targetVol.toFixed(2)];
            setVolProc.running = true;
        }
    }

    function setVolume(value) {
        var clamped = Math.min(Math.max(value, 0.0), 1.0);
        if (audio && audio.audio)
            audio.audio.volume = clamped;
        volThrottler.targetVol = clamped;
        if (!volThrottler.running)
            volThrottler.restart();
    }

    function toggleMute() {
        if (audio && audio.audio)
            audio.audio.muted = !audio.audio.muted;
        muteProc.running = true;
    }

    function volumeIcon(level, muted) {
        if (muted || level === 0) return "volume_off";
        if (level < 0.50) return "volume_down";
        return "volume_up";
    }

    CircularSlider {
        anchors.centerIn: parent
        value: root.currentVolume
        muted: root.currentMuted
        icon: root.volumeIcon(root.currentVolume, root.currentMuted)
        label: "Audio"
        onValueModified: (val) => root.setVolume(val)
        onIconClicked: root.toggleMute()
        onLabelClicked: root.openAudio()
    }
}
