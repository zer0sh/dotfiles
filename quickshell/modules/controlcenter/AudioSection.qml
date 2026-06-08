import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Io
import "../.." as Root

Item {
    id: audioPanel

    signal back()

    property string currentTab: "output"
    property var devices: []
    property string defaultSinkName: ""
    property string defaultSourceName: ""

    Process {
        id: listSinksProc
        command: ["pactl", "list", "short", "sinks"]
        stdout: StdioCollector {
            onStreamFinished: {
                audioPanel.defaultSinkName = ""
                audioPanel.parseDevices(text, "output")
            }
        }
        onExited: {
            getDefaultSinkProc.running = true
        }
    }

    Process {
        id: getDefaultSinkProc
        command: ["pactl", "get-default-sink"]
        stdout: StdioCollector {
            onStreamFinished: {
                audioPanel.defaultSinkName = text.trim()
                audioPanel.markDefault("output")
            }
        }
    }

    Process {
        id: listSourcesProc
        command: ["pactl", "list", "short", "sources"]
        stdout: StdioCollector {
            onStreamFinished: {
                audioPanel.defaultSourceName = ""
                audioPanel.parseDevices(text, "input")
            }
        }
        onExited: {
            getDefaultSourceProc.running = true
        }
    }

    Process {
        id: getDefaultSourceProc
        command: ["pactl", "get-default-source"]
        stdout: StdioCollector {
            onStreamFinished: {
                audioPanel.defaultSourceName = text.trim()
                audioPanel.markDefault("input")
            }
        }
    }

    Process {
        id: setDefaultProc
        stdout: StdioCollector {}
        onExited: (code, status) => { refresh() }
    }

    function parseDevices(output, type) {
        var lines = output.trim().split("\n")
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim()
            if (line === "") continue
            var parts = line.split(/\s+/)
            if (parts.length >= 2) {
                var exists = false
                for (var j = 0; j < audioPanel.devices.length; j++) {
                    if (audioPanel.devices[j].id === parts[0] && audioPanel.devices[j].type === type) {
                        exists = true
                        break
                    }
                }
                if (!exists) {
                    audioPanel.devices.push({ id: parts[0], name: parts[1], type: type, isDefault: false })
                }
            }
        }
        audioPanel.devices = audioPanel.devices
    }

    function markDefault(type) {
        var defName = type === "output" ? audioPanel.defaultSinkName : audioPanel.defaultSourceName
        var list = audioPanel.devices
        for (var i = 0; i < list.length; i++) {
            if (list[i].type === type) {
                list[i].isDefault = (list[i].name === defName || list[i].id === defName)
            }
        }
        audioPanel.devices = list
    }

    function setDefault(name, type) {
        setDefaultProc.command = type === "output"
            ? ["pactl", "set-default-sink", name]
            : ["pactl", "set-default-source", name]
        setDefaultProc.running = true
    }

    function refresh() {
        audioPanel.devices = []
        listSinksProc.running = true
        listSourcesProc.running = true
    }

    Component.onCompleted: refresh()

    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: 20
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 20
            Layout.rightMargin: 20
            Layout.bottomMargin: 12
            spacing: 12

            Text {
                text: "󰓃"
                font.family: Root.Theme.fontFamily
                font.pixelSize: 20
                color: Root.Theme.textPrimary
                Layout.alignment: Qt.AlignVCenter
            }

            Text {
                text: "Audio"
                font.family: Root.Theme.fontFamily
                font.pixelSize: Root.Theme.fontSizeLarge
                font.weight: Font.DemiBold
                color: Root.Theme.textPrimary
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
            }

            Rectangle {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                radius: 16
                color: backBtn.containsMouse ? Root.Theme.surfaceContainerHigh : "transparent"
                Behavior on color { ColorAnimation { duration: 100 } }

                Text {
                    anchors.centerIn: parent
                    text: "󰅁"
                    font.family: Root.Theme.fontFamily
                    font.pixelSize: 18
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

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 12
            Layout.rightMargin: 12
            Layout.bottomMargin: 12
            spacing: 8

            Rectangle {
                Layout.fillWidth: true
                height: 36
                radius: 10
                color: audioPanel.currentTab === "output" ? Root.Theme.primaryContainer : Root.Theme.surfaceContainerHigh
                Behavior on color { ColorAnimation { duration: 100 } }

                Text {
                    anchors.centerIn: parent
                    text: "󰋋  Output"
                    font.family: Root.Theme.fontFamily
                    font.pixelSize: Root.Theme.fontSizeNormal
                    font.weight: audioPanel.currentTab === "output" ? Font.DemiBold : Font.Normal
                    color: audioPanel.currentTab === "output" ? Root.Theme.textOnSecondaryContainer : Root.Theme.textPrimary
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: audioPanel.currentTab = "output"
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 36
                radius: 10
                color: audioPanel.currentTab === "input" ? Root.Theme.primaryContainer : Root.Theme.surfaceContainerHigh
                Behavior on color { ColorAnimation { duration: 100 } }

                Text {
                    anchors.centerIn: parent
                    text: "󰍬  Input"
                    font.family: Root.Theme.fontFamily
                    font.pixelSize: Root.Theme.fontSizeNormal
                    font.weight: audioPanel.currentTab === "input" ? Font.DemiBold : Font.Normal
                    color: audioPanel.currentTab === "input" ? Root.Theme.textOnSecondaryContainer : Root.Theme.textPrimary
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: audioPanel.currentTab = "input"
                }
            }
        }

        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.leftMargin: 12
            Layout.rightMargin: 12
            clip: true
            model: {
                var filtered = []
                var list = audioPanel.devices
                for (var i = 0; i < list.length; i++) {
                    if (list[i].type === audioPanel.currentTab)
                        filtered.push(list[i])
                }
                return filtered
            }

            delegate: Rectangle {
                width: ListView.view.width
                height: 56
                radius: 12
                color: modelData.isDefault ? Root.Theme.primaryContainer : (ma.containsMouse ? Root.Theme.surfaceContainerHigh : "transparent")
                Behavior on color { ColorAnimation { duration: 100 } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 12

                    Text {
                        text: modelData.isDefault ? "󰄕" : "󰄰"
                        font.family: Root.Theme.fontFamily
                        font.pixelSize: 18
                        color: modelData.isDefault ? Root.Theme.primary : Root.Theme.textSecondary
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: modelData.name
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: Root.Theme.fontSizeNormal
                            font.weight: modelData.isDefault ? Font.DemiBold : Font.Normal
                            color: Root.Theme.textPrimary
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    Text {
                        visible: modelData.isDefault
                        text: "Default"
                        font.family: Root.Theme.fontFamily
                        font.pixelSize: Root.Theme.fontSizeXS
                        font.weight: Font.Medium
                        color: Root.Theme.primary
                        Layout.alignment: Qt.AlignVCenter
                    }
                }

                MouseArea {
                    id: ma
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (!modelData.isDefault)
                            audioPanel.setDefault(modelData.name, modelData.type)
                    }
                }
            }
        }
    }
}
