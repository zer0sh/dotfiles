import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../.." as Root

// Vertical Glassmorphic Brightness Capsule (Material You Pixel style)
Rectangle {
    id: root

    implicitWidth: 60
    implicitHeight: 310

    property real brightness: 0.5
    property bool brightnessAvailable: true

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
                    if (!isNaN(current) && !isNaN(max) && max > 0)
                        root.brightness = current / max;
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
        setProc.command = ["brightnessctl", "set", Math.round(clamped * 100) + "%"];
        setProc.running = true;
    }

    function brightnessIcon(level) {
        if (level < 0.33) return "brightness_low";
        if (level < 0.66) return "brightness_medium";
        return "brightness_high";
    }

    radius: width / 2
    color: Qt.rgba(0, 0, 0, 0.22)
    border.width: 1
    border.color: Qt.rgba(255, 255, 255, 0.08)
    clip: true
    visible: root.brightnessAvailable

    // Vertical Progress Fill (bottom to top)
    Rectangle {
        id: progressFill
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: Math.max(0, parent.height * root.brightness)
        radius: parent.radius
        color: Root.Theme.primary

        Behavior on height { NumberAnimation { duration: 60 } }
    }

    // Top Percentage
    Text {
        id: percentText
        anchors.top: parent.top
        anchors.topMargin: 16
        anchors.horizontalCenter: parent.horizontalCenter
        text: Math.round(root.brightness * 100) + "%"
        font.family: Root.Theme.fontFamily
        font.pixelSize: 13
        font.weight: Font.DemiBold
        color: root.brightness > 0.88 ? Root.Theme.tileActiveText : Root.Theme.textPrimary
        z: 2

        Behavior on color { ColorAnimation { duration: Root.Theme.animDurationFast } }
    }

    // Bottom Brightness Icon
    Text {
        id: iconText
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 16
        anchors.horizontalCenter: parent.horizontalCenter
        text: root.brightnessIcon(root.brightness)
        font.family: Root.Theme.iconFont
        font.pixelSize: 24
        color: root.brightness > 0.14 ? Root.Theme.tileActiveText : Root.Theme.textPrimary
        z: 2

        Behavior on color { ColorAnimation { duration: Root.Theme.animDurationFast } }
    }

    // Interaction
    MouseArea {
        anchors.fill: parent
        preventStealing: true
        cursorShape: Qt.PointingHandCursor
        onClicked: (mouse) => updateBrightness(mouse.y)
        onPressed: (mouse) => updateBrightness(mouse.y)
        onPositionChanged: (mouse) => {
            if (pressed) updateBrightness(mouse.y);
        }
        function updateBrightness(my) {
            var val = Math.min(Math.max((height - my) / height, 0.0), 1.0);
            root.setBrightness(val);
        }
    }
}
