import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Io
import "../.." as Root

// Bluetooth Sub-Page — Orbital Radar and Real-Time Device Management
Item {
    id: bt

    signal back()

    property bool enabled: true
    property bool scanning: false
    property string error: ""
    property bool discoveryScanning: false
    property string pairStatus: ""
    property string pairingMAC: ""

    // Connected device details (Right-hand card)
    property string connectedMac: ""
    property string connectedName: ""
    property var connectedBattery: null
    property string connectedIconType: "device"

    // Icon Selector Dialog state
    property bool showIconDialog: false
    property string selectedDeviceMac: ""
    property string selectedDeviceName: ""
    property string currentSelectedIcon: "device"

    // Orbit angle for orbital drift animation (smooth 60fps rotation)
    property real orbitRotation: 0
    property bool animationPaused: false

    NumberAnimation {
        target: bt
        property: "orbitRotation"
        from: 0
        to: 360
        duration: 90000
        loops: Animation.Infinite
        running: bt.visible && bt.enabled && !bt.animationPaused
    }

    // ── Processes ────────────────────────────────────────────────

    Process {
        id: readBtRadarPrefProc
        command: ["python3", "-c", "import json, os; p = os.path.expanduser('~/.config/quickshell/radar_preferences.json'); print(json.load(open(p)).get('bt_paused', False) if os.path.exists(p) else False)"]
        stdout: StdioCollector {
            onStreamFinished: {
                bt.animationPaused = (text.trim() === "True" || text.trim() === "true");
            }
        }
    }

    Process {
        id: saveBtRadarPrefProc
        stdout: StdioCollector {}
    }

    function toggleAnimation() {
        animationPaused = !animationPaused;
        saveBtRadarPrefProc.command = ["python3", "-c", "import json, os; p = os.path.expanduser('~/.config/quickshell/radar_preferences.json'); d = json.load(open(p)) if os.path.exists(p) else {}; d['bt_paused'] = " + (animationPaused ? "True" : "False") + "; json.dump(d, open(p, 'w'))"];
        saveBtRadarPrefProc.running = true;
    }

    // 1. Immediately hydrate from cache
    Process {
        id: readBtCacheProc
        command: ["cat", "/home/zero/.cache/quickshell/bluetooth_status.json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    if (text.trim() === "") return;
                    var d = JSON.parse(text.trim());
                    bt.applyState(d);
                } catch (e) {}
            }
        }
    }

    // 2. Query Bluetooth telemetry script
    Process {
        id: btMetricsProc
        command: ["/home/zero/dotfiles/quickshell/scripts/bluetooth-metrics.py"]
        stdout: StdioCollector {
            onStreamFinished: {
                bt.scanning = false;
                try {
                    if (text.trim() === "") return;
                    var d = JSON.parse(text.trim());
                    bt.applyState(d);
                } catch (e) {}
            }
        }
        onExited: (code, status) => {
            bt.scanning = false;
        }
    }

    // Save icon selection
    Process {
        id: saveIconProc
        stdout: StdioCollector {}
        onExited: {
            btMetricsProc.running = true;
        }
    }

    // Toggle power
    Process {
        id: toggleProc
        stdout: StdioCollector {}
        onExited: (code, status) => {
            powerCheckProc.running = true;
        }
    }

    Process {
        id: powerCheckProc
        command: ["bluetoothctl", "show"]
        stdout: StdioCollector {
            onStreamFinished: {
                bt.enabled = text.includes("Powered: yes");
                if (bt.enabled) btMetricsProc.running = true;
                else {
                    pairedModel.clear();
                    bt.connectedMac = "";
                }
            }
        }
    }

    // Connect / Disconnect
    Process {
        id: connProc
        stdout: StdioCollector {}
        onExited: (code, status) => {
            bt.error = code !== 0 ? "Connection failed" : "";
            btMetricsProc.running = true;
        }
    }

    Process {
        id: disconnProc
        stdout: StdioCollector {}
        onExited: (code, status) => {
            bt.error = code !== 0 ? "Disconnect failed" : "";
            btMetricsProc.running = true;
        }
    }

    // Discovery scanning for unpaired devices
    Process {
        id: scanOnProc
        command: ["bluetoothctl", "scan", "on"]
        stdout: StdioCollector {}
    }

    Process {
        id: scanOffProc
        command: ["bluetoothctl", "scan", "off"]
        stdout: StdioCollector {}
        onExited: (code, status) => {
            allDevicesProc.running = true;
        }
    }

    Process {
        id: allDevicesProc
        command: ["bluetoothctl", "devices"]
        stdout: StdioCollector {
            onStreamFinished: {
                bt.parseUnpairedDevices(text);
            }
        }
    }

    Process {
        id: pairProc
        stdout: StdioCollector {}
        onExited: (code, status) => {
            if (code !== 0) {
                bt.pairStatus = "Pair failed";
                bt.pairingMAC = "";
                pairStatusTimer.running = true;
            } else {
                trustProc.command = ["bluetoothctl", "trust", bt.pairingMAC];
                trustProc.running = true;
            }
        }
    }

    Process {
        id: trustProc
        stdout: StdioCollector {}
        onExited: (code, status) => {
            if (code !== 0) {
                bt.pairStatus = "Trust failed";
                bt.pairingMAC = "";
                pairStatusTimer.running = true;
            } else {
                bt.pairStatus = "Connecting...";
                pairConnProc.command = ["bluetoothctl", "connect", bt.pairingMAC];
                pairConnProc.running = true;
            }
        }
    }

    Process {
        id: pairConnProc
        stdout: StdioCollector {}
        onExited: (code, status) => {
            bt.pairStatus = code !== 0 ? "Paired (connect failed)" : "Paired successfully";
            bt.pairingMAC = "";
            btMetricsProc.running = true;
            pairStatusTimer.running = true;
        }
    }

    Timer {
        id: scanTimer
        interval: 6000
        running: false
        repeat: false
        onTriggered: {
            scanOnProc.running = false;
            scanOffProc.running = true;
            bt.discoveryScanning = false;
        }
    }

    Timer {
        id: pairStatusTimer
        interval: 3500
        running: false
        repeat: false
        onTriggered: bt.pairStatus = ""
    }

    Timer {
        id: btPollingTimer
        interval: 4000
        running: bt.visible && bt.enabled
        repeat: true
        onTriggered: {
            if (!btMetricsProc.running) btMetricsProc.running = true;
        }
    }

    Component.onCompleted: {
        readBtRadarPrefProc.running = true;
        readBtCacheProc.running = true;
        powerCheckProc.running = true;
        bt.scanning = true;
        btMetricsProc.running = true;
    }

    // ── Logic & Helpers ──────────────────────────────────────────

    ListModel { id: pairedModel }
    ListModel { id: unpairedModel }

    function applyState(d) {
        if (d.powered !== undefined) bt.enabled = d.powered;

        if (d.connected) {
            bt.connectedMac = d.connected.mac || "";
            bt.connectedName = d.connected.name || "";
            bt.connectedBattery = d.connected.battery;
            bt.connectedIconType = d.connected.icon_type || "device";
        } else {
            bt.connectedMac = "";
            bt.connectedName = "";
            bt.connectedBattery = null;
            bt.connectedIconType = "device";
        }

        if (d.devices && d.devices.length > 0) {
            // Keep non-connected devices in orbital radar
            var list = [];
            for (var i = 0; i < d.devices.length; i++) {
                var dev = d.devices[i];
                if (!dev.connected) list.push(dev);
            }

            var count = Math.min(list.length, 12);
            pairedModel.clear();
            for (var j = 0; j < count; j++) {
                var item = list[j];
                var baseR = 140 + (j % 3) * 35; // Distributed across radii
                var baseA = (360.0 / count) * j;
                pairedModel.append({
                    mac: item.mac,
                    name: item.name,
                    icon_type: item.icon_type || "device",
                    battery: item.battery !== null && item.battery !== undefined ? item.battery : -1,
                    orbitRadius: baseR,
                    baseAngle: baseA
                });
            }
        }
    }

    function parseUnpairedDevices(allText) {
        unpairedModel.clear();
        var pairedMap = {};
        for (var p = 0; p < pairedModel.count; p++) {
            pairedMap[pairedModel.get(p).mac] = true;
        }
        if (bt.connectedMac !== "") pairedMap[bt.connectedMac] = true;

        var lines = allText.trim().split("\n");
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim();
            if (line === "") continue;
            var parts = line.split(" ");
            if (parts.length >= 3 && parts[0] === "Device") {
                var mac = parts[1];
                var name = parts.slice(2).join(" ");
                if (!pairedMap[mac] && name !== mac.replace(/:/g, "-")) {
                    unpairedModel.append({ mac: mac, name: name });
                }
            }
        }
    }

    function togglePower() {
        toggleProc.command = bt.enabled ? ["bluetoothctl", "power", "off"] : ["bluetoothctl", "power", "on"];
        toggleProc.running = true;
    }

    function startDiscovery() {
        if (bt.discoveryScanning || !bt.enabled) return;
        bt.discoveryScanning = true;
        bt.pairStatus = "";
        unpairedModel.clear();
        scanOnProc.running = true;
        scanTimer.running = true;
    }

    function pairDevice(mac) {
        if (bt.pairingMAC !== "") return;
        bt.pairingMAC = mac;
        bt.pairStatus = "Pairing...";
        pairProc.command = ["bluetoothctl", "pair", mac];
        pairProc.running = true;
    }

    function connectDevice(mac) {
        connProc.command = ["bluetoothctl", "connect", mac];
        connProc.running = true;
    }

    function disconnectDevice(mac) {
        disconnProc.command = ["bluetoothctl", "disconnect", mac];
        disconnProc.running = true;
    }

    function openIconPicker(mac, name, iconType) {
        bt.selectedDeviceMac = mac;
        bt.selectedDeviceName = name;
        bt.currentSelectedIcon = iconType || "device";
        bt.showIconDialog = true;
    }

    function saveIconChoice(iconType) {
        saveIconProc.command = ["/home/zero/dotfiles/quickshell/scripts/bluetooth-metrics.py", "set-icon", bt.selectedDeviceMac, iconType];
        saveIconProc.running = true;
        bt.showIconDialog = false;
    }

    function getDeviceIcon(type) {
        if (type === "mouse") return "󰍽";       // nf-md-mouse
        if (type === "keyboard") return "󰌌";    // nf-md-keyboard
        if (type === "headphones") return "󰋋";  // nf-md-headphones
        if (type === "speaker") return "󰓃";     // nf-md-speaker
        if (type === "gamepad") return "󰊴";     // nf-md-gamepad
        return "󰂲";                             // nf-md-bluetooth_generic
    }

    // ── UI Root Layout ───────────────────────────────────────────

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 16

        // ── Top Header Row (flat, matching Control Center & Battery) ──
        RowLayout {
            Layout.fillWidth: true
            spacing: 14

            // Back button
            Rectangle {
                Layout.preferredWidth: 40
                Layout.preferredHeight: 40
                radius: 20
                color: backArea.containsMouse ? Root.Theme.surfaceContainerHigh : Qt.rgba(255, 255, 255, 0.08)
                border.width: 1
                border.color: Qt.rgba(255, 255, 255, 0.12)
                Behavior on color { ColorAnimation { duration: 100 } }

                Text {
                    anchors.centerIn: parent
                    text: "arrow_back"
                    font.family: Root.Theme.iconFont
                    font.pixelSize: 22
                    color: Root.Theme.textPrimary
                }

                MouseArea {
                    id: backArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: bt.back()
                }
            }

            // Title + Status
            ColumnLayout {
                spacing: 1
                Layout.fillWidth: true

                Text {
                    text: "Bluetooth Radar"
                    color: Root.Theme.textPrimary
                    font.family: Root.Theme.fontFamily
                    font.pixelSize: 18
                    font.weight: Font.DemiBold
                }

                Text {
                    text: !bt.enabled
                        ? "Disabled"
                        : (bt.connectedName !== "" ? "Connected to " + bt.connectedName : "Ready")
                    color: bt.connectedName !== "" ? Root.Theme.primary : Root.Theme.textSecondary
                    font.family: Root.Theme.fontFamily
                    font.pixelSize: 13
                }
            }

            // Scan / Discovery button
            Rectangle {
                Layout.preferredWidth: 38
                Layout.preferredHeight: 38
                radius: 19
                visible: bt.enabled
                color: scanArea.containsMouse ? Root.Theme.surfaceContainerHigh : Qt.rgba(255, 255, 255, 0.06)
                border.width: 1
                border.color: Qt.rgba(255, 255, 255, 0.10)
                Behavior on color { ColorAnimation { duration: 100 } }

                Text {
                    id: scanIcon
                    anchors.centerIn: parent
                    text: "refresh"
                    font.family: Root.Theme.iconFont
                    font.pixelSize: 20
                    color: Root.Theme.textSecondary
                }

                RotationAnimation {
                    target: scanIcon
                    property: "rotation"
                    from: 0
                    to: 360
                    duration: 1000
                    loops: Animation.Infinite
                    running: bt.discoveryScanning
                }

                MouseArea {
                    id: scanArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: bt.startDiscovery()
                }
            }

            // Pause / Resume Orbit Animation Button
            Rectangle {
                Layout.preferredWidth: 38
                Layout.preferredHeight: 38
                radius: 19
                visible: bt.enabled
                color: pauseBtMA.containsMouse ? Root.Theme.surfaceContainerHigh : Qt.rgba(255, 255, 255, 0.06)
                border.width: 1
                border.color: Qt.rgba(255, 255, 255, 0.10)
                Behavior on color { ColorAnimation { duration: 100 } }

                Text {
                    anchors.centerIn: parent
                    text: bt.animationPaused ? "play_arrow" : "pause"
                    font.family: Root.Theme.iconFont
                    font.pixelSize: 20
                    color: bt.animationPaused ? Root.Theme.primary : Root.Theme.textSecondary
                }

                MouseArea {
                    id: pauseBtMA
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: bt.toggleAnimation()
                }
            }

            // Bluetooth Toggle Switch
            Rectangle {
                Layout.preferredWidth: 52
                Layout.preferredHeight: 28
                radius: 14
                color: bt.enabled ? Root.Theme.primary : Root.Theme.surfaceContainerHigh

                Rectangle {
                    width: 22
                    height: 22
                    radius: 11
                    y: 3
                    x: bt.enabled ? parent.width - width - 3 : 3
                    color: Root.Theme.textPrimary
                    Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.InOutQuad } }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: bt.togglePower()
                }
            }
        }

        // ── Error Banner ─────────────────────────────────────────
        Rectangle {
            visible: bt.error !== ""
            Layout.fillWidth: true
            Layout.leftMargin: Root.Theme.paddingNormal
            Layout.rightMargin: 24
            Layout.topMargin: 8
            implicitHeight: errLabel.implicitHeight + 16
            radius: Root.Theme.radiusSmall
            color: Qt.rgba(Root.Theme.error.r, Root.Theme.error.g, Root.Theme.error.b, 0.15)
            border.width: 1
            border.color: Qt.rgba(Root.Theme.error.r, Root.Theme.error.g, Root.Theme.error.b, 0.35)

            Text {
                id: errLabel
                anchors.centerIn: parent
                width: parent.width - 24
                text: bt.error
                font.family: Root.Theme.fontFamily
                font.pixelSize: Root.Theme.fontSizeSmall
                color: Root.Theme.error
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
            }
        }

        // ── Main Radar Canvas & Orbital Stage ─────────────────────
        Item {
            id: radarStage
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            // Radar background guides (static lightweight canvas)
            Canvas {
                id: radarCanvas
                anchors.fill: parent

                property real centerX: (radarStage.width - 280) / 2
                property real centerY: radarStage.height / 2

                onPaint: {
                    var ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);
                    if (!bt.enabled) return;

                    ctx.lineWidth = 1;
                    ctx.strokeStyle = Qt.rgba(Root.Theme.textSecondary.r, Root.Theme.textSecondary.g, Root.Theme.textSecondary.b, 0.10);

                    var rings = [80, 130, 180, 230];
                    for (var r = 0; r < rings.length; r++) {
                        ctx.beginPath();
                        ctx.arc(centerX, centerY, rings[r], 0, 2 * Math.PI);
                        ctx.stroke();
                    }
                }
            }

            // Radar sweep pulse waves emitted from localhost
            Repeater {
                model: 2
                Rectangle {
                    id: pulseWave
                    x: ((radarStage.width - 280) / 2) - width / 2
                    y: (radarStage.height / 2) - height / 2
                    width: 70
                    height: 70
                    radius: width / 2
                    color: "transparent"
                    border.width: 1.5
                    border.color: Root.Theme.primary
                    visible: bt.enabled

                    ParallelAnimation {
                        running: bt.visible && bt.enabled
                        loops: Animation.Infinite

                        NumberAnimation {
                            target: pulseWave
                            property: "width"
                            from: 70
                            to: 470
                            duration: 3600
                            easing.type: Easing.OutQuad
                        }
                        NumberAnimation {
                            target: pulseWave
                            property: "height"
                            from: 70
                            to: 470
                            duration: 3600
                            easing.type: Easing.OutQuad
                        }
                        NumberAnimation {
                            target: pulseWave
                            property: "opacity"
                            from: 0.5
                            to: 0.0
                            duration: 3600
                            easing.type: Easing.OutQuad
                        }
                    }
                }
            }

            // Radar scanning radar line
            Item {
                id: scanRadarHand
                x: (radarStage.width - 280) / 2
                y: radarStage.height / 2
                visible: bt.discoveryScanning && bt.enabled

                Rectangle {
                    width: 225
                    height: 2
                    x: 0
                    y: -1
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: Root.Theme.primary }
                        GradientStop { position: 1.0; color: "transparent" }
                    }
                }

                RotationAnimation {
                    target: scanRadarHand
                    property: "rotation"
                    from: 0
                    to: 360
                    duration: 2500
                    loops: Animation.Infinite
                    running: bt.discoveryScanning && bt.enabled
                }
            }

            // Subtle discovery indicator pill
            Rectangle {
                visible: (bt.discoveryScanning || bt.pairStatus !== "") && bt.enabled
                x: ((radarStage.width - 280) / 2) - width / 2
                y: (radarStage.height / 2) + 60
                height: 26
                width: discRow.implicitWidth + 20
                radius: 13
                color: Qt.rgba(Root.Theme.surfaceContainer.r, Root.Theme.surfaceContainer.g, Root.Theme.surfaceContainer.b, 0.9)
                border.width: 1
                border.color: Qt.rgba(Root.Theme.primary.r, Root.Theme.primary.g, Root.Theme.primary.b, 0.4)
                z: 25

                RowLayout {
                    id: discRow
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        text: "󰑐"
                        font.family: Root.Theme.fontFamily
                        font.pixelSize: 12
                        color: Root.Theme.primary

                        RotationAnimation on rotation {
                            from: 0
                            to: 360
                            duration: 1200
                            loops: Animation.Infinite
                        }
                    }

                    Text {
                        text: bt.pairStatus !== "" ? bt.pairStatus : "Discovering devices..."
                        font.family: Root.Theme.fontFamily
                        font.pixelSize: Root.Theme.fontSizeXS
                        color: Root.Theme.textSecondary
                    }
                }
            }

            // ── Orbiting Bluetooth Device Nodes ───────────────────
            Repeater {
                model: pairedModel

                Item {
                    id: satelliteNode
                    required property int index
                    required property string mac
                    required property string name
                    required property string icon_type
                    required property int battery
                    required property real orbitRadius
                    required property real baseAngle

                    property real currentRad: (baseAngle + bt.orbitRotation) * (Math.PI / 180.0)
                    property real stageCenterX: (radarStage.width - 280) / 2
                    property real stageCenterY: radarStage.height / 2

                    x: stageCenterX + orbitRadius * Math.cos(currentRad) - (nodeBody.width / 2)
                    y: stageCenterY + orbitRadius * Math.sin(currentRad) - (nodeBody.height / 2)
                    z: nodeMA.containsMouse ? 20 : 10

                    Rectangle {
                        id: nodeBody
                        height: 44
                        radius: 22
                        width: Math.min(220, Math.max(110, nodeLayout.implicitWidth + 24))
                        color: nodeMA.containsMouse
                            ? Root.Theme.surfaceContainerHigh
                            : Qt.rgba(Root.Theme.surfaceContainer.r, Root.Theme.surfaceContainer.g, Root.Theme.surfaceContainer.b, 0.9)
                        border.width: nodeMA.containsMouse ? 1.5 : 1
                        border.color: nodeMA.containsMouse
                            ? Root.Theme.primary
                            : Qt.rgba(Root.Theme.surfaceContainerHigh.r, Root.Theme.surfaceContainerHigh.g, Root.Theme.surfaceContainerHigh.b, 0.6)

                        RowLayout {
                            id: nodeLayout
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 8

                            // Device icon (prominent large font)
                            Text {
                                text: bt.getDeviceIcon(icon_type)
                                font.family: Root.Theme.fontFamily
                                font.pixelSize: 18 // Prominent icon
                                color: Root.Theme.primary
                            }

                            // Device Name (max 25 characters)
                            Text {
                                text: name.length > 25 ? name.substring(0, 25) + "..." : name
                                font.family: Root.Theme.fontFamily
                                font.pixelSize: Root.Theme.fontSizeSmall
                                font.weight: Font.Medium
                                color: Root.Theme.textPrimary
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            // Edit icon trigger
                            Rectangle {
                                width: 22
                                height: 22
                                radius: 11
                                color: iconBtnMA.containsMouse ? Root.Theme.surfaceContainerHigh : "transparent"

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰏫" // nf-md-pencil
                                    font.family: Root.Theme.fontFamily
                                    font.pixelSize: 11
                                    color: Root.Theme.textSecondary
                                }

                                MouseArea {
                                    id: iconBtnMA
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        bt.openIconPicker(mac, name, icon_type);
                                    }
                                }
                            }
                        }

                        MouseArea {
                            id: nodeMA
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                bt.connectDevice(mac);
                            }
                        }
                    }
                }
            }

            // ── Central Localhost Host Node ───────────────────────
            Item {
                id: localhostNode
                x: ((radarStage.width - 280) / 2) - width / 2
                y: (radarStage.height / 2) - height / 2
                width: 90
                height: 90
                z: 30

                // Outer ambient ring
                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width + 12
                    height: parent.height + 12
                    radius: width / 2
                    color: "transparent"
                    border.width: 1
                    border.color: Qt.rgba(Root.Theme.primary.r, Root.Theme.primary.g, Root.Theme.primary.b, 0.3)
                }

                // Core central disc
                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: hostMA.containsMouse ? Root.Theme.surfaceBright : Root.Theme.surfaceContainerHigh
                    border.width: 2
                    border.color: Root.Theme.primary

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 2

                        Text {
                            text: "󰌢" // Laptop
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: 26
                            color: Root.Theme.primary
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Text {
                            text: "localhost"
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: Root.Theme.fontSizeXS
                            font.weight: Font.DemiBold
                            color: Root.Theme.textPrimary
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }

                    MouseArea {
                        id: hostMA
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            bt.startDiscovery();
                        }
                    }
                }
            }

            // ── Right Side: Connected Bluetooth Device Card ───────
            Rectangle {
                id: connectedCard
                visible: bt.enabled && bt.connectedMac !== ""
                anchors.right: parent.right
                anchors.rightMargin: 24
                anchors.verticalCenter: parent.verticalCenter
                width: 245
                implicitHeight: cardContent.implicitHeight + 24
                radius: Root.Theme.radiusLarge
                color: Qt.rgba(Root.Theme.surfaceContainer.r, Root.Theme.surfaceContainer.g, Root.Theme.surfaceContainer.b, 0.95)
                border.width: 1.5
                border.color: Root.Theme.primary
                z: 35

                ColumnLayout {
                    id: cardContent
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 10

                    // Header row: Badge + Device label
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Rectangle {
                            width: 32
                            height: 32
                            radius: 16
                            color: Root.Theme.primary

                            Text {
                                anchors.centerIn: parent
                                text: bt.getDeviceIcon(bt.connectedIconType)
                                font.family: Root.Theme.fontFamily
                                font.pixelSize: 18 // Prominent icon
                                color: Root.Theme.tileActiveText
                            }
                        }

                        ColumnLayout {
                            spacing: 1
                            Layout.fillWidth: true

                            Text {
                                text: "PAIRED LINK"
                                font.family: Root.Theme.fontFamily
                                font.pixelSize: 9
                                font.weight: Font.Bold
                                font.letterSpacing: 1
                                color: Root.Theme.primary
                            }

                            Text {
                                text: bt.connectedName
                                font.family: Root.Theme.fontFamily
                                font.pixelSize: Root.Theme.fontSizeNormal
                                font.weight: Font.DemiBold
                                color: Root.Theme.textPrimary
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }
                    }

                    // Divider
                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: Root.Theme.surfaceContainerHigh
                    }

                    // Table details: 2 columns
                    GridLayout {
                        columns: 2
                        columnSpacing: 10
                        rowSpacing: 6
                        Layout.fillWidth: true

                        // Row 1: Type
                        Text {
                            text: "Device Type"
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: Root.Theme.fontSizeXS
                            color: Root.Theme.textSecondary
                        }
                        Text {
                            text: bt.connectedIconType.toUpperCase()
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: Root.Theme.fontSizeXS
                            font.weight: Font.Medium
                            color: Root.Theme.textPrimary
                            Layout.alignment: Qt.AlignRight
                        }

                        // Row 2: MAC Address
                        Text {
                            text: "Address"
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: Root.Theme.fontSizeXS
                            color: Root.Theme.textSecondary
                        }
                        Text {
                            text: bt.connectedMac
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: Root.Theme.fontSizeXS
                            font.weight: Font.Medium
                            color: Root.Theme.textPrimary
                            Layout.alignment: Qt.AlignRight
                            elide: Text.ElideRight
                        }

                        // Row 3: Battery level
                        Text {
                            text: "Battery"
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: Root.Theme.fontSizeXS
                            color: Root.Theme.textSecondary
                        }
                        Text {
                            text: bt.connectedBattery !== null ? bt.connectedBattery + "%" : "N/A"
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: Root.Theme.fontSizeXS
                            font.weight: Font.Medium
                            color: bt.connectedBattery !== null ? Root.Theme.connected : Root.Theme.textSecondary
                            Layout.alignment: Qt.AlignRight
                        }
                    }

                    // Divider
                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: Root.Theme.surfaceContainerHigh
                    }

                    // Action buttons: Disconnect & Change Icon
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Rectangle {
                            Layout.fillWidth: true
                            height: 32
                            radius: 16
                            color: editCardMA.containsMouse ? Root.Theme.surfaceContainerHigh : "transparent"
                            border.width: 1
                            border.color: Root.Theme.surfaceContainerHigh

                            Text {
                                anchors.centerIn: parent
                                text: "Icon"
                                font.family: Root.Theme.fontFamily
                                font.pixelSize: Root.Theme.fontSizeXS
                                color: Root.Theme.textSecondary
                            }

                            MouseArea {
                                id: editCardMA
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: bt.openIconPicker(bt.connectedMac, bt.connectedName, bt.connectedIconType)
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 32
                            radius: 16
                            color: disconnBtnMA.containsMouse ? Qt.rgba(Root.Theme.error.r, Root.Theme.error.g, Root.Theme.error.b, 0.25) : Qt.rgba(Root.Theme.error.r, Root.Theme.error.g, Root.Theme.error.b, 0.12)
                            border.width: 1
                            border.color: Qt.rgba(Root.Theme.error.r, Root.Theme.error.g, Root.Theme.error.b, 0.3)

                            Text {
                                anchors.centerIn: parent
                                text: "Disconnect"
                                font.family: Root.Theme.fontFamily
                                font.pixelSize: Root.Theme.fontSizeXS
                                font.weight: Font.Medium
                                color: Root.Theme.error
                            }

                            MouseArea {
                                id: disconnBtnMA
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: bt.disconnectDevice(bt.connectedMac)
                            }
                        }
                    }
                }
            }

            // ── Discovered Devices Drawer (Bottom drawer when scanning)
            Rectangle {
                visible: bt.enabled && unpairedModel.count > 0
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.leftMargin: Root.Theme.paddingNormal
                anchors.rightMargin: 24
                anchors.bottomMargin: Root.Theme.paddingNormal
                height: 60
                radius: Root.Theme.radiusSmall
                color: Qt.rgba(Root.Theme.surfaceContainer.r, Root.Theme.surfaceContainer.g, Root.Theme.surfaceContainer.b, 0.95)
                border.width: 1
                border.color: Root.Theme.primary
                z: 40

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 12

                    Text {
                        text: "NEW DEVICES (" + unpairedModel.count + "):"
                        font.family: Root.Theme.fontFamily
                        font.pixelSize: 9
                        font.weight: Font.Bold
                        color: Root.Theme.primary
                    }

                    ListView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        orientation: ListView.Horizontal
                        spacing: 8
                        clip: true
                        model: unpairedModel

                        delegate: Rectangle {
                            required property string mac
                            required property string name
                            height: 36
                            width: Math.min(180, nameLabel.implicitWidth + 60)
                            radius: 18
                            color: pairBtnMA.containsMouse ? Root.Theme.surfaceContainerHigh : Root.Theme.surfaceContainer
                            border.width: 1
                            border.color: Root.Theme.surfaceContainerHigh

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                spacing: 6

                                Text {
                                    id: nameLabel
                                    text: name
                                    font.family: Root.Theme.fontFamily
                                    font.pixelSize: Root.Theme.fontSizeXS
                                    color: Root.Theme.textPrimary
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: "󰐕" // Plus / Pair
                                    font.family: Root.Theme.fontFamily
                                    font.pixelSize: 12
                                    color: Root.Theme.primary
                                }
                            }

                            MouseArea {
                                id: pairBtnMA
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: bt.pairDevice(mac)
                            }
                        }
                    }
                }
            }
        }
    }

    // ── Icon Selection Modal Dialog ──────────────────────────────
    Rectangle {
        id: iconModalScrim
        anchors.fill: parent
        visible: bt.showIconDialog
        color: Qt.rgba(0, 0, 0, 0.65)
        z: 100

        MouseArea {
            anchors.fill: parent
            onClicked: bt.showIconDialog = false
        }

        Rectangle {
            id: iconModal
            anchors.centerIn: parent
            width: Math.min(380, parent.width - 32)
            implicitHeight: iconModalCol.implicitHeight + 36
            radius: Root.Theme.radiusLarge
            color: Root.Theme.surfaceContainer
            border.width: 1.5
            border.color: Root.Theme.primary

            MouseArea { anchors.fill: parent }

            ColumnLayout {
                id: iconModalCol
                anchors.fill: parent
                anchors.margins: 18
                spacing: 14

                // Modal Title
                ColumnLayout {
                    spacing: 2
                    Text {
                        text: "Choose Device Icon"
                        font.family: Root.Theme.fontFamily
                        font.pixelSize: Root.Theme.fontSizeNormal
                        font.weight: Font.DemiBold
                        color: Root.Theme.textPrimary
                    }
                    Text {
                        text: bt.selectedDeviceName
                        font.family: Root.Theme.fontFamily
                        font.pixelSize: Root.Theme.fontSizeXS
                        color: Root.Theme.textSecondary
                        elide: Text.ElideRight
                    }
                }

                // Grid of Icons (mouse, keyboard, headphones, speaker, gamepad, device)
                GridLayout {
                    columns: 3
                    columnSpacing: 10
                    rowSpacing: 10
                    Layout.fillWidth: true

                    // Mouse
                    Rectangle {
                        Layout.fillWidth: true
                        height: 58
                        radius: Root.Theme.radiusSmall
                        color: bt.currentSelectedIcon === "mouse" ? Root.Theme.primaryContainer : (mouseMA.containsMouse ? Root.Theme.surfaceContainerHigh : "transparent")
                        border.width: 1
                        border.color: bt.currentSelectedIcon === "mouse" ? Root.Theme.primary : Root.Theme.surfaceContainerHigh

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 2
                            Text {
                                text: "󰍽"
                                font.family: Root.Theme.fontFamily
                                font.pixelSize: 22 // Big icon
                                color: bt.currentSelectedIcon === "mouse" ? Root.Theme.primary : Root.Theme.textPrimary
                                Layout.alignment: Qt.AlignHCenter
                            }
                            Text {
                                text: "Mouse"
                                font.family: Root.Theme.fontFamily
                                font.pixelSize: 10
                                color: Root.Theme.textSecondary
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }

                        MouseArea {
                            id: mouseMA
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: bt.saveIconChoice("mouse")
                        }
                    }

                    // Keyboard
                    Rectangle {
                        Layout.fillWidth: true
                        height: 58
                        radius: Root.Theme.radiusSmall
                        color: bt.currentSelectedIcon === "keyboard" ? Root.Theme.primaryContainer : (kbMA.containsMouse ? Root.Theme.surfaceContainerHigh : "transparent")
                        border.width: 1
                        border.color: bt.currentSelectedIcon === "keyboard" ? Root.Theme.primary : Root.Theme.surfaceContainerHigh

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 2
                            Text {
                                text: "󰌌"
                                font.family: Root.Theme.fontFamily
                                font.pixelSize: 22
                                color: bt.currentSelectedIcon === "keyboard" ? Root.Theme.primary : Root.Theme.textPrimary
                                Layout.alignment: Qt.AlignHCenter
                            }
                            Text {
                                text: "Keyboard"
                                font.family: Root.Theme.fontFamily
                                font.pixelSize: 10
                                color: Root.Theme.textSecondary
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }

                        MouseArea {
                            id: kbMA
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: bt.saveIconChoice("keyboard")
                        }
                    }

                    // Headphones
                    Rectangle {
                        Layout.fillWidth: true
                        height: 58
                        radius: Root.Theme.radiusSmall
                        color: bt.currentSelectedIcon === "headphones" ? Root.Theme.primaryContainer : (hpMA.containsMouse ? Root.Theme.surfaceContainerHigh : "transparent")
                        border.width: 1
                        border.color: bt.currentSelectedIcon === "headphones" ? Root.Theme.primary : Root.Theme.surfaceContainerHigh

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 2
                            Text {
                                text: "󰋋"
                                font.family: Root.Theme.fontFamily
                                font.pixelSize: 22
                                color: bt.currentSelectedIcon === "headphones" ? Root.Theme.primary : Root.Theme.textPrimary
                                Layout.alignment: Qt.AlignHCenter
                            }
                            Text {
                                text: "Headphones"
                                font.family: Root.Theme.fontFamily
                                font.pixelSize: 10
                                color: Root.Theme.textSecondary
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }

                        MouseArea {
                            id: hpMA
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: bt.saveIconChoice("headphones")
                        }
                    }

                    // Speaker
                    Rectangle {
                        Layout.fillWidth: true
                        height: 58
                        radius: Root.Theme.radiusSmall
                        color: bt.currentSelectedIcon === "speaker" ? Root.Theme.primaryContainer : (spkMA.containsMouse ? Root.Theme.surfaceContainerHigh : "transparent")
                        border.width: 1
                        border.color: bt.currentSelectedIcon === "speaker" ? Root.Theme.primary : Root.Theme.surfaceContainerHigh

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 2
                            Text {
                                text: "󰓃"
                                font.family: Root.Theme.fontFamily
                                font.pixelSize: 22
                                color: bt.currentSelectedIcon === "speaker" ? Root.Theme.primary : Root.Theme.textPrimary
                                Layout.alignment: Qt.AlignHCenter
                            }
                            Text {
                                text: "Speaker"
                                font.family: Root.Theme.fontFamily
                                font.pixelSize: 10
                                color: Root.Theme.textSecondary
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }

                        MouseArea {
                            id: spkMA
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: bt.saveIconChoice("speaker")
                        }
                    }

                    // Gamepad / Controller
                    Rectangle {
                        Layout.fillWidth: true
                        height: 58
                        radius: Root.Theme.radiusSmall
                        color: bt.currentSelectedIcon === "gamepad" ? Root.Theme.primaryContainer : (padMA.containsMouse ? Root.Theme.surfaceContainerHigh : "transparent")
                        border.width: 1
                        border.color: bt.currentSelectedIcon === "gamepad" ? Root.Theme.primary : Root.Theme.surfaceContainerHigh

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 2
                            Text {
                                text: "󰊴"
                                font.family: Root.Theme.fontFamily
                                font.pixelSize: 22
                                color: bt.currentSelectedIcon === "gamepad" ? Root.Theme.primary : Root.Theme.textPrimary
                                Layout.alignment: Qt.AlignHCenter
                            }
                            Text {
                                text: "Gamepad"
                                font.family: Root.Theme.fontFamily
                                font.pixelSize: 10
                                color: Root.Theme.textSecondary
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }

                        MouseArea {
                            id: padMA
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: bt.saveIconChoice("gamepad")
                        }
                    }

                    // Generic Device
                    Rectangle {
                        Layout.fillWidth: true
                        height: 58
                        radius: Root.Theme.radiusSmall
                        color: bt.currentSelectedIcon === "device" ? Root.Theme.primaryContainer : (devMA.containsMouse ? Root.Theme.surfaceContainerHigh : "transparent")
                        border.width: 1
                        border.color: bt.currentSelectedIcon === "device" ? Root.Theme.primary : Root.Theme.surfaceContainerHigh

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 2
                            Text {
                                text: "󰂲"
                                font.family: Root.Theme.fontFamily
                                font.pixelSize: 22
                                color: bt.currentSelectedIcon === "device" ? Root.Theme.primary : Root.Theme.textPrimary
                                Layout.alignment: Qt.AlignHCenter
                            }
                            Text {
                                text: "Device"
                                font.family: Root.Theme.fontFamily
                                font.pixelSize: 10
                                color: Root.Theme.textSecondary
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }

                        MouseArea {
                            id: devMA
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: bt.saveIconChoice("device")
                        }
                    }
                }

                // Close Button
                Rectangle {
                    Layout.fillWidth: true
                    height: 36
                    radius: Root.Theme.radiusSmall
                    color: closeIconMA.containsMouse ? Root.Theme.surfaceContainerHigh : "transparent"
                    border.width: 1
                    border.color: Root.Theme.surfaceContainerHigh

                    Text {
                        anchors.centerIn: parent
                        text: "Close"
                        font.family: Root.Theme.fontFamily
                        font.pixelSize: Root.Theme.fontSizeNormal
                        color: Root.Theme.textSecondary
                    }

                    MouseArea {
                        id: closeIconMA
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: bt.showIconDialog = false
                    }
                }
            }
        }
    }
}
