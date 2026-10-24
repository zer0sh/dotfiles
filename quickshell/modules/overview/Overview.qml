import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import "../.." as Root

Scope {
    id: overviewScope

    property bool visible: false
    property var overviewData: ({
        "monitor": { "width": 1920, "height": 1200, "aspect": 1.6 },
        "activeWorkspaceId": 1,
        "activeAddress": "",
        "wallpaper": "",
        "workspaces": [],
        "windows": [],
        "totalWindows": 0
    })

    // Selected navigation index for windows and workspaces
    property int selectedWindowIndex: 0
    property int selectedWorkspaceIndex: 0

    readonly property var allWindows: overviewData.windows || []
    readonly property var workspaces: overviewData.workspaces || []

    readonly property var selectedWindow: {
        if (allWindows.length > 0 && selectedWindowIndex >= 0 && selectedWindowIndex < allWindows.length) {
            return allWindows[selectedWindowIndex];
        }
        return null;
    }

    // Drag and Drop state
    property var draggingWindow: null
    property int dropTargetWorkspaceId: -1
    property real dragGlobalX: 0
    property real dragGlobalY: 0

    // ── Data Fetcher Process ──────────────────────────────────────────
    Process {
        id: dataFetcher
        command: ["/usr/bin/python3", "/home/zero/.config/quickshell/scripts/overview-data.py"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var parsed = JSON.parse(text);
                    overviewScope.overviewData = parsed;
                    if (overviewScope.selectedWindowIndex >= parsed.windows.length) {
                        overviewScope.selectedWindowIndex = Math.max(0, parsed.windows.length - 1);
                    }
                } catch (e) {
                    // silent fallback
                }
            }
        }
    }

    function refreshData(): void {
        dataFetcher.running = true;
    }

    // ── Hyprland Dispatchers ──────────────────────────────────────────
    Process {
        id: dispatchProcess
    }

    function runDispatch(args: list<string>): void {
        dispatchProcess.command = ["hyprctl", "dispatch"].concat(args);
        dispatchProcess.running = true;
    }

    function focusWindow(address: string, wsId: int): void {
        runDispatch(["focuswindow", "address:" + address]);
        overviewScope.visible = false;
    }

    function switchToWorkspace(wsId: int): void {
        runDispatch(["workspace", "" + wsId]);
        overviewScope.visible = false;
    }

    function moveWindowToWorkspace(address: string, targetWsId: int): void {
        runDispatch(["movetoworkspacesilent", "" + targetWsId + ",address:" + address]);
        refreshTimer.restart();
    }

    function closeWindow(address: string): void {
        runDispatch(["closewindow", "address:" + address]);
        refreshTimer.restart();
    }

    Timer {
        id: refreshTimer
        interval: 120
        repeat: false
        onTriggered: overviewScope.refreshData()
    }

    // ── Navigation Functions ──────────────────────────────────────────
    function nextWindow(): void {
        if (!visible) {
            overviewScope.visible = true;
            refreshData();
            selectedWindowIndex = (allWindows.length > 1) ? 1 : 0;
            return;
        }
        if (allWindows.length > 0) {
            selectedWindowIndex = (selectedWindowIndex + 1) % allWindows.length;
            if (selectedWindow) {
                selectedWorkspaceIndex = selectedWindow.workspace_id - 1;
            }
        } else {
            selectedWorkspaceIndex = (selectedWorkspaceIndex + 1) % 10;
        }
    }

    function prevWindow(): void {
        if (!visible) {
            overviewScope.visible = true;
            refreshData();
            selectedWindowIndex = Math.max(0, allWindows.length - 1);
            return;
        }
        if (allWindows.length > 0) {
            selectedWindowIndex = (selectedWindowIndex - 1 + allWindows.length) % allWindows.length;
            if (selectedWindow) {
                selectedWorkspaceIndex = selectedWindow.workspace_id - 1;
            }
        } else {
            selectedWorkspaceIndex = (selectedWorkspaceIndex - 1 + 10) % 10;
        }
    }

    function activateSelected(): void {
        if (selectedWindow) {
            focusWindow(selectedWindow.address, selectedWindow.workspace_id);
        } else {
            switchToWorkspace(selectedWorkspaceIndex + 1);
        }
    }

    onVisibleChanged: {
        if (visible) {
            refreshData();
            draggingWindow = null;
            dropTargetWorkspaceId = -1;
            selectedWindowIndex = 0;
            if (overviewData && overviewData.activeWorkspaceId) {
                selectedWorkspaceIndex = overviewData.activeWorkspaceId - 1;
            }
        }
    }

    // ── IPC Handler: `quickshell ipc call overview ...` ───────────────
    IpcHandler {
        target: "overview"
        function toggle(): void {
            if (overviewScope.visible) {
                overviewScope.visible = false;
            } else {
                overviewScope.visible = true;
            }
        }
        function open(): void {
            overviewScope.visible = true;
        }
        function close(): void {
            overviewScope.visible = false;
        }
        function next(): void {
            overviewScope.nextWindow();
        }
        function prev(): void {
            overviewScope.prevWindow();
        }
    }

    // ── Lazy Overlay Window ──────────────────────────────────────────
    Loader {
        active: overviewScope.visible

        sourceComponent: PanelWindow {
            id: windowOverlay
            visible: true
            anchors.top: true
            anchors.bottom: true
            anchors.left: true
            anchors.right: true
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "quickshell:overview"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            // ── Backdrop Dimmer & Click-to-Close ─────────────────────
            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(0.04, 0.05, 0.08, 0.75)

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (!overviewScope.draggingWindow) {
                            overviewScope.visible = false;
                        }
                    }
                }
            }

            // ── Main UI Layout ───────────────────────────────────────
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 24
                spacing: 16

                // ── Top Header Bar ───────────────────────────────────
                RowLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 16

                    Rectangle {
                        height: 38
                        radius: 19
                        color: Qt.rgba(Root.Theme.surfaceContainer.r, Root.Theme.surfaceContainer.g, Root.Theme.surfaceContainer.b, 0.90)
                        border.color: Root.Theme.panelBorder
                        border.width: 1
                        Layout.alignment: Qt.AlignHCenter
                        implicitWidth: headerRow.implicitWidth + 36

                        RowLayout {
                            id: headerRow
                            anchors.centerIn: parent
                            spacing: 12

                            Text {
                                text: "󰕰"
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 18
                                color: Root.Theme.primary
                            }

                            Text {
                                text: "Hyprland Workspaces"
                                font.family: Root.Theme.fontFamily
                                font.pixelSize: 14
                                font.weight: Font.DemiBold
                                color: Root.Theme.textPrimary
                            }

                            Rectangle {
                                width: 4; height: 4; radius: 2
                                color: Root.Theme.textSecondary
                            }

                            Text {
                                text: overviewScope.allWindows.length + (overviewScope.allWindows.length === 1 ? " open window" : " open windows") + " across 10 workspaces"
                                font.family: Root.Theme.fontFamily
                                font.pixelSize: 12
                                color: Root.Theme.textSecondary
                            }
                        }
                    }
                }

                // ── Center Workspaces 2x5 Grid ───────────────────────
                Item {
                    id: gridContainer
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    // 5 columns, 2 rows (Escritorios 1..5 arriba, 6..10 abajo)
                    Grid {
                        id: wsGrid
                        anchors.centerIn: parent
                        columns: 5
                        rows: 2
                        spacing: 16

                        // Dynamically calculate card dimensions based on container
                        readonly property real availableW: gridContainer.width - (columns - 1) * spacing
                        readonly property real availableH: gridContainer.height - (rows - 1) * spacing
                        readonly property real monAspect: overviewScope.overviewData.monitor ? overviewScope.overviewData.monitor.aspect : 1.6

                        // Max width and height to fit 5x2 comfortably
                        readonly property int cardW: Math.min(350, Math.floor(availableW / columns))
                        readonly property int cardCanvasH: Math.min(220, Math.floor(cardW / monAspect))
                        readonly property int cardTotalH: cardCanvasH

                        Repeater {
                            model: overviewScope.workspaces

                            delegate: Item {
                                id: wsCardDelegate
                                required property var modelData
                                required property int index

                                width: wsGrid.cardW
                                height: wsGrid.cardTotalH

                                readonly property bool isCurrentWs: modelData.is_active || false
                                readonly property bool isWsSelected: overviewScope.selectedWorkspaceIndex === index
                                readonly property bool isDropTarget: overviewScope.dropTargetWorkspaceId === modelData.id
                                readonly property bool hasSelectedWindow: {
                                    if (!overviewScope.selectedWindow) return false;
                                    return overviewScope.selectedWindow.workspace_id === modelData.id;
                                }

                                // ── Desktop Canvas Card ──────────────
                                Rectangle {
                                    id: wsCanvas
                                    anchors.fill: parent
                                    radius: 12
                                    clip: true
                                    color: Qt.rgba(Root.Theme.surfaceContainer.r, Root.Theme.surfaceContainer.g, Root.Theme.surfaceContainer.b, 0.65)
                                    border.color: wsCardDelegate.isDropTarget
                                        ? Root.Theme.connected
                                        : (wsCardDelegate.hasSelectedWindow || wsCardDelegate.isWsSelected
                                            ? Root.Theme.primary
                                            : (wsCardDelegate.isCurrentWs ? Qt.rgba(Root.Theme.primary.r, Root.Theme.primary.g, Root.Theme.primary.b, 0.6) : Root.Theme.panelBorder))
                                    border.width: (wsCardDelegate.isDropTarget || wsCardDelegate.hasSelectedWindow || wsCardDelegate.isWsSelected) ? 2 : 1

                                    scale: wsCardDelegate.isDropTarget ? 1.02 : 1.0
                                    Behavior on scale { NumberAnimation { duration: 100 } }
                                    Behavior on border.color { ColorAnimation { duration: 120 } }

                                    // Miniature Wallpaper
                                    Image {
                                        anchors.fill: parent
                                        source: overviewScope.overviewData.wallpaper ? ("file://" + overviewScope.overviewData.wallpaper) : ""
                                        fillMode: Image.PreserveAspectCrop
                                        asynchronous: true
                                        opacity: 0.35
                                    }

                                    // Workspace Number (top-right, double size, no circle)
                                    Text {
                                        anchors.top: parent.top
                                        anchors.right: parent.right
                                        anchors.topMargin: 8
                                        anchors.rightMargin: 12
                                        text: modelData.name
                                        font.family: Root.Theme.fontFamily
                                        font.pixelSize: 22
                                        font.weight: Font.Bold
                                        color: (wsCardDelegate.hasSelectedWindow || wsCardDelegate.isWsSelected)
                                            ? Root.Theme.primary
                                            : (wsCardDelegate.isCurrentWs
                                                ? Root.Theme.primary
                                                : Qt.rgba(1, 1, 1, 0.65))
                                        style: Text.Outline
                                        styleColor: Qt.rgba(0, 0, 0, 0.5)
                                        z: 10
                                    }

                                        // Empty state message
                                        ColumnLayout {
                                            anchors.centerIn: parent
                                            visible: (!modelData.windows || modelData.windows.length === 0)
                                            spacing: 4

                                            Text {
                                                Layout.alignment: Qt.AlignHCenter
                                                text: "󰇄"
                                                font.family: "Material Symbols Rounded"
                                                font.pixelSize: 22
                                                color: Qt.rgba(Root.Theme.textSecondary.r, Root.Theme.textSecondary.g, Root.Theme.textSecondary.b, 0.35)
                                            }

                                            Text {
                                                Layout.alignment: Qt.AlignHCenter
                                                text: wsCardDelegate.isDropTarget ? "Drop here" : "Empty"
                                                font.family: Root.Theme.fontFamily
                                                font.pixelSize: 11
                                                color: wsCardDelegate.isDropTarget ? Root.Theme.connected : Qt.rgba(Root.Theme.textSecondary.r, Root.Theme.textSecondary.g, Root.Theme.textSecondary.b, 0.5)
                                            }
                                        }

                                        // Canvas click to switch workspace
                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: {
                                                if (!overviewScope.draggingWindow) {
                                                    overviewScope.switchToWorkspace(modelData.id);
                                                }
                                            }
                                        }

                                        // Check if global drag is over this canvas
                                        Timer {
                                            interval: 30
                                            running: overviewScope.draggingWindow !== null
                                            repeat: true
                                            onTriggered: {
                                                var pt = wsCanvas.mapFromItem(windowOverlay, overviewScope.dragGlobalX, overviewScope.dragGlobalY);
                                                if (pt.x >= 0 && pt.x <= wsCanvas.width && pt.y >= 0 && pt.y <= wsCanvas.height) {
                                                    overviewScope.dropTargetWorkspaceId = modelData.id;
                                                }
                                            }
                                        }

                                        // ── Windows inside this Workspace ──
                                        Repeater {
                                            model: modelData.windows

                                            delegate: Item {
                                                id: winItem
                                                required property var modelData
                                                required property int index

                                                // Real proportional layout
                                                x: Math.round(modelData.norm_x * wsCanvas.width)
                                                y: Math.round(modelData.norm_y * wsCanvas.height)
                                                width: Math.max(48, Math.round(modelData.norm_w * wsCanvas.width))
                                                height: Math.max(32, Math.round(modelData.norm_h * wsCanvas.height))

                                                readonly property bool isWinSelected: {
                                                    return overviewScope.selectedWindow && (overviewScope.selectedWindow.address === modelData.address);
                                                }
                                                readonly property bool isBeingDragged: {
                                                    return overviewScope.draggingWindow && (overviewScope.draggingWindow.address === modelData.address);
                                                }

                                                opacity: isBeingDragged ? 0.25 : 1.0

                                                Rectangle {
                                                    id: winBox
                                                    anchors.fill: parent
                                                    radius: 6
                                                    color: winItem.isWinSelected
                                                        ? Qt.rgba(Root.Theme.surfaceContainerHigh.r, Root.Theme.surfaceContainerHigh.g, Root.Theme.surfaceContainerHigh.b, 0.95)
                                                        : (winMouseArea.containsMouse
                                                            ? Qt.rgba(Root.Theme.surfaceContainerHigh.r, Root.Theme.surfaceContainerHigh.g, Root.Theme.surfaceContainerHigh.b, 0.9)
                                                            : Qt.rgba(Root.Theme.surface.r, Root.Theme.surface.g, Root.Theme.surface.b, 0.88))

                                                    border.color: winItem.isWinSelected
                                                        ? Root.Theme.primary
                                                        : (winMouseArea.containsMouse
                                                            ? Qt.rgba(Root.Theme.primary.r, Root.Theme.primary.g, Root.Theme.primary.b, 0.7)
                                                            : Root.Theme.panelBorder)
                                                    border.width: winItem.isWinSelected ? 2 : 1

                                                    // Mini Window Titlebar
                                                    Rectangle {
                                                        id: miniTitlebar
                                                        anchors.top: parent.top
                                                        anchors.left: parent.left
                                                        anchors.right: parent.right
                                                        height: 18
                                                        radius: 6
                                                        color: Qt.rgba(0, 0, 0, 0.25)

                                                        Rectangle {
                                                            anchors.bottom: parent.bottom
                                                            anchors.left: parent.left
                                                            anchors.right: parent.right
                                                            height: 6
                                                            color: miniTitlebar.color
                                                        }

                                                        RowLayout {
                                                            anchors.fill: parent
                                                            anchors.leftMargin: 4
                                                            anchors.rightMargin: 4
                                                            spacing: 3

                                                            IconImage {
                                                                Layout.preferredWidth: 11
                                                                Layout.preferredHeight: 11
                                                                source: Quickshell.iconPath(modelData.icon, "application-x-executable")
                                                                mipmap: true
                                                            }

                                                            Text {
                                                                Layout.fillWidth: true
                                                                text: modelData.appName
                                                                font.family: Root.Theme.fontFamily
                                                                font.pixelSize: 8
                                                                font.weight: Font.Bold
                                                                color: Root.Theme.textPrimary
                                                                elide: Text.ElideRight
                                                            }

                                                            // Close Button (visible on hover)
                                                            Rectangle {
                                                                Layout.preferredWidth: 12
                                                                Layout.preferredHeight: 12
                                                                radius: 6
                                                                color: closeMouseArea.containsMouse ? "#EF4444" : "transparent"
                                                                visible: winMouseArea.containsMouse || winItem.isWinSelected

                                                                Text {
                                                                    anchors.centerIn: parent
                                                                    text: "✕"
                                                                    font.pixelSize: 8
                                                                    color: closeMouseArea.containsMouse ? "#ffffff" : Root.Theme.textSecondary
                                                                }

                                                                MouseArea {
                                                                    id: closeMouseArea
                                                                    anchors.fill: parent
                                                                    hoverEnabled: true
                                                                    cursorShape: Qt.PointingHandCursor
                                                                    onClicked: {
                                                                        overviewScope.closeWindow(modelData.address);
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }

                                                    // Center Icon and Title preview
                                                    ColumnLayout {
                                                        anchors.centerIn: parent
                                                        anchors.topMargin: 12
                                                        spacing: 2

                                                        IconImage {
                                                            Layout.alignment: Qt.AlignHCenter
                                                            Layout.preferredWidth: Math.min(26, Math.max(16, Math.round(winItem.height * 0.4)))
                                                            Layout.preferredHeight: Layout.preferredWidth
                                                            source: Quickshell.iconPath(modelData.icon, "application-x-executable")
                                                            mipmap: true
                                                        }

                                                        Text {
                                                            Layout.alignment: Qt.AlignHCenter
                                                            Layout.maximumWidth: winBox.width - 8
                                                            visible: winBox.height > 50 && winBox.width > 60
                                                            text: modelData.title
                                                            font.family: Root.Theme.fontFamily
                                                            font.pixelSize: 8
                                                            color: Root.Theme.textSecondary
                                                            elide: Text.ElideRight
                                                            horizontalAlignment: Text.AlignHCenter
                                                        }
                                                    }

                                                    // Mouse drag & click
                                                    MouseArea {
                                                        id: winMouseArea
                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                        cursorShape: overviewScope.draggingWindow ? Qt.ClosedHandCursor : Qt.PointingHandCursor
                                                        drag.filterChildren: true

                                                        property real startX: 0
                                                        property real startY: 0
                                                        property bool isDragging: false

                                                        onPressed: (mouse) => {
                                                            startX = mouse.x;
                                                            startY = mouse.y;
                                                            isDragging = false;
                                                        }

                                                        onPositionChanged: (mouse) => {
                                                            if (pressed) {
                                                                var dist = Math.hypot(mouse.x - startX, mouse.y - startY);
                                                                if (dist > 8 && !isDragging) {
                                                                isDragging = true;
                                                                overviewScope.draggingWindow = modelData;
                                                                }
                                                                if (isDragging) {
                                                                var p = winItem.mapToItem(windowOverlay, mouse.x, mouse.y);
                                                                overviewScope.dragGlobalX = p.x;
                                                                overviewScope.dragGlobalY = p.y;
                                                                }
                                                            }
                                                        }

                                                        onReleased: {
                                                            if (isDragging && overviewScope.draggingWindow) {
                                                                if (overviewScope.dropTargetWorkspaceId > 0 && overviewScope.dropTargetWorkspaceId !== modelData.workspace_id) {
                                                                overviewScope.moveWindowToWorkspace(modelData.address, overviewScope.dropTargetWorkspaceId);
                                                                }
                                                                overviewScope.draggingWindow = null;
                                                                overviewScope.dropTargetWorkspaceId = -1;
                                                                isDragging = false;
                                                            } else {
                                                                overviewScope.focusWindow(modelData.address, modelData.workspace_id);
                                                            }
                                                        }

                                                        onEntered: {
                                                            for (var i = 0; i < overviewScope.allWindows.length; i++) {
                                                                if (overviewScope.allWindows[i].address === modelData.address) {
                                                                overviewScope.selectedWindowIndex = i;
                                                                break;
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                // ── Bottom Info & Navigation Bar ─────────────────────
                RowLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 16

                    Rectangle {
                        height: 48
                        radius: 24
                        color: Qt.rgba(Root.Theme.panelBg.r, Root.Theme.panelBg.g, Root.Theme.panelBg.b, 0.94)
                        border.color: Root.Theme.panelBorder
                        border.width: 1
                        Layout.alignment: Qt.AlignHCenter
                        implicitWidth: bottomRow.implicitWidth + 36

                        RowLayout {
                            id: bottomRow
                            anchors.centerIn: parent
                            spacing: 16

                            // Selected App Icon & Info
                            RowLayout {
                                spacing: 10
                                visible: overviewScope.selectedWindow !== null

                                IconImage {
                                    Layout.preferredWidth: 22
                                    Layout.preferredHeight: 22
                                    source: overviewScope.selectedWindow ? Quickshell.iconPath(overviewScope.selectedWindow.icon, "application-x-executable") : ""
                                    mipmap: true
                                }

                                ColumnLayout {
                                    spacing: 1
                                    Text {
                                        text: overviewScope.selectedWindow ? overviewScope.selectedWindow.appName : ""
                                        font.family: Root.Theme.fontFamily
                                        font.pixelSize: 11
                                        font.weight: Font.Bold
                                        color: Root.Theme.textPrimary
                                    }
                                    Text {
                                        Layout.maximumWidth: 260
                                        text: overviewScope.selectedWindow ? overviewScope.selectedWindow.title : ""
                                        font.family: Root.Theme.fontFamily
                                        font.pixelSize: 9
                                        color: Root.Theme.textSecondary
                                        elide: Text.ElideRight
                                    }
                                }
                            }

                            Rectangle {
                                width: 1; height: 20
                                color: Root.Theme.panelBorder
                                visible: overviewScope.selectedWindow !== null
                            }

                            // Hints pills
                            RowLayout {
                                spacing: 10

                                RowLayout {
                                    spacing: 4
                                    Rectangle {
                                        height: 20; radius: 4
                                        color: Qt.rgba(Root.Theme.surfaceContainerHigh.r, Root.Theme.surfaceContainerHigh.g, Root.Theme.surfaceContainerHigh.b, 0.8)
                                        implicitWidth: 36
                                        Text { anchors.centerIn: parent; text: "Tab"; font.pixelSize: 10; font.weight: Font.Bold; color: Root.Theme.primary }
                                    }
                                    Text { text: "Cycle"; font.pixelSize: 10; color: Root.Theme.textSecondary }
                                }

                                RowLayout {
                                    spacing: 4
                                    Rectangle {
                                        height: 20; radius: 4
                                        color: Qt.rgba(Root.Theme.surfaceContainerHigh.r, Root.Theme.surfaceContainerHigh.g, Root.Theme.surfaceContainerHigh.b, 0.8)
                                        implicitWidth: 46
                                        Text { anchors.centerIn: parent; text: "Arrows"; font.pixelSize: 9; font.weight: Font.Bold; color: Root.Theme.primary }
                                    }
                                    Text { text: "Grid"; font.pixelSize: 10; color: Root.Theme.textSecondary }
                                }

                                RowLayout {
                                    spacing: 4
                                    Rectangle {
                                        height: 20; radius: 4
                                        color: Qt.rgba(Root.Theme.surfaceContainerHigh.r, Root.Theme.surfaceContainerHigh.g, Root.Theme.surfaceContainerHigh.b, 0.8)
                                        implicitWidth: 40
                                        Text { anchors.centerIn: parent; text: "1 - 10"; font.pixelSize: 10; font.weight: Font.Bold; color: Root.Theme.primary }
                                    }
                                    Text { text: "Workspace"; font.pixelSize: 10; color: Root.Theme.textSecondary }
                                }

                                RowLayout {
                                    spacing: 4
                                    Rectangle {
                                        height: 20; radius: 4
                                        color: Qt.rgba(Root.Theme.surfaceContainerHigh.r, Root.Theme.surfaceContainerHigh.g, Root.Theme.surfaceContainerHigh.b, 0.8)
                                        implicitWidth: 38
                                        Text { anchors.centerIn: parent; text: "Enter"; font.pixelSize: 10; font.weight: Font.Bold; color: Root.Theme.primary }
                                    }
                                    Text { text: "Select"; font.pixelSize: 10; color: Root.Theme.textSecondary }
                                }

                                RowLayout {
                                    spacing: 4
                                    Rectangle {
                                        height: 20; radius: 4
                                        color: Qt.rgba(Root.Theme.surfaceContainerHigh.r, Root.Theme.surfaceContainerHigh.g, Root.Theme.surfaceContainerHigh.b, 0.8)
                                        implicitWidth: 30
                                        Text { anchors.centerIn: parent; text: "Esc"; font.pixelSize: 10; font.weight: Font.Bold; color: Root.Theme.textSecondary }
                                    }
                                    Text { text: "Close"; font.pixelSize: 10; color: Root.Theme.textSecondary }
                                }
                            }
                        }
                    }
                }
            }

            // ── Floating Drag Proxy (Follows Mouse Cursor) ───────────
            Rectangle {
                visible: overviewScope.draggingWindow !== null
                x: overviewScope.dragGlobalX - width / 2
                y: overviewScope.dragGlobalY - height / 2
                width: 135
                height: 44
                radius: 12
                color: Qt.rgba(Root.Theme.surfaceContainerHigh.r, Root.Theme.surfaceContainerHigh.g, Root.Theme.surfaceContainerHigh.b, 0.95)
                border.color: Root.Theme.primary
                border.width: 2
                z: 9999

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 8

                    IconImage {
                        Layout.preferredWidth: 22
                        Layout.preferredHeight: 22
                        source: overviewScope.draggingWindow ? Quickshell.iconPath(overviewScope.draggingWindow.icon, "application-x-executable") : ""
                        mipmap: true
                    }

                    ColumnLayout {
                        spacing: 1
                        Text {
                            text: overviewScope.draggingWindow ? overviewScope.draggingWindow.appName : ""
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: 10
                            font.weight: Font.Bold
                            color: Root.Theme.textPrimary
                        }
                        Text {
                            text: overviewScope.dropTargetWorkspaceId > 0 ? ("Move to WS " + overviewScope.dropTargetWorkspaceId) : "Dragging..."
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: 9
                            color: overviewScope.dropTargetWorkspaceId > 0 ? Root.Theme.connected : Root.Theme.textSecondary
                        }
                    }
                }
            }

            // ── Keyboard Navigation Handler ──────────────────────────
            Item {
                focus: true
                Keys.onPressed: (event) => {
                    if (event.key === Qt.Key_Escape) {
                        overviewScope.visible = false;
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Tab) {
                        if (event.modifiers & Qt.ShiftModifier) {
                            overviewScope.prevWindow();
                        } else {
                            overviewScope.nextWindow();
                        }
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Backtab) {
                        overviewScope.prevWindow();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Right) {
                        overviewScope.selectedWorkspaceIndex = (overviewScope.selectedWorkspaceIndex + 1) % 10;
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Left) {
                        overviewScope.selectedWorkspaceIndex = (overviewScope.selectedWorkspaceIndex - 1 + 10) % 10;
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Down) {
                        // Spatial grid jump: move to row below (+5)
                        overviewScope.selectedWorkspaceIndex = (overviewScope.selectedWorkspaceIndex + 5) % 10;
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Up) {
                        // Spatial grid jump: move to row above (-5)
                        overviewScope.selectedWorkspaceIndex = (overviewScope.selectedWorkspaceIndex - 5 + 10) % 10;
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                        overviewScope.activateSelected();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Delete || event.key === Qt.Key_Backspace) {
                        if (overviewScope.selectedWindow) {
                            overviewScope.closeWindow(overviewScope.selectedWindow.address);
                        }
                        event.accepted = true;
                    } else if (event.key >= Qt.Key_1 && event.key <= Qt.Key_9) {
                        var targetWs = event.key - Qt.Key_0;
                        overviewScope.switchToWorkspace(targetWs);
                        event.accepted = true;
                    } else if (event.key === Qt.Key_0) {
                        overviewScope.switchToWorkspace(10);
                        event.accepted = true;
                    }
                }
            }
        }
    }
}
