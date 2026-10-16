import QtQuick
import QtQuick.Layouts
import "../.." as Root

Item {
    id: themePanel
    signal back()

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 64
            Rectangle { anchors.fill: parent; radius: Root.Theme.panelRadius; color: Root.Theme.surface }
            Rectangle { anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; height: Root.Theme.panelRadius; color: Root.Theme.surface }
            RowLayout {
                anchors.fill: parent; anchors.leftMargin: Root.Theme.paddingNormal; anchors.rightMargin: Root.Theme.paddingNormal; spacing: 8
                
                Rectangle { 
                    width: 38; height: 38; radius: Root.Theme.radiusSmall
                    color: backMouse.containsMouse ? Root.Theme.surfaceContainerHigh : "transparent"
                    
                    Text {
                        anchors.centerIn: parent
                        text: "󰁍" // Nerd font back arrow
                        color: Root.Theme.textPrimary
                        font.family: Root.Theme.fontFamily
                        font.pixelSize: 18
                    }
                    
                    MouseArea {
                        id: backMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: themePanel.back()
                    }
                }
                
                Text {
                    text: "Theme"; color: "#E5E1E9"; opacity: 1.0
                    font.family: Root.Theme.fontFamily; font.pixelSize: 18; font.bold: true
                    Layout.fillWidth: true 
                }
            }
            Rectangle { anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; height: 1; color: Root.Theme.surfaceContainerHigh }
        }

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: contentCol.height + (Root.Theme.paddingNormal * 2)
            clip: true

            Column {
                id: contentCol
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: Root.Theme.paddingNormal
                spacing: Root.Theme.paddingNormal

                Repeater {
                    model: ListModel { id: themeModel }
                    delegate: Item {
                        id: themeCard
                        width: contentCol.width
                        height: 120
                        
                        property bool isSelected: Root.Theme.currentTheme === model.themeKey
                        
                        Rectangle {
                            anchors.fill: parent
                            radius: Root.Theme.radiusSmall
                            color: themeCard.isSelected ? Root.Theme.primaryContainer : (themeMouse.containsMouse ? Root.Theme.surfaceContainerHigh : Root.Theme.surfaceContainer)
                            opacity: themeCard.isSelected ? 0.2 : 1.0
                        }
                        
                        Rectangle {
                            anchors.fill: parent
                            radius: Root.Theme.radiusSmall
                            color: "transparent"
                            border.color: themeCard.isSelected ? Root.Theme.primary : Root.Theme.surfaceContainerHigh
                            border.width: themeCard.isSelected ? 2 : 1
                            opacity: themeCard.isSelected ? 1.0 : 0.5
                        }
                        
                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 16
                            spacing: 16
                            
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 8
                                
                                Text {
                                    text: Root.Theme._themes[model.themeKey].name
                                    color: "#E5E1E9"
                                    opacity: 1.0
                                    font.family: Root.Theme.fontFamily
                                    font.pixelSize: 18
                                    font.bold: true
                                }
                                
                                Row {
                                    spacing: 10
                                    Rectangle { width: 24; height: 24; radius: 12; color: Root.Theme._themes[model.themeKey].primary }
                                    Rectangle { width: 24; height: 24; radius: 12; color: Root.Theme._themes[model.themeKey].primaryContainer }
                                    Rectangle { width: 24; height: 24; radius: 12; color: Root.Theme._themes[model.themeKey].surface }
                                    Rectangle { width: 24; height: 24; radius: 12; color: Root.Theme._themes[model.themeKey].surfaceContainer }
                                    Rectangle { width: 24; height: 24; radius: 12; color: Root.Theme._themes[model.themeKey].textPrimary }
                                }
                            }
                            
                            Text {
                                text: "󰄬"
                                visible: themeCard.isSelected
                                color: Root.Theme.primary
                                font.family: Root.Theme.fontFamily
                                font.pixelSize: 28
                            }
                        }
                        
                        MouseArea {
                            id: themeMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: Root.Theme.currentTheme = model.themeKey
                        }
                    }
                }
                
                Item {
                    width: 1
                    height: Root.Theme.paddingNormal
                }
            }
        }
    }

    Component.onCompleted: {
        var keys = Root.Theme.themeKeys;
        for (var i = 0; i < keys.length; i++) {
            themeModel.append({ "themeKey": keys[i] });
        }
    }
}
