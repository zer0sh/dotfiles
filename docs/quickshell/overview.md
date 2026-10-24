# Workspace Overview & Window Switcher

The Workspace Overview (`quickshell:overview`) is a Wayland-native, full-screen desktop exposé and window management modal built directly into Quickshell. Triggered via `SUPER + Tab`, it displays a 2×5 responsive grid representing all 10 Hyprland workspaces, accurately rendering window placements, and enabling drag-and-drop window relocation across workspaces.

---

## Visual Design & Architecture

```
+-----------------------------------------------------------------------+
|                 󰕰  Hyprland Workspaces • 6 open windows               |
+-----------------------------------------------------------------------+
|  +-------------+  +-------------+  +-------------+  +-------------+   |
|  | WS 1        |  | WS 2        |  | WS 3        |  | WS 4        |   |
|  |  +-------+  |  |   (Empty)   |  |  +-------+  |  |  +-------+  |   |
|  |  | kitty |  |  |             |  |  | radio |  |  |  |  zen  |  |   |
|  |  +-------+  |  |             |  |  +-------+  |  |  +-------+  |   |
|  +-------------+  +-------------+  +-------------+  +-------------+   |
|  +-------------+  +-------------+  +-------------+  +-------------+   |
|  | WS 6        |  | WS 7        |  | WS 8        |  | WS 9        |   |
|  +-------------+  +-------------+  +-------------+  +-------------+   |
+-----------------------------------------------------------------------+
|  [Tab Cycle]  [Arrows Grid]  [1-10 Workspace]  [Enter Select]  [Esc]  |
+-----------------------------------------------------------------------+
```

* **Surface Layout:** 2 rows of 5 columns displaying all 10 workspaces (1–5 on top, 6–10 on bottom) simultaneously with zero scrolling required.
* **Proportional Scaling:** Computes normalized monitor coordinates (`norm_x`, `norm_y`, `norm_w`, `norm_h`) from `hyprctl clients` and renders each window at its exact geometry and aspect ratio within the miniaturized workspace card.
* **Dynamic Material You Styling:** Inherits active colors from `Theme.qml` (Matugen palette), highlighting the active workspace and selected window with high-contrast accent borders.
* **Miniature Desktop Wallpaper:** Automatically renders the current desktop wallpaper (`~/.config/themes/current/wallpaper`) with an ambient darkened scrim behind each workspace canvas.
* **Zero Overhead Idle:** The overlay component is wrapped in a lazy `Loader { active: overviewScope.visible }`. When dismissed, all QML elements and processes are destroyed, using 0% CPU and 0 MB RAM.

---

## Key Features

### 1. Drag & Drop Window Relocation

Windows can be dragged directly between any of the 10 workspaces:

* **Interactive Drag Ghost:** Clicking and dragging any window spawns an elevated proxy showing the application's system icon and target workspace indicator.
* **Target Detection:** Hovering over any workspace canvas highlights the card in connected green/accent color with a *"Drop here"* indicator.
* **Instant Compositor Dispatch:** On release, Quickshell executes:
  ```bash
  hyprctl dispatch movetoworkspacesilent <target_ws>,address:<window_address>
  ```
  The window is routed silently and the workspace layouts update in real time.

### 2. Window Management & Quick Actions

* **App Identity & Icons:** Uses `overview-data.py` to resolve desktop entries (`.desktop`), pairing application class names with system icons via `Quickshell.iconPath()`.
* **Quick Close Button:** Hovering over any window reveals a `✕` close button in the mini-titlebar, invoking `hyprctl dispatch closewindow address:<addr>`.
* **Selected Window Inspector:** A bottom pill displays the focused application name, full window title, and active keyboard shortcuts.

### 3. Keyboard & Mouse Controls

| Input | Action |
| :--- | :--- |
| `SUPER + Tab` / `Tab` | Open overview / Cycle to next window across workspaces |
| `SUPER + SHIFT + Tab` / `Shift + Tab` | Cycle to previous window |
| `Arrow Keys` (`←`, `→`, `↑`, `↓`) | Spatial grid navigation (`↑`/`↓` jump rows ±5 workspaces) |
| `1` – `9`, `0` | Instant jump to workspace 1–10 |
| `Enter` / `Space` | Focus selected window and close overview |
| `Delete` / `Backspace` | Close selected window |
| `Esc` / Click Outside | Close overview without changing focus |
| Click Window | Focus that window directly |
| Click Workspace Canvas | Switch directly to that workspace |

---

## IPC Interface

The module registers under IPC target `overview`:

```bash
# Toggle visibility
quickshell ipc call overview toggle

# Open and focus next window
quickshell ipc call overview next

# Open and focus previous window
quickshell ipc call overview prev

# Close overview
quickshell ipc call overview close
```
