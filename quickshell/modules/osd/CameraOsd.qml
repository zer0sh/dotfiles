import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../.." as Root

Scope {
    id: cameraOsd

    property bool isMirrored: true
    property bool streamActive: false
    property bool hasFrame: false
    property int _frameCounter: 0
    property int imgActive: 0
    property string lastSnapshotPath: ""

    IpcHandler {
        target: "camera"

        function toggle(): void {
            if (osdWin.visible && !dismissAnim.running) {
                osdWin.dismiss()
            } else {
                osdWin.showOsd()
            }
        }

        function show(): void {
            osdWin.showOsd()
        }

        function hide(): void {
            osdWin.dismiss()
        }
    }

    Process {
        id: streamProc
        command: ["/usr/bin/python3", "/home/zero/.config/quickshell/scripts/camera-preview.py", "stream"]
    }

    Process {
        id: snapProc
        command: ["/usr/bin/python3", "/home/zero/.config/quickshell/scripts/camera-preview.py", "snapshot"]
        stdout: StdioCollector {
            onStreamFinished: {
                var p = text.trim()
                if (p !== "") {
                    cameraOsd.lastSnapshotPath = p
                }
            }
        }
    }

    function takeSnapshot() {
        flashAnim.restart()
        dismissTimer.restart()
        if (!snapProc.running) {
            snapProc.running = true
        }
    }

    Timer {
        id: frameTimer
        interval: 60
        repeat: true
        running: osdWin.visible && cameraOsd.streamActive
        onTriggered: {
            cameraOsd._frameCounter++
            var nextSource = "file:///tmp/qs-camera-preview.jpg?v=" + cameraOsd._frameCounter
            if (cameraOsd.imgActive === 0) {
                imgB.source = nextSource
            } else {
                imgA.source = nextSource
            }
        }
    }

    PanelWindow {
        id: osdWin
        visible: false
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell:camera-osd"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        anchors.top: true
        implicitWidth: 440
        implicitHeight: Math.max(140, Root.Theme.shelfHeight + osdCard.implicitHeight + 20)

        mask: Region {
            item: osdWrapper
        }

        function showOsd() {
            dismissAnim.stop()
            appearAnim.stop()

            cameraOsd.hasFrame = false
            cameraOsd._frameCounter = 0
            cameraOsd.imgActive = 0
            imgA.source = ""
            imgB.source = ""

            cameraOsd.streamActive = true
            if (!streamProc.running) {
                streamProc.running = true
            }

            if (!visible) {
                osdCard._scaleY = 0.0
                osdCard._scaleX = 0.82
                osdCard._opacity = 0
                cardContent.opacity = 0
                visible = true
            }

            appearAnim.start()
            dismissTimer.restart()
        }

        function dismiss() {
            dismissTimer.stop()
            if (!dismissAnim.running) {
                appearAnim.stop()
                dismissAnim.start()
            }
        }

        Timer {
            id: dismissTimer
            interval: 12000
            repeat: false
            onTriggered: {
                if (!cardHover.containsMouse) {
                    osdWin.dismiss()
                }
            }
        }

        ParallelAnimation {
            id: appearAnim
            NumberAnimation {
                target: osdCard
                property: "_scaleY"
                from: 0.0
                to: 1.0
                duration: 280
                easing.type: Easing.OutBack
                easing.overshoot: 1.18
            }
            NumberAnimation {
                target: osdCard
                property: "_scaleX"
                from: 0.82
                to: 1.0
                duration: 260
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: osdCard
                property: "_opacity"
                from: 0.0
                to: 1.0
                duration: 160
                easing.type: Easing.OutQuad
            }
            SequentialAnimation {
                PauseAnimation { duration: 50 }
                NumberAnimation {
                    target: cardContent
                    property: "opacity"
                    from: 0.0
                    to: 1.0
                    duration: 180
                    easing.type: Easing.OutQuad
                }
            }
        }

        SequentialAnimation {
            id: dismissAnim
            ParallelAnimation {
                NumberAnimation {
                    target: cardContent
                    property: "opacity"
                    to: 0.0
                    duration: 100
                    easing.type: Easing.InQuad
                }
                NumberAnimation {
                    target: osdCard
                    property: "_scaleY"
                    to: 0.0
                    duration: 190
                    easing.type: Easing.InBack
                    easing.overshoot: 1.1
                }
                NumberAnimation {
                    target: osdCard
                    property: "_scaleX"
                    to: 0.85
                    duration: 170
                    easing.type: Easing.InQuad
                }
                NumberAnimation {
                    target: osdCard
                    property: "_opacity"
                    to: 0.0
                    duration: 170
                    easing.type: Easing.InQuad
                }
            }
            ScriptAction {
                script: {
                    osdWin.visible = false
                    cameraOsd.streamActive = false
                    streamProc.running = false
                    cameraOsd.hasFrame = false
                    imgA.source = ""
                    imgB.source = ""
                }
            }
        }

        Item {
            id: osdWrapper
            width: 436
            height: osdCard.implicitHeight + 10
            anchors.top: parent.top
            anchors.topMargin: Root.Theme.shelfHeight - 4
            anchors.horizontalCenter: parent.horizontalCenter

            Item {
                id: osdCard
                property real _opacity: 0
                property real _scaleX: 1.0
                property real _scaleY: 1.0

                width: 380
                implicitHeight: cardContent.implicitHeight + 28
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                opacity: _opacity

                transformOrigin: Item.Top
                transform: Scale {
                    origin.x: osdCard.width / 2
                    origin.y: 0
                    xScale: osdCard._scaleX
                    yScale: osdCard._scaleY
                }

                Shape {
                    id: osdShape
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width + 56
                    layer.enabled: true
                    layer.samples: 8
                    layer.smooth: true

                    ShapePath {
                        strokeWidth: 0
                        strokeColor: "transparent"
                        fillColor: Qt.rgba(Root.Theme.panelBg.r,
                                           Root.Theme.panelBg.g,
                                           Root.Theme.panelBg.b, 0.98)

                        startX: 0
                        startY: 0

                        PathLine { x: 0; y: 3 }

                        PathCubic {
                            control1X: 14; control1Y: 3
                            control2X: 28; control2Y: 17
                            x: 28; y: 31
                        }
                        PathLine { x: 28; y: Math.max(31, osdShape.height - 28) }
                        PathCubic {
                            control1X: 28; control1Y: osdShape.height - 14
                            control2X: 42; control2Y: osdShape.height
                            x: 56; y: osdShape.height
                        }
                        PathLine { x: Math.max(56, osdShape.width - 56); y: osdShape.height }
                        PathCubic {
                            control1X: osdShape.width - 42; control1Y: osdShape.height
                            control2X: osdShape.width - 28; control2Y: osdShape.height - 14
                            x: osdShape.width - 28; y: Math.max(31, osdShape.height - 28)
                        }
                        PathLine { x: osdShape.width - 28; y: 31 }
                        PathCubic {
                            control1X: osdShape.width - 28; control1Y: 17
                            control2X: osdShape.width - 14; control2Y: 3
                            x: osdShape.width; y: 3
                        }
                        PathLine { x: osdShape.width; y: 0 }
                        PathLine { x: 0; y: 0 }
                    }

                    ShapePath {
                        strokeWidth: 2
                        strokeColor: Root.Theme.primary
                        fillColor: "transparent"
                        capStyle: ShapePath.FlatCap
                        joinStyle: ShapePath.RoundJoin

                        Behavior on strokeColor { ColorAnimation { duration: 180 } }

                        startX: 0
                        startY: 3

                        PathCubic {
                            control1X: 14; control1Y: 3
                            control2X: 28; control2Y: 17
                            x: 28; y: 31
                        }
                        PathLine { x: 28; y: Math.max(31, osdShape.height - 28) }
                        PathCubic {
                            control1X: 28; control1Y: osdShape.height - 14
                            control2X: 42; control2Y: osdShape.height
                            x: 56; y: osdShape.height
                        }
                        PathLine { x: Math.max(56, osdShape.width - 56); y: osdShape.height }
                        PathCubic {
                            control1X: osdShape.width - 42; control1Y: osdShape.height
                            control2X: osdShape.width - 28; control2Y: osdShape.height - 14
                            x: osdShape.width - 28; y: Math.max(31, osdShape.height - 28)
                        }
                        PathLine { x: osdShape.width - 28; y: 31 }
                        PathCubic {
                            control1X: osdShape.width - 28; control1Y: 17
                            control2X: osdShape.width - 14; control2Y: 3
                            x: osdShape.width; y: 3
                        }
                    }
                }

                ColumnLayout {
                    id: cardContent
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    anchors.topMargin: 10
                    anchors.bottomMargin: 14
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: "󰄀"
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: 18
                            color: Root.Theme.primary
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Text {
                            text: "CAMERA PREVIEW"
                            color: Root.Theme.primary
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: Root.Theme.fontSizeXS
                            font.weight: Font.DemiBold
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Rectangle {
                            Layout.alignment: Qt.AlignVCenter
                            height: 18
                            width: liveRow.implicitWidth + 12
                            radius: 9
                            color: cameraOsd.hasFrame
                                ? Qt.rgba(0.13, 0.77, 0.36, 0.16)
                                : Qt.rgba(Root.Theme.textSecondary.r, Root.Theme.textSecondary.g, Root.Theme.textSecondary.b, 0.12)
                            border.width: 1
                            border.color: cameraOsd.hasFrame
                                ? Qt.rgba(0.13, 0.77, 0.36, 0.4)
                                : Qt.rgba(Root.Theme.textSecondary.r, Root.Theme.textSecondary.g, Root.Theme.textSecondary.b, 0.25)

                            Row {
                                id: liveRow
                                anchors.centerIn: parent
                                spacing: 4

                                Rectangle {
                                    width: 6
                                    height: 6
                                    radius: 3
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: cameraOsd.hasFrame ? "#22c55e" : Root.Theme.textSecondary

                                    SequentialAnimation on opacity {
                                        running: cameraOsd.hasFrame
                                        loops: Animation.Infinite
                                        NumberAnimation { from: 1.0; to: 0.3; duration: 800; easing.type: Easing.InOutSine }
                                        NumberAnimation { from: 0.3; to: 1.0; duration: 800; easing.type: Easing.InOutSine }
                                    }
                                }

                                Text {
                                    text: cameraOsd.hasFrame ? "LIVE" : "STARTING"
                                    color: cameraOsd.hasFrame ? "#22c55e" : Root.Theme.textSecondary
                                    font.family: Root.Theme.fontFamily
                                    font.pixelSize: 10
                                    font.weight: Font.Bold
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                        }

                        Item { Layout.fillWidth: true }

                        Rectangle {
                            Layout.preferredWidth: 26
                            Layout.preferredHeight: 26
                            radius: 13
                            color: flipHover.containsMouse
                                ? Qt.rgba(Root.Theme.textPrimary.r, Root.Theme.textPrimary.g, Root.Theme.textPrimary.b, 0.12)
                                : (cameraOsd.isMirrored ? Qt.rgba(Root.Theme.primary.r, Root.Theme.primary.g, Root.Theme.primary.b, 0.2) : "transparent")

                            Text {
                                anchors.centerIn: parent
                                text: "󰅪"
                                font.family: Root.Theme.fontFamily
                                font.pixelSize: 14
                                color: cameraOsd.isMirrored ? Root.Theme.primary : Root.Theme.textSecondary
                            }

                            MouseArea {
                                id: flipHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    cameraOsd.isMirrored = !cameraOsd.isMirrored
                                    dismissTimer.restart()
                                }
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: 26
                            Layout.preferredHeight: 26
                            radius: 13
                            color: closeHover.containsMouse
                                ? Qt.rgba(Root.Theme.error.r, Root.Theme.error.g, Root.Theme.error.b, 0.2)
                                : "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: "󰅖"
                                font.family: Root.Theme.fontFamily
                                font.pixelSize: 14
                                color: closeHover.containsMouse ? Root.Theme.error : Root.Theme.textSecondary
                            }

                            MouseArea {
                                id: closeHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: osdWin.dismiss()
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 196
                        radius: 14
                        color: Root.Theme.surfaceContainerHigh
                        border.width: 1
                        border.color: Qt.rgba(Root.Theme.panelBorder.r,
                                              Root.Theme.panelBorder.g,
                                              Root.Theme.panelBorder.b, 0.6)
                        clip: true

                        Column {
                            anchors.centerIn: parent
                            spacing: 8
                            visible: !cameraOsd.hasFrame

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "󰄀"
                                font.family: Root.Theme.fontFamily
                                font.pixelSize: 32
                                color: Root.Theme.textSecondary
                                opacity: 0.7
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "Connecting camera..."
                                font.family: Root.Theme.fontFamily
                                font.pixelSize: Root.Theme.fontSizeSmall
                                color: Root.Theme.textSecondary
                            }
                        }

                        Image {
                            id: imgA
                            anchors.fill: parent
                            fillMode: Image.PreserveAspectCrop
                            mirror: cameraOsd.isMirrored
                            cache: false
                            asynchronous: false
                            visible: cameraOsd.imgActive === 0 && cameraOsd.hasFrame
                            onStatusChanged: {
                                if (status === Image.Ready) {
                                    cameraOsd.hasFrame = true
                                    cameraOsd.imgActive = 0
                                }
                            }
                        }

                        Image {
                            id: imgB
                            anchors.fill: parent
                            fillMode: Image.PreserveAspectCrop
                            mirror: cameraOsd.isMirrored
                            cache: false
                            asynchronous: false
                            visible: cameraOsd.imgActive === 1 && cameraOsd.hasFrame
                            onStatusChanged: {
                                if (status === Image.Ready) {
                                    cameraOsd.hasFrame = true
                                    cameraOsd.imgActive = 1
                                }
                            }
                        }

                        Rectangle {
                            id: flashOverlay
                            anchors.fill: parent
                            color: "#FFFFFF"
                            opacity: 0.0

                            SequentialAnimation {
                                id: flashAnim
                                NumberAnimation { target: flashOverlay; property: "opacity"; from: 0.0; to: 0.75; duration: 70; easing.type: Easing.OutQuad }
                                NumberAnimation { target: flashOverlay; property: "opacity"; from: 0.75; to: 0.0; duration: 180; easing.type: Easing.InQuad }
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: cameraOsd.isMirrored ? "Mirror mode active" : "Normal view"
                            color: Root.Theme.textSecondary
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: Root.Theme.fontSizeXS
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Item { Layout.fillWidth: true }

                        Rectangle {
                            id: snapBtn
                            Layout.preferredHeight: 30
                            Layout.preferredWidth: snapContent.implicitWidth + 20
                            radius: 15
                            color: snapMouse.containsMouse
                                ? Qt.rgba(Root.Theme.primary.r, Root.Theme.primary.g, Root.Theme.primary.b, 0.25)
                                : Qt.rgba(Root.Theme.primary.r, Root.Theme.primary.g, Root.Theme.primary.b, 0.15)
                            border.width: 1
                            border.color: Root.Theme.primary

                            Row {
                                id: snapContent
                                anchors.centerIn: parent
                                spacing: 6

                                Text {
                                    text: "󰄀"
                                    font.family: Root.Theme.fontFamily
                                    font.pixelSize: 14
                                    color: Root.Theme.primary
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    text: "Snapshot"
                                    font.family: Root.Theme.fontFamily
                                    font.pixelSize: Root.Theme.fontSizeSmall
                                    font.weight: Font.DemiBold
                                    color: Root.Theme.primary
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            MouseArea {
                                id: snapMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: cameraOsd.takeSnapshot()
                            }
                        }
                    }
                }

                MouseArea {
                    id: cardHover
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.NoButton
                    onPositionChanged: dismissTimer.restart()
                }
            }
        }
    }
}
