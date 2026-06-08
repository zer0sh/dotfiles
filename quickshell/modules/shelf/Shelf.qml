import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.SystemTray
import "../.." as Root

Scope {
    id: shelf

    PanelWindow {
        id: panelWindow

        anchors {
            left: true
            right: true
            top: true
        }

        implicitHeight: Root.Theme.shelfHeight
        exclusiveZone: Root.Theme.shelfHeight
        color: "transparent"

        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "quickshell:shelf"

        Rectangle {
            id: shelfBackground
            anchors.fill: parent
            color: Root.Theme.shelfBg
            radius: Root.Theme.radiusLarge

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: Root.Theme.radiusLarge
                color: parent.color
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Root.Theme.padding
                anchors.rightMargin: Root.Theme.padding
                spacing: Root.Theme.paddingSmall

                WorkspaceIndicator {
                    Layout.alignment: Qt.AlignVCenter
                }

                Item { Layout.fillWidth: true }

                Item {
                    Layout.preferredWidth: 50
                    Layout.preferredHeight: 50
                    Layout.alignment: Qt.AlignVCenter
                    SearchButton { }
                }

                Item { Layout.fillWidth: true }

                StatusArea {
                    Layout.alignment: Qt.AlignVCenter
                }

                Row {
                    spacing: Root.Theme.paddingSmall
                    Layout.alignment: Qt.AlignVCenter

                    Repeater {
                        model: SystemTray.items

                        delegate: Item {
                            required property SystemTrayItem modelData
                            width: 26; height: 26

                            Image {
                                anchors.fill: parent
                                source: modelData.icon
                                sourceSize.width: 26
                                sourceSize.height: 26
                            }

                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                onClicked: (mouse) => {
                                    if (mouse.button === Qt.LeftButton)
                                        modelData.activate()
                                    else
                                        modelData.display(panelWindow, mouse.x, mouse.y)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
