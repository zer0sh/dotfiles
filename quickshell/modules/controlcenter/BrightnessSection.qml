import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../.." as Root

// Circular Brightness Controller (Material You Pixel style)
Item {
    id: root

    implicitWidth: 94
    implicitHeight: 94

    property real brightness: 0.5
    property bool brightnessAvailable: true
    property real savedBrightness: 0.5
    property bool isMuted: brightness < 0.02

    // ── Read brightness via brightnessctl -m ──
    Process {
        id: readProc
        command: ["brightnessctl", "--class=backlight", "-m"]
        stdout: StdioCollector {
            onStreamFinished: {
                var parts = text.trim().split(",");
                if (parts.length >= 5) {
                    var current = parseFloat(parts[2]);
                    var max = parseFloat(parts[4]);
                    if (!isNaN(current) && !isNaN(max) && max > 0) {
                        var val = current / max;
                        root.brightness = val;
                        if (val > 0.05) root.savedBrightness = val;
                    }
                }
            }
        }
        onExited: (code, status) => {
            if (code !== 0)
                root.brightnessAvailable = false;
        }
    }

    // ── Set brightness process ──
    Process {
        id: setProc
    }

    Component.onCompleted: readProc.running = true

    function setBrightness(value) {
        var clamped = Math.min(Math.max(value, 0.0), 1.0);
        root.brightness = clamped;
        if (clamped > 0.05) root.savedBrightness = clamped;
        setProc.command = ["brightnessctl", "set", Math.round(clamped * 100) + "%"];
        setProc.running = true;
    }

    function toggleMute() {
        if (root.brightness > 0.02) {
            root.savedBrightness = root.brightness;
            setBrightness(0.0);
        } else {
            var restore = (root.savedBrightness > 0.05) ? root.savedBrightness : 0.5;
            setBrightness(restore);
        }
    }

    function brightnessIcon(level, muted) {
        if (muted || level < 0.02) return "brightness_low";
        if (level < 0.33) return "brightness_low";
        if (level < 0.66) return "brightness_medium";
        return "brightness_high";
    }

    visible: root.brightnessAvailable

    CircularSlider {
        anchors.centerIn: parent
        value: root.brightness
        muted: root.isMuted
        icon: root.brightnessIcon(root.brightness, root.isMuted)
        label: "Screen"
        onValueModified: (val) => root.setBrightness(val)
        onIconClicked: root.toggleMute()
    }
}
