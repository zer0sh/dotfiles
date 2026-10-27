import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Io
import "../.." as Root

// Wi-Fi Sub-Page — Orbital Radar and Real-Time Network Management
Item {
    id: wifiPanel

    signal back()

    property bool wifiEnabled: true
    property bool scanning: false
    property string errorMessage: ""

    // Connected Network Card Details (Instant cached state)
    property string connectedSsid: ""
    property int connectedSignal: 0
    property string connectedSecurity: "--"
    property string connectedDbm: "--"
    property string connectedIp: "--"
    property string connectedRange: "--"

    // Telemetry and HUD state
    property bool showHud: false
    property string pingMs: "--"
    property string bitrateVal: "--"
    property string rxRate: "--"
    property string txRate: "--"

    // Password modal state
    property string targetSSID: ""
    property string targetSecurity: ""
    property bool showPasswordModal: false
    property bool connecting: false

    // Orbit angle for orbital drift animation (smooth 60fps rotation)
    property real orbitRotation: 0
    property bool animationPaused: false

    NumberAnimation {
        target: wifiPanel
        property: "orbitRotation"
        from: 0
        to: 360
        duration: 90000
        loops: Animation.Infinite
        running: wifiPanel.visible && wifiPanel.wifiEnabled && !wifiPanel.animationPaused
    }

    // ── Instant Cache & Process Execution ────────────────────────

    Process {
        id: readRadarPrefProc
        command: ["python3", "-c", "import json, os; p = os.path.expanduser('~/.config/quickshell/radar_preferences.json'); print(json.load(open(p)).get('wifi_paused', False) if os.path.exists(p) else False)"]
        stdout: StdioCollector {
            onStreamFinished: {
                wifiPanel.animationPaused = (text.trim() === "True" || text.trim() === "true");
            }
        }
    }

    Process {
        id: saveRadarPrefProc
        stdout: StdioCollector {}
    }

    function toggleAnimation() {
        animationPaused = !animationPaused;
        saveRadarPrefProc.command = ["python3", "-c", "import json, os; p = os.path.expanduser('~/.config/quickshell/radar_preferences.json'); d = json.load(open(p)) if os.path.exists(p) else {}; d['wifi_paused'] = " + (animationPaused ? "True" : "False") + "; json.dump(d, open(p, 'w'))"];
        saveRadarPrefProc.running = true;
    }

    // 1. Immediately hydrate connected state from JSON cache
    Process {
        id: readStatusCacheProc
        command: ["cat", "/home/zero/.cache/quickshell/wifi_status.json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    if (text.trim() === "") return;
                    var d = JSON.parse(text.trim());
                    if (d.connected && d.ssid) {
                        wifiPanel.connectedSsid = d.ssid;
                        wifiPanel.connectedSignal = parseInt(d.signal) || 0;
                        wifiPanel.connectedSecurity = d.security || "--";
                        wifiPanel.connectedDbm = d.dbm || "--";
                        wifiPanel.connectedIp = d.ip || "--";
                        wifiPanel.connectedRange = d.range || "--";
                        wifiPanel.pingMs = d.ping || "--";
                        wifiPanel.bitrateVal = d.bitrate || "--";
                        wifiPanel.rxRate = d.rx_rate || "--";
                        wifiPanel.txRate = d.tx_rate || "--";
                    }
                } catch (e) {}
            }
        }
    }

    // 2. Immediately populate network list from raw scan cache
    Process {
        id: readScanCacheProc
        command: ["cat", "/home/zero/.cache/quickshell/wifi_cache.raw"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (networkListModel.count === 0 && text.trim() !== "") {
                    wifiPanel.parseNetworks(text);
                }
            }
        }
    }

    Process {
        id: radioStatusProc
        command: ["nmcli", "radio", "wifi"]
        stdout: StdioCollector {
            onStreamFinished: {
                var wasEnabled = wifiPanel.wifiEnabled;
                wifiPanel.wifiEnabled = (text.trim() === "enabled");
                if (wifiPanel.wifiEnabled && !wasEnabled) {
                    wifiPanel.scanning = true;
                    listNetworksProc.running = true;
                }
                if (!wifiPanel.wifiEnabled) {
                    networkListModel.clear();
                    wifiPanel.connectedSsid = "";
                }
            }
        }
    }

    Process {
        id: listNetworksProc
        command: ["/bin/sh", "-c", "nmcli -t -f active,ssid,signal,security dev wifi list > /home/zero/.cache/quickshell/wifi_cache.raw.tmp && mv /home/zero/.cache/quickshell/wifi_cache.raw.tmp /home/zero/.cache/quickshell/wifi_cache.raw && cat /home/zero/.cache/quickshell/wifi_cache.raw"]
        stdout: StdioCollector {
            onStreamFinished: {
                wifiPanel.scanning = false;
                if (text.trim() !== "") {
                    wifiPanel.parseNetworks(text);
                }
            }
        }
        onExited: (exitCode, exitStatus) => {
            wifiPanel.scanning = false;
            if (exitCode !== 0 && networkListModel.count === 0) {
                wifiPanel.errorMessage = "Scan failed";
            }
        }
    }

    Process {
        id: toggleWifiProc
        stdout: StdioCollector {}
        onExited: (exitCode, exitStatus) => { radioStatusProc.running = true; }
    }

    Process {
        id: connectProc
        stdout: StdioCollector {}
        onExited: (exitCode, exitStatus) => {
            wifiPanel.connecting = false;
            if (exitCode !== 0) {
                wifiPanel.errorMessage = "Connection failed";
            } else {
                wifiPanel.errorMessage = "";
                wifiPanel.showPasswordModal = false;
                wifiPanel.targetSSID = "";
            }
            listNetworksProc.running = true;
            metricsProc.running = true;
        }
    }

    Process {
        id: savedConnectProc
        stdout: StdioCollector {}
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                wifiPanel.connecting = false;
                wifiPanel.errorMessage = "";
                wifiPanel.showPasswordModal = false;
                wifiPanel.targetSSID = "";
                listNetworksProc.running = true;
                metricsProc.running = true;
            } else {
                wifiPanel.connecting = false;
                if (wifiPanel.targetSecurity !== "" && wifiPanel.targetSecurity !== "--") {
                    wifiPanel.showPasswordModal = true;
                    Qt.callLater(() => modalPasswordField.forceActiveFocus());
                } else {
                    wifiPanel.connectToNetwork(wifiPanel.targetSSID, "");
                }
            }
        }
    }

    Process {
        id: rescanProc
        command: ["nmcli", "dev", "wifi", "rescan"]
        stdout: StdioCollector {}
        onExited: (exitCode, exitStatus) => { listNetworksProc.running = true; }
    }

    // Live Metrics Telemetry Process (very low CPU usage)
    Process {
        id: metricsProc
        command: ["/home/zero/dotfiles/quickshell/scripts/wifi-metrics.py"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var data = JSON.parse(text.trim());
                    wifiPanel.pingMs = data.ping || "--";
                    wifiPanel.bitrateVal = data.bitrate || "--";
                    wifiPanel.rxRate = data.rx_rate || "--";
                    wifiPanel.txRate = data.tx_rate || "--";
                    if (data.connected && data.ssid) {
                        wifiPanel.connectedSsid = data.ssid;
                        wifiPanel.connectedSignal = parseInt(data.signal) || 0;
                        wifiPanel.connectedSecurity = data.security || "--";
                        wifiPanel.connectedDbm = data.dbm || "--";
                        wifiPanel.connectedIp = data.ip || "--";
                        wifiPanel.connectedRange = data.range || "--";
                    } else if (!data.connected) {
                        wifiPanel.connectedSsid = "";
                    }
                } catch (e) {}
            }
        }
    }

    Timer {
        id: telemetryTimer
        interval: 3500
        running: wifiPanel.visible && wifiPanel.wifiEnabled && (wifiPanel.connectedSsid !== "" || wifiPanel.showHud)
        repeat: true
        onTriggered: {
            if (!metricsProc.running) metricsProc.running = true;
        }
    }

    Timer {
        id: refreshTimer
        interval: 14000
        running: wifiPanel.visible && wifiPanel.wifiEnabled
        repeat: true
        onTriggered: {
            if (!wifiPanel.scanning) listNetworksProc.running = true;
        }
    }

    Component.onCompleted: {
        readRadarPrefProc.running = true;
        readStatusCacheProc.running = true;
        readScanCacheProc.running = true;
        radioStatusProc.running = true;
        wifiPanel.scanning = true;
        listNetworksProc.running = true;
        metricsProc.running = true;
    }

    // ── Data Logic ───────────────────────────────────────────────

    ListModel { id: networkListModel }

    function parseNetworks(output) {
        var lines = output.trim().split("\n");
        var networks = [];
        var seen = {};
        var foundConnected = false;

        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim();
            if (line === "") continue;

            var parts = line.split(":");
            if (parts.length < 4) continue;

            var inUse = parts[0].trim();
            var ssid = parts[1].trim();
            var sig = parseInt(parts[2].trim());
            var sec = parts.slice(3).join(":").trim();

            if (isNaN(sig)) sig = 0;
            if (ssid === "") continue;

            var isConn = (inUse === "yes" || inUse === "*");
            if (isConn) {
                foundConnected = true;
                wifiPanel.connectedSsid = ssid;
                wifiPanel.connectedSignal = sig;
                if (sec !== "") wifiPanel.connectedSecurity = sec;
            }

            if (seen[ssid] !== undefined) {
                var idx = seen[ssid];
                if (networks[idx].signal < sig) {
                    networks[idx].signal = sig;
                    networks[idx].security = sec;
                }
                if (isConn) networks[idx].connected = true;
                continue;
            }

            seen[ssid] = networks.length;
            networks.push({
                ssid: ssid,
                signal: sig,
                security: sec,
                connected: isConn
            });
        }

        if (!foundConnected) {
            wifiPanel.connectedSsid = "";
        }

        var orbitingList = [];
        for (var k = 0; k < networks.length; k++) {
            if (!networks[k].connected) {
                orbitingList.push(networks[k]);
            }
        }

        orbitingList.sort(function(a, b) {
            return b.signal - a.signal;
        });

        var displayCount = Math.min(orbitingList.length, 12);
        networkListModel.clear();
        for (var j = 0; j < displayCount; j++) {
            var item = orbitingList[j];
            var clampedSig = Math.max(15, Math.min(100, item.signal));
            var orbitR = 215 - (clampedSig / 100.0) * 105;
            var baseAngle = (360.0 / displayCount) * j;

            networkListModel.append({
                ssid: item.ssid,
                signal: item.signal,
                security: item.security,
                orbitRadius: orbitR,
                baseAngle: baseAngle
            });
        }

        errorMessage = "";
    }

    function toggleWifi() {
        if (wifiEnabled) {
            toggleWifiProc.command = ["nmcli", "radio", "wifi", "off"];
        } else {
            toggleWifiProc.command = ["nmcli", "radio", "wifi", "on"];
        }
        toggleWifiProc.running = true;
    }

    function connectToNetwork(ssid, password) {
        connecting = true;
        if (password && password.length > 0) {
            connectProc.command = ["nmcli", "dev", "wifi", "connect", ssid, "password", password];
        } else {
            connectProc.command = ["nmcli", "dev", "wifi", "connect", ssid];
        }
        connectProc.running = true;
    }

    function selectNetwork(ssid, security) {
        targetSSID = ssid;
        targetSecurity = security;
        errorMessage = "";
        connecting = true;
        savedConnectProc.command = ["nmcli", "connection", "up", "id", ssid];
        savedConnectProc.running = true;
    }

    function signalIcon(strength) {
        if (strength <= 25) return "󰤯";
        if (strength <= 50) return "󰤟";
        if (strength <= 75) return "󰤢";
        return "󰤨";
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
                    onClicked: wifiPanel.back()
                }
            }

            // Title + Status indicator
            ColumnLayout {
                spacing: 1
                Layout.fillWidth: true

                Text {
                    text: "Wi-Fi Radar"
                    color: Root.Theme.textPrimary
                    font.family: Root.Theme.fontFamily
                    font.pixelSize: 18
                    font.weight: Font.DemiBold
                }

                Text {
                    text: !wifiPanel.wifiEnabled
                        ? "Disabled"
                        : (wifiPanel.connectedSsid !== "" ? "Connected to " + wifiPanel.connectedSsid : "Disconnected")
                    color: wifiPanel.connectedSsid !== "" ? Root.Theme.primary : Root.Theme.textSecondary
                    font.family: Root.Theme.fontFamily
                    font.pixelSize: 13
                }
            }

            // Telemetry HUD Toggle
            Rectangle {
                Layout.preferredWidth: 38
                Layout.preferredHeight: 38
                radius: 19
                visible: wifiPanel.wifiEnabled
                color: wifiPanel.showHud ? Root.Theme.primary : (hudArea.containsMouse ? Root.Theme.surfaceContainerHigh : Qt.rgba(255, 255, 255, 0.06))
                border.width: 1
                border.color: Qt.rgba(255, 255, 255, 0.10)
                Behavior on color { ColorAnimation { duration: 100 } }

                Text {
                    anchors.centerIn: parent
                    text: "speed"
                    font.family: Root.Theme.iconFont
                    font.pixelSize: 20
                    color: wifiPanel.showHud ? Root.Theme.tileActiveText : Root.Theme.textSecondary
                }

                MouseArea {
                    id: hudArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        wifiPanel.showHud = !wifiPanel.showHud;
                        if (wifiPanel.showHud) metricsProc.running = true;
                    }
                }
            }

            // Refresh scan button
            Rectangle {
                Layout.preferredWidth: 38
                Layout.preferredHeight: 38
                radius: 19
                visible: wifiPanel.wifiEnabled
                color: refreshArea.containsMouse ? Root.Theme.surfaceContainerHigh : Qt.rgba(255, 255, 255, 0.06)
                border.width: 1
                border.color: Qt.rgba(255, 255, 255, 0.10)
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
                    duration: 1000
                    loops: Animation.Infinite
                    running: wifiPanel.scanning
                }

                MouseArea {
                    id: refreshArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (!wifiPanel.scanning && wifiPanel.wifiEnabled) {
                            wifiPanel.scanning = true;
                            wifiPanel.errorMessage = "";
                            rescanProc.running = true;
                            metricsProc.running = true;
                        }
                    }
                }
            }

            // Pause / Resume Orbit Animation Button
            Rectangle {
                Layout.preferredWidth: 38
                Layout.preferredHeight: 38
                radius: 19
                visible: wifiPanel.wifiEnabled
                color: pauseBtnMA.containsMouse ? Root.Theme.surfaceContainerHigh : Qt.rgba(255, 255, 255, 0.06)
                border.width: 1
                border.color: Qt.rgba(255, 255, 255, 0.10)
                Behavior on color { ColorAnimation { duration: 100 } }

                Text {
                    anchors.centerIn: parent
                    text: wifiPanel.animationPaused ? "play_arrow" : "pause"
                    font.family: Root.Theme.iconFont
                    font.pixelSize: 20
                    color: wifiPanel.animationPaused ? Root.Theme.primary : Root.Theme.textSecondary
                }

                MouseArea {
                    id: pauseBtnMA
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: wifiPanel.toggleAnimation()
                }
            }

            // Wi-Fi Power Switch
            Rectangle {
                Layout.preferredWidth: 52
                Layout.preferredHeight: 28
                radius: 14
                color: wifiPanel.wifiEnabled ? Root.Theme.primary : Root.Theme.surfaceContainerHigh

                Rectangle {
                    width: 22
                    height: 22
                    radius: 11
                    y: 3
                    x: wifiPanel.wifiEnabled ? parent.width - width - 3 : 3
                    color: Root.Theme.textPrimary
                    Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.InOutQuad } }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: wifiPanel.toggleWifi()
                }
            }
        }

        // ── Error Banner ─────────────────────────────────────────
        Rectangle {
            visible: wifiPanel.errorMessage !== ""
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
                text: wifiPanel.errorMessage
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

            // Radar background guides: rendered via simple static Shape/Canvas
            Canvas {
                id: radarCanvas
                anchors.fill: parent

                property real centerX: (radarStage.width - 280) / 2
                property real centerY: radarStage.height / 2

                onPaint: {
                    var ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);

                    if (!wifiPanel.wifiEnabled) return;

                    ctx.lineWidth = 1;
                    ctx.strokeStyle = Qt.rgba(Root.Theme.textSecondary.r, Root.Theme.textSecondary.g, Root.Theme.textSecondary.b, 0.10);

                    var rings = [75, 125, 175, 225];
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
                    visible: wifiPanel.wifiEnabled

                    ParallelAnimation {
                        running: wifiPanel.visible && wifiPanel.wifiEnabled
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
                visible: wifiPanel.scanning && wifiPanel.wifiEnabled

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
                    running: wifiPanel.scanning && wifiPanel.wifiEnabled
                }
            }

            // Subtle integrated loading indicator pill when scanning
            Rectangle {
                visible: wifiPanel.scanning && wifiPanel.wifiEnabled
                x: ((radarStage.width - 280) / 2) - width / 2
                y: (radarStage.height / 2) + 60
                height: 26
                width: scanRow.implicitWidth + 20
                radius: 13
                color: Qt.rgba(Root.Theme.surfaceContainer.r, Root.Theme.surfaceContainer.g, Root.Theme.surfaceContainer.b, 0.9)
                border.width: 1
                border.color: Qt.rgba(Root.Theme.primary.r, Root.Theme.primary.g, Root.Theme.primary.b, 0.4)
                z: 25

                RowLayout {
                    id: scanRow
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
                        text: "Scanning frequencies..."
                        font.family: Root.Theme.fontFamily
                        font.pixelSize: Root.Theme.fontSizeXS
                        color: Root.Theme.textSecondary
                    }
                }
            }

            // ── Orbiting Wi-Fi Network Nodes ──────────────────────
            Repeater {
                model: networkListModel

                Item {
                    id: satelliteNode
                    required property int index
                    required property string ssid
                    required property int signal
                    required property string security
                    required property real orbitRadius
                    required property real baseAngle

                    property real currentRad: (baseAngle + wifiPanel.orbitRotation) * (Math.PI / 180.0)
                    property real stageCenterX: (radarStage.width - 280) / 2
                    property real stageCenterY: radarStage.height / 2

                    x: stageCenterX + orbitRadius * Math.cos(currentRad) - (nodeBody.width / 2)
                    y: stageCenterY + orbitRadius * Math.sin(currentRad) - (nodeBody.height / 2)
                    z: nodeMA.containsMouse ? 20 : 10

                    Rectangle {
                        id: nodeBody
                        height: 44
                        radius: 22
                        width: Math.min(210, Math.max(105, nodeLayout.implicitWidth + 24))
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

                            Text {
                                text: wifiPanel.signalIcon(signal)
                                font.family: Root.Theme.fontFamily
                                font.pixelSize: 16
                                color: Root.Theme.primary
                            }

                            Text {
                                text: ssid.length > 25 ? ssid.substring(0, 25) + "..." : ssid
                                font.family: Root.Theme.fontFamily
                                font.pixelSize: Root.Theme.fontSizeSmall
                                font.weight: Font.Medium
                                color: Root.Theme.textPrimary
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Text {
                                visible: security !== "" && security !== "--" && security !== "Open"
                                text: "󰌾"
                                font.family: Root.Theme.fontFamily
                                font.pixelSize: 12
                                color: Root.Theme.textSecondary
                            }
                        }

                        MouseArea {
                            id: nodeMA
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: wifiPanel.selectNetwork(ssid, security)
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
                            text: "󰌢"
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
                            wifiPanel.showHud = !wifiPanel.showHud;
                            if (wifiPanel.showHud) metricsProc.running = true;
                        }
                    }
                }
            }

            // ── Right Side: Connected Network Table Card ──────────
            Rectangle {
                id: connectedCard
                visible: wifiPanel.wifiEnabled && wifiPanel.connectedSsid !== ""
                anchors.right: parent.right
                anchors.rightMargin: 24 // Increased right margin
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

                    // Header row: Badge + Connected label
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Rectangle {
                            width: 28
                            height: 28
                            radius: 14
                            color: Root.Theme.primary

                            Text {
                                anchors.centerIn: parent
                                text: "󰤨"
                                font.family: Root.Theme.fontFamily
                                font.pixelSize: 14
                                color: Root.Theme.tileActiveText
                            }
                        }

                        ColumnLayout {
                            spacing: 1
                            Layout.fillWidth: true

                            Text {
                                text: "ACTIVE LINK"
                                font.family: Root.Theme.fontFamily
                                font.pixelSize: 9
                                font.weight: Font.Bold
                                font.letterSpacing: 1
                                color: Root.Theme.primary
                            }

                            Text {
                                text: wifiPanel.connectedSsid
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

                        // Row 1: Security
                        Text {
                            text: "Security"
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: Root.Theme.fontSizeXS
                            color: Root.Theme.textSecondary
                        }
                        Text {
                            text: wifiPanel.connectedSecurity
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: Root.Theme.fontSizeXS
                            font.weight: Font.Medium
                            color: Root.Theme.textPrimary
                            Layout.alignment: Qt.AlignRight
                            elide: Text.ElideRight
                        }

                        // Row 2: Signal (dBm + %)
                        Text {
                            text: "Signal"
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: Root.Theme.fontSizeXS
                            color: Root.Theme.textSecondary
                        }
                        Text {
                            text: wifiPanel.connectedDbm + " (" + wifiPanel.connectedSignal + "%)"
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: Root.Theme.fontSizeXS
                            font.weight: Font.Medium
                            color: Root.Theme.textPrimary
                            Layout.alignment: Qt.AlignRight
                        }

                        // Row 3: IP Address
                        Text {
                            text: "IPv4"
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: Root.Theme.fontSizeXS
                            color: Root.Theme.textSecondary
                        }
                        Text {
                            text: wifiPanel.connectedIp
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: Root.Theme.fontSizeXS
                            font.weight: Font.Medium
                            color: Root.Theme.textPrimary
                            Layout.alignment: Qt.AlignRight
                        }

                        // Row 4: Subnet Range
                        Text {
                            text: "Subnet"
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: Root.Theme.fontSizeXS
                            color: Root.Theme.textSecondary
                        }
                        Text {
                            text: wifiPanel.connectedRange
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: Root.Theme.fontSizeXS
                            font.weight: Font.Medium
                            color: Root.Theme.textPrimary
                            Layout.alignment: Qt.AlignRight
                        }
                    }

                    // Divider
                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: Root.Theme.surfaceContainerHigh
                    }

                    // Live speed row
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        RowLayout {
                            spacing: 3
                            Text {
                                text: "󰁝"
                                font.family: Root.Theme.fontFamily
                                font.pixelSize: 11
                                color: Root.Theme.primary
                            }
                            Text {
                                text: wifiPanel.txRate
                                font.family: Root.Theme.fontFamily
                                font.pixelSize: Root.Theme.fontSizeXS
                                color: Root.Theme.textPrimary
                            }
                        }

                        Item { Layout.fillWidth: true }

                        RowLayout {
                            spacing: 3
                            Text {
                                text: "󰁅"
                                font.family: Root.Theme.fontFamily
                                font.pixelSize: 11
                                color: Root.Theme.connected
                            }
                            Text {
                                text: wifiPanel.rxRate
                                font.family: Root.Theme.fontFamily
                                font.pixelSize: Root.Theme.fontSizeXS
                                color: Root.Theme.textPrimary
                            }
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        wifiPanel.showHud = !wifiPanel.showHud;
                        if (wifiPanel.showHud) metricsProc.running = true;
                    }
                }
            }

            // ── Floating Telemetry HUD Card ───────────────────────
            Rectangle {
                id: telemetryHud
                visible: wifiPanel.showHud && wifiPanel.wifiEnabled
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.leftMargin: Root.Theme.paddingNormal
                anchors.rightMargin: 24
                anchors.bottomMargin: Root.Theme.paddingNormal
                height: 74
                radius: Root.Theme.radiusSmall
                color: Qt.rgba(Root.Theme.surfaceContainer.r, Root.Theme.surfaceContainer.g, Root.Theme.surfaceContainer.b, 0.95)
                border.width: 1
                border.color: Qt.rgba(Root.Theme.primary.r, Root.Theme.primary.g, Root.Theme.primary.b, 0.35)
                z: 40

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 16

                    // Ping Metric
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text {
                            text: "PING"
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: 9
                            font.weight: Font.DemiBold
                            color: Root.Theme.textSecondary
                        }
                        RowLayout {
                            spacing: 4
                            Text {
                                text: "󰉑"
                                font.family: Root.Theme.fontFamily
                                font.pixelSize: 14
                                color: Root.Theme.primary
                            }
                            Text {
                                text: wifiPanel.pingMs
                                font.family: Root.Theme.fontFamily
                                font.pixelSize: Root.Theme.fontSizeSmall
                                font.weight: Font.DemiBold
                                color: Root.Theme.textPrimary
                            }
                        }
                    }

                    // Divider
                    Rectangle { width: 1; height: 32; color: Root.Theme.surfaceContainerHigh }

                    // Bitrate / Link Speed Metric
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text {
                            text: "SPEED"
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: 9
                            font.weight: Font.DemiBold
                            color: Root.Theme.textSecondary
                        }
                        RowLayout {
                            spacing: 4
                            Text {
                                text: "󰓜"
                                font.family: Root.Theme.fontFamily
                                font.pixelSize: 14
                                color: Root.Theme.primary
                            }
                            Text {
                                text: wifiPanel.bitrateVal
                                font.family: Root.Theme.fontFamily
                                font.pixelSize: Root.Theme.fontSizeSmall
                                font.weight: Font.DemiBold
                                color: Root.Theme.textPrimary
                            }
                        }
                    }

                    // Divider
                    Rectangle { width: 1; height: 32; color: Root.Theme.surfaceContainerHigh }

                    // Transfer Rates (Up / Down)
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text {
                            text: "TRANSFER"
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: 9
                            font.weight: Font.DemiBold
                            color: Root.Theme.textSecondary
                        }
                        RowLayout {
                            spacing: 8
                            // Upload
                            RowLayout {
                                spacing: 2
                                Text {
                                    text: "󰁝"
                                    font.family: Root.Theme.fontFamily
                                    font.pixelSize: 13
                                    color: Root.Theme.primary
                                }
                                Text {
                                    text: wifiPanel.txRate
                                    font.family: Root.Theme.fontFamily
                                    font.pixelSize: Root.Theme.fontSizeSmall
                                    color: Root.Theme.textPrimary
                                }
                            }
                            // Download
                            RowLayout {
                                spacing: 2
                                Text {
                                    text: "󰁅"
                                    font.family: Root.Theme.fontFamily
                                    font.pixelSize: 13
                                    color: Root.Theme.connected
                                }
                                Text {
                                    text: wifiPanel.rxRate
                                    font.family: Root.Theme.fontFamily
                                    font.pixelSize: Root.Theme.fontSizeSmall
                                    color: Root.Theme.textPrimary
                                }
                            }
                        }
                    }

                    // Refresh Button inside HUD
                    Rectangle {
                        width: 34
                        height: 34
                        radius: 17
                        color: hudRefreshMA.containsMouse ? Root.Theme.surfaceContainerHigh : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: "󰑐"
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: 16
                            color: Root.Theme.primary
                        }

                        MouseArea {
                            id: hudRefreshMA
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: metricsProc.running = true
                        }
                    }
                }
            }
        }
    }

    // ── Password Input Modal Overlay ─────────────────────────────
    Rectangle {
        id: modalScrim
        anchors.fill: parent
        visible: wifiPanel.showPasswordModal
        color: Qt.rgba(0, 0, 0, 0.6)
        z: 100

        MouseArea {
            anchors.fill: parent
            onClicked: {
                wifiPanel.showPasswordModal = false;
                wifiPanel.targetSSID = "";
            }
        }

        Rectangle {
            id: modalDialog
            anchors.centerIn: parent
            width: Math.min(380, parent.width - 32)
            height: 180
            radius: Root.Theme.radiusLarge
            color: Root.Theme.surfaceContainer
            border.width: 1
            border.color: Root.Theme.primary

            MouseArea {
                anchors.fill: parent
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 12

                Text {
                    text: "Connect to " + wifiPanel.targetSSID
                    font.family: Root.Theme.fontFamily
                    font.pixelSize: Root.Theme.fontSizeNormal
                    font.weight: Font.DemiBold
                    color: Root.Theme.textPrimary
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 40
                    radius: Root.Theme.radiusSmall
                    color: Root.Theme.surfaceContainerHigh
                    border.width: modalPasswordField.activeFocus ? 1 : 0
                    border.color: Root.Theme.primary

                    TextField {
                        id: modalPasswordField
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        placeholderText: "Enter password"
                        placeholderTextColor: Qt.rgba(Root.Theme.textSecondary.r, Root.Theme.textSecondary.g, Root.Theme.textSecondary.b, 0.5)
                        color: Root.Theme.textPrimary
                        echoMode: TextInput.Password
                        font.family: Root.Theme.fontFamily
                        font.pixelSize: Root.Theme.fontSizeNormal
                        background: Item {}
                        onAccepted: {
                            wifiPanel.connectToNetwork(wifiPanel.targetSSID, text);
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Rectangle {
                        Layout.fillWidth: true
                        height: 36
                        radius: Root.Theme.radiusSmall
                        color: modalCancelMA.containsMouse ? Root.Theme.surfaceContainerHigh : "transparent"
                        border.width: 1
                        border.color: Root.Theme.surfaceContainerHigh

                        Text {
                            anchors.centerIn: parent
                            text: "Cancel"
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: Root.Theme.fontSizeNormal
                            color: Root.Theme.textSecondary
                        }

                        MouseArea {
                            id: modalCancelMA
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                wifiPanel.showPasswordModal = false;
                                wifiPanel.targetSSID = "";
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 36
                        radius: Root.Theme.radiusSmall
                        color: modalConnectMA.containsMouse ? Qt.lighter(Root.Theme.primary, 1.2) : Root.Theme.primary

                        Text {
                            anchors.centerIn: parent
                            text: wifiPanel.connecting ? "Connecting..." : "Connect"
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: Root.Theme.fontSizeNormal
                            font.weight: Font.DemiBold
                            color: Root.Theme.tileActiveText
                        }

                        MouseArea {
                            id: modalConnectMA
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                wifiPanel.connectToNetwork(wifiPanel.targetSSID, modalPasswordField.text);
                            }
                        }
                    }
                }
            }
        }
    }
}
