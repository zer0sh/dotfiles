import QtQuick
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
            color:                "transparent"
            exclusionMode:        ExclusionMode.Ignore
            WlrLayershell.layer:          WlrLayer.Top
            WlrLayershell.namespace:      "quickshell:notifications-toast"
            WlrLayershell.keyboardFocus:  WlrKeyboardFocus.None

            anchors.top:   true
            implicitWidth: 380
            implicitHeight: Math.min(600, toastModel.count * 140 + 60)

            mask: Region {
                item: toastCol
            }

            Column {
                id: toastCol
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 46
                spacing: 10

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
                        width:  360
                        height: popup.height

                        NotificationPopup {
                            id:      popup
                            width:   parent.width
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
