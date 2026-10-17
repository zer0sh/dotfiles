import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../.." as Root

Rectangle {
    id: weatherRoot

    property string temp: "--°"
    property string city: "Weather"
    property string condition: "Loading..."
    property string icon: "partly_cloudy_day"
    property string humidity: "--%"
    property string feelsLike: "--°"
    property bool refreshing: false

    implicitHeight: 136
    implicitWidth: 200

    radius: 24
    color: Root.Theme.glassCard
    border.width: 1
    border.color: Root.Theme.glassCardBorder
    clip: true

    Process {
        id: weatherProc
        command: ["/home/zero/.config/quickshell/scripts/weather.py"]
        stdout: StdioCollector {
            onStreamFinished: {
                weatherRoot.refreshing = false;
                try {
                    var data = JSON.parse(text.trim());
                    if (data.temp) weatherRoot.temp = data.temp;
                    if (data.city) weatherRoot.city = data.city;
                    if (data.condition) weatherRoot.condition = data.condition;
                    if (data.icon) weatherRoot.icon = data.icon;
                    if (data.humidity) weatherRoot.humidity = data.humidity;
                    if (data.feels_like) weatherRoot.feelsLike = data.feels_like;
                } catch (e) {
                    console.log("Weather parse error:", e);
                }
            }
        }
        onExited: (code) => {
            weatherRoot.refreshing = false;
        }
    }

    Component.onCompleted: {
        weatherProc.running = true;
    }

    Timer {
        interval: 900000 // Refresh every 15 minutes
        repeat: true
        running: true
        onTriggered: {
            if (!weatherProc.running) weatherProc.running = true;
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 6

        // Top Row: Icon + Temperature
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Text {
                text: weatherRoot.icon
                font.family: Root.Theme.iconFont
                font.pixelSize: 36
                color: Root.Theme.primary
                Layout.alignment: Qt.AlignVCenter
            }

            Item { Layout.fillWidth: true }

            Text {
                text: weatherRoot.temp
                font.family: Root.Theme.fontFamily
                font.pixelSize: 30
                font.weight: Font.Bold
                color: Root.Theme.textPrimary
                Layout.alignment: Qt.AlignVCenter
            }
        }

        // Condition description
        Text {
            text: weatherRoot.condition
            font.family: Root.Theme.fontFamily
            font.pixelSize: 13
            font.weight: Font.Medium
            color: Root.Theme.textPrimary
            elide: Text.ElideRight
            Layout.fillWidth: true
        }

        Item { Layout.fillHeight: true }

        // Bottom Row: City + Humidity
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            RowLayout {
                spacing: 3
                Layout.fillWidth: true

                Text {
                    text: "location_on"
                    font.family: Root.Theme.iconFont
                    font.pixelSize: 13
                    color: Root.Theme.textSecondary
                }

                Text {
                    text: weatherRoot.city
                    font.family: Root.Theme.fontFamily
                    font.pixelSize: 12
                    color: Root.Theme.textSecondary
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }

            RowLayout {
                spacing: 3

                Text {
                    text: "water_drop"
                    font.family: Root.Theme.iconFont
                    font.pixelSize: 13
                    color: Root.Theme.textSecondary
                }

                Text {
                    text: weatherRoot.humidity
                    font.family: Root.Theme.fontFamily
                    font.pixelSize: 12
                    color: Root.Theme.textSecondary
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        onClicked: {
            weatherRoot.refreshing = true;
            weatherProc.running = true;
        }
    }
}
