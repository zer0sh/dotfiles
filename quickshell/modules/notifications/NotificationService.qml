pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

QtObject {
    id: root

    // Exposed notification list (JS array of parsed notification objects)
    property var notifications: []
    property int count: notifications.length
    // Suppresses toast popups while keeping notifications in history.
    property bool dndEnabled: false


    // Internal map of id → Notification object (for tracked=false on remove)
    property var _notifMap: ({})

    // Signal emitted for each new notification — toast layer listens here
    signal newNotification(int notifId, string appName, string summary,
                           string body, string urgency, int timeout)

    // ── NotificationServer — claims org.freedesktop.Notifications on DBus ──
    property var server: NotificationServer {
        keepOnReload: false
        bodySupported: true
        bodyMarkupSupported: false
        actionsSupported: false

        onNotification: function(notif) {
            // Keep in tracked list for history
            notif.tracked = true
            root._notifMap[notif.id] = notif
            var displayApp = root._displayAppName(notif.appName)

            // Prepend to history array
            var newList = root.notifications.slice()
            newList.unshift({
                id: notif.id,
                appName: displayApp,
                summary: notif.summary,
                body: notif.body,
                urgency: root._urgencyStr(notif.urgency),
                timestamp: Date.now(),
                iconPath: notif.appIcon
            })
            root.notifications = newList

            var ms = notif.expireTimeout > 0 ? Math.round(notif.expireTimeout) : 5000
            if (!root.dndEnabled) {
                root.newNotification(notif.id, displayApp, notif.summary,
                                     notif.body, root._urgencyStr(notif.urgency), ms)
            }

            root._updateWaybar()
        }
    }

    // ── Waybar signal process ─────────────────────────────────────────────
    property var _waybarProc: Process {
        id: waybarProc
    }

    function _updateWaybar() {
        var c = root.notifications.length
        waybarProc.command = ["sh", "-c",
            "printf '%s' '" + c + "' > /tmp/qs-notif-count; pkill -RTMIN+1 waybar 2>/dev/null; true"]
        waybarProc.running = false
        waybarProc.running = true
    }

    // ── Helpers ───────────────────────────────────────────────────────────
    function _displayAppName(appName) {
        var name = (appName || "").toString().trim()
        var normalized = name.toLowerCase().replace(/[_ ]/g, "-")
        if (normalized === "notify-send" ||
            normalized === "org.freedesktop.notifications" ||
            normalized === "freedesktop-notifications") {
            return "System"
        }
        return name !== "" ? name : "System"
    }

    function _urgencyStr(urgency) {
        if (urgency === NotificationUrgency.Critical) return "CRITICAL"
        if (urgency === NotificationUrgency.Low)      return "LOW"
        return "NORMAL"
    }

    // Compute relative timestamp string (uses Unix epoch ms from Date.now())
    function relativeTime(timestampMs) {
        if (!timestampMs || timestampMs <= 0) return ""
        var diffSec = Math.floor((Date.now() - timestampMs) / 1000)
        if (diffSec < 0)    return "just now"
        if (diffSec < 60)   return "just now"
        if (diffSec < 3600) {
            var m = Math.floor(diffSec / 60)
            return m + (m === 1 ? " min ago" : " mins ago")
        }
        if (diffSec < 86400) {
            var h = Math.floor(diffSec / 3600)
            return h + (h === 1 ? " hour ago" : " hours ago")
        }
        var d = Math.floor(diffSec / 86400)
        return d + (d === 1 ? " day ago" : " days ago")
    }

    function clearAll() {
        for (var id in root._notifMap) {
            if (root._notifMap.hasOwnProperty(id))
                root._notifMap[id].tracked = false
        }
        root._notifMap = {}
        root.notifications = []
        root._updateWaybar()
    }

    function removeNotification(notifId) {
        if (root._notifMap[notifId]) {
            root._notifMap[notifId].tracked = false
            delete root._notifMap[notifId]
        }
        root.notifications = root.notifications.filter(function(n) {
            return n.id !== notifId
        })
        root._updateWaybar()
    }
}
