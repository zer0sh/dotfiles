import QtQuick
import QtQuick.Layouts
import "../.." as Root

BaseCarouselCard {
    id: cardRoot

    property string shaderKey: ""
    property string shaderTitle: ""
    property string shaderSubtitle: ""
    property string shaderThumb: ""
    property bool isCurrentShader: false

    Item {
        anchors.fill: parent

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
                scale: cardRoot.isHovered ? 1.08 : 1.0
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
            font.weight: (cardRoot.isHovered || cardRoot.isSelected) ? Font.Bold : Font.Medium
            color: (cardRoot.isHovered || cardRoot.isSelected) ? Root.Theme.primary : Root.Theme.textPrimary
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
