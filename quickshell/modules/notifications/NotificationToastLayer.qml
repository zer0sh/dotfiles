import QtQuick
import Quickshell
import Quickshell.Wayland
import "../.." as Root

Scope {
    id: toastLayer

    ListModel { id: toastModel }

    Connections {
        target: NotificationService

        function onNewNotification(notifId, appName, summary, body, urgency, timeout) {
            toastModel.append({
                notifId:  notifId,
                appName:  appName,
                summary:  summary,
                body:     body,
                urgency:  urgency,
                timeout:  timeout > 0 ? timeout : 5000
            })
        }
    }

    PanelWindow {
        id: toastWin
        visible:              toastModel.count > 0
        color:                "transparent"
        exclusionMode:        ExclusionMode.Ignore
        WlrLayershell.layer:          WlrLayer.Overlay
        WlrLayershell.namespace:      "quickshell:notifications-toast"
        WlrLayershell.keyboardFocus:  WlrKeyboardFocus.None

        anchors.bottom: true
        anchors.left:   true
        anchors.right:  true
        implicitHeight: 600

        Column {
            id: toastCol
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 40
            spacing: 8

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
                            NotificationService.removeNotification(id)
                            toastWin._removeById(id)
                        }
                    }

                    Timer {
                        property int _notifId: model.notifId
                        interval:  model.timeout
                        running:   true
                        repeat:    false
                        onTriggered: toastWin._removeById(_notifId)
                    }
                }
            }
        }

        function _removeById(notifId) {
            for (var i = 0; i < toastModel.count; i++) {
                if (toastModel.get(i).notifId === notifId) {
                    toastModel.remove(i)
                    return
                }
            }
        }
    }
}
