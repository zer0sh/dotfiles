import QtQuick
import QtQuick.Layouts
import "../.." as Root

Rectangle {
    id: root

    property int hours: 0
    property int minutes: 0
    property int seconds: 0
    property string dayName: "Today"
    property string dateString: ""
    property string timeString: "00:00"

    implicitWidth: 180
    implicitHeight: 330

    radius: 24
    color: Root.Theme.glassCard
    border.width: 1
    border.color: Root.Theme.glassCardBorder
    clip: true

    function updateTime() {
        var d = new Date()
        root.hours = d.getHours()
        root.minutes = d.getMinutes()
        root.seconds = d.getSeconds()

        var days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        var months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

        root.dayName = days[d.getDay()]
        root.dateString = d.getDate() + " " + months[d.getMonth()]

        var hh = (root.hours < 10 ? "0" : "") + root.hours
        var mm = (root.minutes < 10 ? "0" : "") + root.minutes
        root.timeString = hh + ":" + mm
    }

    Component.onCompleted: updateTime()

    Timer {
        interval: 1000
        repeat: true
        running: true
        onTriggered: root.updateTime()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 0

        // Header: Clean Day & Date (Minimalist Material You style)
        Text {
            text: root.dayName + ", " + root.dateString
            font.family: Root.Theme.fontFamily
            font.pixelSize: 13
            font.weight: Font.DemiBold
            color: Root.Theme.primary
            Layout.alignment: Qt.AlignHCenter
        }

        Item { Layout.fillHeight: true }

        // Analog Clock Face (Material You Pixel / Android pure style)
        Item {
            id: clockFace
            Layout.alignment: Qt.AlignHCenter
            width: 144
            height: 144

            // Subtle dial glass disc
            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: Qt.rgba(255, 255, 255, 0.03)
                border.width: 1
                border.color: Qt.rgba(255, 255, 255, 0.08)
            }

            // 4 Minimalist Cardinal Markers (12, 3, 6, 9)
            Repeater {
                model: 4
                Item {
                    anchors.centerIn: parent
                    width: clockFace.width
                    height: clockFace.height
                    rotation: index * 90

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.topMargin: 8
                        width: 4
                        height: 4
                        radius: 2
                        color: Qt.rgba(255, 255, 255, 0.35)
                    }
                }
            }

            // Hour Hand — Thick Material You capsule pill
            Item {
                anchors.centerIn: parent
                width: 1
                height: 1
                rotation: (root.hours % 12 + root.minutes / 60.0) * 30

                Behavior on rotation {
                    RotationAnimation {
                        duration: 300
                        direction: RotationAnimation.Shortest
                    }
                }

                Rectangle {
                    width: 14
                    height: 46
                    radius: 7
                    color: Root.Theme.primary
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: -7
                }
            }

            // Minute Hand — Bold Material You capsule pill
            Item {
                anchors.centerIn: parent
                width: 1
                height: 1
                rotation: (root.minutes + root.seconds / 60.0) * 6

                Behavior on rotation {
                    RotationAnimation {
                        duration: 300
                        direction: RotationAnimation.Shortest
                    }
                }

                Rectangle {
                    width: 10
                    height: 60
                    radius: 5
                    color: Root.Theme.textPrimary
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: -5
                }
            }


            // Center Pivot Cap
            Rectangle {
                anchors.centerIn: parent
                width: 16
                height: 16
                radius: 8
                color: Root.Theme.primary

                Rectangle {
                    anchors.centerIn: parent
                    width: 4
                    height: 4
                    radius: 2
                    color: Root.Theme.panelBg
                }
            }
        }

        Item { Layout.fillHeight: true }

        // Bottom Footer: Bold Digital Time
        Text {
            text: root.timeString
            font.family: Root.Theme.fontFamily
            font.pixelSize: 24
            font.weight: Font.Bold
            color: Root.Theme.textPrimary
            Layout.alignment: Qt.AlignHCenter
        }
    }
}
