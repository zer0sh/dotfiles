import QtQuick
import QtQuick.Layouts
import "../.." as Root

Item {
    id: root

    property real value: 0.0
    property bool muted: false
    property string icon: ""
    property string label: ""
    property color accentColor: Root.Theme.primary

    readonly property color effectiveAccentColor: muted
        ? Qt.rgba(Root.Theme.primary.r, Root.Theme.primary.g, Root.Theme.primary.b, 0.35)
        : Root.Theme.primary

    property real trackWidth: 5
    property real knobRadius: 4.5
    property real arcRadius: 38
    property bool dragging: false

    property real displayValue: value

    Behavior on displayValue {
        enabled: !root.dragging
        NumberAnimation { duration: 60; easing.type: Easing.OutQuad }
    }

    signal valueModified(real newValue)
    signal iconClicked()
    signal labelClicked()

    implicitWidth: 94
    implicitHeight: 94

    onDisplayValueChanged: arcCanvas.requestPaint()
    onEffectiveAccentColorChanged: arcCanvas.requestPaint()
    onMutedChanged: arcCanvas.requestPaint()
    onWidthChanged: arcCanvas.requestPaint()
    onHeightChanged: arcCanvas.requestPaint()

    function updateFromPos(mx, my) {
        var cx = width / 2;
        var cy = height / 2;
        var dx = mx - cx;
        var dy = my - cy;
        var rad = Math.atan2(dy, dx);
        var deg = rad * 180 / Math.PI;
        if (deg < 0) deg += 360;

        // Dial spans 135 deg (bottom-left) to 405 deg (45 deg bottom-right)
        var a = deg;
        if (a < 90) a += 360;

        var val;
        if (deg > 45 && deg < 135) {
            val = (deg > 90) ? 0.0 : 1.0;
        } else {
            val = (a - 135) / 270.0;
            val = Math.max(0.0, Math.min(1.0, val));
        }
        root.valueModified(val);
    }

    // Outer Canvas for minimal circular border & accent arc
    Canvas {
        id: arcCanvas
        anchors.fill: parent
        antialiasing: true
        smooth: true

        onAvailableChanged: if (available) requestPaint()
        Component.onCompleted: requestPaint()

        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);

            var cx = width / 2;
            var cy = height / 2;
            var r = root.arcRadius;

            var startDeg = 135;
            var totalDeg = 270;
            var startRad = startDeg * Math.PI / 180;
            var endDeg = startDeg + totalDeg;
            var endRad = endDeg * Math.PI / 180;

            // 1. Inactive background track
            ctx.beginPath();
            ctx.arc(cx, cy, r, startRad, endRad, false);
            ctx.lineWidth = root.trackWidth;
            ctx.lineCap = "round";
            ctx.strokeStyle = Qt.rgba(255, 255, 255, 0.10);
            ctx.stroke();

            // 2. Active arc (border with accent)
            var val = Math.max(0.0, Math.min(1.0, root.displayValue));
            var activeEndRad = startRad;

            if (val > 0.005) {
                var activeEndDeg = startDeg + val * totalDeg;
                activeEndRad = activeEndDeg * Math.PI / 180;

                ctx.beginPath();
                ctx.arc(cx, cy, r, startRad, activeEndRad, false);
                ctx.lineWidth = root.trackWidth;
                ctx.lineCap = "round";
                ctx.strokeStyle = root.effectiveAccentColor;
                ctx.stroke();
            }

            // 3. Knob indicator
            var knobX = cx + r * Math.cos(activeEndRad);
            var knobY = cy + r * Math.sin(activeEndRad);

            // Subtle knob shadow
            ctx.beginPath();
            ctx.arc(knobX, knobY, root.knobRadius + 1.5, 0, 2 * Math.PI);
            ctx.fillStyle = Qt.rgba(0, 0, 0, 0.40);
            ctx.fill();

            // Knob core in accent
            ctx.beginPath();
            ctx.arc(knobX, knobY, root.knobRadius, 0, 2 * Math.PI);
            ctx.fillStyle = val > 0.005 ? root.effectiveAccentColor : Qt.rgba(255, 255, 255, 0.35);
            ctx.fill();

            // Inner bright dot
            ctx.beginPath();
            ctx.arc(knobX, knobY, root.knobRadius * 0.45, 0, 2 * Math.PI);
            ctx.fillStyle = val > 0.005 ? Qt.rgba(255, 255, 255, 0.85) : Qt.rgba(255, 255, 255, 0.6);
            ctx.fill();
        }
    }

    // Outer MouseArea for dragging along the circular border & mouse wheel
    MouseArea {
        id: outerMouse
        anchors.fill: parent
        hoverEnabled: true
        preventStealing: true
        cursorShape: Qt.PointingHandCursor

        onPressed: (mouse) => {
            var cx = width / 2;
            var cy = height / 2;
            var dx = mouse.x - cx;
            var dy = mouse.y - cy;
            var dist = Math.sqrt(dx * dx + dy * dy);
            // If clicking outer border area, start drag immediately
            if (dist >= 28) {
                root.dragging = true;
                root.updateFromPos(mouse.x, mouse.y);
            }
        }

        onPositionChanged: (mouse) => {
            if (root.dragging) {
                root.updateFromPos(mouse.x, mouse.y);
            }
        }

        onReleased: {
            root.dragging = false;
        }

        onCanceled: {
            root.dragging = false;
        }

        onWheel: (wheel) => {
            var step = (wheel.angleDelta.y > 0) ? 0.05 : -0.05;
            var n = Math.max(0.0, Math.min(1.0, root.value + step));
            root.valueModified(n);
        }
    }

    // Center interactive area (purely minimal, no separate inner disc)
    Item {
        id: centerArea
        width: 56
        height: 56
        anchors.centerIn: parent

        scale: centerMouse.pressed ? 0.90 : (centerMouse.containsMouse ? 1.08 : 1.0)

        Behavior on scale {
            NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 2

            // Center Icon (Tapping mutes)
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: root.icon
                font.family: Root.Theme.iconFont
                font.pixelSize: 26
                color: root.muted
                    ? Root.Theme.textSecondary
                    : (centerMouse.containsMouse ? root.effectiveAccentColor : Root.Theme.textPrimary)

                Behavior on color {
                    ColorAnimation { duration: Root.Theme.animDurationFast }
                }
            }

            // Minimal sub-label (label, percentage when dragging, or "Mute")
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: root.muted
                    ? "Mute"
                    : (root.dragging ? Math.round(root.value * 100) + "%" : root.label)
                font.family: Root.Theme.fontFamily
                font.pixelSize: 11
                font.weight: Font.Medium
                color: root.muted
                    ? (Root.Theme.error !== undefined ? Root.Theme.error : "#F28B82")
                    : (centerMouse.containsMouse ? Root.Theme.textPrimary : Root.Theme.textSecondary)

                Behavior on color {
                    ColorAnimation { duration: Root.Theme.animDurationFast }
                }
            }
        }

        MouseArea {
            id: centerMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton

            onClicked: (mouse) => {
                if (mouse.button === Qt.RightButton) {
                    root.labelClicked();
                } else {
                    root.iconClicked();
                }
            }

            onWheel: (wheel) => {
                var step = (wheel.angleDelta.y > 0) ? 0.05 : -0.05;
                var n = Math.max(0.0, Math.min(1.0, root.value + step));
                root.valueModified(n);
            }
        }
    }
}
