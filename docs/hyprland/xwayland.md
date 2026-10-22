# XWayland Compatibility & Window Rules

This document details the architectural challenges encountered when running legacy X11 and Chromium Embedded Framework (CEF) / Electron applications through **XWayland** on Hyprland, along with compositor rules to eliminate graphical artifacts, transparent boxes, and unwanted borders around popup windows.

---

## Background & Architecture

While most modern Wayland applications support native Wayland protocols (using subsurfaces, xdg-shell, and client-side popups), several popular applications still rely on **XWayland**:

* **Spotify**: Uses a custom Chromium Embedded Framework (CEF) build that crashes when forced into native Wayland with GPU acceleration (`[FATAL:content/browser/gpu/gpu_data_manager_impl_private.cc] GPU process isn't usable`).
* **Steam**: Relies on X11 libraries for window management and overlays.
* **Electron / Chromium legacy apps**: Run under X11 by default unless explicitly configured with Ozone Wayland flags.

---

## The Issue: Transparent Popup Boxes & Shadow Artifacts

Under XWayland, dropdown menus, context menus, and tooltips are rendered by the client application inside an oversized rectangular X11 window surface. The application draws its own soft drop-shadow into the padding around the actual menu content.

Because XWayland passes the entire buffer to Hyprland as a flat surface without subsurface alpha metadata:

1. **Blur Bleed**: When `decoration:blur:popups = true` is enabled in `decoration.conf`, Hyprland applies the compositor blur pass across the entire transparent buffer, producing a blurry, frosted rectangle around context menus.
2. **Double Shadows**: Hyprland's `decoration:shadow` draws an outer window shadow around the bounding rectangle of the XWayland window, resulting in double shadows or dark rectangular borders.
3. **Unwanted Borders**: Without explicit exclusion, popup menus may inherit the global `border_size` defined in `general:border_size`.

```text
┌──────────────────────────────────────────────┐  <-- Hyprland bounding box (blurred & shadowed)
│      Transparent X11 Padding Buffer          │
│   ┌────────────────────────────────────┐     │
│   │   Actual Context / Dropdown Menu   │     │
│   │   • Item 1                         │     │
│   │   • Item 2                         │     │
│   └────────────────────────────────────┘     │
│                                              │
└──────────────────────────────────────────────┘
```

---

## The Fix: Hyprland Window Rules

Hyprland provides granular window rule properties (`match:`) to target XWayland popups specifically without degrading visual effects on main tiled or floating windows.

In `~/.config/hypr/window.conf`:

```ini
# Prevent transparent box and blur artifacts on XWayland popups/dropdown menus
windowrule = no_blur on, match:xwayland 1, match:float 1, match:title ^$
windowrule = no_shadow on, match:xwayland 1, match:float 1, match:title ^$
```

### Breakdown of Match Properties

| Property | Value | Description |
| :--- | :--- | :--- |
| `match:xwayland` | `1` | Restricts the rule strictly to windows managed by the XWayland bridge. |
| `match:float` | `1` | Matches only floating surfaces (dropdowns and context menus are always floating). |
| `match:title` | `^$` | Matches empty window titles. In XWayland, dropdown menus and popups are spawned with an empty string title, distinguishing them from actual titled floating dialogs. |
| `no_blur on` | Effect | Disables compositor background blur across the transparent buffer. |
| `no_shadow on` | Effect | Disables Hyprland's external window shadow for the popup. |

!!! tip "Eliminating Extraneous Borders"
    If an XWayland application creates menus with borders from Hyprland's `general:border_size`, append the following rule:
    ```ini
    windowrule = no_border on, match:xwayland 1, match:float 1, match:title ^$
    ```

---

## Native Wayland Alternative (When Supported)

For applications that have working Wayland backends, running them natively eliminates the need for XWayland workarounds entirely:

### Google Chrome / Chromium
Add the following flags to `~/.config/chrome-flags.conf` (or `~/.config/chromium-flags.conf`):

```text
--ozone-platform-hint=auto
--enable-features=WaylandWindowDecorations
```

### Electron Applications (VS Code, Discord, Obsidian)
Launch with standard Ozone arguments:

```bash
code --ozone-platform=wayland --enable-features=UseOzonePlatform
```

*(Note: As verified in our testing, Spotify's bundled CEF cannot use these flags without crashing; Spotify should continue running via `--ozone-platform=x11` with the window rules described above).*

---

## Verification & Debugging

To inspect window properties and verify if a window is running under XWayland or native Wayland, run:

```bash
hyprctl clients
```

Look for the following fields in the output:

* `xwayland: 1` — The window is running under XWayland.
* `xwayland: 0` — The window is running natively on Wayland.
* `class` and `title` — Use these values to refine your `match:` expressions.
