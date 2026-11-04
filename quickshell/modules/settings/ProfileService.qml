pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: profileService

    readonly property string configPath: "/home/zero/.config/quickshell/profile.json"
    property string username: "zero"
    property string displayName: "zero"
    property string avatarPath: "/home/zero/.face"
    property int avatarTimestamp: 1
    property bool isUpdatingAvatar: false

    readonly property string avatarUrl: "file://" + avatarPath + "?t=" + avatarTimestamp

    signal profileChanged()

    // ── Load saved profile ───────────────────────────────────────
    property Process readProc: Process {
        id: readProc
        command: ["/bin/sh", "-c", "cat " + profileService.configPath + " 2>/dev/null || true"]
        stdout: StdioCollector {
            onStreamFinished: {
                var raw = text.trim();
                if (raw !== "") {
                    try {
                        var parsed = JSON.parse(raw);
                        if (parsed.displayName && parsed.displayName.trim() !== "") {
                            profileService.displayName = parsed.displayName.trim();
                        }
                        if (parsed.username && parsed.username.trim() !== "") {
                            profileService.username = parsed.username.trim();
                        }
                    } catch (e) {
                        console.warn("[ProfileService] Error parsing profile.json:", e);
                    }
                }
                profileService.profileChanged();
            }
        }
    }

    // ── Save profile to disk ─────────────────────────────────────
    property Process saveProc: Process {
        id: saveProc
    }

    function saveProfile() {
        if (saveProc.running) saveProc.running = false;
        var data = {
            "username": profileService.username,
            "displayName": profileService.displayName
        };
        var jsonStr = JSON.stringify(data, null, 2);
        saveProc.command = [
            "/bin/sh", "-c",
            "mkdir -p ~/.config/quickshell && printf '%s\\n' '" +
            jsonStr.replace(/'/g, "'\\''") +
            "' > " + profileService.configPath
        ];
        saveProc.running = true;
        profileService.profileChanged();
    }

    function setDisplayName(newName) {
        if (!newName || newName.trim() === "") return;
        profileService.displayName = newName.trim();
        saveProfile();
    }

    // ── Update avatar using Zenity + script ───────────────────────
    property Process avatarProc: Process {
        id: avatarProc
        command: ["/home/zero/.config/quickshell/scripts/update-avatar.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                var result = text.trim();
                profileService.isUpdatingAvatar = false;
                if (result !== "") {
                    profileService.avatarTimestamp = Date.now();
                    profileService.profileChanged();
                }
            }
        }
        onExited: function(exitCode, exitStatus) {
            profileService.isUpdatingAvatar = false;
        }
    }

    function pickAvatar() {
        if (avatarProc.running) return;
        isUpdatingAvatar = true;
        avatarProc.running = true;
    }

    Component.onCompleted: {
        readProc.running = true;
    }
}
