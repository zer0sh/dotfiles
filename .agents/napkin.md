# Napkin Runbook

## Environment & Daemons
1. **[2026-10-23] GNOME/GTK4 App Startup Lag (~3.5s) on Hyprland**
   - **Cause:** `xdg-desktop-portal-gnome` expects GNOME Shell and Mutter on D-Bus. When absent in Hyprland, D-Bus queries hang until timeout.
   - **Important Quirk:** Masking `xdg-desktop-portal-gnome.service` via `systemctl --user mask` is *insufficient* because D-Bus service activation files in `/usr/share/dbus-1/services/` still trigger activations.
   - **Do instead:** Fully purge the package (`sudo apt remove --purge xdg-desktop-portal-gnome`), enforce `default=hyprland;gtk` in `~/.config/xdg-desktop-portal/portals.conf`, and ensure `autostart.conf` exports `WAYLAND_DISPLAY` and `XDG_CURRENT_DESKTOP` to `systemd` and `dbus-update-activation-environment`.

2. **[2026-10-23] Hyprland Workspace Overview via Quickshell IPC & Drag-and-Drop**
   - **Architecture:** Instead of heavy live screencopy video streams, client geometries (`x, y, w, h`) from `hyprctl clients -j` are normalized relative to focused monitor bounds.
   - **Multi-Monitor Offsets:** In Hyprland, `mon.x` and `mon.y` offsets must be subtracted from client `at` coordinates before normalizing by `mon.width` and `mon.height`.
   - **Silent Relocation:** Drag-and-drop window relocation across workspaces uses `hyprctl dispatch movetoworkspacesilent <id>,address:<addr>` to avoid abrupt viewport jumps while the overview modal is open.
