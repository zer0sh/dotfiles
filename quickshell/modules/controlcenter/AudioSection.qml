import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Io
import Quickshell.Services.Pipewire
import "../.." as Root

Item {
    id: audioPanel

    signal back()

    property string currentTab: "outputs"
    property var sinks: []
    property var sources: []
    property var apps: []
    property var devices: currentTab === "inputs" ? sources : (currentTab === "apps" ? apps : sinks)
    property string defaultSinkName: ""
    property string defaultSourceName: ""
    property bool loading: false

    // Track PipeWire native default sink and source for instant event updates without polling
    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource]
    }

    Connections {
        target: Pipewire
        function onDefaultAudioSinkChanged() {
            if (audioPanel.x === 0) audioPanel.refresh();
        }
        function onDefaultAudioSourceChanged() {
            if (audioPanel.x === 0) audioPanel.refresh();
        }
    }

    // 1. Immediately hydrate from cache
    Process {
        id: readCacheProc
        command: ["cat", "/home/zero/.cache/quickshell/audio_status.json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    if (text.trim() === "") return;
                    var d = JSON.parse(text.trim());
                    audioPanel.applyState(d);
                } catch (e) {}
            }
        }
    }

    // 2. Query audio backend telemetry
    Process {
        id: fetchStatusProc
        command: ["/home/zero/dotfiles/quickshell/scripts/audio-manager.py", "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                audioPanel.loading = false;
                try {
                    if (text.trim() === "") return;
                    var d = JSON.parse(text.trim());
                    audioPanel.applyState(d);
                } catch (e) {}
            }
        }
        onExited: (code, status) => {
            audioPanel.loading = false;
        }
    }

    // 3. Execution process for audio actions
    Process {
        id: actionProc
        stdout: StdioCollector {}
        onExited: (code, status) => {
            audioPanel.refresh();
        }
    }

    // React entirely on-demand: when navigating into Audio sub-page
    onXChanged: {
        if (x === 0) {
            readCacheProc.running = true;
            refresh();
        }
    }

    function applyState(d) {
        if (!d) return;
        if (d.defaultSink !== undefined) audioPanel.defaultSinkName = d.defaultSink;
        if (d.defaultSource !== undefined) audioPanel.defaultSourceName = d.defaultSource;
        if (d.sinks !== undefined) audioPanel.sinks = d.sinks;
        if (d.sources !== undefined) audioPanel.sources = d.sources;
        if (d.apps !== undefined) audioPanel.apps = d.apps;
    }

    function refresh() {
        loading = true;
        fetchStatusProc.running = true;
    }

    function setDefaultSink(name) {
        defaultSinkName = name;
        var list = sinks;
        for (var i = 0; i < list.length; i++) {
            list[i].isDefault = (list[i].name === name);
        }
        sinks = list;
        actionProc.command = ["/home/zero/dotfiles/quickshell/scripts/audio-manager.py", "set-sink", name];
        actionProc.running = true;
    }

    function setDefaultSource(name) {
        defaultSourceName = name;
        var list = sources;
        for (var i = 0; i < list.length; i++) {
            list[i].isDefault = (list[i].name === name);
        }
        sources = list;
        actionProc.command = ["/home/zero/dotfiles/quickshell/scripts/audio-manager.py", "set-source", name];
        actionProc.running = true;
    }

    function setSinkVolume(name, val) {
        var clamped = Math.max(0, Math.min(100, Math.round(val)));
        var list = sinks;
        for (var i = 0; i < list.length; i++) {
            if (list[i].name === name) list[i].volume = clamped;
        }
        sinks = list;
        actionProc.command = ["/home/zero/dotfiles/quickshell/scripts/audio-manager.py", "sink-volume", name, clamped.toString()];
        actionProc.running = true;
    }

    function toggleSinkMute(name) {
        var list = sinks;
        for (var i = 0; i < list.length; i++) {
            if (list[i].name === name) list[i].muted = !list[i].muted;
        }
        sinks = list;
        actionProc.command = ["/home/zero/dotfiles/quickshell/scripts/audio-manager.py", "sink-mute", name, "toggle"];
        actionProc.running = true;
    }

    function setSourceVolume(name, val) {
        var clamped = Math.max(0, Math.min(100, Math.round(val)));
        var list = sources;
        for (var i = 0; i < list.length; i++) {
            if (list[i].name === name) list[i].volume = clamped;
        }
        sources = list;
        actionProc.command = ["/home/zero/dotfiles/quickshell/scripts/audio-manager.py", "source-volume", name, clamped.toString()];
        actionProc.running = true;
    }

    function toggleSourceMute(name) {
        var list = sources;
        for (var i = 0; i < list.length; i++) {
            if (list[i].name === name) list[i].muted = !list[i].muted;
        }
        sources = list;
        actionProc.command = ["/home/zero/dotfiles/quickshell/scripts/audio-manager.py", "source-mute", name, "toggle"];
        actionProc.running = true;
    }

    function setAppVolume(id, val) {
        var clamped = Math.max(0, Math.min(100, Math.round(val)));
        var list = apps;
        for (var i = 0; i < list.length; i++) {
            if (list[i].id === id) list[i].volume = clamped;
        }
        apps = list;
        actionProc.command = ["/home/zero/dotfiles/quickshell/scripts/audio-manager.py", "app-volume", id.toString(), clamped.toString()];
        actionProc.running = true;
    }

    function toggleAppMute(id) {
        var list = apps;
        for (var i = 0; i < list.length; i++) {
            if (list[i].id === id) list[i].muted = !list[i].muted;
        }
        apps = list;
        actionProc.command = ["/home/zero/dotfiles/quickshell/scripts/audio-manager.py", "app-mute", id.toString(), "toggle"];
        actionProc.running = true;
    }

    Component.onCompleted: {
        readCacheProc.running = true;
        refresh();
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: 18
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        anchors.bottomMargin: 16
        spacing: 14

        // ── Header Bar ──────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Rectangle {
                width: 38
                height: 38
                radius: 19
                color: Root.Theme.surfaceContainerHigh

                Text {
                    anchors.centerIn: parent
                    text: "graphic_eq"
                    font.family: Root.Theme.iconFont
                    font.pixelSize: 22
                    color: Root.Theme.primary
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    text: "Audio"
                    font.family: Root.Theme.fontFamily
                    font.pixelSize: Root.Theme.fontSizeLarge
                    font.weight: Font.DemiBold
                    color: Root.Theme.textPrimary
                }

                Text {
                    text: {
                        if (audioPanel.currentTab === "outputs") {
                            for (var i = 0; i < audioPanel.sinks.length; i++) {
                                if (audioPanel.sinks[i].isDefault) return audioPanel.sinks[i].label;
                            }
                            return "Salidas de audio";
                        } else if (audioPanel.currentTab === "inputs") {
                            for (var j = 0; j < audioPanel.sources.length; j++) {
                                if (audioPanel.sources[j].isDefault) return audioPanel.sources[j].label;
                            }
                            return "Entradas de audio";
                        } else {
                            return audioPanel.apps.length + " aplicacion(es) activa(s)";
                        }
                    }
                    font.family: Root.Theme.fontFamily
                    font.pixelSize: Root.Theme.fontSizeXS
                    color: Root.Theme.textSecondary
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }

            // Refresh button
            Rectangle {
                width: 36
                height: 36
                radius: 18
                color: refreshMa.containsMouse ? Root.Theme.surfaceContainerHigh : "transparent"
                Behavior on color { ColorAnimation { duration: 100 } }

                Text {
                    id: refreshIcon
                    anchors.centerIn: parent
                    text: "refresh"
                    font.family: Root.Theme.iconFont
                    font.pixelSize: 20
                    color: Root.Theme.textSecondary
                }

                RotationAnimation {
                    target: refreshIcon
                    property: "rotation"
                    from: 0
                    to: 360
                    duration: 800
                    loops: Animation.Infinite
                    running: audioPanel.loading
                }

                MouseArea {
                    id: refreshMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: audioPanel.refresh()
                }
            }

            // Back button
            Rectangle {
                width: 36
                height: 36
                radius: 18
                color: backBtn.containsMouse ? Root.Theme.surfaceContainerHigh : "transparent"
                Behavior on color { ColorAnimation { duration: 100 } }

                Text {
                    anchors.centerIn: parent
                    text: "arrow_back"
                    font.family: Root.Theme.iconFont
                    font.pixelSize: 20
                    color: Root.Theme.textPrimary
                }

                MouseArea {
                    id: backBtn
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: audioPanel.back()
                }
            }
        }

        // ── Tabs Bar (Outputs, Inputs, Apps) ─────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            // Tab Outputs
            Rectangle {
                Layout.fillWidth: true
                height: 36
                radius: 18
                color: audioPanel.currentTab === "outputs" ? Root.Theme.primaryContainer : Root.Theme.surfaceContainerHigh
                Behavior on color { ColorAnimation { duration: 120 } }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        text: "speaker"
                        font.family: Root.Theme.iconFont
                        font.pixelSize: 16
                        color: audioPanel.currentTab === "outputs" ? Root.Theme.primary : Root.Theme.textSecondary
                    }

                    Text {
                        text: "Salidas"
                        font.family: Root.Theme.fontFamily
                        font.pixelSize: Root.Theme.fontSizeSmall
                        font.weight: audioPanel.currentTab === "outputs" ? Font.DemiBold : Font.Normal
                        color: audioPanel.currentTab === "outputs" ? Root.Theme.textPrimary : Root.Theme.textSecondary
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: audioPanel.currentTab = "outputs"
                }
            }

            // Tab Inputs
            Rectangle {
                Layout.fillWidth: true
                height: 36
                radius: 18
                color: audioPanel.currentTab === "inputs" ? Root.Theme.primaryContainer : Root.Theme.surfaceContainerHigh
                Behavior on color { ColorAnimation { duration: 120 } }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        text: "mic"
                        font.family: Root.Theme.iconFont
                        font.pixelSize: 16
                        color: audioPanel.currentTab === "inputs" ? Root.Theme.primary : Root.Theme.textSecondary
                    }

                    Text {
                        text: "Entradas"
                        font.family: Root.Theme.fontFamily
                        font.pixelSize: Root.Theme.fontSizeSmall
                        font.weight: audioPanel.currentTab === "inputs" ? Font.DemiBold : Font.Normal
                        color: audioPanel.currentTab === "inputs" ? Root.Theme.textPrimary : Root.Theme.textSecondary
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: audioPanel.currentTab = "inputs"
                }
            }

            // Tab Apps
            Rectangle {
                Layout.fillWidth: true
                height: 36
                radius: 18
                color: audioPanel.currentTab === "apps" ? Root.Theme.primaryContainer : Root.Theme.surfaceContainerHigh
                Behavior on color { ColorAnimation { duration: 120 } }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        text: "music_note"
                        font.family: Root.Theme.iconFont
                        font.pixelSize: 16
                        color: audioPanel.currentTab === "apps" ? Root.Theme.primary : Root.Theme.textSecondary
                    }

                    Text {
                        text: "Apps" + (audioPanel.apps.length > 0 ? " (" + audioPanel.apps.length + ")" : "")
                        font.family: Root.Theme.fontFamily
                        font.pixelSize: Root.Theme.fontSizeSmall
                        font.weight: audioPanel.currentTab === "apps" ? Font.DemiBold : Font.Normal
                        color: audioPanel.currentTab === "apps" ? Root.Theme.textPrimary : Root.Theme.textSecondary
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: audioPanel.currentTab = "apps"
                }
            }
        }

        // ── Device List (Outputs & Inputs) ──────────────────────────
        ListView {
            id: deviceListView
            visible: audioPanel.currentTab !== "apps"
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 10
            model: audioPanel.currentTab === "inputs" ? audioPanel.sources : audioPanel.sinks

            delegate: Rectangle {
                id: deviceCard
                width: ListView.view.width
                height: 96
                radius: 16
                color: modelData.isDefault
                    ? Qt.rgba(Root.Theme.primary.r, Root.Theme.primary.g, Root.Theme.primary.b, 0.12)
                    : (cardMa.containsMouse ? Root.Theme.surfaceContainerHigh : Qt.rgba(255, 255, 255, 0.04))
                border.width: 1
                border.color: modelData.isDefault ? Root.Theme.primary : Qt.rgba(255, 255, 255, 0.08)
                Behavior on color { ColorAnimation { duration: 120 } }

                property int currentVolume: modelData.volume
                property bool isDragging: false

                onCurrentVolumeChanged: {
                    if (!isDragging) {
                        displayVolume = modelData.volume;
                    }
                }

                property int displayVolume: modelData.volume

                Process {
                    id: devVolProc
                }

                Timer {
                    id: devVolThrottler
                    interval: 40
                    repeat: false
                    onTriggered: {
                        if (audioPanel.currentTab === "inputs") {
                            devVolProc.command = ["pactl", "set-source-volume", modelData.name, deviceCard.displayVolume + "%"];
                        } else {
                            devVolProc.command = ["pactl", "set-sink-volume", modelData.name, deviceCard.displayVolume + "%"];
                        }
                        devVolProc.running = true;
                    }
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    // Top Row: Icon, Titles, Default Badge, Mute Button
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        // Device Type Icon
                        Rectangle {
                            width: 34
                            height: 34
                            radius: 17
                            color: modelData.isDefault ? Root.Theme.primary : Root.Theme.surfaceContainerHigh

                            Text {
                                anchors.centerIn: parent
                                text: modelData.icon || (audioPanel.currentTab === "inputs" ? "mic" : "speaker")
                                font.family: Root.Theme.iconFont
                                font.pixelSize: 18
                                color: modelData.isDefault ? Root.Theme.tileActiveText : Root.Theme.textPrimary
                            }
                        }

                        // Labels (Click to set as default)
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            Text {
                                text: modelData.label || modelData.name
                                font.family: Root.Theme.fontFamily
                                font.pixelSize: Root.Theme.fontSizeNormal
                                font.weight: modelData.isDefault ? Font.DemiBold : Font.Normal
                                color: Root.Theme.textPrimary
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Text {
                                text: modelData.nick || modelData.description || ""
                                font.family: Root.Theme.fontFamily
                                font.pixelSize: Root.Theme.fontSizeXS
                                color: Root.Theme.textSecondary
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        // Default Status Indicator
                        Rectangle {
                            visible: modelData.isDefault
                            height: 24
                            implicitWidth: defaultLabelRow.width + 14
                            radius: 12
                            color: Qt.rgba(Root.Theme.primary.r, Root.Theme.primary.g, Root.Theme.primary.b, 0.22)

                            RowLayout {
                                id: defaultLabelRow
                                anchors.centerIn: parent
                                spacing: 4

                                Text {
                                    text: "check_circle"
                                    font.family: Root.Theme.iconFont
                                    font.pixelSize: 13
                                    color: Root.Theme.primary
                                }

                                Text {
                                    text: "Activo"
                                    font.family: Root.Theme.fontFamily
                                    font.pixelSize: Root.Theme.fontSizeXS
                                    font.weight: Font.DemiBold
                                    color: Root.Theme.primary
                                }
                            }
                        }

                        // Mute button
                        Rectangle {
                            width: 32
                            height: 32
                            radius: 16
                            color: modelData.muted
                                ? Qt.rgba(Root.Theme.error.r, Root.Theme.error.g, Root.Theme.error.b, 0.25)
                                : (muteMa.containsMouse ? Root.Theme.surfaceContainerHigh : "transparent")
                            Behavior on color { ColorAnimation { duration: 100 } }

                            Text {
                                anchors.centerIn: parent
                                text: {
                                    if (audioPanel.currentTab === "inputs") {
                                        return modelData.muted ? "mic_off" : "mic";
                                    }
                                    return modelData.muted ? "volume_off" : "volume_up";
                                }
                                font.family: Root.Theme.iconFont
                                font.pixelSize: 18
                                color: modelData.muted ? Root.Theme.error : Root.Theme.textPrimary
                            }

                            MouseArea {
                                id: muteMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (audioPanel.currentTab === "inputs") {
                                        audioPanel.toggleSourceMute(modelData.name);
                                    } else {
                                        audioPanel.toggleSinkMute(modelData.name);
                                    }
                                }
                            }
                        }
                    }

                    // Bottom Row: Volume Slider with comfortable hit area and knob
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Item {
                            id: sliderContainer
                            Layout.fillWidth: true
                            height: 28

                            // Visual Track
                            Rectangle {
                                id: trackRect
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                height: 8
                                radius: 4
                                color: Root.Theme.sliderTrack

                                Rectangle {
                                    id: fillRect
                                    height: parent.height
                                    width: Math.max(0, Math.min(trackRect.width, trackRect.width * (deviceCard.displayVolume / 100.0)))
                                    radius: parent.radius
                                    color: modelData.muted ? Root.Theme.textSecondary : Root.Theme.primary
                                }

                                // Visible thumb knob
                                Rectangle {
                                    width: 14
                                    height: 14
                                    radius: 7
                                    anchors.verticalCenter: parent.verticalCenter
                                    x: Math.max(0, Math.min(trackRect.width - width, trackRect.width * (deviceCard.displayVolume / 100.0) - width / 2))
                                    color: modelData.muted ? Root.Theme.textSecondary : Root.Theme.primary
                                    border.width: 2
                                    border.color: Root.Theme.panelBg
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                preventStealing: true

                                function applyVol(mx) {
                                    var pct = Math.max(0, Math.min(100, Math.round((mx / width) * 100)));
                                    deviceCard.displayVolume = pct;
                                    if (modelData.isDefault && audioPanel.currentTab === "outputs" && Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) {
                                        Pipewire.defaultAudioSink.audio.volume = pct / 100.0;
                                    }
                                    if (!devVolThrottler.running) {
                                        devVolThrottler.start();
                                    }
                                }

                                onPressed: (mouse) => {
                                    deviceCard.isDragging = true;
                                    applyVol(mouse.x);
                                }
                                onPositionChanged: (mouse) => {
                                    if (pressed) applyVol(mouse.x);
                                }
                                onReleased: (mouse) => {
                                    deviceCard.isDragging = false;
                                    applyVol(mouse.x);
                                    if (audioPanel.currentTab === "inputs") {
                                        devVolProc.command = ["pactl", "set-source-volume", modelData.name, deviceCard.displayVolume + "%"];
                                    } else {
                                        devVolProc.command = ["pactl", "set-sink-volume", modelData.name, deviceCard.displayVolume + "%"];
                                    }
                                    devVolProc.running = true;
                                }
                            }
                        }

                        // Percentage Label
                        Text {
                            text: deviceCard.displayVolume + "%"
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: Root.Theme.fontSizeSmall
                            font.weight: Font.Medium
                            color: modelData.muted ? Root.Theme.textSecondary : Root.Theme.textPrimary
                            Layout.preferredWidth: 40
                            horizontalAlignment: Text.AlignRight
                        }
                    }
                }

                // Click header area to select device as default
                MouseArea {
                    id: cardMa
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 50
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (!modelData.isDefault) {
                            if (audioPanel.currentTab === "inputs") {
                                audioPanel.setDefaultSource(modelData.name);
                            } else {
                                audioPanel.setDefaultSink(modelData.name);
                            }
                        }
                    }
                }
            }
        }

        // Empty state for devices
        Text {
            visible: audioPanel.currentTab !== "apps" && deviceListView.count === 0
            Layout.fillWidth: true
            Layout.fillHeight: true
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            text: audioPanel.currentTab === "inputs" ? "No se encontraron entradas de audio" : "No se encontraron salidas de audio"
            font.family: Root.Theme.fontFamily
            font.pixelSize: Root.Theme.fontSizeNormal
            color: Root.Theme.textSecondary
        }

        // ── Apps List (Streams) ─────────────────────────────────────
        ListView {
            id: appListView
            visible: audioPanel.currentTab === "apps"
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 10
            model: audioPanel.apps

            delegate: Rectangle {
                id: appCard
                width: ListView.view.width
                height: 96
                radius: 16
                color: appMa.containsMouse ? Root.Theme.surfaceContainerHigh : Qt.rgba(255, 255, 255, 0.04)
                border.width: 1
                border.color: Qt.rgba(255, 255, 255, 0.08)
                Behavior on color { ColorAnimation { duration: 120 } }

                property int currentVolume: modelData.volume
                property bool isDragging: false

                onCurrentVolumeChanged: {
                    if (!isDragging) {
                        appDisplayVolume = modelData.volume;
                    }
                }

                property int appDisplayVolume: modelData.volume

                Process {
                    id: appVolProc
                }

                Timer {
                    id: appVolThrottler
                    interval: 40
                    repeat: false
                    onTriggered: {
                        appVolProc.command = ["pactl", "set-sink-input-volume", modelData.id.toString(), appCard.appDisplayVolume + "%"];
                        appVolProc.running = true;
                    }
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    // Top Row: App Icon, Names, Mute Button
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        // App Icon Badge
                        Rectangle {
                            width: 34
                            height: 34
                            radius: 17
                            color: Root.Theme.surfaceContainerHigh

                            Text {
                                anchors.centerIn: parent
                                text: modelData.icon || "volume_up"
                                font.family: Root.Theme.iconFont
                                font.pixelSize: 18
                                color: Root.Theme.primary
                            }
                        }

                        // App & Stream Labels
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            Text {
                                text: modelData.name || "Aplicacion"
                                font.family: Root.Theme.fontFamily
                                font.pixelSize: Root.Theme.fontSizeNormal
                                font.weight: Font.DemiBold
                                color: Root.Theme.textPrimary
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Text {
                                text: modelData.title || modelData.binary || "Stream de audio"
                                font.family: Root.Theme.fontFamily
                                font.pixelSize: Root.Theme.fontSizeXS
                                color: Root.Theme.textSecondary
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        // App Mute button
                        Rectangle {
                            width: 32
                            height: 32
                            radius: 16
                            color: modelData.muted
                                ? Qt.rgba(Root.Theme.error.r, Root.Theme.error.g, Root.Theme.error.b, 0.25)
                                : (appMuteMa.containsMouse ? Root.Theme.surfaceContainerHigh : "transparent")
                            Behavior on color { ColorAnimation { duration: 100 } }

                            Text {
                                anchors.centerIn: parent
                                text: modelData.muted ? "volume_off" : "volume_up"
                                font.family: Root.Theme.iconFont
                                font.pixelSize: 18
                                color: modelData.muted ? Root.Theme.error : Root.Theme.textPrimary
                            }

                            MouseArea {
                                id: appMuteMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: audioPanel.toggleAppMute(modelData.id)
                            }
                        }
                    }

                    // Bottom Row: App Volume Slider with comfortable hit area and knob
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Item {
                            id: appSliderContainer
                            Layout.fillWidth: true
                            height: 28

                            Rectangle {
                                id: appTrackRect
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                height: 8
                                radius: 4
                                color: Root.Theme.sliderTrack

                                Rectangle {
                                    id: appFillRect
                                    height: parent.height
                                    width: Math.max(0, Math.min(appTrackRect.width, appTrackRect.width * (appCard.appDisplayVolume / 100.0)))
                                    radius: parent.radius
                                    color: modelData.muted ? Root.Theme.textSecondary : Root.Theme.primary
                                }

                                // Visible thumb knob
                                Rectangle {
                                    width: 14
                                    height: 14
                                    radius: 7
                                    anchors.verticalCenter: parent.verticalCenter
                                    x: Math.max(0, Math.min(appTrackRect.width - width, appTrackRect.width * (appCard.appDisplayVolume / 100.0) - width / 2))
                                    color: modelData.muted ? Root.Theme.textSecondary : Root.Theme.primary
                                    border.width: 2
                                    border.color: Root.Theme.panelBg
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                preventStealing: true

                                function applyAppVol(mx) {
                                    var pct = Math.max(0, Math.min(100, Math.round((mx / width) * 100)));
                                    appCard.appDisplayVolume = pct;
                                    if (!appVolThrottler.running) {
                                        appVolThrottler.start();
                                    }
                                }

                                onPressed: (mouse) => {
                                    appCard.isDragging = true;
                                    applyAppVol(mouse.x);
                                }
                                onPositionChanged: (mouse) => {
                                    if (pressed) applyAppVol(mouse.x);
                                }
                                onReleased: (mouse) => {
                                    appCard.isDragging = false;
                                    applyAppVol(mouse.x);
                                    appVolProc.command = ["pactl", "set-sink-input-volume", modelData.id.toString(), appCard.appDisplayVolume + "%"];
                                    appVolProc.running = true;
                                }
                            }
                        }

                        Text {
                            text: appCard.appDisplayVolume + "%"
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: Root.Theme.fontSizeSmall
                            font.weight: Font.Medium
                            color: modelData.muted ? Root.Theme.textSecondary : Root.Theme.textPrimary
                            Layout.preferredWidth: 40
                            horizontalAlignment: Text.AlignRight
                        }
                    }
                }

                MouseArea {
                    id: appMa
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.NoButton
                }
            }
        }

        // Empty state for apps
        ColumnLayout {
            visible: audioPanel.currentTab === "apps" && appListView.count === 0
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignCenter
            spacing: 8

            Text {
                text: "music_off"
                font.family: Root.Theme.iconFont
                font.pixelSize: 32
                color: Root.Theme.textSecondary
                Layout.alignment: Qt.AlignHCenter
            }

            Text {
                text: "No hay aplicaciones reproduciendo audio"
                font.family: Root.Theme.fontFamily
                font.pixelSize: Root.Theme.fontSizeNormal
                color: Root.Theme.textSecondary
                Layout.alignment: Qt.AlignHCenter
            }
        }
    }
}
