# Application Launcher & Dynamic Command Drawer

Quickshell implements a floating bottom-center application launcher and action drawer inspired by Caelestia Shell. Docked directly to the bottom screen edge, it provides application launching, system actions, real-time command routing, theme selection, desktop gadget toggling, and an integrated non-modal music player.

---

## Architecture & Geometry

The launcher window lives in `quickshell/modules/launcher/Launcher.qml` and operates on the Wayland layer shell:

* **Layer Surface:** Positioned on `WlrLayershell.layer: WlrLayer.Overlay`.
* **Docking Position:** Centered horizontally on the active display and anchored flush to the bottom edge (`anchors.bottomMargin: 0`).
* **Dynamic Island Curvature:** Top corners are rounded (`topLeftRadius: 28`, `topRightRadius: 28`), while bottom corners remain square (`bottomLeftRadius: 0`, `bottomRightRadius: 0`) against the monitor boundary.
* **Concave Shoulder Fillets:** Uses hardware-accelerated `QtQuick.Shapes` geometry (28 px radius) bridging the monitor's bottom bezel cleanly into the vertical shoulders of the card.
* **Surface Styling:** Obsidian glass finish matching Waybar and the Control Center (`alpha 0.80`), with dynamic Material Design 3 accent outlines and shadow elevation.

---

## File Structure

```text
quickshell/
├── modules/
│   └── launcher/
│       ├── Launcher.qml             # Main overlay window, state machine, and search bar
│       ├── AppItem.qml              # Application list row delegate with icon and metadata
│       ├── ActionItem.qml           # System action row delegate
│       ├── ThemeCard.qml            # Theme palette preview card with Material 3 mockup
│       ├── GadgetCard.qml           # Desktop widget toggle card with real-time UI preview
│       └── WallpaperCard.qml        # 16:9 wallpaper thumbnail card delegate
└── scripts/
    ├── list-apps.py                 # Fast desktop entry parser (exports JSON)
    ├── focus-player.sh              # MPRIS player window activator
    └── resolve-icons.sh             # Desktop icon path resolver
```

---

## Operational Modes

The launcher features an adaptive state machine driven by the bottom text input:

### 1. Application Search Mode (Default)
When the search bar contains text without command prefixes:
* Scans all installed desktop applications indexed by `list-apps.py`.
* Displays the official application icon, title in bold, and comment / category metadata.
* **Selection State:**
  * Active item receives a vibrant translucent primary tint (`rgba(primary, 0.22)`) and a 1.5 px glowing primary border.
  * A vertical accent pill indicator on the left edge marks the active selection.
  * Right edge renders a `[ 󰌑 Enter ]` badge.
  * Subtle scale expansion for the active icon and title.
* **Keyboard Navigation:** `Up` and `Down` arrow keys navigate the list with automated viewport scrolling (`positionViewAtIndex`). Pressing `Enter` executes the application, and `Escape` cancels.

### 2. Action / Command Mode (`/` or `>`)
Typing `/` or `>` switches the list view to system actions:
* **Wallpaper Carousel:** Switches to the wallpaper picker (`/wallpaper `).
* **Theme Carousel:** Switches to the visual theme picker (`/theme `).
* **Desktop Gadgets:** Opens the gadget management carousel (`/gadgets `).
* **Lock Screen:** Dispatches session lock via `hyprlock`.
* **Sleep / Suspend:** Triggers system suspend (`systemctl suspend`).
* **Power Controls:** System reboot and power off actions.

### 3. Theme Carousel Mode (`/theme`)
Typing `/theme `, `/tema `, `>theme `, or invoking `qs ipc call launcher theme` opens the horizontal theme picker:
* Expands the container into an interactive horizontal carousel (1080 px width, 340 px to 392 px height).
* **Theme Presets:**
  * **Wallpaper (Matugen):** Dynamic Material Design 3 extraction based on the active desktop wallpaper.
  * **Custom Accent:** Deep onyx black surfaces (`#0A0A0C`) paired with an interactive 10-color accent chip bar (`Carmesí`, `Lava`, `Ámbar`, `Esmeralda`, `Turquesa`, `Cyan`, `Cobalto`, `Amatista`, `Fucsia`, `Rosa`).
  * **Static Presets:** Cobalt Night, Amethyst, Arctic Mist, Crimson Night, and Cyberpunk.
* **Matugen Dynamic Modes Selector:** When Matugen is active, a top pill bar lets the user choose between 9 color generation algorithms (`Vibrant`, `Fruit Salad`, `Monochrome`, `Tonal Spot`, `Expressive`, `Rainbow`, `Fidelity`, `Content`, and `Neutral`) with live system-wide re-theming.
* **Live System Integration:** Selecting a theme persists it to `~/.config/quickshell/current-theme` and triggers `apply-theme.sh` or `apply-matugen.sh` across Waybar, Hyprland borders, Kitty, and Alacritty in real time.

### 4. Desktop Gadgets Mode (`/gadgets` or `/widgets`)
Typing `/gadgets `, `/widgets `, or invoking `qs ipc call launcher gadgets`:
* Displays 224x214 px cards with live previews of desktop widgets (`DeskClock`, `Calendar`, and hardware widgets).
* Status badge dynamically displays `Active` (green) or `Hidden` (muted).
* Pressing `Enter` or clicking toggles widget visibility instantly. Detailed in the [Desktop Gadgets Guide](gadgets.md).

### 5. Unified MPRIS Music Player Mode (`/music`)
Typing `/music `, `>music `, or pressing `SUPER + M` (`qs ipc call miniplayer toggle`):
* **Non-Modal Passthrough Surface:** Modal screen dimming is disabled (`dimBg.visible: false`) and keyboard grabs are relinquished (`WlrKeyboardFocus.None`), permitting full desktop interaction while music is open.
* **Input Region Masking:** Mouse events are restricted to the player card and fillets via `mask: Region { item: musicRegionItem }`. Clicks on empty screen space reach the underlying desktop windows.
* **MPRIS Controls:** Album art (140x140 px) with hover focus, track title, artist info, interactive seek bar, and transport controls (Previous, Play/Pause, Next).

---

## IPC Commands and Keybindings

```bash
# Toggle application launcher
qs ipc call launcher toggle

# Open command mode
qs ipc call launcher search ">"

# Open theme carousel directly
qs ipc call launcher theme
qs ipc call themepicker toggle

# Open desktop gadgets carousel
qs ipc call launcher gadgets

# Open unified bottom music player
qs ipc call launcher music
qs ipc call miniplayer toggle

# Programmatic selection navigation
qs ipc call launcher next
qs ipc call launcher prev
qs ipc call launcher activate
```

!!! note "IPC Note on Quickshell 0.3.1"
    In Quickshell 0.3.1, calling `qs ipc call <target> show` directly is not dispatchable. Use `toggle` to open and close windows, or `qs ipc call launcher search "<query>"`, which reliably reveals the drawer.

### Hyprland Integration (`~/.config/hypr/binds.conf`)

* `SUPER + Space`: Launches `~/.config/hypr/scripts/toggle-menu`, calling `qs ipc call launcher toggle` with Wofi as fallback.
* `SUPER + M`: Toggles the unified music player via `qs ipc call miniplayer toggle`.
* `SUPER + W`: Opens the wallpaper carousel via `qs ipc call launcher wallpaper`.

---

## Related Documentation

* [Wallpaper Engine](wallpapers.md): Wallpaper background transitions and carousel selector.
* [Desktop Gadgets](gadgets.md): Desktop ambient widgets managed via `/gadgets`.
* [Clipboard Manager](clipboard.md): Bottom-docked clipboard history panel.
* [Keyboard Shortcuts Overlay](shortcuts-overlay.md): System cheatsheet modal.
