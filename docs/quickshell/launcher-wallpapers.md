# Floating Launcher & Animated Wallpaper Carousel

Quickshell implements a floating bottom-center application launcher and animated wallpaper selector inspired by Caelestia Shell. The component is integrated directly with Wayland layershell, Matugen color extraction, and hardware-accelerated QML transitions.

---

## Architecture Overview

The system consists of two coordinated Quickshell modules:

1. **Floating Launcher & Dynamic Island Drawer (`modules/launcher/`):**
   * Placed on `WlrLayershell.layer: WlrLayer.Overlay`.
   * Horizontally centered and docked directly to the bottom edge of the display (`anchors.bottomMargin: 0`).
   * Dynamic Island emergence geometry: top corners rounded (`topLeftRadius: 28`, `topRightRadius: 28`), bottom corners square (`bottomLeftRadius: 0`, `bottomRightRadius: 0`), and borderless glass finish matching Waybar (`alpha 0.80`).
   * Hardware-accelerated dual concave fillets (`QtQuick.Shapes` with 28 px radius) smoothly bridging the bottom screen edge into both vertical shoulders of the card.
   * Search input at the bottom with real-time mode detection:
     * **Application Mode (default):** Lists system desktop entries with official icons, titles, and descriptions.
     * **Command / Actions Mode (`/` or `>`):** Activated by typing `/` (or `>`) to expose system commands.
     * **Wallpaper Carousel (`/wallpaper` / `SUPER + W`):** Horizontal card carousel featuring 16:9 previews, active wallpaper glow, and a local file explorer.
     * **Shader Selector (`/shader`):** Real-time hyprland post-processing screen shader carousel.
     * **Theme Carousel (`/theme`):** Material Design 3 and custom theme palette selector.
     * **Gadget Manager (`/gadgets`):** Ambient desktop widgets toggler.
     * **Music Player Mode (`/music` / `SUPER + M`):** Bottom-docked MPRIS controller with non-modal desktop click passthrough.
2. **Desktop Background Engine (`modules/background/Background.qml`):**
   * Placed on `WlrLayershell.layer: WlrLayer.Background` on all connected displays (`Quickshell.screens`).
   * Implements a double-buffer (ping-pong) layer switching architecture, guaranteeing reliable consecutive wallpaper transitions without QML property binding degradation.
   * Manages smooth cross-image animations, replacing static background setters like `swaybg`.
   * Applies the "Zoom & Blur" (Emergence) transition:
     * Outgoing wallpaper scales from 1.0 to 1.15 while fading opacity from 1.0 to 0.0 in 750 ms (`Easing.InOutQuad`).
     * Incoming wallpaper scales from 0.88 to 1.0 while fading opacity from 0.0 to 1.0 in 750 ms (`Easing.InOutQuad`).
   * Triggers `apply-matugen.sh` asynchronously to regenerate system palettes across Hyprland, Waybar, Alacritty, and Quickshell.

### Wallpaper Carousel Preview

![Quickshell Wallpaper Carousel](../assets/images/quickshell/launcher-wallpapers.png)

---

## File Structure

```text
quickshell/
├── GadgetsManager.qml               # Central desktop gadgets state and persistence manager
├── modules/
│   ├── background/
│   │   └── Background.qml           # Fullscreen background layer with Zoom & Blur transition
│   ├── gadgets/
│   │   └── GadgetHeader.qml         # Interactive drag handle, coordinates sync, and close button
│   └── launcher/
│       ├── Launcher.qml             # Main overlay window, state machine, and search bar
│       ├── WallpaperCard.qml        # 16:9 wallpaper thumbnail card and browse button
│       ├── ThemeCard.qml            # Theme palette preview card with Material 3 mockup
│       ├── GadgetCard.qml           # Desktop widget toggle card with real-time UI preview
│       ├── AppItem.qml              # Application list row delegate with icon and metadata
│       └── ActionItem.qml           # System action row delegate
└── scripts/
    ├── list-apps.py                 # Fast desktop entry parser (exports JSON)
    ├── browse-wallpaper.sh          # Zenity file picker integration
    └── resolve-icons.sh             # Desktop icon path resolver
```

---

## Operational Modes

### 1. Application Search Mode
When the search input is empty or contains standard text:
* Lists all installed `.desktop` applications discovered by `list-apps.py`.
* Shows application icon, title in bold, and comment / category description.
* **High-Contrast Selection Feedback:**
  * Active item receives a vibrant translucent primary tint (`rgba(primary, 0.22)`) and 1.5 px glowing primary border.
  * Vertical accent pill indicator on the left border.
  * Prominent `[ 󰌑 Enter ]` badge on the right edge.
  * Dynamic icon and title scale expansion.
* Keyboard navigation: `Up` / `Down` arrows move selection with automatic viewport positioning (`positionViewAtIndex`), `Enter` executes the application and closes the launcher, `Escape` cancels.

### 2. Action / Command Mode (`/` or `>`)
Typing `/` (or `>`) filters available system commands:
* **Wallpaper Carousel:** Enters the horizontal wallpaper picker carousel (`/wallpaper `).
* **Theme Carousel:** Enters the horizontal visual theme picker carousel (`/theme `).
* **Lock Screen:** Locks session using `hyprlock`.
* **Sleep / Suspend:** Suspends the machine to RAM (`systemctl suspend`).
* **Restart System / Shut Down:** Session reboot and power-off actions.

### 3. Wallpaper Carousel Mode
Typing `/wallpaper ` (or pressing `SUPER + W`) opens the horizontal carousel:
* Expanded floating card container (1080 px width, 340 px height, 24 px radius) offering generous horizontal and vertical headroom.
* **Caelestia Shell Containment & Edge Fade Overlays:**
  * Strict clipping (`clip: true`) enforced across the floating dock card, content viewport, and horizontal list view, eliminating lateral overflow beyond container boundaries.
  * Left and right 32 px horizontal gradient fade overlays that smoothly blend scrollable cards into the dark dock background without hard cutoffs.
* Displays 16:9 cards (224x214 px with 120 px thumbnail height) generated from `/home/zero/Pictures/walls/` and cached in `~/.cache/wallpapers/`.
* **Hover & Selection Styling:**
  * Dynamic elevation: Cards lift upward by -5 px on hover (-2 px on keyboard selection).
  * Smooth scale: Subtle 1.05 expansion on hover (1.03 on keyboard selection) with `Easing.OutCubic`.
  * Internal thumbnail zoom: 16:9 thumbnail expands to 1.05 within rounded bounds.
  * Vibrant halo glow: Border widens to 2 px with primary accent color and expanded glow margins.
* **Active Badge:** The currently active desktop wallpaper is highlighted with an "Active" badge and a focused double border.
* **Add Local File Card:** Positioned at the end of the carousel. Clicking or pressing `Enter` opens a native file dialog (`zenity`) to import external images, automatically caching thumbnails and applying the wallpaper.

### 4. Theme Carousel Mode
Typing `/theme ` or `/tema ` (also `>theme `), clicking "Theme" in the Control Center, or executing `qs ipc call launcher theme` opens the horizontal theme carousel:
* Reuses the same 1080 px floating container (smoothly expanding from 340 px to 392 px height when Matugen or Custom is selected) and horizontal scroll architecture as the wallpaper carousel.
* **Featured Themes Order:**
  * **1. Wallpaper (Matugen):** Dynamic Material Design 3 generation based on active wallpaper.
  * **2. Custom Accent:** Fixed deep onyx black surfaces (`#0A0A0C`) with interactive accent color chip selector.
  * **Static Presets:** Cobalt Night, Amethyst, Arctic Mist, Crimson Night, and Cyberpunk.
* **Matugen Dynamic Modes Selector:**
  * When "Wallpaper (Matugen)" is selected or active, an animated top header gracefully expands with Material You mode pills for all 9 Matugen color scheme algorithms: `Vibrant`, `Fruit Salad`, `Monochrome`, `Tonal Spot`, `Expressive`, `Rainbow`, `Fidelity`, `Content`, and `Neutral`.
  * **Live Palette Preview:** Clicking any mode chip immediately applies that scheme via `apply-matugen.sh` in the background, updating desktop accent colors and Quickshell in real-time without dismissing the launcher.
  * The active scheme type is saved to `~/.config/themes/current/scheme_type` and preserved across subsequent wallpaper transitions.
* **Custom Accent Color Bar:**
  * When "Custom" is selected, an animated top bar expands with interactive color pills (`Carmesí`, `Lava`, `Ámbar`, `Esmeralda`, `Turquesa`, `Cyan`, `Cobalto`, `Amatista`, `Fucsia`, `Rosa`).
  * Clicking any accent immediately updates Quickshell, saves the preference to `~/.config/quickshell/custom-accent`, and executes `apply-theme.sh custom` across Waybar, Hyprland borders, Kitty, and Alacritty in real-time.
* **Visual Theme Cards (`ThemeCard.qml`):**
  * Displays 224x214 px cards with a dedicated 120 px preview container showcasing an interface mockup for each palette.
  * Preview includes a miniature header, active primary widget, slider with active track, accent chip, and 5 color swatches (`primary`, `primaryContainer`, `surfaceContainerHigh`, `connected`, `textPrimary`).
  * Palette colors resolve via explicit `Qt.color` conversion, ensuring accurate rendering across static palettes, dynamic Custom accents, and Matugen extractions.
  * An "Active" badge dynamically marks the currently applied theme.
* **Interactive Behavior:**
  * Selecting a card applies the theme instantly via `Theme.currentTheme`, persists it to `~/.config/quickshell/current-theme`, triggers `apply-theme.sh` or `apply-matugen.sh` across the system, and closes the launcher on `Enter`.
  * Full keyboard support with `Left` / `Right` navigation, `Enter` to apply, and text filtering (e.g. `>theme cobalt`).

### 5. Desktop Gadgets Mode (`/gadgets` or `/widgets`)
Typing `/gadgets `, `/widgets `, or `/gadget ` (also with `>`), selecting "Desktop Gadgets" from the `/` commands list, or running `qs ipc call launcher gadgets` opens the desktop gadgets carousel:
* **Interactive Gadget Cards (`GadgetCard.qml`):**
  * Displays 224x214 px cards showcasing live visual mockups of desktop widgets (`DeskClock`, `Calendar`, and future extensions).
  * Top-right badge dynamically indicates status: green `Active` checkmark or muted `Hidden` badge.
  * Clicking any card or pressing `Enter` toggles the gadget visibility on the desktop in real time.
* **On-Desktop Interaction (`GadgetHeader.qml`):**
  * **Smooth Proximity Reveal:** Desktop gadgets feature an integrated header that stays invisible during normal use and reveals smoothly (`opacity: 1.0` in 220 ms) when hovering over the widget.
  * **Freeform Drag Handle:** A centered Material You style drag pill allows repositioning the widget freely across the screen. Coordinates are calculated dynamically using Layershell panel margins and automatically saved to `~/.config/quickshell/gadgets.json`.
  * **Close Button (`✕`):** Clicking the close button in the header hides the gadget immediately and updates state persistence. The gadget can be restored at any time via the `/gadgets` launcher carousel.

### 6. Unified Music Player Mode (`/music`)
Typing `/music `, `/musica `, `>music `, or pressing `SUPER + M` (`qs ipc call miniplayer toggle`) opens the unified bottom-docked music player:
* **Non-Modal Passthrough Surface:**
  * Disables modal screen dimming (`dimBg.visible: false`).
  * Relinquishes keyboard focus grabs (`WlrKeyboardFocus.None`), allowing full desktop interaction while music is open.
  * Masks mouse pointer events strictly to the active player card and its bottom fillets via `mask: Region { item: musicRegionItem }`, ensuring all transparent desktop areas pass clicks directly to background windows.
* **Full MPRIS Controls:**
  * 140x140 px album art with hover focus overlay (clicking raises or launches the player application using `focus-player.sh`).
  * Track title and artist / identity labels with text truncation.
  * Interactive seekable progress bar with real-time position polling and `mm:ss` timestamp indicators.
  * Previous, Play/Pause toggle, and Next playback controls.
  * Explicit close button (`✕`) in the player header and search bar.

---

## IPC Commands and Keybindings

The launcher and background engine expose IPC endpoints:

```bash
# Toggle application launcher
qs ipc call launcher toggle

# Open unified music player directly
qs ipc call launcher music
qs ipc call miniplayer toggle

# Open wallpaper carousel directly
qs ipc call launcher wallpaper

# Open theme carousel directly
qs ipc call launcher theme
qs ipc call themepicker toggle

# Open desktop gadgets carousel directly
qs ipc call launcher gadgets

# Toggle individual gadgets via IPC
qs ipc call gadgets toggle deskclock
qs ipc call gadgets toggle calendar

# Navigate selection via IPC
qs ipc call launcher next
qs ipc call launcher prev
qs ipc call launcher activate

# Filter commands or text via IPC
qs ipc call launcher search ">"
qs ipc call launcher search "/gadgets"

# Set wallpaper programmatically with animated transition
qs ipc call wallpaper set "/path/to/image.png"

# Close the launcher (the same command reopens it)
qs ipc call launcher toggle
```

**Note:** `hide()` works over IPC, but `qs ipc call <target> show` is not dispatchable in Quickshell 0.3.1: the CLI prints the target's function list and the panel stays closed (reproduced on `launcher`, `clipboard` and `controlcenter`). Use `toggle` to open and close a panel, or `qs ipc call launcher search "<query>"`, which always sets the launcher visible.

### Hyprland Integration (`~/.config/hypr/binds.conf`)

* `SUPER + Space`: Runs `~/.config/hypr/scripts/toggle-menu`, invoking `qs ipc call launcher toggle` with Wofi as fallback.
* `SUPER + W`: Invokes `qs ipc call launcher wallpaper` to present the wallpaper carousel.
