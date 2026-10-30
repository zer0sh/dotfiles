import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../.." as Root

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

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        mask: Region {
            item: mainCard
        }

        // Contenedor principal sin fondo ni bordes — arrastrable directamente
        Item {
            id: mainCard
            x: weatherGadget.posX
            y: weatherGadget.posY
            width: 350
            height: 290
            property bool isDragging: false

            Binding {
                target: mainCard
                property: "x"
                value: weatherGadget.posX
                when: !mainCard.isDragging
            }
            Binding {
                target: mainCard
                property: "y"
                value: weatherGadget.posY
                when: !mainCard.isDragging
            }

            // Arrastre libre desde cualquier punto del widget del clima
            MouseArea {
                id: dragArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: pressed ? Qt.ClosedHandCursor : (containsMouse ? Qt.OpenHandCursor : Qt.ArrowCursor)
                drag.target: mainCard
                drag.axis: Drag.XAndYAxis

                onPressed: {
                    mainCard.isDragging = true
                }

                onReleased: {
                    var fx = Math.round(mainCard.x)
                    var fy = Math.round(mainCard.y)
                    weatherGadget.posX = fx
                    weatherGadget.posY = fy
                    Root.GadgetsManager.setPosition("weather", fx, fy)
                    mainCard.isDragging = false
                }
            }

            // Botón sutil de cierre al pasar el cursor
            Text {
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: 6
                z: 100
                text: "✕"
                font.family: Root.Theme.fontFamily
                font.pixelSize: 13
                font.weight: Font.Bold
                color: closeHover.hovered ? Root.Theme.error : Qt.rgba(Root.Theme.textSecondary.r, Root.Theme.textSecondary.g, Root.Theme.textSecondary.b, 0.45)
                opacity: dragArea.containsMouse ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 180 } }

                HoverHandler { id: closeHover }
                TapHandler {
                    onTapped: Root.GadgetsManager.setEnabled("weather", false)
                }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.topMargin: 16
                anchors.bottomMargin: 14
                anchors.leftMargin: 16
                anchors.rightMargin: 16
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

                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 74

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
