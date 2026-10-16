import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../.." as Root

Item {
    id: wallpaperPanel
    signal back()

    property string wallpaperDir: "/home/zero/Pictures/walls/"
    property string cacheDir: "/home/zero/.cache/wallpapers/"
    property bool loading: true

    ListModel { id: wallpaperModel }

    // Asegura que las miniaturas cacheadas existan antes de listar. Es rápido
    // (idempotente): solo regenera las que faltan o están desactualizadas.
    Process {
        id: cacheProc
        command: ["/home/zero/.config/themes/update-wallpaper-cache.sh", wallpaperPanel.wallpaperDir]
        onExited: (exitCode, exitStatus) => {
            listProc.running = true;
        }
    }

    Process {
        id: listProc
        command: ["find", wallpaperPanel.wallpaperDir, "-maxdepth", "1", "-type", "f",
            "(", "-iname", "*.jpg", "-o", "-iname", "*.jpeg", "-o", "-iname", "*.png",
            "-o", "-iname", "*.gif", "-o", "-iname", "*.bmp", "-o", "-iname", "*.webp", ")"]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.trim().split("\n");
                wallpaperModel.clear();
                for (var i = 0; i < lines.length; i++) {
                    var file = lines[i].trim();
                    if (file !== "") {
                        // Miniatura cacheada correspondiente a este wallpaper.
                        var base = file.split("/").pop();
                        wallpaperModel.append({
                            path: file,
                            thumb: wallpaperPanel.cacheDir + base + ".jpg"
                        });
                    }
                }
                loading = false;
            }
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) loading = false;
        }
    }

    Process {
        id: setProc
    }

    Process {
        id: matugenProc
    }

    function setWallpaper(path) {
        setProc.command = ["/bin/sh", "-c",
            "killall swaybg 2>/dev/null; nohup swaybg -o eDP-1 -i '" + path + "' -m fill >/dev/null 2>&1 &"];
        setProc.running = true;

        matugenProc.command = ["/home/zero/.config/themes/apply-matugen.sh", path];
        matugenProc.running = true;
    }

    Component.onCompleted: {
        loading = true;
        cacheProc.running = true;
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Header
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 64

            Rectangle { anchors.fill: parent; radius: Root.Theme.panelRadius; color: Root.Theme.surface }
            Rectangle { anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; height: Root.Theme.panelRadius; color: Root.Theme.surface }

            RowLayout {
                anchors.fill: parent; anchors.leftMargin: Root.Theme.paddingNormal; anchors.rightMargin: Root.Theme.paddingNormal; spacing: 8

                Rectangle {
                    width: 38; height: 38; radius: Root.Theme.radiusSmall
                    color: backArea.containsMouse ? Root.Theme.surfaceContainerHigh : "transparent"
                    Text {
                        anchors.centerIn: parent
                        text: "󰁍"
                        color: Root.Theme.textPrimary
                        font.family: Root.Theme.fontFamily; font.pixelSize: 18
                    }
                    MouseArea {
                        id: backArea; anchors.fill: parent; hoverEnabled: true
                        onClicked: wallpaperPanel.back()
                    }
                }

                Text {
                    text: "Wallpaper"
                    color: Root.Theme.textPrimary
                    font.family: Root.Theme.fontFamily; font.pixelSize: 18; font.weight: Font.DemiBold
                    Layout.fillWidth: true
                }
            }

            Rectangle { anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; height: 1; color: Root.Theme.surfaceContainerHigh }
        }

        // Loading state
        Text {
            visible: loading
            text: "Loading..."
            font.family: Root.Theme.fontFamily; font.pixelSize: Root.Theme.fontSizeNormal
            color: Root.Theme.textSecondary
            Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; Layout.topMargin: 40
        }

        // Empty state
        Text {
            visible: !loading && wallpaperModel.count === 0
            text: "No wallpapers found"
            font.family: Root.Theme.fontFamily; font.pixelSize: Root.Theme.fontSizeNormal
            color: Root.Theme.textSecondary
            Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; Layout.topMargin: 40
        }

        // Wallpaper list
        ListView {
            id: wallList
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: !loading && wallpaperModel.count > 0
            clip: true
            model: wallpaperModel
            spacing: 8
            cacheBuffer: 200
            leftMargin: Root.Theme.paddingNormal
            rightMargin: Root.Theme.paddingNormal
            topMargin: Root.Theme.paddingNormal
            bottomMargin: Root.Theme.paddingNormal

            delegate: Item {
                required property string path
                required property string thumb
                width: wallList.width - Root.Theme.paddingNormal * 2
                height: 72

                Rectangle {
                    anchors.fill: parent
                    radius: Root.Theme.radiusSmall
                    color: wpArea.containsMouse
                        ? Root.Theme.surfaceContainerHigh
                        : Root.Theme.surfaceContainer
                    border.width: 1
                    border.color: wpArea.containsMouse
                        ? Root.Theme.surfaceBright
                        : "transparent"
                    Behavior on color { ColorAnimation { duration: Root.Theme.animDurationFast } }

                    RowLayout {
                        anchors.fill: parent; anchors.margins: 6; spacing: 12

                        Rectangle {
                            width: 96; height: 60; radius: 8; clip: true
                            color: Root.Theme.surface
                            Image {
                                anchors.fill: parent
                                source: "file://" + thumb
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            spacing: 2

                            Text {
                                text: path.split("/").pop()
                                font.family: Root.Theme.fontFamily
                                font.pixelSize: Root.Theme.fontSizeNormal
                                color: Root.Theme.textPrimary
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }
                    }
                }

                MouseArea {
                    id: wpArea; anchors.fill: parent; hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: wallpaperPanel.setWallpaper(path)
                }
            }

            footer: Item { width: 1; height: Root.Theme.paddingNormal }
        }
    }
}
