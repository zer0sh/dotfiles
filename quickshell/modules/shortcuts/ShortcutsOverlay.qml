import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../.." as Root

Scope {
    id: shortcuts

    property bool visible: false
    property var binds: []
    property var variables: ({})

    function initVars() {
        variables = {}
        variables["$mainMod"] = "󰻀"
    }

    function parseBinds(output) {
        var lines = output.split("\n")
        var result = []
        var lastComment = ""
        initVars()

        for (var i = 0; i < lines.length; i++) {
            var line = lines[i]

            if (line.charAt(0) === "#") {
                lastComment = line.substring(1).trim()
                continue
            }

            line = line.trim()
            if (line === "") { lastComment = ""; continue }

            if (line.indexOf("=") !== -1 && line.indexOf("bind") === -1 && line.indexOf("bindm") === -1) {
                var eq = line.indexOf("=")
                var varname = line.substring(0, eq).trim()
                var varval = line.substring(eq + 1).trim()
                if (varname.charAt(0) === "$" && varname !== "$mainMod") {
                    variables[varname] = varval
                }
                lastComment = ""
                continue
            }

            if (line.indexOf("bind = ") === 0 || line.indexOf("bind ") === 0) {
                var rest = line.indexOf("=") !== -1 ? line.substring(line.indexOf("=") + 1).trim() : ""
                if (rest === "") { lastComment = ""; continue }

                var parts = []
                var current = ""
                for (var j = 0; j < rest.length; j++) {
                    var ch = rest.charAt(j)
                    if (ch === ",") {
                        parts.push(current.trim())
                        current = ""
                    } else {
                        current += ch
                    }
                }
                if (current.trim() !== "") parts.push(current.trim())

                if (parts.length >= 3) {
                    var mods = resolveVar(parts[0])
                    var key = resolveVar(parts[1])
                    var dispatcher = parts[2]
                    var args = parts.slice(3).join(", ")

                    var displayMods = mods.replace(/ /g, " + ")
                    if (displayMods !== "") displayMods += " + "
                    var displayKey = key

                    var desc = lastComment !== "" ? lastComment : dispatcher + (args !== "" ? " " + args : "")

                    var UNWANTED = ["movefocus", "movewindow", "workspace", "movetoworkspace",
                                    "resizeactive", "mouse_down", "mouse_up"]
                    var skip = false
                    for (var k = 0; k < UNWANTED.length; k++) {
                        if (dispatcher === UNWANTED[k]) { skip = true; break }
                    }
                    if (!skip) {
                        result.push({ key: displayMods + displayKey, desc: desc })
                    }
                }
                lastComment = ""
            }
        }

        binds = result
    }

    function resolveVar(val) {
        return val.replace(/\$[A-Za-z_][A-Za-z0-9_]*/g, function(m) {
            return variables[m] !== undefined ? variables[m] : m
        })
    }

    Process {
        id: bindReader
        command: ["cat", "/home/zero/.config/hypr/binds.conf"]
        stdout: StdioCollector {
            onStreamFinished: {
                shortcuts.parseBinds(text)
            }
        }
    }

    onVisibleChanged: {
        if (visible) bindReader.running = true
    }

    Component.onCompleted: bindReader.running = true

    Loader {
        active: shortcuts.visible

        sourceComponent: PanelWindow {
            id: overlay
            visible: true
            anchors.top: true
            anchors.bottom: true
            anchors.left: true
            anchors.right: true
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "quickshell:shortcuts"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(0, 0, 0, 0.4)

                MouseArea {
                    anchors.fill: parent
                    onClicked: shortcuts.visible = false
                }
            }

            Rectangle {
                anchors.centerIn: parent
                width: 640
                height: Math.min(480, listContent.implicitHeight + 56)
                radius: 20
                color: Qt.rgba(Root.Theme.panelBg.r, Root.Theme.panelBg.g, Root.Theme.panelBg.b, 0.88)
                border.color: Root.Theme.panelBorder
                border.width: 1

                MouseArea { anchors.fill: parent }

                ColumnLayout {
                    id: listContent
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 24
                    spacing: 10

                    Text {
                        text: "Shortcuts"
                        font.family: Root.Theme.fontFamily
                        font.pixelSize: Root.Theme.fontSizeXL
                        font.weight: Font.Bold
                        color: Root.Theme.textPrimary
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: Root.Theme.panelBorder
                    }

                    Flickable {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.min(binds.length * 32, 360)
                        contentHeight: bindsList.implicitHeight
                        clip: true
                        interactive: binds.length > 8

                        ColumnLayout {
                            id: bindsList
                            width: parent.width
                            spacing: 6

                            Repeater {
                                model: shortcuts.binds

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 12

                                    Rectangle {
                                        Layout.preferredWidth: 200
                                        height: 24
                                        radius: 6
                                        color: Root.Theme.surfaceContainer

                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.key
                                            font.family: Root.Theme.fontFamily
                                            font.pixelSize: Root.Theme.fontSizeSmall
                                            font.weight: Font.DemiBold
                                            color: Root.Theme.primary
                                        }
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.desc
                                        font.family: Root.Theme.fontFamily
                                        font.pixelSize: Root.Theme.fontSizeNormal
                                        color: Root.Theme.textPrimary
                                        elide: Text.ElideRight
                                    }
                                }
                            }
                        }
                    }

                    Item { height: 4 }

                    Text {
                        text: "Edit binds in ~/.config/hypr/binds.conf"
                        font.family: Root.Theme.fontFamily
                        font.pixelSize: Root.Theme.fontSizeXS
                        color: Root.Theme.textSecondary
                    }
                }
            }

            Item {
                focus: true
                Keys.onPressed: (event) => {
                    if (event.key === Qt.Key_Escape || event.key === Qt.Key_F1) {
                        shortcuts.visible = false
                        event.accepted = true
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "shortcuts"
        function toggle(): void { shortcuts.visible = !shortcuts.visible; }
        function open(): void   { shortcuts.visible = true; }
        function close(): void  { shortcuts.visible = false; }
    }
}
