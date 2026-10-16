import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../.." as Root

Item {
    id: root

    implicitHeight: contentColumn.implicitHeight
    implicitWidth: parent ? parent.width : 300

    property real brightness: 0.5
    property bool brightnessAvailable: true

    // ── Read brightness via brightnessctl -m ──
    Process {
        id: readProc
        command: ["brightnessctl", "--class=backlight", "-m"]
        stdout: StdioCollector {
            onStreamFinished: {
                // format: device,class,current,percentage%,max
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
        if (level < 0.33) return "󰃞";
        if (level < 0.66) return "󰃟";
        return "󰃠";
    }

    // ── UI Layout ──
    ColumnLayout {
        id: contentColumn
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: Root.Theme.spacingSmall

        // Sink name (Brightness label)
        Text {
            text: "Screen Brightness"
            font.family: Root.Theme.fontFamily
            font.pixelSize: Root.Theme.fontSizeSmall
            color: Root.Theme.textSecondary
            elide: Text.ElideRight
            Layout.fillWidth: true
        }

        // One UI-style brightness capsule
        Rectangle {
            Layout.fillWidth: true
            height: 46
            radius: height / 2
            color: Root.Theme.surfaceContainerHigh
            clip: true
            visible: root.brightnessAvailable

            // Active fill
            Rectangle {
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                width: Math.max(parent.height, parent.width * root.brightness)
                radius: parent.radius
                color: Root.Theme.sliderActiveTrack
                Behavior on width { NumberAnimation { duration: 80 } }
            }

            // Circular brightness icon surface
            Rectangle {
                width: 36
                height: 36
                anchors.left: parent.left
                anchors.leftMargin: 5
                anchors.verticalCenter: parent.verticalCenter
                radius: width / 2
                color: Root.Theme.textPrimary
                z: 1

                Text {
                    anchors.centerIn: parent
                    text: root.brightnessIcon(root.brightness)
                    font.family: Root.Theme.fontFamily
                    font.pixelSize: 21
                    color: Root.Theme.tileActiveText
                }
            }

            // Percentage text (right)
            Text {
                anchors.right: parent.right
                anchors.rightMargin: 18
                anchors.verticalCenter: parent.verticalCenter
                text: Math.round(root.brightness * 100) + "%"
                font.family: Root.Theme.fontFamily
                font.pixelSize: Root.Theme.fontSizeSmall
                font.weight: Font.DemiBold
                color: root.brightness > 0.72 ? Root.Theme.tileActiveText : Root.Theme.textPrimary
                z: 1
            }

            MouseArea {
                anchors.fill: parent
                preventStealing: true
                cursorShape: Qt.PointingHandCursor
                onPressed: (mouse) => { if (mouse.x >= 56) updateBrightness(mouse.x) }
                onPositionChanged: (mouse) => { if (pressed && mouse.x >= 56) updateBrightness(mouse.x) }
                function updateBrightness(mx) {
                    var val = Math.min(Math.max(mx / width, 0.0), 1.0);
                    root.setBrightness(val);
                }
            }
        }
    }
}
