import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import "." as Notifications
import "../.." as Root

Scope {
    id: toastLayer

    ListModel { id: toastModel }

    function removeById(notifId) {
        for (var i = 0; i < toastModel.count; i++) {
            if (toastModel.get(i).notifId === notifId) {
                toastModel.remove(i)
                return
            }
        }
    }

    Connections {
        target: Notifications.NotificationService

        function onNewNotification(notifId, appName, summary, body, urgency, timeout) {
            toastModel.insert(0, {
                notifId:  notifId,
                appName:  appName,
                summary:  summary,
                body:     body,
                urgency:  urgency,
                timeout:  timeout > 0 ? timeout : 5000
            })
            if (toastModel.count > 4) {
                toastModel.remove(toastModel.count - 1)
            }
        }
    }

    Loader {
        id: toastLoader
        active: toastModel.count > 0

        sourceComponent: PanelWindow {
            id: toastWin
            color:               "transparent"
            exclusionMode:       ExclusionMode.Ignore
            WlrLayershell.layer:         WlrLayer.Top
            WlrLayershell.namespace:     "quickshell:notifications-toast"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            anchors.top:   true
            implicitWidth: 440
            implicitHeight: Math.min(700, Root.Theme.shelfHeight + toastCol.implicitHeight + 40)

            mask: Region {
                item: toastWrapper
            }

            Item {
                id: toastWrapper
                width: 436
                height: toastCol.implicitHeight
                anchors.top: parent.top
                anchors.topMargin: Root.Theme.shelfHeight
                anchors.horizontalCenter: parent.horizontalCenter

                // Clipping container for emergence animation directly out of Waybar
                Item {
                    id: toastClip
                    anchors.fill: parent
                    clip: true

                    Column {
                        id: toastCol
                        width: 380
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 8

                        move: Transition {
                            NumberAnimation {
                                properties: "y"
                                duration: 250
                                easing.type: Easing.OutCubic
                            }
                        }

                        Repeater {
                            model: toastModel

                            delegate: Item {
                                id: delegateItem
                                width:  toastCol.width
                                height: popup.height

                                NotificationPopup {
                                    id:      popup
                                    width:   parent.width
                                    isTop:   index === 0
                                    notifId: model.notifId
                                    appName: model.appName
                                    summary: model.summary
                                    body:    model.body
                                    urgency: model.urgency

                                    onDismissed: function(id) {
                                        toastLayer.removeById(id)
                                    }
                                }

                                Timer {
                                    property int _notifId: model.notifId
                                    interval:  (model.timeout && model.timeout > 0) ? model.timeout : 5000
                                    running:   true
                                    repeat:    false
                                    onTriggered: popup.dismiss()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
