import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Shapes
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../.." as Root
import "." as Settings

Scope {
    id: settingsRoot

    property bool visible: false
    property bool _showing: false
    property bool _panelOpen: false
    property string currentSection: "profile"

    readonly property var sections: [
        { id: "profile", label: "Profile", icon: "person", desc: "Account and avatar" },
        { id: "theme", label: "Theme & Style", icon: "palette", desc: "Colors, Matugen and presets" },
        { id: "lockscreen", label: "Lock Screen", icon: "lock", desc: "Screen lock timeout and hypridle" },
        { id: "weather", label: "Weather & Location", icon: "cloud", desc: "Forecast location and custom label" },
        { id: "about", label: "About", icon: "info", desc: "System specifications" }
    ]

    onVisibleChanged: {
        if (visible) {
            Settings.SystemService.refresh();
            Settings.LockService.refresh();
            _showing = true;
        } else {
            _panelOpen = false;
        }
    }

    function toggle() {
        visible = !visible;
    }

    Loader {
        active: settingsRoot._showing

        sourceComponent: PanelWindow {
            id: settingsWindow
            visible: true

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "quickshell:settings"
            WlrLayershell.layer: Settings.ProfileService.isUpdatingAvatar ? WlrLayer.Bottom : WlrLayer.Overlay
            WlrLayershell.keyboardFocus: Settings.ProfileService.isUpdatingAvatar ? WlrKeyboardFocus.None : WlrKeyboardFocus.Exclusive

            Shortcut {
                sequence: "Escape"
                enabled: !Settings.ProfileService.isUpdatingAvatar
                onActivated: edgePanelWrapper.close()
            }

            Root.EdgePanel {
                id: edgePanelWrapper
                edge: "top"
                panelWidth: Math.min(940, settingsWindow.width - 80)
                panelHeight: Math.min(640, settingsWindow.height - Root.Theme.shelfHeight - 40)
                shoulderRadius: 28
                showDim: !Settings.ProfileService.isUpdatingAvatar
                closeOnClickOutside: !Settings.ProfileService.isUpdatingAvatar
                onCloseRequested: edgePanelWrapper.close()
                onClosed: {
                    settingsRoot.visible = false;
                    settingsRoot._panelOpen = false;
                    settingsRoot._showing = false;
                }

                // Contenedor principal de contenidos
                Item {
                    id: dialogBox
                    anchors.fill: parent
                    anchors.leftMargin: 28
                    anchors.rightMargin: 28
                    clip: true

                    // Prevenir cierre accidental al interactuar dentro
                    MouseArea {
                        anchors.fill: parent
                    }

                    // Botón de Cerrar estilo Material You (Flotante)
                    Rectangle {
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: 18
                        z: 10
                        width: 36
                        height: 36
                        radius: 18
                        color: closeArea.containsMouse ? Root.Theme.surfaceContainerHigh : Qt.rgba(Root.Theme.surfaceContainer.r, Root.Theme.surfaceContainer.g, Root.Theme.surfaceContainer.b, 0.6)
                        Behavior on color { ColorAnimation { duration: Root.Theme.animDurationFast } }

                        Text {
                            anchors.centerIn: parent
                            text: "close"
                            font.family: Root.Theme.iconFont
                            font.pixelSize: 18
                            color: closeArea.containsMouse ? Root.Theme.textPrimary : Root.Theme.textSecondary
                        }

                        MouseArea {
                            id: closeArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: edgePanelWrapper.close()
                        }
                    }

                // ── Layout Principal (Sidebar + Content) ───────────
                RowLayout {
                    anchors.fill: parent
                    spacing: 0

                    // Sidebar / Navigation Rail
                    Rectangle {
                        Layout.preferredWidth: 230
                        Layout.fillHeight: true
                        color: Qt.rgba(Root.Theme.surfaceContainer.r, Root.Theme.surfaceContainer.g, Root.Theme.surfaceContainer.b, 0.4)

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 18
                            spacing: 8

                            // Encabezado de Navegación
                            RowLayout {
                                Layout.leftMargin: 8
                                Layout.topMargin: 4
                                Layout.bottomMargin: 12
                                spacing: 10

                                Text {
                                    text: "settings"
                                    font.family: Root.Theme.iconFont
                                    font.pixelSize: 22
                                    color: Root.Theme.primary
                                }

                                Text {
                                    text: "Settings"
                                    font.family: Root.Theme.fontFamily
                                    font.pixelSize: 18
                                    font.weight: Font.Bold
                                    color: Root.Theme.textPrimary
                                }
                            }

                                Repeater {
                                    model: settingsRoot.sections

                                    delegate: Rectangle {
                                        id: navItem
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 52
                                        radius: 26

                                        readonly property bool isSelected: settingsRoot.currentSection === modelData.id
                                        readonly property bool isHovered: navMouse.containsMouse

                                        color: isSelected
                                            ? Qt.rgba(Root.Theme.primary.r, Root.Theme.primary.g, Root.Theme.primary.b, 0.16)
                                            : (isHovered ? Root.Theme.surfaceContainerHigh : "transparent")

                                        Behavior on color { ColorAnimation { duration: Root.Theme.animDurationFast } }

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 16
                                            anchors.rightMargin: 16
                                            spacing: 12

                                            Text {
                                                text: modelData.icon
                                                font.family: Root.Theme.iconFont
                                                font.pixelSize: 22
                                                color: navItem.isSelected ? Root.Theme.primary : Root.Theme.textSecondary
                                            }

                                            Text {
                                                Layout.fillWidth: true
                                                text: modelData.label
                                                font.family: Root.Theme.fontFamily
                                                font.pixelSize: 14
                                                font.weight: navItem.isSelected ? Font.DemiBold : Font.Normal
                                                color: navItem.isSelected ? Root.Theme.primary : Root.Theme.textPrimary
                                                elide: Text.ElideRight
                                            }
                                        }

                                        MouseArea {
                                            id: navMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: settingsRoot.currentSection = modelData.id
                                        }
                                    }
                                }

                                Item { Layout.fillHeight: true }
                            }

                            // Divisor vertical
                            Rectangle {
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                anchors.right: parent.right
                                width: 1
                                color: Qt.rgba(255, 255, 255, 0.08)
                            }
                        }

                        // Right Content Panel
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            color: "transparent"

                            Flickable {
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.topMargin: 28
                                anchors.bottomMargin: 28
                                anchors.leftMargin: 28
                                anchors.rightMargin: 56
                                contentWidth: width
                                contentHeight: contentCol.height
                                clip: true

                                ColumnLayout {
                                    id: contentCol
                                    width: parent.width
                                    spacing: 20

                                    // ════════════════════════════════════════════════
                                    // PROFILE SECTION
                                    // ════════════════════════════════════════════════
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 20
                                        visible: settingsRoot.currentSection === "profile"

                                        // Profile Header
                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 4

                                            Text {
                                                text: "Profile"
                                                font.family: Root.Theme.fontFamily
                                                font.pixelSize: 22
                                                font.weight: Font.Bold
                                                color: Root.Theme.textPrimary
                                            }

                                            Text {
                                                text: "Personalize your account details and profile picture"
                                                font.family: Root.Theme.fontFamily
                                                font.pixelSize: 13
                                                color: Root.Theme.textSecondary
                                            }
                                        }

                                    // Card 1: Avatar
                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 128
                                        radius: 20
                                        color: Root.Theme.surfaceContainer
                                        border.width: 1
                                        border.color: Qt.rgba(255, 255, 255, 0.06)

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.margins: 18
                                            spacing: 18

                                            Item {
                                                Layout.preferredWidth: 84
                                                Layout.preferredHeight: 84

                                                Rectangle {
                                                    anchors.fill: parent
                                                    radius: width / 2
                                                    color: Root.Theme.surfaceContainerHigh
                                                }

                                                Image {
                                                    id: avatarImg
                                                    anchors.fill: parent
                                                    source: Settings.ProfileService.avatarUrl
                                                    cache: false
                                                    fillMode: Image.PreserveAspectCrop
                                                    visible: false
                                                }

                                                Rectangle {
                                                    id: avatarMask
                                                    anchors.fill: parent
                                                    radius: width / 2
                                                    visible: false
                                                }

                                                OpacityMask {
                                                    anchors.fill: parent
                                                    source: avatarImg
                                                    maskSource: avatarMask
                                                }

                                                Rectangle {
                                                    anchors.fill: parent
                                                    radius: width / 2
                                                    color: "transparent"
                                                    border.width: 2
                                                    border.color: Root.Theme.primary
                                                }
                                            }

                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                spacing: 6

                                                Text {
                                                    text: "Profile Picture"
                                                    font.family: Root.Theme.fontFamily
                                                    font.pixelSize: 15
                                                    font.weight: Font.DemiBold
                                                    color: Root.Theme.textPrimary
                                                }

                                                Text {
                                                    text: "Avatar synced with ~/.face and system control center"
                                                    font.family: Root.Theme.fontFamily
                                                    font.pixelSize: 12
                                                    color: Root.Theme.textSecondary
                                                }

                                                // Change Picture Button
                                                Rectangle {
                                                    Layout.preferredWidth: changeBtnContent.width + 28
                                                    Layout.preferredHeight: 36
                                                    radius: 18
                                                    color: changeBtnMouse.containsMouse ? Qt.darker(Root.Theme.primary, 1.1) : Root.Theme.primary
                                                    Behavior on color { ColorAnimation { duration: Root.Theme.animDurationFast } }

                                                    RowLayout {
                                                        id: changeBtnContent
                                                        anchors.centerIn: parent
                                                        spacing: 6

                                                        Text {
                                                            text: Settings.ProfileService.isUpdatingAvatar ? "hourglass_top" : "photo_camera"
                                                            font.family: Root.Theme.iconFont
                                                            font.pixelSize: 16
                                                            color: Root.Theme.tileActiveText
                                                        }

                                                        Text {
                                                            text: Settings.ProfileService.isUpdatingAvatar ? "Selecting..." : "Change Picture"
                                                            font.family: Root.Theme.fontFamily
                                                            font.pixelSize: 13
                                                            font.weight: Font.DemiBold
                                                            color: Root.Theme.tileActiveText
                                                        }
                                                    }

                                                    MouseArea {
                                                        id: changeBtnMouse
                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: Settings.ProfileService.pickAvatar()
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    // Card 2: Account details & Display Name
                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 180
                                        radius: 20
                                        color: Root.Theme.surfaceContainer
                                        border.width: 1
                                        border.color: Qt.rgba(255, 255, 255, 0.06)

                                        ColumnLayout {
                                            anchors.fill: parent
                                            anchors.margins: 20
                                            spacing: 12

                                            Text {
                                                text: "Account Details"
                                                font.family: Root.Theme.fontFamily
                                                font.pixelSize: 15
                                                font.weight: Font.DemiBold
                                                color: Root.Theme.textPrimary
                                            }

                                            // System username (badge)
                                            RowLayout {
                                                spacing: 10

                                                Text {
                                                    text: "System user:"
                                                    font.family: Root.Theme.fontFamily
                                                    font.pixelSize: 13
                                                    color: Root.Theme.textSecondary
                                                }

                                                Rectangle {
                                                    Layout.preferredHeight: 24
                                                    Layout.preferredWidth: userBadgeText.implicitWidth + 16
                                                    radius: 6
                                                    color: Root.Theme.surfaceContainerHigh

                                                    Text {
                                                        id: userBadgeText
                                                        anchors.centerIn: parent
                                                        text: "@" + Settings.ProfileService.username
                                                        font.family: Root.Theme.fontFamily
                                                        font.pixelSize: 12
                                                        font.weight: Font.DemiBold
                                                        color: Root.Theme.textPrimary
                                                    }
                                                }
                                            }

                                            // Display Name Input Field
                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                spacing: 6

                                                Text {
                                                    text: "Display Name"
                                                    font.family: Root.Theme.fontFamily
                                                    font.pixelSize: 13
                                                    font.weight: Font.Medium
                                                    color: Root.Theme.textSecondary
                                                }

                                                RowLayout {
                                                    Layout.fillWidth: true
                                                    spacing: 10

                                                    Rectangle {
                                                        Layout.fillWidth: true
                                                        Layout.preferredHeight: 42
                                                        radius: 12
                                                        color: Root.Theme.surfaceContainerHigh
                                                        border.width: displayNameInput.activeFocus ? 2 : 1
                                                        border.color: displayNameInput.activeFocus ? Root.Theme.primary : Qt.rgba(255, 255, 255, 0.1)

                                                        TextInput {
                                                            id: displayNameInput
                                                            anchors.fill: parent
                                                            anchors.leftMargin: 12
                                                            anchors.rightMargin: 12
                                                            verticalAlignment: TextInput.AlignVCenter
                                                            text: Settings.ProfileService.displayName
                                                            font.family: Root.Theme.fontFamily
                                                            font.pixelSize: 14
                                                            color: Root.Theme.textPrimary
                                                            selectByMouse: true
                                                            selectionColor: Qt.rgba(Root.Theme.primary.r, Root.Theme.primary.g, Root.Theme.primary.b, 0.4)
                                                            onAccepted: {
                                                                Settings.ProfileService.setDisplayName(displayNameInput.text);
                                                                saveFeedbackTimer.restart();
                                                            }
                                                        }
                                                    }

                                                    // Save Button
                                                    Rectangle {
                                                        Layout.preferredWidth: saveContent.width + 24
                                                        Layout.preferredHeight: 42
                                                        radius: 12
                                                        color: saveMouse.containsMouse ? Qt.darker(Root.Theme.primary, 1.1) : Root.Theme.primary
                                                        Behavior on color { ColorAnimation { duration: Root.Theme.animDurationFast } }

                                                        RowLayout {
                                                            id: saveContent
                                                            anchors.centerIn: parent
                                                            spacing: 6

                                                            Text {
                                                                text: saveFeedbackTimer.running ? "check" : "save"
                                                                font.family: Root.Theme.iconFont
                                                                font.pixelSize: 16
                                                                color: Root.Theme.tileActiveText
                                                            }

                                                            Text {
                                                                text: saveFeedbackTimer.running ? "Saved!" : "Save"
                                                                font.family: Root.Theme.fontFamily
                                                                font.pixelSize: 13
                                                                font.weight: Font.DemiBold
                                                                color: Root.Theme.tileActiveText
                                                            }
                                                        }

                                                        MouseArea {
                                                            id: saveMouse
                                                            anchors.fill: parent
                                                            hoverEnabled: true
                                                            cursorShape: Qt.PointingHandCursor
                                                            onClicked: {
                                                                Settings.ProfileService.setDisplayName(displayNameInput.text);
                                                                saveFeedbackTimer.restart();
                                                            }
                                                        }

                                                        Timer {
                                                            id: saveFeedbackTimer
                                                            interval: 1800
                                                            repeat: false
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                    // ════════════════════════════════════════════════
                                    // THEME & STYLE SECTION
                                    // ════════════════════════════════════════════════
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 20
                                        visible: settingsRoot.currentSection === "theme"

                                        // Section Header
                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 4

                                            Text {
                                                text: "Theme & Style"
                                                font.family: Root.Theme.fontFamily
                                                font.pixelSize: 22
                                                font.weight: Font.Bold
                                                color: Root.Theme.textPrimary
                                            }

                                            Text {
                                                text: "Choose how system colors are generated. At least one option remains active"
                                                font.family: Root.Theme.fontFamily
                                                font.pixelSize: 13
                                                color: Root.Theme.textSecondary
                                            }
                                        }

                                        // ── Option 1: Dynamic Wallpaper Colors (Matugen) ──
                                        Rectangle {
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: matugenContentCol.height + 36
                                            radius: 20
                                            color: Root.Theme.surfaceContainer
                                            border.width: Settings.ThemeService.activeMode === "matugen" ? 2 : 1
                                            border.color: Settings.ThemeService.activeMode === "matugen"
                                                ? Root.Theme.primary
                                                : Qt.rgba(255, 255, 255, 0.06)

                                            Behavior on border.color { ColorAnimation { duration: 180 } }

                                            ColumnLayout {
                                                id: matugenContentCol
                                                anchors.top: parent.top
                                                anchors.left: parent.left
                                                anchors.right: parent.right
                                                anchors.margins: 18
                                                spacing: 16

                                                // Card Header with Toggle
                                                RowLayout {
                                                    Layout.fillWidth: true
                                                    spacing: 14

                                                    Rectangle {
                                                        Layout.preferredWidth: 42
                                                        Layout.preferredHeight: 42
                                                        radius: 21
                                                        color: Settings.ThemeService.activeMode === "matugen"
                                                            ? Qt.rgba(Root.Theme.primary.r, Root.Theme.primary.g, Root.Theme.primary.b, 0.2)
                                                            : Root.Theme.surfaceContainerHigh

                                                        Text {
                                                            anchors.centerIn: parent
                                                            text: "auto_awesome"
                                                            font.family: Root.Theme.iconFont
                                                            font.pixelSize: 22
                                                            color: Settings.ThemeService.activeMode === "matugen"
                                                                ? Root.Theme.primary
                                                                : Root.Theme.textSecondary
                                                        }
                                                    }

                                                    ColumnLayout {
                                                        Layout.fillWidth: true
                                                        spacing: 2

                                                        RowLayout {
                                                            spacing: 8
                                                            Text {
                                                                text: "Dynamic Wallpaper Colors (Matugen)"
                                                                font.family: Root.Theme.fontFamily
                                                                font.pixelSize: 15
                                                                font.weight: Font.DemiBold
                                                                color: Root.Theme.textPrimary
                                                            }

                                                            Rectangle {
                                                                visible: Settings.ThemeService.activeMode === "matugen"
                                                                Layout.preferredHeight: 18
                                                                Layout.preferredWidth: 54
                                                                radius: 9
                                                                color: Qt.rgba(Root.Theme.primary.r, Root.Theme.primary.g, Root.Theme.primary.b, 0.2)

                                                                Text {
                                                                    anchors.centerIn: parent
                                                                    text: "ACTIVE"
                                                                    font.family: Root.Theme.fontFamily
                                                                    font.pixelSize: 9
                                                                    font.weight: Font.Bold
                                                                    color: Root.Theme.primary
                                                                }
                                                            }
                                                        }

                                                        Text {
                                                            text: "Extract Material You colors dynamically from your active wallpaper"
                                                            font.family: Root.Theme.fontFamily
                                                            font.pixelSize: 12
                                                            color: Root.Theme.textSecondary
                                                        }
                                                    }

                                                    // Material 3 Switch
                                                    Rectangle {
                                                        id: matugenSwitch
                                                        Layout.preferredWidth: 48
                                                        Layout.preferredHeight: 28
                                                        radius: 14
                                                        color: Settings.ThemeService.activeMode === "matugen"
                                                            ? Root.Theme.primary
                                                            : Root.Theme.surfaceContainerHigh
                                                        border.width: 1
                                                        border.color: Settings.ThemeService.activeMode === "matugen"
                                                            ? Root.Theme.primary
                                                            : Qt.rgba(255, 255, 255, 0.12)

                                                        Behavior on color { ColorAnimation { duration: 180 } }

                                                        Rectangle {
                                                            width: 20
                                                            height: 20
                                                            radius: 10
                                                            y: 4
                                                            x: Settings.ThemeService.activeMode === "matugen" ? 24 : 4
                                                            color: Settings.ThemeService.activeMode === "matugen"
                                                                ? Root.Theme.onPrimary
                                                                : Root.Theme.textSecondary

                                                            Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                                                            Behavior on color { ColorAnimation { duration: 180 } }
                                                        }

                                                        MouseArea {
                                                            anchors.fill: parent
                                                            cursorShape: Qt.PointingHandCursor
                                                            onClicked: {
                                                                // Keeps at least one active
                                                                Settings.ThemeService.setMode("matugen");
                                                            }
                                                        }
                                                    }
                                                }

                                                // Scheme selector title & preview
                                                RowLayout {
                                                    Layout.fillWidth: true
                                                    spacing: 8

                                                    Text {
                                                        text: "COLOR SCHEMES"
                                                        font.family: Root.Theme.fontFamily
                                                        font.pixelSize: 11
                                                        font.weight: Font.Bold
                                                        color: Root.Theme.textSecondary
                                                    }

                                                    Item { Layout.fillWidth: true }

                                                    // Live Palette preview circles
                                                    RowLayout {
                                                        spacing: 5

                                                        Text {
                                                            text: "Live Palette:"
                                                            font.family: Root.Theme.fontFamily
                                                            font.pixelSize: 11
                                                            color: Root.Theme.textSecondary
                                                            Layout.alignment: Qt.AlignVCenter
                                                        }

                                                        Rectangle {
                                                            width: 16
                                                            height: 16
                                                            radius: 8
                                                            color: Settings.ThemeService.matugenColors.primary
                                                            border.width: 1
                                                            border.color: Qt.rgba(255, 255, 255, 0.15)
                                                        }
                                                        Rectangle {
                                                            width: 16
                                                            height: 16
                                                            radius: 8
                                                            color: Settings.ThemeService.matugenColors.primaryContainer
                                                            border.width: 1
                                                            border.color: Qt.rgba(255, 255, 255, 0.15)
                                                        }
                                                        Rectangle {
                                                            width: 16
                                                            height: 16
                                                            radius: 8
                                                            color: Settings.ThemeService.matugenColors.tertiary
                                                            border.width: 1
                                                            border.color: Qt.rgba(255, 255, 255, 0.15)
                                                        }
                                                        Rectangle {
                                                            width: 16
                                                            height: 16
                                                            radius: 8
                                                            color: Settings.ThemeService.matugenColors.surfaceContainer
                                                            border.width: 1
                                                            border.color: Qt.rgba(255, 255, 255, 0.15)
                                                        }
                                                    }
                                                }

                                                // Scheme Chips
                                                Flow {
                                                    Layout.fillWidth: true
                                                    spacing: 8

                                                    Repeater {
                                                        model: Settings.ThemeService.matugenSchemes

                                                        delegate: Rectangle {
                                                            id: schemeChip
                                                            height: 36
                                                            width: chipRow.width + 24
                                                            radius: 18

                                                            readonly property bool isSelected: Settings.ThemeService.activeMatugenScheme === modelData.id && Settings.ThemeService.activeMode === "matugen"
                                                            readonly property bool isHovered: chipMouse.containsMouse

                                                            color: isSelected
                                                                ? Qt.rgba(Root.Theme.primary.r, Root.Theme.primary.g, Root.Theme.primary.b, 0.18)
                                                                : (isHovered ? Root.Theme.surfaceContainerHigh : Qt.rgba(255, 255, 255, 0.04))
                                                            border.width: isSelected ? 1.5 : 1
                                                            border.color: isSelected
                                                                ? Root.Theme.primary
                                                                : Qt.rgba(255, 255, 255, 0.08)

                                                            Behavior on color { ColorAnimation { duration: 140 } }
                                                            Behavior on border.color { ColorAnimation { duration: 140 } }

                                                            RowLayout {
                                                                id: chipRow
                                                                anchors.centerIn: parent
                                                                spacing: 7

                                                                Text {
                                                                    text: modelData.icon
                                                                    font.family: Root.Theme.iconFont
                                                                    font.pixelSize: 16
                                                                    color: schemeChip.isSelected ? Root.Theme.primary : Root.Theme.textSecondary
                                                                }

                                                                Text {
                                                                    text: modelData.name
                                                                    font.family: Root.Theme.fontFamily
                                                                    font.pixelSize: 12
                                                                    font.weight: schemeChip.isSelected ? Font.DemiBold : Font.Normal
                                                                    color: schemeChip.isSelected ? Root.Theme.primary : Root.Theme.textPrimary
                                                                }
                                                            }

                                                            MouseArea {
                                                                id: chipMouse
                                                                anchors.fill: parent
                                                                hoverEnabled: true
                                                                cursorShape: Qt.PointingHandCursor
                                                                onClicked: {
                                                                    Settings.ThemeService.enableMatugen(modelData.id);
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }

                                        // ── Option 2: Preset Themes ──
                                        Rectangle {
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: presetContentCol.height + 36
                                            radius: 20
                                            color: Root.Theme.surfaceContainer
                                            border.width: Settings.ThemeService.activeMode === "preset" ? 2 : 1
                                            border.color: Settings.ThemeService.activeMode === "preset"
                                                ? Root.Theme.primary
                                                : Qt.rgba(255, 255, 255, 0.06)

                                            Behavior on border.color { ColorAnimation { duration: 180 } }

                                            ColumnLayout {
                                                id: presetContentCol
                                                anchors.top: parent.top
                                                anchors.left: parent.left
                                                anchors.right: parent.right
                                                anchors.margins: 18
                                                spacing: 16

                                                // Card Header with Toggle
                                                RowLayout {
                                                    Layout.fillWidth: true
                                                    spacing: 14

                                                    Rectangle {
                                                        Layout.preferredWidth: 42
                                                        Layout.preferredHeight: 42
                                                        radius: 21
                                                        color: Settings.ThemeService.activeMode === "preset"
                                                            ? Qt.rgba(Root.Theme.primary.r, Root.Theme.primary.g, Root.Theme.primary.b, 0.2)
                                                            : Root.Theme.surfaceContainerHigh

                                                        Text {
                                                            anchors.centerIn: parent
                                                            text: "palette"
                                                            font.family: Root.Theme.iconFont
                                                            font.pixelSize: 22
                                                            color: Settings.ThemeService.activeMode === "preset"
                                                                ? Root.Theme.primary
                                                                : Root.Theme.textSecondary
                                                        }
                                                    }

                                                    ColumnLayout {
                                                        Layout.fillWidth: true
                                                        spacing: 2

                                                        RowLayout {
                                                            spacing: 8
                                                            Text {
                                                                text: "Preset Themes"
                                                                font.family: Root.Theme.fontFamily
                                                                font.pixelSize: 15
                                                                font.weight: Font.DemiBold
                                                                color: Root.Theme.textPrimary
                                                            }

                                                            Rectangle {
                                                                visible: Settings.ThemeService.activeMode === "preset"
                                                                Layout.preferredHeight: 18
                                                                Layout.preferredWidth: 54
                                                                radius: 9
                                                                color: Qt.rgba(Root.Theme.primary.r, Root.Theme.primary.g, Root.Theme.primary.b, 0.2)

                                                                Text {
                                                                    anchors.centerIn: parent
                                                                    text: "ACTIVE"
                                                                    font.family: Root.Theme.fontFamily
                                                                    font.pixelSize: 9
                                                                    font.weight: Font.Bold
                                                                    color: Root.Theme.primary
                                                                }
                                                            }
                                                        }

                                                        Text {
                                                            text: "Handcrafted color schemes designed for optimal contrast and elegance"
                                                            font.family: Root.Theme.fontFamily
                                                            font.pixelSize: 12
                                                            color: Root.Theme.textSecondary
                                                        }
                                                    }

                                                    // Material 3 Switch
                                                    Rectangle {
                                                        Layout.preferredWidth: 48
                                                        Layout.preferredHeight: 28
                                                        radius: 14
                                                        color: Settings.ThemeService.activeMode === "preset"
                                                            ? Root.Theme.primary
                                                            : Root.Theme.surfaceContainerHigh
                                                        border.width: 1
                                                        border.color: Settings.ThemeService.activeMode === "preset"
                                                            ? Root.Theme.primary
                                                            : Qt.rgba(255, 255, 255, 0.12)

                                                        Behavior on color { ColorAnimation { duration: 180 } }

                                                        Rectangle {
                                                            width: 20
                                                            height: 20
                                                            radius: 10
                                                            y: 4
                                                            x: Settings.ThemeService.activeMode === "preset" ? 24 : 4
                                                            color: Settings.ThemeService.activeMode === "preset"
                                                                ? Root.Theme.onPrimary
                                                                : Root.Theme.textSecondary

                                                            Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                                                            Behavior on color { ColorAnimation { duration: 180 } }
                                                        }

                                                        MouseArea {
                                                            anchors.fill: parent
                                                            cursorShape: Qt.PointingHandCursor
                                                            onClicked: {
                                                                // Keeps at least one active
                                                                Settings.ThemeService.setMode("preset");
                                                            }
                                                        }
                                                    }
                                                }

                                                // Preset theme cards
                                                Flow {
                                                    Layout.fillWidth: true
                                                    spacing: 10

                                                    Repeater {
                                                        model: Settings.ThemeService.presetThemes

                                                        delegate: Rectangle {
                                                            id: presetCard
                                                            width: (parent.width - 20) / 3
                                                            height: 84
                                                            radius: 14

                                                            readonly property bool isSelected: Settings.ThemeService.activeMode === "preset" && Root.Theme.currentTheme === modelData.id
                                                            readonly property bool isHovered: cardMouse.containsMouse

                                                            color: isSelected
                                                                ? Qt.rgba(Root.Theme.primary.r, Root.Theme.primary.g, Root.Theme.primary.b, 0.14)
                                                                : (isHovered ? Qt.rgba(255, 255, 255, 0.06) : Qt.rgba(255, 255, 255, 0.03))
                                                            border.width: isSelected ? 2 : 1
                                                            border.color: isSelected
                                                                ? Root.Theme.primary
                                                                : Qt.rgba(255, 255, 255, 0.08)

                                                            Behavior on border.color { ColorAnimation { duration: 140 } }
                                                            Behavior on color { ColorAnimation { duration: 140 } }

                                                            ColumnLayout {
                                                                anchors.fill: parent
                                                                anchors.margins: 12
                                                                spacing: 8

                                                                RowLayout {
                                                                    Layout.fillWidth: true
                                                                    spacing: 6

                                                                    // Palette dots
                                                                    Rectangle {
                                                                        width: 14
                                                                        height: 14
                                                                        radius: 7
                                                                        color: modelData.primary
                                                                    }
                                                                    Rectangle {
                                                                        width: 14
                                                                        height: 14
                                                                        radius: 7
                                                                        color: modelData.container
                                                                    }
                                                                    Rectangle {
                                                                        width: 14
                                                                        height: 14
                                                                        radius: 7
                                                                        color: modelData.surface
                                                                        border.width: 1
                                                                        border.color: Qt.rgba(255, 255, 255, 0.2)
                                                                    }

                                                                    Item { Layout.fillWidth: true }

                                                                    Text {
                                                                        visible: presetCard.isSelected
                                                                        text: "check_circle"
                                                                        font.family: Root.Theme.iconFont
                                                                        font.pixelSize: 16
                                                                        color: Root.Theme.primary
                                                                    }
                                                                }

                                                                Text {
                                                                    Layout.fillWidth: true
                                                                    text: modelData.name
                                                                    font.family: Root.Theme.fontFamily
                                                                    font.pixelSize: 13
                                                                    font.weight: presetCard.isSelected ? Font.Bold : Font.Medium
                                                                    color: presetCard.isSelected ? Root.Theme.primary : Root.Theme.textPrimary
                                                                    elide: Text.ElideRight
                                                                }
                                                            }

                                                            MouseArea {
                                                                id: cardMouse
                                                                anchors.fill: parent
                                                                hoverEnabled: true
                                                                cursorShape: Qt.PointingHandCursor
                                                                onClicked: {
                                                                    Settings.ThemeService.enablePreset(modelData.id);
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }

                                        // ── Option 3: Custom Accent Color ──
                                        Rectangle {
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: customContentCol.height + 36
                                            radius: 20
                                            color: Root.Theme.surfaceContainer
                                            border.width: Settings.ThemeService.activeMode === "custom" ? 2 : 1
                                            border.color: Settings.ThemeService.activeMode === "custom"
                                                ? Root.Theme.primary
                                                : Qt.rgba(255, 255, 255, 0.06)

                                            Behavior on border.color { ColorAnimation { duration: 180 } }

                                            ColumnLayout {
                                                id: customContentCol
                                                anchors.top: parent.top
                                                anchors.left: parent.left
                                                anchors.right: parent.right
                                                anchors.margins: 18
                                                spacing: 16

                                                // Card Header with Toggle
                                                RowLayout {
                                                    Layout.fillWidth: true
                                                    spacing: 14

                                                    Rectangle {
                                                        Layout.preferredWidth: 42
                                                        Layout.preferredHeight: 42
                                                        radius: 21
                                                        color: Settings.ThemeService.activeMode === "custom"
                                                            ? Qt.rgba(Root.Theme.primary.r, Root.Theme.primary.g, Root.Theme.primary.b, 0.2)
                                                            : Root.Theme.surfaceContainerHigh

                                                        Text {
                                                            anchors.centerIn: parent
                                                            text: "colorize"
                                                            font.family: Root.Theme.iconFont
                                                            font.pixelSize: 22
                                                            color: Settings.ThemeService.activeMode === "custom"
                                                                ? Root.Theme.primary
                                                                : Root.Theme.textSecondary
                                                        }
                                                    }

                                                    ColumnLayout {
                                                        Layout.fillWidth: true
                                                        spacing: 2

                                                        RowLayout {
                                                            spacing: 8
                                                            Text {
                                                                text: "Custom Accent"
                                                                font.family: Root.Theme.fontFamily
                                                                font.pixelSize: 15
                                                                font.weight: Font.DemiBold
                                                                color: Root.Theme.textPrimary
                                                            }

                                                            Rectangle {
                                                                visible: Settings.ThemeService.activeMode === "custom"
                                                                Layout.preferredHeight: 18
                                                                Layout.preferredWidth: 54
                                                                radius: 9
                                                                color: Qt.rgba(Root.Theme.primary.r, Root.Theme.primary.g, Root.Theme.primary.b, 0.2)

                                                                Text {
                                                                    anchors.centerIn: parent
                                                                    text: "ACTIVE"
                                                                    font.family: Root.Theme.fontFamily
                                                                    font.pixelSize: 9
                                                                    font.weight: Font.Bold
                                                                    color: Root.Theme.primary
                                                                }
                                                            }
                                                        }

                                                        Text {
                                                            text: "Choose a signature accent color from the curated palette"
                                                            font.family: Root.Theme.fontFamily
                                                            font.pixelSize: 12
                                                            color: Root.Theme.textSecondary
                                                        }
                                                    }

                                                    // Material 3 Switch
                                                    Rectangle {
                                                        Layout.preferredWidth: 48
                                                        Layout.preferredHeight: 28
                                                        radius: 14
                                                        color: Settings.ThemeService.activeMode === "custom"
                                                            ? Root.Theme.primary
                                                            : Root.Theme.surfaceContainerHigh
                                                        border.width: 1
                                                        border.color: Settings.ThemeService.activeMode === "custom"
                                                            ? Root.Theme.primary
                                                            : Qt.rgba(255, 255, 255, 0.12)

                                                        Behavior on color { ColorAnimation { duration: 180 } }

                                                        Rectangle {
                                                            width: 20
                                                            height: 20
                                                            radius: 10
                                                            y: 4
                                                            x: Settings.ThemeService.activeMode === "custom" ? 24 : 4
                                                            color: Settings.ThemeService.activeMode === "custom"
                                                                ? Root.Theme.onPrimary
                                                                : Root.Theme.textSecondary

                                                            Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                                                            Behavior on color { ColorAnimation { duration: 180 } }
                                                        }

                                                        MouseArea {
                                                            anchors.fill: parent
                                                            cursorShape: Qt.PointingHandCursor
                                                            onClicked: {
                                                                // Keeps at least one active
                                                                Settings.ThemeService.setMode("custom");
                                                            }
                                                        }
                                                    }
                                                }

                                                // Quick Pixel Color Dots
                                                ColumnLayout {
                                                    Layout.fillWidth: true
                                                    spacing: 8

                                                    Text {
                                                        text: "PIXEL PALETTE"
                                                        font.family: Root.Theme.fontFamily
                                                        font.pixelSize: 11
                                                        font.weight: Font.Bold
                                                        color: Root.Theme.textSecondary
                                                    }

                                                    RowLayout {
                                                        Layout.fillWidth: true
                                                        spacing: 10

                                                        Repeater {
                                                            model: Settings.ThemeService.quickAccents

                                                            delegate: Rectangle {
                                                                id: accentDot
                                                                width: 34
                                                                height: 34
                                                                radius: 17
                                                                color: modelData.hex

                                                                readonly property bool isSelected: Settings.ThemeService.activeMode === "custom" && Settings.ThemeService.customAccent.toUpperCase() === modelData.hex.toUpperCase()
                                                                readonly property bool isHovered: dotMouse.containsMouse

                                                                border.width: isSelected ? 3 : (isHovered ? 2 : 1)
                                                                border.color: isSelected
                                                                    ? "#FFFFFF"
                                                                    : Qt.rgba(255, 255, 255, 0.25)

                                                                scale: isHovered ? 1.12 : (isSelected ? 1.06 : 1.0)
                                                                Behavior on scale { NumberAnimation { duration: 120 } }

                                                                Text {
                                                                    visible: accentDot.isSelected
                                                                    anchors.centerIn: parent
                                                                    text: "check"
                                                                    font.family: Root.Theme.iconFont
                                                                    font.pixelSize: 18
                                                                    font.weight: Font.Bold
                                                                    color: "#FFFFFF"
                                                                }

                                                                MouseArea {
                                                                    id: dotMouse
                                                                    anchors.fill: parent
                                                                    hoverEnabled: true
                                                                    cursorShape: Qt.PointingHandCursor
                                                                    onClicked: {
                                                                        customHexInput.text = modelData.hex;
                                                                        Settings.ThemeService.enableCustom(modelData.hex);
                                                                    }
                                                                }
                                                            }
                                                        }

                                                        Item { Layout.fillWidth: true }
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    // ════════════════════════════════════════════════
                                    // LOCK SCREEN & SECURITY SECTION
                                    // ════════════════════════════════════════════════
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 20
                                        visible: settingsRoot.currentSection === "lockscreen"

                                        // Section Header
                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 4

                                            Text {
                                                text: "Lock Screen & Security"
                                                font.family: Root.Theme.fontFamily
                                                font.pixelSize: 22
                                                font.weight: Font.Bold
                                                color: Root.Theme.textPrimary
                                            }

                                            Text {
                                                text: "Manage session idle inactivity timeout and screen lock daemon behavior"
                                                font.family: Root.Theme.fontFamily
                                                font.pixelSize: 13
                                                color: Root.Theme.textSecondary
                                            }
                                        }

                                        // ── Live Status Banner ──
                                        Rectangle {
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 90
                                            radius: 20
                                            color: Root.Theme.surfaceContainer
                                            border.width: 1
                                            border.color: Qt.rgba(255, 255, 255, 0.08)

                                            RowLayout {
                                                anchors.fill: parent
                                                anchors.margins: 18
                                                spacing: 16

                                                Rectangle {
                                                    Layout.preferredWidth: 48
                                                    Layout.preferredHeight: 48
                                                    radius: 24
                                                    color: Settings.LockService.enabled
                                                        ? Qt.rgba(Root.Theme.primary.r, Root.Theme.primary.g, Root.Theme.primary.b, 0.2)
                                                        : Root.Theme.surfaceContainerHigh

                                                    Text {
                                                        anchors.centerIn: parent
                                                        text: Settings.LockService.enabled ? "lock" : "lock_open"
                                                        font.family: Root.Theme.iconFont
                                                        font.pixelSize: 24
                                                        color: Settings.LockService.enabled ? Root.Theme.primary : Root.Theme.textSecondary
                                                    }
                                                }

                                                ColumnLayout {
                                                    Layout.fillWidth: true
                                                    spacing: 4

                                                    RowLayout {
                                                        spacing: 8
                                                        Text {
                                                            text: Settings.LockService.enabled
                                                                ? ("Locks after " + Settings.LockService.formattedTime)
                                                                : "Automatic Lock Disabled"
                                                            font.family: Root.Theme.fontFamily
                                                            font.pixelSize: 16
                                                            font.weight: Font.Bold
                                                            color: Root.Theme.textPrimary
                                                        }

                                                        Rectangle {
                                                            Layout.preferredHeight: 20
                                                            Layout.preferredWidth: statusText.implicitWidth + 14
                                                            radius: 10
                                                            color: Settings.LockService.enabled
                                                                ? Qt.rgba(Root.Theme.primary.r, Root.Theme.primary.g, Root.Theme.primary.b, 0.2)
                                                                : Qt.rgba(255, 255, 255, 0.08)

                                                            Text {
                                                                id: statusText
                                                                anchors.centerIn: parent
                                                                text: Settings.LockService.enabled ? "ACTIVE" : "INACTIVE"
                                                                font.family: Root.Theme.fontFamily
                                                                font.pixelSize: 10
                                                                font.weight: Font.Bold
                                                                color: Settings.LockService.enabled ? Root.Theme.primary : Root.Theme.textSecondary
                                                            }
                                                        }
                                                    }

                                                    Text {
                                                        text: Settings.LockService.enabled
                                                            ? "Hypridle will automatically activate Hyprlock when user is idle"
                                                            : "Your session will remain unlocked indefinitely while idle"
                                                        font.family: Root.Theme.fontFamily
                                                        font.pixelSize: 12
                                                        color: Root.Theme.textSecondary
                                                    }
                                                }

                                                // Test / Lock Now Button
                                                Rectangle {
                                                    Layout.preferredHeight: 40
                                                    Layout.preferredWidth: lockNowRow.implicitWidth + 24
                                                    radius: 20
                                                    color: lockNowMouse.containsMouse ? Qt.darker(Root.Theme.primary, 1.1) : Root.Theme.primary

                                                    Behavior on color { ColorAnimation { duration: Root.Theme.animDurationFast } }

                                                    RowLayout {
                                                        id: lockNowRow
                                                        anchors.centerIn: parent
                                                        spacing: 8

                                                        Text {
                                                            text: "lock"
                                                            font.family: Root.Theme.iconFont
                                                            font.pixelSize: 18
                                                            color: Root.Theme.tileActiveText
                                                        }

                                                        Text {
                                                            text: "Lock Now"
                                                            font.family: Root.Theme.fontFamily
                                                            font.pixelSize: 13
                                                            font.weight: Font.DemiBold
                                                            color: Root.Theme.tileActiveText
                                                        }
                                                    }

                                                    MouseArea {
                                                        id: lockNowMouse
                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: Settings.LockService.lockNow()
                                                    }
                                                }
                                            }
                                        }

                                        // ── Card 1: Master Enable / Disable Toggle ──
                                        Rectangle {
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 76
                                            radius: 20
                                            color: Root.Theme.surfaceContainer
                                            border.width: 1
                                            border.color: Qt.rgba(255, 255, 255, 0.06)

                                            RowLayout {
                                                anchors.fill: parent
                                                anchors.margins: 18
                                                spacing: 14

                                                Rectangle {
                                                    Layout.preferredWidth: 42
                                                    Layout.preferredHeight: 42
                                                    radius: 21
                                                    color: Settings.LockService.enabled
                                                        ? Qt.rgba(Root.Theme.primary.r, Root.Theme.primary.g, Root.Theme.primary.b, 0.2)
                                                        : Root.Theme.surfaceContainerHigh

                                                    Text {
                                                        anchors.centerIn: parent
                                                        text: "schedule"
                                                        font.family: Root.Theme.iconFont
                                                        font.pixelSize: 22
                                                        color: Settings.LockService.enabled ? Root.Theme.primary : Root.Theme.textSecondary
                                                    }
                                                }

                                                ColumnLayout {
                                                    Layout.fillWidth: true
                                                    spacing: 2

                                                    Text {
                                                        text: "Automatic Screen Lock"
                                                        font.family: Root.Theme.fontFamily
                                                        font.pixelSize: 15
                                                        font.weight: Font.DemiBold
                                                        color: Root.Theme.textPrimary
                                                    }

                                                    Text {
                                                        text: "Automatically engage lock screen when inactive for the specified time"
                                                        font.family: Root.Theme.fontFamily
                                                        font.pixelSize: 12
                                                        color: Root.Theme.textSecondary
                                                    }
                                                }

                                                // Material 3 Switch Toggle
                                                Rectangle {
                                                    id: lockToggleSwitch
                                                    Layout.preferredWidth: 48
                                                    Layout.preferredHeight: 28
                                                    radius: 14
                                                    color: Settings.LockService.enabled
                                                        ? Root.Theme.primary
                                                        : Root.Theme.surfaceContainerHigh
                                                    border.width: 1
                                                    border.color: Settings.LockService.enabled
                                                        ? Root.Theme.primary
                                                        : Qt.rgba(255, 255, 255, 0.12)

                                                    Behavior on color { ColorAnimation { duration: 180 } }

                                                    Rectangle {
                                                        width: 20
                                                        height: 20
                                                        radius: 10
                                                        y: 4
                                                        x: Settings.LockService.enabled ? 24 : 4
                                                        color: Settings.LockService.enabled
                                                            ? Root.Theme.tileActiveText
                                                            : Root.Theme.textSecondary

                                                        Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                                                        Behavior on color { ColorAnimation { duration: 180 } }
                                                    }

                                                    MouseArea {
                                                        anchors.fill: parent
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: Settings.LockService.toggleEnabled(!Settings.LockService.enabled)
                                                    }
                                                }
                                            }
                                        }

                                        // ── Card 2: Inactivity Timeout Duration ──
                                        Rectangle {
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: timeoutCol.height + 36
                                            radius: 20
                                            color: Root.Theme.surfaceContainer
                                            border.width: 1
                                            border.color: Qt.rgba(255, 255, 255, 0.06)
                                            opacity: Settings.LockService.enabled ? 1.0 : 0.45

                                            Behavior on opacity { NumberAnimation { duration: 200 } }

                                            ColumnLayout {
                                                id: timeoutCol
                                                anchors.top: parent.top
                                                anchors.left: parent.left
                                                anchors.right: parent.right
                                                anchors.margins: 18
                                                spacing: 16

                                                RowLayout {
                                                    Layout.fillWidth: true
                                                    spacing: 12

                                                    Rectangle {
                                                        Layout.preferredWidth: 38
                                                        Layout.preferredHeight: 38
                                                        radius: 19
                                                        color: Root.Theme.surfaceContainerHigh

                                                        Text {
                                                            anchors.centerIn: parent
                                                            text: "timer"
                                                            font.family: Root.Theme.iconFont
                                                            font.pixelSize: 20
                                                            color: Root.Theme.primary
                                                        }
                                                    }

                                                    ColumnLayout {
                                                        Layout.fillWidth: true
                                                        spacing: 2

                                                        Text {
                                                            text: "Inactivity Timeout"
                                                            font.family: Root.Theme.fontFamily
                                                            font.pixelSize: 15
                                                            font.weight: Font.DemiBold
                                                            color: Root.Theme.textPrimary
                                                        }

                                                        Text {
                                                            text: "Choose or slide how long the system must be idle before locking"
                                                            font.family: Root.Theme.fontFamily
                                                            font.pixelSize: 12
                                                            color: Root.Theme.textSecondary
                                                        }
                                                    }

                                                    // Current selected value badge
                                                    Rectangle {
                                                        Layout.preferredHeight: 30
                                                        Layout.preferredWidth: timeoutBadgeText.implicitWidth + 20
                                                        radius: 15
                                                        color: Qt.rgba(Root.Theme.primary.r, Root.Theme.primary.g, Root.Theme.primary.b, 0.15)
                                                        border.width: 1
                                                        border.color: Qt.rgba(Root.Theme.primary.r, Root.Theme.primary.g, Root.Theme.primary.b, 0.3)

                                                        Text {
                                                            id: timeoutBadgeText
                                                            anchors.centerIn: parent
                                                            text: Settings.LockService.formattedTime
                                                            font.family: Root.Theme.fontFamily
                                                            font.pixelSize: 12
                                                            font.weight: Font.Bold
                                                            color: Root.Theme.primary
                                                        }
                                                    }
                                                }

                                                // Quick Preset Chips
                                                ColumnLayout {
                                                    Layout.fillWidth: true
                                                    spacing: 8

                                                    Text {
                                                        text: "QUICK PRESETS"
                                                        font.family: Root.Theme.fontFamily
                                                        font.pixelSize: 11
                                                        font.weight: Font.Bold
                                                        color: Root.Theme.textSecondary
                                                    }

                                                    Flow {
                                                        Layout.fillWidth: true
                                                        spacing: 8

                                                        Repeater {
                                                            model: Settings.LockService.presetOptions

                                                            delegate: Rectangle {
                                                                id: presetChip
                                                                height: 34
                                                                width: chipLabel.implicitWidth + 28
                                                                radius: 17

                                                                readonly property bool isCurrent: Settings.LockService.enabled && Settings.LockService.timeoutSeconds === modelData.seconds
                                                                readonly property bool isHovered: chipMouseArea.containsMouse

                                                                color: isCurrent
                                                                    ? Qt.rgba(Root.Theme.primary.r, Root.Theme.primary.g, Root.Theme.primary.b, 0.2)
                                                                    : (isHovered ? Root.Theme.surfaceContainerHigh : Qt.rgba(255, 255, 255, 0.04))
                                                                border.width: isCurrent ? 1.5 : 1
                                                                border.color: isCurrent ? Root.Theme.primary : Qt.rgba(255, 255, 255, 0.08)

                                                                Behavior on color { ColorAnimation { duration: 150 } }

                                                                RowLayout {
                                                                    anchors.centerIn: parent
                                                                    spacing: 6

                                                                    Text {
                                                                        visible: presetChip.isCurrent
                                                                        text: "check"
                                                                        font.family: Root.Theme.iconFont
                                                                        font.pixelSize: 14
                                                                        font.weight: Font.Bold
                                                                        color: Root.Theme.primary
                                                                    }

                                                                    Text {
                                                                        id: chipLabel
                                                                        text: modelData.label
                                                                        font.family: Root.Theme.fontFamily
                                                                        font.pixelSize: 12
                                                                        font.weight: presetChip.isCurrent ? Font.DemiBold : Font.Normal
                                                                        color: presetChip.isCurrent ? Root.Theme.primary : Root.Theme.textPrimary
                                                                    }
                                                                }

                                                                MouseArea {
                                                                    id: chipMouseArea
                                                                    anchors.fill: parent
                                                                    enabled: Settings.LockService.enabled
                                                                    hoverEnabled: true
                                                                    cursorShape: Qt.PointingHandCursor
                                                                    onClicked: Settings.LockService.setTimeout(modelData.seconds)
                                                                }
                                                            }
                                                        }
                                                    }
                                                }

                                                // Custom Slider Row
                                                ColumnLayout {
                                                    Layout.fillWidth: true
                                                    spacing: 8

                                                    RowLayout {
                                                        Layout.fillWidth: true
                                                        Text {
                                                            text: "CUSTOM SLIDER"
                                                            font.family: Root.Theme.fontFamily
                                                            font.pixelSize: 11
                                                            font.weight: Font.Bold
                                                            color: Root.Theme.textSecondary
                                                        }

                                                        Item { Layout.fillWidth: true }

                                                        Text {
                                                            text: Math.round(lockSlider.currentMinutes) + " min"
                                                            font.family: Root.Theme.fontFamily
                                                            font.pixelSize: 12
                                                            font.weight: Font.Bold
                                                            color: Root.Theme.primary
                                                        }
                                                    }

                                                    // Interactive Horizontal Slider
                                                    Item {
                                                        id: lockSlider
                                                        Layout.fillWidth: true
                                                        height: 36
                                                        enabled: Settings.LockService.enabled

                                                        // Range: 1 min to 60 min
                                                        readonly property real minMinutes: 1
                                                        readonly property real maxMinutes: 60
                                                        property real currentMinutes: Math.max(minMinutes, Math.min(maxMinutes, Settings.LockService.timeoutSeconds / 60))

                                                        Timer {
                                                            id: sliderDebounceTimer
                                                            interval: 350
                                                            repeat: false
                                                            onTriggered: {
                                                                var sec = Math.round(lockSlider.currentMinutes) * 60;
                                                                Settings.LockService.setTimeout(sec);
                                                            }
                                                        }

                                                        Rectangle {
                                                            id: sliderTrack
                                                            anchors.left: parent.left
                                                            anchors.right: parent.right
                                                            anchors.verticalCenter: parent.verticalCenter
                                                            height: 8
                                                            radius: 4
                                                            color: Root.Theme.sliderTrack

                                                            Rectangle {
                                                                id: sliderFill
                                                                height: parent.height
                                                                radius: 4
                                                                color: Root.Theme.primary
                                                                width: Math.max(0, Math.min(parent.width, parent.width * ((lockSlider.currentMinutes - lockSlider.minMinutes) / (lockSlider.maxMinutes - lockSlider.minMinutes))))
                                                            }

                                                            // Handle knob
                                                            Rectangle {
                                                                id: sliderThumb
                                                                width: 20
                                                                height: 20
                                                                radius: 10
                                                                anchors.verticalCenter: parent.verticalCenter
                                                                x: Math.max(0, Math.min(parent.width - width, sliderFill.width - (width / 2)))
                                                                color: Root.Theme.sliderThumb
                                                                border.width: 3
                                                                border.color: Root.Theme.primary

                                                                Rectangle {
                                                                    anchors.fill: parent
                                                                    radius: 10
                                                                    color: Qt.rgba(Root.Theme.primary.r, Root.Theme.primary.g, Root.Theme.primary.b, 0.2)
                                                                    scale: sliderMouseArea.drag.active ? 1.6 : (sliderMouseArea.containsMouse ? 1.3 : 1.0)
                                                                    Behavior on scale { NumberAnimation { duration: 150 } }
                                                                }
                                                            }
                                                        }

                                                        MouseArea {
                                                            id: sliderMouseArea
                                                            anchors.fill: parent
                                                            hoverEnabled: true
                                                            cursorShape: Qt.PointingHandCursor

                                                            function updateFromMouse(mouseX) {
                                                                var norm = Math.max(0.0, Math.min(1.0, mouseX / width));
                                                                var mins = Math.round(lockSlider.minMinutes + norm * (lockSlider.maxMinutes - lockSlider.minMinutes));
                                                                lockSlider.currentMinutes = mins;
                                                                sliderDebounceTimer.restart();
                                                            }

                                                            onPressed: (mouse) => updateFromMouse(mouse.x)
                                                            onPositionChanged: (mouse) => {
                                                                if (pressed) updateFromMouse(mouse.x);
                                                            }
                                                        }
                                                    }

                                                    RowLayout {
                                                        Layout.fillWidth: true
                                                        Text {
                                                            text: "1 min"
                                                            font.family: Root.Theme.fontFamily
                                                            font.pixelSize: 11
                                                            color: Root.Theme.textSecondary
                                                        }
                                                        Item { Layout.fillWidth: true }
                                                        Text {
                                                            text: "30 min"
                                                            font.family: Root.Theme.fontFamily
                                                            font.pixelSize: 11
                                                            color: Root.Theme.textSecondary
                                                        }
                                                        Item { Layout.fillWidth: true }
                                                        Text {
                                                            text: "60 min"
                                                            font.family: Root.Theme.fontFamily
                                                            font.pixelSize: 11
                                                            color: Root.Theme.textSecondary
                                                        }
                                                    }
                                                }
                                            }
                                        }

                                        // ── Info & Hints Card ──
                                        Rectangle {
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 74
                                            radius: 20
                                            color: Root.Theme.surfaceContainer
                                            border.width: 1
                                            border.color: Qt.rgba(255, 255, 255, 0.06)

                                            RowLayout {
                                                anchors.fill: parent
                                                anchors.margins: 18
                                                spacing: 14

                                                Rectangle {
                                                    Layout.preferredWidth: 38
                                                    Layout.preferredHeight: 38
                                                    radius: 19
                                                    color: Root.Theme.surfaceContainerHigh

                                                    Text {
                                                        anchors.centerIn: parent
                                                        text: "info"
                                                        font.family: Root.Theme.iconFont
                                                        font.pixelSize: 20
                                                        color: Root.Theme.primary
                                                    }
                                                }

                                                ColumnLayout {
                                                    Layout.fillWidth: true
                                                    spacing: 2

                                                    Text {
                                                        text: "Keyboard Shortcut & Configuration"
                                                        font.family: Root.Theme.fontFamily
                                                        font.pixelSize: 13
                                                        font.weight: Font.DemiBold
                                                        color: Root.Theme.textPrimary
                                                    }

                                                    Text {
                                                        text: "Press Super + L anytime to lock instantly. Configuration synced with ~/.config/hypr/hypridle.conf"
                                                        font.family: Root.Theme.fontFamily
                                                        font.pixelSize: 11
                                                        color: Root.Theme.textSecondary
                                                    }
                                                }
                                            }
                                        }

                                        // Status or saving message toast
                                        RowLayout {
                                            visible: Settings.LockService.isSaving || Settings.LockService.statusMessage !== ""
                                            spacing: 8
                                            Layout.fillWidth: true

                                            Text {
                                                text: Settings.LockService.isSaving ? "hourglass_top" : "check_circle"
                                                font.family: Root.Theme.iconFont
                                                font.pixelSize: 16
                                                color: Root.Theme.primary
                                            }

                                            Text {
                                                text: Settings.LockService.isSaving ? "Updating hypridle daemon..." : Settings.LockService.statusMessage
                                                font.family: Root.Theme.fontFamily
                                                font.pixelSize: 12
                                                font.weight: Font.Medium
                                                color: Root.Theme.primary
                                                Layout.fillWidth: true
                                            }
                                        }
                                    }

                                    // ════════════════════════════════════════════════
                                    // WEATHER & LOCATION SECTION
                                    // ════════════════════════════════════════════════
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 20
                                        visible: settingsRoot.currentSection === "weather"

                                        // Section Header
                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 4

                                            Text {
                                                text: "Weather & Location"
                                                font.family: Root.Theme.fontFamily
                                                font.pixelSize: 22
                                                font.weight: Font.Bold
                                                color: Root.Theme.textPrimary
                                            }

                                            Text {
                                                text: "Set your city and how you want it to appear"
                                                font.family: Root.Theme.fontFamily
                                                font.pixelSize: 13
                                                color: Root.Theme.textSecondary
                                            }
                                        }

                                        // ── Live Preview Card ──
                                        Rectangle {
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 90
                                            radius: 20
                                            color: Root.Theme.surfaceContainer
                                            border.width: 1
                                            border.color: Qt.rgba(255, 255, 255, 0.08)

                                            RowLayout {
                                                anchors.fill: parent
                                                anchors.margins: 18
                                                spacing: 16

                                                Rectangle {
                                                    Layout.preferredWidth: 48
                                                    Layout.preferredHeight: 48
                                                    radius: 24
                                                    color: Qt.rgba(Root.Theme.primary.r, Root.Theme.primary.g, Root.Theme.primary.b, 0.2)

                                                    Text {
                                                        anchors.centerIn: parent
                                                        text: "wb_sunny"
                                                        font.family: Root.Theme.iconFont
                                                        font.pixelSize: 26
                                                        color: Root.Theme.primary
                                                    }
                                                }

                                                ColumnLayout {
                                                    Layout.fillWidth: true
                                                    spacing: 4

                                                    RowLayout {
                                                        spacing: 8

                                                        Text {
                                                            text: {
                                                                var lbl = weatherLabelInput.text.trim();
                                                                if (lbl !== "") return lbl.toUpperCase();
                                                                var city = weatherCityInput.text.trim();
                                                                if (city.indexOf(",") !== -1) return city.split(",")[0].trim().toUpperCase();
                                                                return (city || "LOCATION").toUpperCase();
                                                            }
                                                            font.family: Root.Theme.fontFamily
                                                            font.pixelSize: 17
                                                            font.weight: Font.Bold
                                                            color: Root.Theme.textPrimary
                                                        }

                                                        Rectangle {
                                                            Layout.preferredHeight: 18
                                                            Layout.preferredWidth: weatherLabelInput.text.trim() !== "" ? 64 : 64
                                                            radius: 9
                                                            color: weatherLabelInput.text.trim() !== ""
                                                                ? Qt.rgba(Root.Theme.primary.r, Root.Theme.primary.g, Root.Theme.primary.b, 0.2)
                                                                : Root.Theme.surfaceContainerHigh

                                                            Text {
                                                                anchors.centerIn: parent
                                                                text: weatherLabelInput.text.trim() !== "" ? "CUSTOM" : "DEFAULT"
                                                                font.family: Root.Theme.fontFamily
                                                                font.pixelSize: 9
                                                                font.weight: Font.Bold
                                                                color: weatherLabelInput.text.trim() !== "" ? Root.Theme.primary : Root.Theme.textSecondary
                                                            }
                                                        }
                                                    }

                                                    Text {
                                                        text: "Source: " + (weatherCityInput.text.trim() || "Cali, Colombia")
                                                        font.family: Root.Theme.fontFamily
                                                        font.pixelSize: 12
                                                        color: Root.Theme.textSecondary
                                                    }
                                                }
                                            }
                                        }

                                        // ── Real Queried Location Card ──
                                        Rectangle {
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: realLocCol.height + 36
                                            radius: 20
                                            color: Root.Theme.surfaceContainer
                                            border.width: 1
                                            border.color: Qt.rgba(255, 255, 255, 0.06)

                                            ColumnLayout {
                                                id: realLocCol
                                                anchors.top: parent.top
                                                anchors.left: parent.left
                                                anchors.right: parent.right
                                                anchors.margins: 18
                                                spacing: 14

                                                RowLayout {
                                                    Layout.fillWidth: true
                                                    spacing: 12

                                                    Rectangle {
                                                        Layout.preferredWidth: 38
                                                        Layout.preferredHeight: 38
                                                        radius: 19
                                                        color: Root.Theme.surfaceContainerHigh

                                                        Text {
                                                            anchors.centerIn: parent
                                                            text: "location_on"
                                                            font.family: Root.Theme.iconFont
                                                            font.pixelSize: 20
                                                            color: Root.Theme.primary
                                                        }
                                                    }

                                                    ColumnLayout {
                                                        Layout.fillWidth: true
                                                        spacing: 2

                                                        Text {
                                                            text: "Location"
                                                            font.family: Root.Theme.fontFamily
                                                            font.pixelSize: 15
                                                            font.weight: Font.DemiBold
                                                            color: Root.Theme.textPrimary
                                                        }

                                                        Text {
                                                            text: "City used for weather forecasts"
                                                            font.family: Root.Theme.fontFamily
                                                            font.pixelSize: 12
                                                            color: Root.Theme.textSecondary
                                                        }
                                                    }
                                                }

                                                // City Input Row
                                                Rectangle {
                                                    Layout.fillWidth: true
                                                    Layout.preferredHeight: 46
                                                    radius: 14
                                                    color: Root.Theme.surfaceContainerHigh
                                                    border.width: (weatherCityInput.activeFocus || Settings.WeatherService.isError) ? 2 : 1
                                                    border.color: Settings.WeatherService.isError
                                                        ? Root.Theme.error
                                                        : (weatherCityInput.activeFocus ? Root.Theme.primary : Qt.rgba(255, 255, 255, 0.08))

                                                    Timer {
                                                        id: searchDebounceTimer
                                                        interval: 350
                                                        repeat: false
                                                        onTriggered: {
                                                            if (!weatherCityInput.suppressSearch) {
                                                                Settings.WeatherService.search(weatherCityInput.text);
                                                            }
                                                        }
                                                    }

                                                    RowLayout {
                                                        anchors.fill: parent
                                                        anchors.leftMargin: 14
                                                        anchors.rightMargin: 14
                                                        spacing: 10

                                                        Text {
                                                            text: Settings.WeatherService.isSearching ? "sync" : "travel_explore"
                                                            font.family: Root.Theme.iconFont
                                                            font.pixelSize: 18
                                                            color: Settings.WeatherService.isError ? Root.Theme.error : (Settings.WeatherService.isSearching ? Root.Theme.primary : Root.Theme.textSecondary)

                                                            RotationAnimation on rotation {
                                                                running: Settings.WeatherService.isSearching
                                                                loops: Animation.Infinite
                                                                from: 0
                                                                to: 360
                                                                duration: 900
                                                            }
                                                        }

                                                        TextInput {
                                                            id: weatherCityInput
                                                            property bool suppressSearch: false
                                                            Layout.fillWidth: true
                                                            text: Settings.WeatherService.realLocation
                                                            color: Root.Theme.textPrimary
                                                            font.family: Root.Theme.fontFamily
                                                            font.pixelSize: 14
                                                            verticalAlignment: TextInput.AlignVCenter
                                                            selectByMouse: true
                                                            onTextChanged: {
                                                                if (Settings.WeatherService.isError) {
                                                                    Settings.WeatherService.isError = false;
                                                                    Settings.WeatherService.errorMessage = "";
                                                                }
                                                                if (!suppressSearch && activeFocus) {
                                                                    searchDebounceTimer.restart();
                                                                }
                                                            }
                                                        }

                                                        // Clear or close search button
                                                        Rectangle {
                                                            visible: weatherCityInput.text.length > 0 || Settings.WeatherService.searchResults.length > 0
                                                            Layout.preferredWidth: 26
                                                            Layout.preferredHeight: 26
                                                            radius: 13
                                                            color: clearCityMouse.containsMouse ? Root.Theme.surfaceContainerHighest : "transparent"

                                                            Text {
                                                                anchors.centerIn: parent
                                                                text: "close"
                                                                font.family: Root.Theme.iconFont
                                                                font.pixelSize: 16
                                                                color: Root.Theme.textSecondary
                                                            }

                                                            MouseArea {
                                                                id: clearCityMouse
                                                                anchors.fill: parent
                                                                hoverEnabled: true
                                                                cursorShape: Qt.PointingHandCursor
                                                                onClicked: {
                                                                    Settings.WeatherService.clearSearch();
                                                                    weatherCityInput.text = "";
                                                                    weatherCityInput.forceActiveFocus();
                                                                }
                                                            }
                                                        }
                                                    }
                                                }

                                                // Search Results Dropdown / Picker List
                                                ColumnLayout {
                                                    visible: Settings.WeatherService.searchResults.length > 0
                                                    Layout.fillWidth: true
                                                    spacing: 4

                                                    Repeater {
                                                        model: Settings.WeatherService.searchResults

                                                        delegate: Rectangle {
                                                            id: searchResItem
                                                            Layout.fillWidth: true
                                                            Layout.preferredHeight: 48
                                                            radius: 12
                                                            color: searchResMouse.containsMouse ? Root.Theme.surfaceContainerHighest : Qt.rgba(255, 255, 255, 0.03)
                                                            border.width: 1
                                                            border.color: searchResMouse.containsMouse ? Root.Theme.primary : Qt.rgba(255, 255, 255, 0.06)

                                                            Behavior on color { ColorAnimation { duration: 120 } }
                                                            Behavior on border.color { ColorAnimation { duration: 120 } }

                                                            RowLayout {
                                                                anchors.fill: parent
                                                                anchors.leftMargin: 12
                                                                anchors.rightMargin: 12
                                                                spacing: 12

                                                                Text {
                                                                    text: "location_on"
                                                                    font.family: Root.Theme.iconFont
                                                                    font.pixelSize: 18
                                                                    color: searchResMouse.containsMouse ? Root.Theme.primary : Root.Theme.textSecondary
                                                                }

                                                                ColumnLayout {
                                                                    Layout.fillWidth: true
                                                                    spacing: 1

                                                                    Text {
                                                                        text: modelData.name
                                                                        font.family: Root.Theme.fontFamily
                                                                        font.pixelSize: 13
                                                                        font.weight: Font.DemiBold
                                                                        color: Root.Theme.textPrimary
                                                                    }

                                                                    Text {
                                                                        text: modelData.display
                                                                        font.family: Root.Theme.fontFamily
                                                                        font.pixelSize: 11
                                                                        color: Root.Theme.textSecondary
                                                                        elide: Text.ElideRight
                                                                        Layout.fillWidth: true
                                                                    }
                                                                }

                                                                Text {
                                                                    text: "check"
                                                                    font.family: Root.Theme.iconFont
                                                                    font.pixelSize: 16
                                                                    color: Root.Theme.primary
                                                                    visible: searchResMouse.containsMouse
                                                                }
                                                            }

                                                            MouseArea {
                                                                id: searchResMouse
                                                                anchors.fill: parent
                                                                hoverEnabled: true
                                                                cursorShape: Qt.PointingHandCursor
                                                                onClicked: {
                                                                    weatherCityInput.suppressSearch = true;
                                                                    weatherCityInput.text = modelData.query;
                                                                    weatherCityInput.suppressSearch = false;
                                                                    Settings.WeatherService.clearSearch();
                                                                }
                                                            }
                                                        }
                                                    }
                                                }

                                                // Error alert banner if location not found
                                                RowLayout {
                                                    visible: Settings.WeatherService.isError
                                                    spacing: 8
                                                    Layout.fillWidth: true

                                                    Text {
                                                        text: "error"
                                                        font.family: Root.Theme.iconFont
                                                        font.pixelSize: 16
                                                        color: Root.Theme.error
                                                    }

                                                    Text {
                                                        text: Settings.WeatherService.errorMessage
                                                        font.family: Root.Theme.fontFamily
                                                        font.pixelSize: 12
                                                        font.weight: Font.Medium
                                                        color: Root.Theme.error
                                                        Layout.fillWidth: true
                                                        wrapMode: Text.Wrap
                                                    }
                                                }
                                            }
                                        }

                                        // ── Custom Display Label Card ──
                                        Rectangle {
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: customLabelCol.height + 36
                                            radius: 20
                                            color: Root.Theme.surfaceContainer
                                            border.width: 1
                                            border.color: Qt.rgba(255, 255, 255, 0.06)

                                            ColumnLayout {
                                                id: customLabelCol
                                                anchors.top: parent.top
                                                anchors.left: parent.left
                                                anchors.right: parent.right
                                                anchors.margins: 18
                                                spacing: 14

                                                RowLayout {
                                                    Layout.fillWidth: true
                                                    spacing: 12

                                                    Rectangle {
                                                        Layout.preferredWidth: 38
                                                        Layout.preferredHeight: 38
                                                        radius: 19
                                                        color: Root.Theme.surfaceContainerHigh

                                                        Text {
                                                            anchors.centerIn: parent
                                                            text: "edit_note"
                                                            font.family: Root.Theme.iconFont
                                                            font.pixelSize: 20
                                                            color: Root.Theme.primary
                                                        }
                                                    }

                                                    ColumnLayout {
                                                        Layout.fillWidth: true
                                                        spacing: 2

                                                        Text {
                                                            text: "Display Name"
                                                            font.family: Root.Theme.fontFamily
                                                            font.pixelSize: 15
                                                            font.weight: Font.DemiBold
                                                            color: Root.Theme.textPrimary
                                                        }

                                                        Text {
                                                            text: "Optional name shown on your desktop"
                                                            font.family: Root.Theme.fontFamily
                                                            font.pixelSize: 12
                                                            color: Root.Theme.textSecondary
                                                        }
                                                    }
                                                }

                                                // Custom Label Input Row
                                                Rectangle {
                                                    Layout.fillWidth: true
                                                    Layout.preferredHeight: 46
                                                    radius: 14
                                                    color: Root.Theme.surfaceContainerHigh
                                                    border.width: weatherLabelInput.activeFocus ? 2 : 1
                                                    border.color: weatherLabelInput.activeFocus ? Root.Theme.primary : Qt.rgba(255, 255, 255, 0.08)

                                                    RowLayout {
                                                        anchors.fill: parent
                                                        anchors.leftMargin: 14
                                                        anchors.rightMargin: 14
                                                        spacing: 10

                                                        Text {
                                                            text: "label"
                                                            font.family: Root.Theme.iconFont
                                                            font.pixelSize: 18
                                                            color: Root.Theme.textSecondary
                                                        }

                                                        TextInput {
                                                            id: weatherLabelInput
                                                            Layout.fillWidth: true
                                                            text: Settings.WeatherService.customLabel
                                                            color: Root.Theme.textPrimary
                                                            font.family: Root.Theme.fontFamily
                                                            font.pixelSize: 14
                                                            verticalAlignment: TextInput.AlignVCenter
                                                            selectByMouse: true
                                                        }

                                                        // Clear label button if text present
                                                        Rectangle {
                                                            visible: weatherLabelInput.text.length > 0
                                                            Layout.preferredWidth: 26
                                                            Layout.preferredHeight: 26
                                                            radius: 13
                                                            color: clearMouse.containsMouse ? Root.Theme.surfaceContainerHighest : "transparent"

                                                            Text {
                                                                anchors.centerIn: parent
                                                                text: "close"
                                                                font.family: Root.Theme.iconFont
                                                                font.pixelSize: 16
                                                                color: Root.Theme.textSecondary
                                                            }

                                                            MouseArea {
                                                                id: clearMouse
                                                                anchors.fill: parent
                                                                hoverEnabled: true
                                                                cursorShape: Qt.PointingHandCursor
                                                                onClicked: weatherLabelInput.text = ""
                                                            }
                                                        }
                                                    }
                                                }

                                                // Dynamic Explanation Text
                                                RowLayout {
                                                    spacing: 6

                                                    Text {
                                                        text: "visibility"
                                                        font.family: Root.Theme.iconFont
                                                        font.pixelSize: 16
                                                        color: Root.Theme.textSecondary
                                                    }

                                                    Text {
                                                        text: {
                                                            var lbl = weatherLabelInput.text.trim();
                                                            var name = lbl !== "" ? lbl : (weatherCityInput.text.trim().split(",")[0] || "City");
                                                            return "Appears as: " + name;
                                                        }
                                                        font.family: Root.Theme.fontFamily
                                                        font.pixelSize: 12
                                                        color: Root.Theme.textSecondary
                                                    }
                                                }
                                            }
                                        }

                                        // ── Action Buttons Row ──
                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 12

                                            // Save Changes Button
                                            Rectangle {
                                                Layout.preferredHeight: 46
                                                Layout.preferredWidth: 120
                                                radius: 23
                                                color: saveLocMouse.containsMouse
                                                    ? Qt.rgba(Root.Theme.primary.r, Root.Theme.primary.g, Root.Theme.primary.b, 0.85)
                                                    : Root.Theme.primary

                                                RowLayout {
                                                    anchors.centerIn: parent
                                                    spacing: 8

                                                    Text {
                                                        text: Settings.WeatherService.isSaving ? "hourglass_top" : "check"
                                                        font.family: Root.Theme.iconFont
                                                        font.pixelSize: 18
                                                        color: Root.Theme.onPrimary
                                                    }

                                                    Text {
                                                        text: Settings.WeatherService.isSaving ? "Saving..." : "Save"
                                                        font.family: Root.Theme.fontFamily
                                                        font.pixelSize: 14
                                                        font.weight: Font.DemiBold
                                                        color: Root.Theme.onPrimary
                                                    }
                                                }

                                                MouseArea {
                                                    id: saveLocMouse
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    enabled: !Settings.WeatherService.isSaving
                                                    onClicked: {
                                                        Settings.WeatherService.saveLocation(weatherCityInput.text, weatherLabelInput.text);
                                                    }
                                                }
                                            }

                                            // Refresh Now Button
                                            Rectangle {
                                                Layout.preferredHeight: 46
                                                Layout.preferredWidth: 120
                                                radius: 23
                                                color: refreshLocMouse.containsMouse ? Root.Theme.surfaceContainerHighest : Root.Theme.surfaceContainerHigh
                                                border.width: 1
                                                border.color: Qt.rgba(255, 255, 255, 0.08)

                                                RowLayout {
                                                    anchors.centerIn: parent
                                                    spacing: 8

                                                    Text {
                                                        text: "refresh"
                                                        font.family: Root.Theme.iconFont
                                                        font.pixelSize: 18
                                                        color: Root.Theme.textPrimary
                                                    }

                                                    Text {
                                                        text: "Refresh"
                                                        font.family: Root.Theme.fontFamily
                                                        font.pixelSize: 14
                                                        font.weight: Font.Medium
                                                        color: Root.Theme.textPrimary
                                                    }
                                                }

                                                MouseArea {
                                                    id: refreshLocMouse
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    enabled: !Settings.WeatherService.isSaving
                                                    onClicked: {
                                                        Settings.WeatherService.refreshNow();
                                                    }
                                                }
                                            }

                                            // Status or error text indicator
                                            RowLayout {
                                                visible: Settings.WeatherService.statusMessage !== "" || Settings.WeatherService.isError
                                                spacing: 6
                                                Layout.leftMargin: 8

                                                Text {
                                                    text: Settings.WeatherService.isError ? "error" : "check_circle"
                                                    font.family: Root.Theme.iconFont
                                                    font.pixelSize: 16
                                                    color: Settings.WeatherService.isError ? Root.Theme.error : Root.Theme.primary
                                                }

                                                Text {
                                                    text: Settings.WeatherService.isError ? Settings.WeatherService.errorMessage : Settings.WeatherService.statusMessage
                                                    font.family: Root.Theme.fontFamily
                                                    font.pixelSize: 13
                                                    color: Settings.WeatherService.isError ? Root.Theme.error : Root.Theme.primary
                                                }
                                            }

                                            Item { Layout.fillWidth: true }
                                        }
                                    }

                                    // ════════════════════════════════════════════════
                                    // ABOUT SECTION
                                    // ════════════════════════════════════════════════
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 20
                                        visible: settingsRoot.currentSection === "about"

                                        // Section Header
                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 4

                                            Text {
                                                text: "About Device"
                                                font.family: Root.Theme.fontFamily
                                                font.pixelSize: 22
                                                font.weight: Font.Bold
                                                color: Root.Theme.textPrimary
                                            }

                                            Text {
                                                text: "Hardware specifications and system details"
                                                font.family: Root.Theme.fontFamily
                                                font.pixelSize: 13
                                                color: Root.Theme.textSecondary
                                            }
                                        }

                                        // Hero Device Card
                                        Rectangle {
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 84
                                            radius: 20
                                            color: Root.Theme.surfaceContainer
                                            border.width: 1
                                            border.color: Qt.rgba(255, 255, 255, 0.06)

                                            RowLayout {
                                                anchors.fill: parent
                                                anchors.margins: 18
                                                spacing: 16

                                                Rectangle {
                                                    Layout.preferredWidth: 48
                                                    Layout.preferredHeight: 48
                                                    radius: 24
                                                    color: Qt.rgba(Root.Theme.primary.r, Root.Theme.primary.g, Root.Theme.primary.b, 0.16)

                                                    Text {
                                                        anchors.centerIn: parent
                                                        text: "laptop_chromebook"
                                                        font.family: Root.Theme.iconFont
                                                        font.pixelSize: 24
                                                        color: Root.Theme.primary
                                                    }
                                                }

                                                ColumnLayout {
                                                    Layout.fillWidth: true
                                                    spacing: 3

                                                    Text {
                                                        text: Settings.SystemService.hostname
                                                        font.family: Root.Theme.fontFamily
                                                        font.pixelSize: 17
                                                        font.weight: Font.Bold
                                                        color: Root.Theme.textPrimary
                                                    }

                                                    Text {
                                                        text: Settings.SystemService.osName + " • Hyprland"
                                                        font.family: Root.Theme.fontFamily
                                                        font.pixelSize: 13
                                                        color: Root.Theme.textSecondary
                                                    }
                                                }
                                            }
                                        }

                                        // Specifications Card
                                        Rectangle {
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: specsList.height + 20
                                            radius: 20
                                            color: Root.Theme.surfaceContainer
                                            border.width: 1
                                            border.color: Qt.rgba(255, 255, 255, 0.06)

                                            ColumnLayout {
                                                id: specsList
                                                anchors.top: parent.top
                                                anchors.left: parent.left
                                                anchors.right: parent.right
                                                anchors.margins: 10
                                                spacing: 2

                                                Repeater {
                                                    model: [
                                                        { icon: "memory", label: "Memory (RAM)", key: "ram" },
                                                        { icon: "developer_board", label: "Processor", key: "cpu" },
                                                        { icon: "layers", label: "Operating System", key: "os" },
                                                        { icon: "terminal", label: "Kernel", key: "kernel" },
                                                        { icon: "inventory_2", label: "Installed Packages", key: "packages" }
                                                    ]

                                                    delegate: Rectangle {
                                                        Layout.fillWidth: true
                                                        Layout.preferredHeight: 52
                                                        radius: 12
                                                        color: rowHover.containsMouse ? Qt.rgba(255, 255, 255, 0.03) : "transparent"

                                                        MouseArea {
                                                            id: rowHover
                                                            anchors.fill: parent
                                                            hoverEnabled: true
                                                        }

                                                        RowLayout {
                                                            anchors.fill: parent
                                                            anchors.leftMargin: 12
                                                            anchors.rightMargin: 12
                                                            spacing: 14

                                                            Rectangle {
                                                                Layout.preferredWidth: 34
                                                                Layout.preferredHeight: 34
                                                                radius: 17
                                                                color: Root.Theme.surfaceContainerHigh

                                                                Text {
                                                                    anchors.centerIn: parent
                                                                    text: modelData.icon
                                                                    font.family: Root.Theme.iconFont
                                                                    font.pixelSize: 18
                                                                    color: Root.Theme.primary
                                                                }
                                                            }

                                                            ColumnLayout {
                                                                Layout.fillWidth: true
                                                                spacing: 1

                                                                Text {
                                                                    text: modelData.label
                                                                    font.family: Root.Theme.fontFamily
                                                                    font.pixelSize: 11
                                                                    color: Root.Theme.textSecondary
                                                                }

                                                                Text {
                                                                    Layout.fillWidth: true
                                                                    text: {
                                                                        if (modelData.key === "ram") return Settings.SystemService.ram;
                                                                        if (modelData.key === "cpu") return Settings.SystemService.cpu;
                                                                        if (modelData.key === "os") return Settings.SystemService.osName;
                                                                        if (modelData.key === "kernel") return Settings.SystemService.kernel;
                                                                        if (modelData.key === "packages") return Settings.SystemService.packages;
                                                                        return "";
                                                                    }
                                                                    font.family: Root.Theme.fontFamily
                                                                    font.pixelSize: 13
                                                                    font.weight: Font.Medium
                                                                    color: Root.Theme.textPrimary
                                                                    elide: Text.ElideRight
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
                }
            }
        }
    }
}
