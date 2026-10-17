import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../.." as Root
import "../notifications" as Notifications

Scope {
    id: controlCenter

    property bool panelVisible: false
    property bool _showing: false
    property bool _panelOpen: false
    property string currentPage: "main"
    property bool notificationsExpanded: false

    property string wifiStatus: ""
    property bool wifiEnabled: true
    property bool btEnabled: true
    property int btConnectedCount: 0
    readonly property bool dndEnabled: Notifications.NotificationService.dndEnabled
    property bool caffeineEnabled: false
    property string powerProfile: "balanced"
    property bool nightLightEnabled: false
    property string shaderName: "Off"
    readonly property bool airplaneModeEnabled: !wifiEnabled && !btEnabled
    property bool brightnessAvailable: false
    property QtObject powerMenuRef: null

    onPanelVisibleChanged: {
        if (panelVisible) {
            _showing = true
            wifiStatusProc.running = true
            btStatusProc.running = true
            btConnectedProc.running = true
            brightnessCheckProc.running = true
            powerProfileProc.running = true
            shaderStatusProc.running = true
            caffeineCheckProc.running = true
            nightLightCheckProc.running = true
        } else {
            _panelOpen = false
            resetPageTimer.running = true
        }
    }

    Timer {
        id: resetPageTimer
        interval: 300
        repeat: false
        onTriggered: {
            controlCenter.currentPage = "main"
            controlCenter.notificationsExpanded = false
        }
    }

    function toggleNotifications() {
        if (!panelVisible) {
            currentPage = "main"
            notificationsExpanded = true
            panelVisible = true
        } else {
            if (notificationsExpanded) {
                panelVisible = false
            } else {
                currentPage = "main"
                notificationsExpanded = true
            }
        }
    }

    // ── Status processes ──────────────────────────────────────────

    // WiFi: nmcli -t -f TYPE,STATE,CONNECTION device
    Process {
        id: wifiStatusProc
        command: ["nmcli", "-t", "-f", "TYPE,STATE,CONNECTION", "device"]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.trim().split("\n");
                var found = false;
                for (var i = 0; i < lines.length; i++) {
                    // Some lines may have escaped colons; split on unescaped ":"
                    var parts = lines[i].split(":");
                    if (parts.length >= 1 && parts[0] === "wifi") {
                        found = true;
                        var state = parts.length >= 2 ? parts[1] : "";
                        var conn = parts.length >= 3 ? parts.slice(2).join(":") : "";
                        if (state === "connected" || state === "connecting (getting IP address)" || state.startsWith("connecting")) {
                            controlCenter.wifiEnabled = true;
                            controlCenter.wifiStatus = conn !== "" ? conn : "Connected";
                        } else if (state === "unavailable" || state === "unmanaged") {
                            controlCenter.wifiEnabled = false;
                            controlCenter.wifiStatus = "";
                        } else {
                            controlCenter.wifiEnabled = true;
                            controlCenter.wifiStatus = "";
                        }
                        break;
                    }
                }
                if (!found) {
                    controlCenter.wifiEnabled = false;
                    controlCenter.wifiStatus = "";
                }
            }
        }
    }

    // BT: bluetoothctl show
    Process {
        id: btStatusProc
        command: ["bluetoothctl", "show"]
        stdout: StdioCollector {
            onStreamFinished: {
                controlCenter.btEnabled = text.includes("Powered: yes");
            }
        }
    }

    // BT connected count: bluetoothctl devices Connected
    Process {
        id: btConnectedProc
        command: ["bluetoothctl", "devices", "Connected"]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.trim().split("\n");
                var count = 0;
                for (var i = 0; i < lines.length; i++) {
                    if (lines[i].trim().startsWith("Device"))
                        count++;
                }
                controlCenter.btConnectedCount = count;
            }
        }
    }

    // Brightness hardware detection
    Process {
        id: brightnessCheckProc
        command: ["brightnessctl", "--class=backlight", "-l"]
        stdout: StdioCollector {
            onStreamFinished: {
                controlCenter.brightnessAvailable = text.trim() !== ""
            }
        }
    }

    // ── Toggle actions ────────────────────────────────────────────

    // Reusable notify-send for quick toggles (Wi-Fi, BT, DND, Airplane, Caffeine)
    Process {
        id: toggleNotifyProc
    }

    function notifyChange(title, message) {
        toggleNotifyProc.command = ["/usr/bin/notify-send", title, message]
        toggleNotifyProc.running = true
    }

    Process {
        id: wifiToggleProc
        command: ["nmcli", "radio", "wifi", controlCenter.wifiEnabled ? "off" : "on"]
        onExited: wifiStatusProc.running = true
    }

    Process {
        id: btToggleProc
        command: ["bluetoothctl", "power", controlCenter.btEnabled ? "off" : "on"]
        onExited: btStatusProc.running = true
    }

    Process {
        id: airplaneWifiProc
        command: ["nmcli", "radio", "wifi", controlCenter.airplaneModeEnabled ? "on" : "off"]
        onExited: wifiStatusProc.running = true
    }

    Process {
        id: airplaneBtProc
        command: ["bluetoothctl", "power", controlCenter.airplaneModeEnabled ? "on" : "off"]
        onExited: btStatusProc.running = true
    }

    // Power profiles provided by power-profiles-daemon / GNOME.
    Process {
        id: powerProfileProc
        command: ["powerprofilesctl", "get"]
        stdout: StdioCollector {
            onStreamFinished: {
                var profile = text.trim()
                if (profile === "power-saver" || profile === "balanced" || profile === "performance")
                    controlCenter.powerProfile = profile
            }
        }
    }

    Process {
        id: setPowerProfileProc
        onExited: powerProfileProc.running = true
    }

    function powerProfileLabel() {
        if (powerProfile === "power-saver") return "Power Saver"
        if (powerProfile === "performance") return "Performance"
        return "Balanced"
    }

    function powerProfileIcon() {
        if (powerProfile === "power-saver") return "energy_savings_leaf"
        if (powerProfile === "performance") return "speed"
        return "tune"
    }

    function cyclePowerProfile() {
        var next = "balanced"
        if (powerProfile === "balanced") next = "performance"
        else if (powerProfile === "performance") next = "power-saver"
        setPowerProfileProc.command = ["powerprofilesctl", "set", next]
        setPowerProfileProc.running = true
        powerProfile = next
    }

    Process {
        id: caffeineCheckProc
        command: ["/bin/sh", "-c", "test -f ~/.cache/caffeine-mode || pgrep -f 'Caffeine mode'"]
        onExited: (code) => {
            controlCenter.caffeineEnabled = (code === 0)
        }
    }

    Process {
        id: nightLightCheckProc
        command: ["pgrep", "-x", "hyprsunset"]
        onExited: (code) => {
            controlCenter.nightLightEnabled = (code === 0)
        }
    }

    // Caffeine: keep the session awake while the toggle is active.
    Process {
        id: caffeineProc
        command: ["systemd-inhibit", "--what=idle:sleep", "--who=Quickshell",
                  "--why=Caffeine mode", "sleep", "infinity"]
        onExited: controlCenter.caffeineEnabled = false
    }

    Process {
        id: caffeineFileProc
    }

    Process {
        id: waybarSignalProc
    }

    function updateWaybar(sig) {
        waybarSignalProc.command = ["pkill", "-RTMIN+" + sig, "waybar"]
        waybarSignalProc.running = true
    }

    function toggleCaffeine() {
        if (controlCenter.caffeineEnabled) {
            caffeineProc.running = false
            controlCenter.caffeineEnabled = false
            caffeineFileProc.command = ["rm", "-f", "/home/zero/.cache/caffeine-mode"]
            caffeineFileProc.running = true
            notifyChange("Caffeine", "Caffeine mode disabled")
        } else {
            controlCenter.caffeineEnabled = true
            caffeineProc.running = true
            caffeineFileProc.command = ["touch", "/home/zero/.cache/caffeine-mode"]
            caffeineFileProc.running = true
            notifyChange("Caffeine", "Caffeine mode enabled")
        }
        updateWaybar(8)
    }

    // Night Light: toggle 100 % manual y sincrónico. Usa hyprsunset (nativo de
    // Hyprland) porque wlsunset falla en esta build ("gamma control failed").
    // hyprsunset aplica la temperatura de forma constante (sin modo automático
    // por sol). El estado del botón se controla en la UI; hyprsunset como efecto.
    Process {
        id: nightLightProc
        command: ["/bin/sh", "-c", "setsid nohup hyprsunset -t 4000 >/dev/null 2>&1 < /dev/null &"]
    }

    Process {
        id: nightLightStopProc
        command: ["/bin/sh", "-c", "pkill -x hyprsunset 2>/dev/null; true"]
    }

    Process {
        id: nightLightNotifyProc
    }

    function toggleNightLight() {
        if (controlCenter.nightLightEnabled) {
            // apagar
            nightLightStopProc.running = true
            controlCenter.nightLightEnabled = false
            nightLightNotifyProc.command = ["/usr/bin/notify-send", "Night light", "Light color filter disabled"]
        } else {
            // encender
            nightLightProc.running = true
            controlCenter.nightLightEnabled = true
            nightLightNotifyProc.command = ["/usr/bin/notify-send", "Night light", "Light color filter enabled (4000K)"]
        }
        nightLightNotifyProc.running = true
        updateWaybar(9)
    }

    Process {
        id: shaderStatusProc
        command: ["/home/zero/.config/hypr/scripts/filter", "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                var result = text.trim()
                if (result.indexOf("Filtro activo:") === 0)
                    controlCenter.shaderName = result.substring("Filtro activo:".length).trim()
                else
                    controlCenter.shaderName = "Off"
            }
        }
    }

    Process {
        id: shaderNextProc
        command: ["/home/zero/.config/hypr/scripts/filter", "next"]
        onExited: shaderStatusProc.running = true
    }

    Process {
        id: shaderToggleProc
        command: ["/home/zero/.config/hypr/scripts/filter", "toggle"]
        onExited: shaderStatusProc.running = true
    }

    function shaderLabel() {
        if (shaderName === "Sepia Vintage") return "Sepia"
        if (shaderName === "Blanco y Negro") return "B&W"
        if (shaderName === "Film Noir") return "Noir"
        if (shaderName === "Vívido") return "Vivid"
        if (shaderName === "Vintage") return "Vintage"
        return "Shader Off"
    }

    function cycleShader() {
        shaderNextProc.running = true
    }

    function toggleShader() {
        shaderToggleProc.running = true
    }



    // ── Theme persistence ────────────────────────────────────────
    Process {
        id: themeSaveProc
        command: ["/bin/sh", "-c", "echo '" + Root.Theme.currentTheme + "' > ~/.config/quickshell/current-theme"]
    }

    Process {
        id: themeApplyProc
        command: ["/home/zero/.config/quickshell/scripts/apply-theme.sh", Root.Theme.currentTheme]
    }

    Connections {
        target: Root.Theme
        function onCurrentThemeChanged() {
            themeSaveProc.running = true;
            if (Root.Theme.currentTheme === "matugen") {
                themeApplyProc.command = ["/home/zero/.config/themes/apply-matugen.sh"];
            } else {
                themeApplyProc.command = ["/home/zero/.config/quickshell/scripts/apply-theme.sh", Root.Theme.currentTheme];
            }
            themeApplyProc.running = true;
        }
    }

    // Poll status every 8s while panel is visible
    Timer {
        interval: 8000
        running: controlCenter.panelVisible
        repeat: true
        onTriggered: {
            wifiStatusProc.running = true
            btStatusProc.running = true
            btConnectedProc.running = true
            brightnessCheckProc.running = true
            shaderStatusProc.running = true
        }
    }

    Process {
        id: launchWallpaperProc
        command: ["quickshell", "ipc", "call", "launcher", "wallpaper"]
    }

    Process {
        id: launchThemeProc
        command: ["quickshell", "ipc", "call", "launcher", "theme"]
    }

    // ── IPC handlers ──────────────────────────────────────────────

    IpcHandler {
        target: "controlcenter"

        function toggle(): void { controlCenter.panelVisible = !controlCenter.panelVisible }
        function show(): void { controlCenter.panelVisible = true }
        function hide(): void { controlCenter.panelVisible = false }
        function openPage(page: string): void {
            if (page === "theme") {
                controlCenter.panelVisible = false
                launchThemeProc.running = true
                return
            }
            if (page === "wallpaper") {
                controlCenter.panelVisible = false
                launchWallpaperProc.running = true
                return
            }
            controlCenter.panelVisible = true
            controlCenter.currentPage = page
        }
        function toggleCaffeine(): void { controlCenter.toggleCaffeine() }
        function toggleNightLight(): void { controlCenter.toggleNightLight() }
        function toggleShader(): void { controlCenter.toggleShader() }
    }

    IpcHandler {
        target: "controlcenter_wallpaper"

        function toggle(): void {
            controlCenter.panelVisible = false
            launchWallpaperProc.running = true
        }
    }

    IpcHandler {
        target: "controlcenter_theme"

        function toggle(): void {
            controlCenter.panelVisible = false
            launchThemeProc.running = true
        }
    }

    IpcHandler {
        target: "notifications"

        function toggle(): void {
            controlCenter.toggleNotifications()
        }
        function show(): void {
            controlCenter.currentPage = "main"
            controlCenter.notificationsExpanded = true
            controlCenter.panelVisible = true
        }
        function hide(): void {
            controlCenter.notificationsExpanded = false
        }
    }

    // ── Overlay window / panel ────────────────────────────────────

    Loader {
        active: controlCenter._showing

        sourceComponent: PanelWindow {
            id: panelWindow
            visible: true

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            color: "transparent"
            exclusionMode: ExclusionMode.Ignore

            WlrLayershell.namespace: "quickshell:controlcenter"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            Component.onCompleted: openDelayTimer.start()

            Timer {
                id: openDelayTimer
                interval: 16
                repeat: false
                onTriggered: if (controlCenter.panelVisible) controlCenter._panelOpen = true
            }

            Shortcut {
                sequence: "Escape"
                onActivated: {
                    if (controlCenter.currentPage !== "main")
                        controlCenter.currentPage = "main"
                    else
                        controlCenter.panelVisible = false
                }
            }

            // click-outside close area
            MouseArea {
                anchors.fill: parent
                onClicked: controlCenter.panelVisible = false
            }

            // Clip region: top edge sits below the shelf.
            // The panel animates inside this region so it appears to
            // emerge from the shelf rather than sliding through it.
            Item {
                id: panelClip
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.topMargin: Root.Theme.shelfHeight
                clip: true

                Rectangle {
                    id: panel

                    width: Root.Theme.panelWidth
                    anchors.right: parent.right
                    anchors.rightMargin: Root.Theme.spacingSmall

                    // parent is now panelClip (height = screen - shelf).
                    // hidden  → y = -panel.height - spacing  (above clip, hidden)
                    // visible → y = spacing  (below shelf)

                    states: [
                        State {
                            name: "visible"
                            when: controlCenter._panelOpen
                            PropertyChanges {
                                target: panel
                                y: Root.Theme.spacingSmall
                            }
                        },
                        State {
                            name: "hidden"
                            when: !controlCenter._panelOpen
                            PropertyChanges {
                                target: panel
                                y: -panel.height - Root.Theme.spacingSmall
                            }
                        }
                    ]

                    transitions: [
                        Transition {
                            from: "hidden"
                            to: "visible"
                            NumberAnimation {
                                property: "y"
                                duration: Root.Theme.animDuration
                                easing.type: Easing.OutCubic
                            }
                        },
                        Transition {
                            from: "visible"
                            to: "hidden"
                            SequentialAnimation {
                                NumberAnimation {
                                    property: "y"
                                    duration: Root.Theme.animDuration
                                    easing.type: Easing.OutCubic
                                }
                                ScriptAction {
                                    script: controlCenter._showing = false
                                }
                            }
                        }
                    ]

                radius: 30
                // Translucent glass surface with Hyprland blur behind it
                color: Root.Theme.glassPanel
                border.width: 1.5
                border.color: Root.Theme.glassBorder
                clip: true

                // block click-through to overlay close area
                MouseArea {
                    anchors.fill: parent
                }

                height: pageContainer.height
                implicitHeight: pageContainer.height

                Item {
                    id: pageContainer
                    width: panel.width
                    height: mainPage.height

                    // MAIN PAGE
                    Item {
                        id: mainPage
                        width: pageContainer.width
                        height: mainContent.implicitHeight + Root.Theme.spacingLarge * 2
                        x: controlCenter.currentPage === "main" ? 0 : -pageContainer.width

                        Behavior on x {
                            NumberAnimation {
                                duration: Root.Theme.animDuration
                                easing.type: Easing.OutCubic
                            }
                        }

                        ColumnLayout {
                            id: mainContent
                            anchors {
                                left: parent.left
                                right: parent.right
                                top: parent.top
                                leftMargin: 20
                                rightMargin: 20
                                topMargin: 20
                            }
                            spacing: 18

                            // Header with user info + power button
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 12

                                Rectangle {
                                    Layout.preferredWidth: 46
                                    Layout.preferredHeight: 46
                                    radius: 23
                                    clip: true
                                    color: Root.Theme.surfaceContainerHigh

                                    Image {
                                        anchors.fill: parent
                                        source: "file:///home/zero/.face"
                                        fillMode: Image.PreserveAspectCrop
                                    }
                                }

                                ColumnLayout {
                                    spacing: 1

                                    Text {
                                        text: "zero"
                                        font.family: Root.Theme.fontFamily
                                        font.pixelSize: 16
                                        font.weight: Font.DemiBold
                                        color: Root.Theme.textPrimary
                                    }

                                    Text {
                                        text: "Welcome back"
                                        font.family: Root.Theme.fontFamily
                                        font.pixelSize: 13
                                        color: Root.Theme.textSecondary
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                Rectangle {
                                    Layout.preferredWidth: 40
                                    Layout.preferredHeight: 40
                                    radius: 20
                                    color: powerBtn.containsMouse ? Root.Theme.surfaceContainerHigh : "transparent"
                                    Behavior on color { ColorAnimation { duration: Root.Theme.animDurationFast } }

                                    Text {
                                        anchors.centerIn: parent
                                        text: "power_settings_new"
                                        font.family: Root.Theme.iconFont
                                        font.pixelSize: 22
                                        color: Root.Theme.textPrimary
                                    }

                                    MouseArea {
                                        id: powerBtn
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: { if (controlCenter.powerMenuRef) controlCenter.powerMenuRef.menuOpen = !controlCenter.powerMenuRef.menuOpen }
                                    }
                                }
                            }

                            // Middle Row: Analog Clock (left) + Quick Toggles (center) + Vertical Sliders (right)
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 20

                                AnalogClockWidget {
                                    Layout.preferredWidth: 180
                                    Layout.fillHeight: true
                                }

                                // Quick Toggles Grid (4 columns x 3 rows = 12 buttons)
                                GridLayout {
                                    columns: 4
                                    columnSpacing: 16
                                    rowSpacing: 14
                                    Layout.preferredWidth: 440
                                    Layout.fillWidth: true

                                    CircleToggle {
                                        Layout.fillWidth: true
                                        active: controlCenter.wifiEnabled
                                        icon: controlCenter.wifiEnabled ? "wifi" : "wifi_off"
                                        label: "Wi-Fi"
                                        hasDetail: true
                                        onClicked: {
                                            wifiToggleProc.running = true
                                            if (controlCenter.wifiEnabled)
                                                 notifyChange("Wi-Fi", "Wi-Fi turned off")
                                            else
                                                 notifyChange("Wi-Fi", "Wi-Fi turned on")
                                        }
                                        onDetailClicked: controlCenter.currentPage = "wifi"
                                    }

                                    CircleToggle {
                                        Layout.fillWidth: true
                                        active: controlCenter.btEnabled
                                        icon: controlCenter.btEnabled ? "bluetooth" : "bluetooth_disabled"
                                        label: "Bluetooth"
                                        hasDetail: true
                                        onClicked: {
                                            btToggleProc.running = true
                                            if (controlCenter.btEnabled)
                                                notifyChange("Bluetooth", "Bluetooth turned off")
                                            else
                                                notifyChange("Bluetooth", "Bluetooth turned on")
                                        }
                                        onDetailClicked: controlCenter.currentPage = "bluetooth"
                                    }

                                    CircleToggle {
                                        Layout.fillWidth: true
                                        active: controlCenter.dndEnabled
                                        icon: "do_not_disturb_on"
                                        label: "DND"
                                        onClicked: {
                                            var next = !Notifications.NotificationService.dndEnabled
                                            Notifications.NotificationService.dndEnabled = next
                                            if (next)
                                                notifyChange("Do Not Disturb", "Do Not Disturb enabled")
                                            else
                                                notifyChange("Do Not Disturb", "Do Not Disturb disabled")
                                        }
                                    }

                                    CircleToggle {
                                        Layout.fillWidth: true
                                        active: controlCenter.airplaneModeEnabled
                                        icon: "airplanemode_active"
                                        label: "Airplane"
                                        onClicked: {
                                            airplaneWifiProc.running = true
                                            airplaneBtProc.running = true
                                            if (controlCenter.airplaneModeEnabled)
                                                notifyChange("Airplane Mode", "Airplane mode disabled")
                                            else
                                                notifyChange("Airplane Mode", "Airplane mode enabled")
                                        }
                                    }

                                    CircleToggle {
                                        Layout.fillWidth: true
                                        active: controlCenter.caffeineEnabled
                                        icon: "coffee"
                                        label: "Caffeine"
                                        onClicked: controlCenter.toggleCaffeine()
                                    }

                                    CircleToggle {
                                        Layout.fillWidth: true
                                        active: controlCenter.powerProfile === "performance"
                                        icon: controlCenter.powerProfileIcon()
                                        label: controlCenter.powerProfileLabel()
                                        onClicked: controlCenter.cyclePowerProfile()
                                    }

                                    CircleToggle {
                                        Layout.fillWidth: true
                                        active: controlCenter.nightLightEnabled
                                        icon: controlCenter.nightLightEnabled ? "bedtime" : "wb_sunny"
                                        label: "Night Light"
                                        onClicked: controlCenter.toggleNightLight()
                                    }

                                    CircleToggle {
                                        Layout.fillWidth: true
                                        active: controlCenter.shaderName !== "Off"
                                        icon: "auto_fix_high"
                                        label: controlCenter.shaderLabel()
                                        hasDetail: true
                                        onClicked: controlCenter.toggleShader()
                                        onDetailClicked: controlCenter.cycleShader()
                                    }

                                    CircleToggle {
                                        Layout.fillWidth: true
                                        active: true
                                        icon: "volume_up"
                                        label: "Audio"
                                        hasDetail: true
                                        onClicked: controlCenter.currentPage = "audio"
                                        onDetailClicked: controlCenter.currentPage = "audio"
                                    }

                                    CircleToggle {
                                        Layout.fillWidth: true
                                        active: true
                                        icon: "palette"
                                        label: "Theme"
                                        onClicked: {
                                            controlCenter.panelVisible = false
                                            launchThemeProc.running = true
                                        }
                                    }

                                    CircleToggle {
                                        Layout.fillWidth: true
                                        active: true
                                        icon: "battery_full"
                                        label: "Energy"
                                        hasDetail: true
                                        onClicked: controlCenter.currentPage = "battery"
                                        onDetailClicked: controlCenter.currentPage = "battery"
                                    }

                                    CircleToggle {
                                        Layout.fillWidth: true
                                        active: true
                                        icon: "wallpaper"
                                        label: "Wallpaper"
                                        onClicked: {
                                            controlCenter.panelVisible = false
                                            launchWallpaperProc.running = true
                                        }
                                    }
                                }

                                // Vertical Sliders Card (Glassmorphic card matching AnalogClockWidget and WeatherWidget)
                                Rectangle {
                                    Layout.fillHeight: true
                                    Layout.preferredWidth: 168
                                    radius: 24
                                    color: Root.Theme.glassCard
                                    border.width: 1
                                    border.color: Root.Theme.glassCardBorder
                                    clip: true

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 14
                                        spacing: 14

                                        VolumeSection {
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            onOpenAudio: controlCenter.currentPage = "audio"
                                        }

                                        BrightnessSection {
                                            visible: controlCenter.brightnessAvailable
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                        }
                                    }
                                }
                            }

                            // Bottom Row: Music Player (left) + Weather Widget (right)
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 18

                                MusicSection {
                                    Layout.fillWidth: true
                                    panelVisible: controlCenter.panelVisible
                                    onOpenAppRequested: controlCenter.panelVisible = false
                                }

                                WeatherWidget {
                                    Layout.preferredWidth: 200
                                    Layout.fillHeight: true
                                }
                            }

                            // Notifications Collapsible Section
                            Rectangle {
                                id: notifCard
                                Layout.fillWidth: true
                                radius: 24
                                color: Root.Theme.glassCard
                                border.width: 1
                                border.color: Root.Theme.glassCardBorder
                                clip: true

                                implicitHeight: controlCenter.notificationsExpanded
                                    ? (notifHeaderRow.height + notifBody.implicitHeight)
                                    : notifHeaderRow.height

                                Behavior on implicitHeight {
                                    NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
                                }

                                Item {
                                    id: notifHeaderRow
                                    anchors.top: parent.top
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    height: 48

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 18
                                        anchors.rightMargin: 14
                                        spacing: 10

                                        Text {
                                            text: "󰂚"
                                            font.family: Root.Theme.fontFamily
                                            font.pixelSize: 18
                                            color: Notifications.NotificationService.count > 0 ? Root.Theme.primary : Root.Theme.textSecondary
                                        }

                                        Text {
                                            text: "Notifications • ( " + Notifications.NotificationService.count + " )"
                                            font.family: Root.Theme.fontFamily
                                            font.pixelSize: 14
                                            font.weight: Font.DemiBold
                                            color: Root.Theme.textPrimary
                                            Layout.fillWidth: true
                                        }

                                        // Botón Clear All
                                        Rectangle {
                                            visible: controlCenter.notificationsExpanded && Notifications.NotificationService.count > 0
                                            width: clearAllText.implicitWidth + 20
                                            height: 28
                                            radius: 14
                                            color: clearAllMouse.containsMouse ? Root.Theme.surfaceContainerHigh : "transparent"

                                            Behavior on color { ColorAnimation { duration: 100 } }

                                            Text {
                                                id: clearAllText
                                                anchors.centerIn: parent
                                                text: "Clear all"
                                                font.family: Root.Theme.fontFamily
                                                font.pixelSize: 12
                                                font.weight: Font.DemiBold
                                                color: Root.Theme.textSecondary
                                            }

                                            MouseArea {
                                                id: clearAllMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: Notifications.NotificationService.clearAll()
                                            }
                                        }

                                        // Botón pequeño de flecha hacia abajo
                                        Rectangle {
                                            width: 32
                                            height: 32
                                            radius: 16
                                            color: notifToggleMouse.containsMouse ? Root.Theme.surfaceContainerHigh : "transparent"

                                            Behavior on color { ColorAnimation { duration: 100 } }

                                            Text {
                                                anchors.centerIn: parent
                                                text: "󰅀"
                                                font.family: Root.Theme.fontFamily
                                                font.pixelSize: 18
                                                color: Root.Theme.textPrimary
                                                rotation: controlCenter.notificationsExpanded ? 180 : 0

                                                Behavior on rotation {
                                                    NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                                                }
                                            }

                                            MouseArea {
                                                id: notifToggleMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: controlCenter.notificationsExpanded = !controlCenter.notificationsExpanded
                                            }
                                        }
                                    }

                                    // Clic en la barra para alternar colapsado
                                    MouseArea {
                                        anchors.fill: parent
                                        anchors.rightMargin: 80
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: controlCenter.notificationsExpanded = !controlCenter.notificationsExpanded
                                    }
                                }

                                Item {
                                    id: notifBody
                                    anchors.top: notifHeaderRow.bottom
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    visible: controlCenter.notificationsExpanded
                                    opacity: controlCenter.notificationsExpanded ? 1.0 : 0.0

                                    Behavior on opacity {
                                        NumberAnimation { duration: 200 }
                                    }

                                    implicitHeight: {
                                        if (Notifications.NotificationService.count === 0) return 96;
                                        return Math.min(notifListView.contentHeight + 20, 260);
                                    }

                                    // Separador fino
                                    Rectangle {
                                        anchors.top: parent.top
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.leftMargin: 16
                                        anchors.rightMargin: 16
                                        height: 1
                                        color: Qt.rgba(255, 255, 255, 0.08)
                                    }

                                    // Estado vacío
                                    ColumnLayout {
                                        anchors.centerIn: parent
                                        spacing: 6
                                        visible: Notifications.NotificationService.count === 0

                                        Text {
                                            Layout.alignment: Qt.AlignHCenter
                                            text: "󰂚"
                                            font.family: Root.Theme.fontFamily
                                            font.pixelSize: 28
                                            color: Root.Theme.textSecondary
                                            opacity: 0.4
                                        }

                                        Text {
                                            Layout.alignment: Qt.AlignHCenter
                                            text: "No notifications"
                                            font.family: Root.Theme.fontFamily
                                            font.pixelSize: 13
                                            color: Root.Theme.textSecondary
                                            opacity: 0.6
                                        }
                                    }

                                    // Lista de notificaciones
                                    ListView {
                                        id: notifListView
                                        anchors.fill: parent
                                        anchors.topMargin: 8
                                        anchors.bottomMargin: 8
                                        clip: true
                                        visible: Notifications.NotificationService.count > 0
                                        spacing: 4
                                        boundsMovement: Flickable.StopAtBounds

                                        model: Notifications.NotificationService.notifications

                                        delegate: Notifications.NotificationItem {
                                            width: notifListView.width
                                            notifId: modelData.id
                                            appName: modelData.appName
                                            summary: modelData.summary
                                            body: modelData.body
                                            urgency: modelData.urgency
                                            timestamp: modelData.timestamp
                                            timeAgo: Notifications.NotificationService.relativeTime(modelData.timestamp)

                                            onDismissed: function(id) {
                                                Notifications.NotificationService.removeNotification(id);
                                            }
                                        }

                                        ScrollBar.vertical: ScrollBar {
                                            active: true
                                            policy: ScrollBar.AsNeeded
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // WIFI SUB-PAGE
                    WifiSection {
                        width: pageContainer.width
                        height: pageContainer.height
                        x: controlCenter.currentPage === "wifi" ? 0 : pageContainer.width

                        Behavior on x {
                            NumberAnimation {
                                duration: Root.Theme.animDuration
                                easing.type: Easing.OutCubic
                            }
                        }

                        onBack: {
                            controlCenter.currentPage = "main"
                            wifiStatusProc.running = true
                        }
                    }

                    // BLUETOOTH SUB-PAGE
                    BluetoothSection {
                        width: pageContainer.width
                        height: pageContainer.height
                        x: controlCenter.currentPage === "bluetooth" ? 0 : pageContainer.width

                        Behavior on x {
                            NumberAnimation {
                                duration: Root.Theme.animDuration
                                easing.type: Easing.OutCubic
                            }
                        }

                        onBack: {
                            controlCenter.currentPage = "main"
                            btStatusProc.running = true
                            btConnectedProc.running = true
                        }
                    }

                    // AUDIO SUB-PAGE
                    AudioSection {
                        width: pageContainer.width
                        height: pageContainer.height
                        x: controlCenter.currentPage === "audio" ? 0 : pageContainer.width

                        Behavior on x {
                            NumberAnimation {
                                duration: Root.Theme.animDuration
                                easing.type: Easing.OutCubic
                            }
                        }

                        onBack: {
                            controlCenter.currentPage = "main"
                        }
                    }




                    // BATTERY SUB-PAGE
                    BatterySection {
                        width: pageContainer.width
                        height: pageContainer.height
                        controlCenterRef: controlCenter
                        x: controlCenter.currentPage === "battery" ? 0 : pageContainer.width

                        Behavior on x {
                            NumberAnimation {
                                duration: Root.Theme.animDuration
                                easing.type: Easing.OutCubic
                            }
                        }

                        onBack: {
                            controlCenter.currentPage = "main"
                        }
                    }
                }
            }  // end Rectangle (panel)
            }  // end Item (panelClip)
        }
    }
}
