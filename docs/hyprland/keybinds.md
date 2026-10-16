# Keybindings

All keybindings are centralized in [`binds.conf`](file:///home/zero/.config/hypr/binds.conf). The primary modifier key is `SUPER` (`$mainMod`).

---

## 🚀 Applications & System

| Shortcut | Action | Target / Command |
| :--- | :--- | :--- |
| `SUPER + Enter` | Open terminal | `alacritty` |
| `SUPER + E` | Open file manager | `nautilus` |
| `SUPER + Space` | Application launcher | `wofi --show drun` |
| `SUPER + Q` | Close active window | `killactive` |
| `SUPER + SHIFT + R` | Reload Hyprland config | `hyprctl reload` |
| `SUPER + L` | Lock screen | `hyprlock` |
| `SUPER + P` | Display layout editor | `nwg-displays` |
| `SUPER + X` | Launch app as root | `scripts/sudo-launcher` |

---

## 📸 Screen Capture & Recording

| Shortcut | Action | Tool / Helper Script |
| :--- | :--- | :--- |
| `Print` | Fullscreen screenshot | `scripts/screenshot` (saves to disk + copies to clipboard) |
| `SUPER + S` | Capture selected area | `scripts/screenshot area` |
| `SUPER + SHIFT + O` | Optical Character Recognition (OCR) | `scripts/ocr` (extracts text to clipboard) |
| `SUPER + ALT + R` | Toggle screen recording | `scripts/record` (saves MP4 with audio) |

---

## 🎛️ Quickshell & Desktop Overlays

| Shortcut | Action | IPC Command |
| :--- | :--- | :--- |
| `CTRL + ALT + Del` | Power menu | `quickshell ipc call powermenu toggle` |
| `SUPER + W` | Wallpaper picker | `quickshell ipc call wallpaper toggle` |
| `SUPER + M` | Mini music player | `quickshell ipc call miniplayer toggle` |
| `F1` | Shortcut cheatsheet overlay | `quickshell ipc call shortcuts toggle` |

---

## 🎨 Screen Filters & Shaders

| Shortcut | Applied Shader | Helper Script |
| :--- | :--- | :--- |
| `SUPER + B` | Toggle active shader ON / OFF | `scripts/filter toggle` |
| `SUPER + CTRL + 1` | Vintage Sepia | `scripts/filter sepia` |
| `SUPER + CTRL + 2` | Black & White | `scripts/filter bw` |
| `SUPER + CTRL + 3` | Film Noir | `scripts/filter noir` |
| `SUPER + CTRL + 4` | Aged Vintage | `scripts/filter vintage` |
| `SUPER + CTRL + 5` | Vivid Colors | `scripts/filter vivid` |
| `SUPER + CTRL + 0` | Disable shaders | `scripts/filter off` |
