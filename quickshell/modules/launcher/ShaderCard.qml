import QtQuick
import QtQuick.Layouts
import "../.." as Root

Item {
    id: cardRoot

    property string shaderKey: ""
    property string shaderTitle: ""
    property string shaderSubtitle: ""
    property string shaderThumb: ""
    property bool isCurrentShader: false
    property bool isSelected: false

    readonly property bool isHovered: mouseArea.containsMouse

    signal activated()

    width: 224
    height: 214

    // Dynamic scale and elevation matching Caelestia design
    scale: mouseArea.containsMouse ? 1.05 : (isSelected ? 1.03 : 1.0)
    y: mouseArea.containsMouse ? -5 : (isSelected ? -2 : 0)
    z: mouseArea.containsMouse ? 100 : (isSelected ? 20 : 1)

    Behavior on scale {
        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
    }
    Behavior on y {
        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
    }

    Rectangle {
        id: bgCard
        anchors.fill: parent
        radius: 18
        color: cardRoot.isSelected
            ? Root.Theme.surfaceContainerHigh
            : (mouseArea.containsMouse
                ? Qt.rgba(Root.Theme.surfaceBright.r, Root.Theme.surfaceBright.g, Root.Theme.surfaceBright.b, 0.95)
                : Qt.rgba(Root.Theme.surfaceContainer.r, Root.Theme.surfaceContainer.g, Root.Theme.surfaceContainer.b, 0.65))

        border.width: 2
        border.color: Root.Theme.primary

        Behavior on color { ColorAnimation { duration: 180 } }
        Behavior on border.color { ColorAnimation { duration: 180 } }

        // Dynamic outer glow halo
        Rectangle {
            anchors.fill: parent
            anchors.margins: mouseArea.containsMouse ? -8 : -5
            radius: 24
            color: "transparent"
            border.width: mouseArea.containsMouse ? 2 : 1
            border.color: (mouseArea.containsMouse || cardRoot.isSelected)
                ? Qt.rgba(Root.Theme.primary.r, Root.Theme.primary.g, Root.Theme.primary.b, mouseArea.containsMouse ? 0.6 : 0.35)
                : "transparent"
            visible: mouseArea.containsMouse || cardRoot.isSelected

            Behavior on anchors.margins { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            Behavior on border.color { ColorAnimation { duration: 200 } }
        }

        Item {
            anchors.fill: parent
            anchors.margins: 10

            // 16:10 thumbnail container
            Rectangle {
                id: thumbContainer
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width
                height: 120
                radius: 12
                clip: true
                color: Root.Theme.surface

                Image {
                    id: thumbImg
                    anchors.fill: parent
                    source: cardRoot.shaderThumb !== "" ? "file://" + cardRoot.shaderThumb : ""
                    fillMode: Image.PreserveAspectCrop
                    smooth: true
                    asynchronous: true

                    // Smooth zoom on hover
                    scale: mouseArea.containsMouse ? 1.08 : 1.0
                    transformOrigin: Item.Center

                    Behavior on scale {
                        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                    }
                }

                // Active shader badge
                Rectangle {
                    visible: cardRoot.isCurrentShader
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.margins: 6
                    width: 66
                    height: 22
                    radius: 11
                    color: Root.Theme.primary

                    Row {
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            text: "󰄬"
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: 11
                            color: Root.Theme.tileActiveText
                        }

                        Text {
                            text: "Active"
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: 11
                            font.weight: Font.Bold
                            color: Root.Theme.tileActiveText
                        }
                    }
                }
            }

            // Shader title
            Text {
                id: titleText
                anchors.top: thumbContainer.bottom
                anchors.topMargin: 8
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - 4
                text: cardRoot.shaderTitle
                font.family: Root.Theme.fontFamily
                font.pixelSize: 14
                font.weight: (mouseArea.containsMouse || cardRoot.isSelected) ? Font.Bold : Font.Medium
                color: (mouseArea.containsMouse || cardRoot.isSelected) ? Root.Theme.primary : Root.Theme.textPrimary
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
            }

            // Descriptive subtitle
            Text {
                anchors.top: titleText.bottom
                anchors.topMargin: 3
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - 6
                text: cardRoot.shaderSubtitle
                font.family: Root.Theme.fontFamily
                font.pixelSize: 11
                color: Root.Theme.textSecondary
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: cardRoot.activated()
    }
}
