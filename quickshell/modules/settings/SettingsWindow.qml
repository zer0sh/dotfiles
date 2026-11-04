import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../.." as Root
import "." as Settings

Scope {
    id: settingsRoot

    property bool visible: false
    property string currentSection: "profile"

    readonly property var sections: [
        { id: "profile", label: "Profile", icon: "person", desc: "Account and avatar" },
        { id: "theme", label: "Theme & Style", icon: "palette", desc: "Colors, Matugen and presets" },
        { id: "about", label: "About", icon: "info", desc: "System specifications" }
    ]

    onVisibleChanged: {
        if (visible) {
            Settings.SystemService.refresh();
        }
    }

    function toggle() {
        visible = !visible;
    }

    Loader {
        active: settingsRoot.visible

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
                onActivated: settingsRoot.visible = false
            }

            // Fondo oscuro / Backdrop clickeable para cerrar
            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(0, 0, 0, 0.5)
                visible: !Settings.ProfileService.isUpdatingAvatar

                MouseArea {
                    anchors.fill: parent
                    enabled: !Settings.ProfileService.isUpdatingAvatar
                    onClicked: settingsRoot.visible = false
                }
            }

            // Ventana Principal estilo Pixel / Material You
            Rectangle {
                id: dialogBox
                anchors.centerIn: parent
                width: Math.min(880, settingsWindow.width - 48)
                height: Math.min(560, settingsWindow.height - 48)
                radius: 28

                color: Root.Theme.surface
                border.width: 1
                border.color: Qt.rgba(255, 255, 255, 0.12)
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
                        onClicked: settingsRoot.visible = false
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
                                                            text: "Choose a signature color dot or enter your own custom hex value"
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

                                                // Custom Hex Color Input Row
                                                RowLayout {
                                                    Layout.fillWidth: true
                                                    spacing: 12

                                                    // Current color indicator
                                                    Rectangle {
                                                        Layout.preferredWidth: 38
                                                        Layout.preferredHeight: 38
                                                        radius: 19
                                                        color: {
                                                            var c = customHexInput.text.trim();
                                                            return (c.charAt(0) === "#" && (c.length === 7 || c.length === 4)) ? c : Settings.ThemeService.customAccent;
                                                        }
                                                        border.width: 2
                                                        border.color: Qt.rgba(255, 255, 255, 0.3)
                                                    }

                                                    Rectangle {
                                                        Layout.fillWidth: true
                                                        Layout.preferredHeight: 44
                                                        radius: 14
                                                        color: Root.Theme.surfaceContainerHigh
                                                        border.width: customHexInput.activeFocus ? 2 : 1
                                                        border.color: customHexInput.activeFocus ? Root.Theme.primary : Qt.rgba(255, 255, 255, 0.08)

                                                        RowLayout {
                                                            anchors.fill: parent
                                                            anchors.leftMargin: 14
                                                            anchors.rightMargin: 14
                                                            spacing: 10

                                                            Text {
                                                                text: "tag"
                                                                font.family: Root.Theme.iconFont
                                                                font.pixelSize: 18
                                                                color: Root.Theme.textSecondary
                                                            }

                                                            TextInput {
                                                                id: customHexInput
                                                                Layout.fillWidth: true
                                                                text: Settings.ThemeService.customAccent
                                                                color: Root.Theme.textPrimary
                                                                font.family: Root.Theme.fontFamily
                                                                font.pixelSize: 14
                                                                verticalAlignment: TextInput.AlignVCenter
                                                                selectByMouse: true
                                                                maximumLength: 7
                                                                onAccepted: {
                                                                    var val = text.trim();
                                                                    if (val.charAt(0) !== "#") val = "#" + val;
                                                                    if (/^#[0-9a-fA-F]{6}$/.test(val)) {
                                                                        Settings.ThemeService.enableCustom(val);
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }

                                                    // Apply Button
                                                    Rectangle {
                                                        Layout.preferredWidth: 100
                                                        Layout.preferredHeight: 44
                                                        radius: 22
                                                        color: applyHexMouse.containsMouse
                                                            ? Qt.rgba(Root.Theme.primary.r, Root.Theme.primary.g, Root.Theme.primary.b, 0.85)
                                                            : Root.Theme.primary

                                                        RowLayout {
                                                            anchors.centerIn: parent
                                                            spacing: 6

                                                            Text {
                                                                text: "check"
                                                                font.family: Root.Theme.iconFont
                                                                font.pixelSize: 18
                                                                color: Root.Theme.onPrimary
                                                            }

                                                            Text {
                                                                text: "Apply"
                                                                font.family: Root.Theme.fontFamily
                                                                font.pixelSize: 13
                                                                font.weight: Font.DemiBold
                                                                color: Root.Theme.onPrimary
                                                            }
                                                        }

                                                        MouseArea {
                                                            id: applyHexMouse
                                                            anchors.fill: parent
                                                            hoverEnabled: true
                                                            cursorShape: Qt.PointingHandCursor
                                                            onClicked: {
                                                                var val = customHexInput.text.trim();
                                                                if (val.charAt(0) !== "#") val = "#" + val;
                                                                if (/^#[0-9a-fA-F]{6}$/.test(val)) {
                                                                    Settings.ThemeService.enableCustom(val);
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
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
