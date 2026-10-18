import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../.." as Root
import "../gadgets" as Gadgets

Scope {
    id: weatherGadget

    property string temp: "--°"
    property string city: "Weather"
    property string condition: "Loading..."
    property string icon: "partly_cloudy_day"
    property string humidity: "--%"
    property string feelsLike: "--°"
    property var forecast: []
    property bool refreshing: false

    property bool panelVisible: Root.GadgetsManager.isEnabled("weather")
    property int posX: Root.GadgetsManager.getPosition("weather", 1420, 520).x
    property int posY: Root.GadgetsManager.getPosition("weather", 1420, 520).y

    Connections {
        target: Root.GadgetsManager
        function onStateChanged() {
            weatherGadget.panelVisible = Root.GadgetsManager.isEnabled("weather");
            var pos = Root.GadgetsManager.getPosition("weather", 1420, 520);
            weatherGadget.posX = pos.x;
            weatherGadget.posY = pos.y;
        }
    }

    IpcHandler {
        target: "weathergadget"
        function toggle(): void { Root.GadgetsManager.toggle("weather") }
        function show(): void { Root.GadgetsManager.setEnabled("weather", true) }
        function hide(): void { Root.GadgetsManager.setEnabled("weather", false) }
        function refresh(): void {
            if (!weatherProc.running) {
                weatherGadget.refreshing = true;
                weatherProc.running = true;
            }
        }
    }

    Process {
        id: weatherProc
        command: ["/home/zero/.config/quickshell/scripts/weather.py"]
        stdout: StdioCollector {
            onStreamFinished: {
                weatherGadget.refreshing = false;
                try {
                    var data = JSON.parse(text.trim());
                    if (data.temp) weatherGadget.temp = data.temp;
                    if (data.city) weatherGadget.city = data.city;
                    if (data.condition) weatherGadget.condition = data.condition;
                    if (data.icon) weatherGadget.icon = data.icon;
                    if (data.humidity) weatherGadget.humidity = data.humidity;
                    if (data.feels_like) weatherGadget.feelsLike = data.feels_like;
                    if (data.forecast) weatherGadget.forecast = data.forecast;
                } catch (e) {
                    console.log("[WeatherGadget] Parse error:", e);
                }
            }
        }
        onExited: (code) => {
            weatherGadget.refreshing = false;
        }
    }

    Component.onCompleted: {
        weatherProc.running = true;
    }

    Timer {
        interval: 900000 // 15 mins
        repeat: true
        running: true
        onTriggered: {
            if (!weatherProc.running) weatherProc.running = true;
        }
    }

    PanelWindow {
        id: win
        visible: weatherGadget.panelVisible
        color: "transparent"

        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.namespace: "quickshell-weathergadget"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        anchors.top: true
        anchors.left: true
        margins.top: weatherGadget.posY
        margins.left: weatherGadget.posX
        implicitWidth: 350
        implicitHeight: 290

        Rectangle {
            id: mainCard
            anchors.fill: parent
            radius: 24
            color: Qt.rgba(0.05, 0.05, 0.08, 0.65)
            border.color: Root.Theme.primary
            border.width: 2

            HoverHandler {
                id: cardHover
            }

            Gadgets.GadgetHeader {
                windowRef: win
                gadgetId: "weather"
                managerRef: Root.GadgetsManager
                parentHovered: cardHover.hovered
            }

            // Glow exterior
            Rectangle {
                anchors.fill: parent
                anchors.margins: -6
                radius: 28
                color: "transparent"
                border.color: Qt.rgba(Root.Theme.primary.r, Root.Theme.primary.g, Root.Theme.primary.b, 0.35)
                border.width: 1.5
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.topMargin: 40
                anchors.bottomMargin: 18
                anchors.leftMargin: 20
                anchors.rightMargin: 20
                spacing: 12

                // Top: City & Feels like
                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: weatherGadget.city.toUpperCase()
                        font.family: Root.Theme.fontFamily
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        font.letterSpacing: 1.5
                        color: Root.Theme.primary
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: "Feels " + weatherGadget.feelsLike
                        font.family: Root.Theme.fontFamily
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        color: Root.Theme.textSecondary
                    }
                }

                // Middle: Today's Weather (prominent)
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 16

                    // Weather Icon & Condition below
                    ColumnLayout {
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 4

                        Text {
                            text: weatherGadget.icon
                            font.family: Root.Theme.iconFont
                            font.pixelSize: 56
                            color: Qt.lighter(Root.Theme.primary, 1.2)
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Text {
                            text: weatherGadget.condition
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: 13
                            font.weight: Font.Medium
                            color: Root.Theme.textPrimary
                            elide: Text.ElideRight
                            Layout.maximumWidth: 140
                            horizontalAlignment: Text.AlignHCenter
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Big Temperature
                    Text {
                        text: weatherGadget.temp
                        font.family: Root.Theme.fontFamily
                        font.pixelSize: 74
                        font.weight: Font.Bold
                        color: Qt.lighter(Root.Theme.primary, 1.25)
                        Layout.alignment: Qt.AlignVCenter
                        style: Text.Sunken
                        styleColor: Root.Theme.primary
                    }
                }

                // Divider
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Qt.rgba(Root.Theme.outline.r, Root.Theme.outline.g, Root.Theme.outline.b, 0.25)
                }

                // Bottom: Next 2 Days Forecast (smaller cards)
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Repeater {
                        model: weatherGadget.forecast

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 74
                            radius: 14
                            color: Qt.rgba(Root.Theme.surfaceContainer.r, Root.Theme.surfaceContainer.g, Root.Theme.surfaceContainer.b, 0.5)
                            border.color: Qt.rgba(Root.Theme.outline.r, Root.Theme.outline.g, Root.Theme.outline.b, 0.2)
                            border.width: 1

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 2

                                Text {
                                    text: modelData.day
                                    font.family: Root.Theme.fontFamily
                                    font.pixelSize: 11
                                    font.weight: Font.Bold
                                    color: Root.Theme.primary
                                    Layout.alignment: Qt.AlignHCenter
                                }

                                RowLayout {
                                    spacing: 6
                                    Layout.alignment: Qt.AlignHCenter

                                    Text {
                                        text: modelData.icon
                                        font.family: Root.Theme.iconFont
                                        font.pixelSize: 22
                                        color: Qt.lighter(Root.Theme.primary, 1.1)
                                    }

                                    Text {
                                        text: modelData.temp
                                        font.family: Root.Theme.fontFamily
                                        font.pixelSize: 14
                                        font.weight: Font.Bold
                                        color: Root.Theme.textPrimary
                                    }
                                }

                                Text {
                                    text: modelData.condition
                                    font.family: Root.Theme.fontFamily
                                    font.pixelSize: 10
                                    font.weight: Font.Normal
                                    color: Root.Theme.textSecondary
                                    elide: Text.ElideRight
                                    Layout.maximumWidth: 110
                                    horizontalAlignment: Text.AlignHCenter
                                    Layout.alignment: Qt.AlignHCenter
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
