import QtQuick
import "../.." as Root

// ChromeOS-style app icon: white circle background + icon + label
// Hover state: white semi-transparent rounded rect behind the whole cell
Item {
    id: appIcon
    width: 120
    height: 120

    required property string appName
    required property string iconSource

    property bool isSelected: false

    signal clicked()

    // ── Hover / selected background (white translucent rounded rect) ─
    Rectangle {
        id: hoverRect
        anchors.fill: parent
        anchors.margins: 9
        radius: 22
        color: mouseArea.pressed
            ? Qt.rgba(1, 1, 1, 0.15)
            : (mouseArea.containsMouse || appIcon.isSelected)
                ? Qt.rgba(1, 1, 1, 0.08)
                : "transparent"

        Behavior on color { ColorAnimation { duration: 100 } }
    }

    // ── Colored circle background ─────────────────────────────
    readonly property var palette: [
        "#E57373", "#64B5F6", "#81C784", "#FFB74D",
        "#BA68C8", "#4DD0E1", "#F06292", "#AED581",
        "#7986CB", "#FFD54F", "#4DB6AC", "#A1887F"
    ]

    property color circleColor: {
        var idx = appName.charCodeAt(0) % palette.length;
        return palette[idx];
    }

    Rectangle {
        id: circleBackground
        width: 54
        height: 54
        radius: 27
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 12
        color: Qt.rgba(circleColor.r, circleColor.g, circleColor.b, 0.75)
        clip: true

        scale: mouseArea.pressed ? 0.93 : 1.0
        Behavior on scale {
            NumberAnimation { duration: 80; easing.type: Easing.OutCubic }
        }

        // ── First letter (no icons) ─
        Text {
            anchors.centerIn: parent
            text: appIcon.appName.length > 0 ? appIcon.appName.charAt(0).toUpperCase() : "?"
            font.pixelSize: 24
            font.family: Root.Theme.fontFamily
            font.weight: Font.Bold
            color: "#ffffff"
        }
    }

    // ── App name label ───────────────────────────────────────────
    Text {
        anchors.top: circleBackground.bottom
        anchors.topMargin: 8
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width - 8
        text: appIcon.appName
        font.pixelSize: 12
        font.family: Root.Theme.fontFamily
        font.weight: Font.Bold
        color: Root.Theme.textPrimary
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
        maximumLineCount: 2
    }

    // ── Click area ───────────────────────────────────────────────
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: appIcon.clicked()
    }
}
