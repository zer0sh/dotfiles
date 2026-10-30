# Clipboard Manager

The Clipboard Manager (`quickshell:clipboard`) is a Wayland-native history drawer built directly into Quickshell. Docked smoothly below the [Waybar Status Bar](../apps/waybar.md) and integrated with `cliphist`, it provides an instantaneous, visual clipboard buffer for text and image previews.

---

## Architecture & Visual Design

The module (`modules/clipboard/ClipboardPanel.qml` and `ClipboardItem.qml`) adheres strictly to the Dynamic Island and Material Design 3 aesthetics established across the desktop environment:

* **Dynamic Island Shelf Architecture:** Docked flush below Waybar (`shelfHeight: 36px`, `y: 0`, `anchors.rightMargin: 0`) on the top-right edge of the active display.
* **Concave Transition Fillet:** Hardware-accelerated `QtQuick.Shapes` inverted fillet (28 px radius) seamlessly bridging Waybar's bottom edge with the panel's left vertical shoulder.
* **Continuous Accent Border:** Outer 2 px outline styled with the primary accent token (`Root.Theme.primary`), leaving the top edge open towards Waybar for an organic, integrated finish.
* **Optimized Dimensions:** Engineered with a compact width of `616 px` (30% narrower than the standard 880 px Control Center panel) to maximize usable desktop real estate.
* **Unified Translucency:** Surface opacity at `0.85` on `Root.Theme.panelBg` backed by compositor blur rules, with individual entry cards rendered at `0.95` opacity on `Root.Theme.surfaceContainer`.

```text
+-------------------------------------------------------------+
| Waybar Status Bar                                           |
+----------------------------------------------+--------------+
                                              / (28px Fillet)
                   +-------------------------+
                   |  󰅌 Clipboard (N items)  |
                   +-------------------------+
                   |  󰍉 Search history...    |
                   +-------------------------+
                   | [󰅌] Copied text entry   |
                   +-------------------------+
                   | [🖼] Image thumbnail     |
                   +-------------------------+
                   |           [ Clear all ] |
                   +-------------------------+
```

---

## Core Features

### 1. High-Performance Controller (`clipboard-manager.py`)

Backend operations are managed by a dedicated, asynchronous Python controller (`~/.config/quickshell/scripts/clipboard-manager.py`) outputting structured JSON to Quickshell's `quickshell.io.Process` pipelines:

* **Buffer & Streaming:** Reads real-time entries from `cliphist list`, streaming up to 50 active items directly to the QML model.
* **Binary Detection:** Automatically identifies PNG, JPEG, and GIF binary streams or `[[ binary data ]]` descriptors without blocking the UI thread.
* **Thumbnail Cache:** Decodes image entries on demand into `/tmp/cliphist-thumbs/<id>.png` with zero redundant re-decoding.
* **Surgical Deletion:** Targets exact entry lines for deletion using `cliphist delete` and cleans up associated cached thumbnails.

### 2. Live Search & Instant Filtering

* **Debounced Search Bar:** Clean search input field located below the header with real-time text matching (140 ms debounce) over entry previews.
* **Quick Reset:** One-click clear button (`✕`) to instantly restore the full 50-item catalog.
* **Dynamic Placeholders:** Responsive empty states differentiating between an empty clipboard and zero search query matches.

### 3. Multimedia & Screenshot Previews

* **Image Thumbnails:** Captured screenshots and copied images render a dedicated 90x68 px preview container (`Image.PreserveAspectFit`) with rounded corners and dark contrast backing.
* **Format & Dimensions Telemetry:** Displays dimensions metadata (e.g., `1920x1080`) when available from `cliphist`.
* **Binary Re-Injection:** Clicking an image card re-injects the exact original binary payload back into the Wayland clipboard via `cliphist decode <id> | wl-copy`.

### 4. Interactive Feedback & Per-Item Deletion

* **Copied Feedback (`✓`):** Clicking any card triggers an instant checkmark badge and an accent outline pulse, providing immediate visual confirmation before dismissal.
* **Single-Item Deletion (`✕`):** Hovering over any card exposes a dedicated circular delete button. Clicking it removes only that specific item via `cliphist delete`, allowing sensitive data (such as passwords or tokens) to be purged without wiping the entire history.
* **Unified Clear Action:** Bottom-aligned pill button ("Clear all") styled with error-accented hover reactions to wipe all stored entries via `cliphist wipe`.

---

## Keybindings and Invocations

| Trigger | Action | Target / IPC Command |
| :--- | :--- | :--- |
| `SUPER + V` | Toggle clipboard panel | `quickshell ipc call clipboard toggle` |
| `Waybar Icon` | Toggle clipboard panel | `custom/clipboard` (`qs ipc call clipboard toggle`) |
| `Escape` | Dismiss panel | Closes active overlay and unloads layer |
| `Click Outside` | Dismiss panel | Fullscreen transparent hit-test overlay |

---

## CLI & Scripting Reference

You can interact with the clipboard engine directly from the command line:

```bash
# Toggle the panel via IPC
qs ipc call clipboard toggle

# List the last 50 items in JSON format
~/.config/quickshell/scripts/clipboard-manager.py list "" 50

# Filter history for a keyword
~/.config/quickshell/scripts/clipboard-manager.py list "hyprland" 20

# Re-copy a specific item by ID
~/.config/quickshell/scripts/clipboard-manager.py copy 862

# Delete a single item by ID
~/.config/quickshell/scripts/clipboard-manager.py delete 862

# Wipe all clipboard history and clear thumbnail cache
~/.config/quickshell/scripts/clipboard-manager.py wipe
```

---

## Related Documentation

* [Waybar Status Bar](../apps/waybar.md): Configuration of the `custom/clipboard` module in the status bar.
* [Hyprland Keybindings Catalog](../hyprland/keybinds.md): Keybinding assignment for `SUPER + V`.
* [Control Center Architecture](index.md): Design tokens, concave fillets, and shelf geometry.
