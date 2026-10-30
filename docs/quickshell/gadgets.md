# Desktop Gadgets Suite

The Quickshell Desktop Gadgets system provides a lightweight, borderless, and containerless desktop widget ecosystem built natively for Wayland and Hyprland. Designed with zero visual clutter, each gadget floats directly above the desktop wallpaper without artificial background panels, window borders, or blur boxes, blending seamlessly into your active workspace.

The suite features 6 ambient desktop gadgets powered by Qt Quick, Wayland Layer Shell input masking, and reactive Python telemetry backends, with real-time drag-and-drop repositioning, bidirectional JSON persistence, and full IPC automation.

---

## Architecture & Visual Overview

```mermaid
flowchart TD
    subgraph Wayland Compsitor ["Wayland & Hyprland Environment"]
        LayerShell["WlrLayershell (WlrLayer.Bottom)"]
        Exclusion["ExclusionMode.Ignore (Zero Window Displacement)"]
        Mask["Dynamic Input Mask (Region item: mainCard)"]
    end

    subgraph Native Interaction Engine ["Zero-Jitter Drag & Interaction"]
        MouseArea["MouseArea (drag.target: mainCard)"]
        HighFPS["Direct Native GPU Drag @ Monitor Refresh Rate"]
        HoverControls["Discrete Hover Controls (Close ✕ & Cycle 󰑐)"]
    end

    subgraph Desktop Gadgets ["The 6 Desktop Gadgets"]
        DeskClock["Desk Clock (DeskClock.qml)"]
        Calendar["Desktop Calendar (Calendar.qml)"]
        Weather["Weather Forecast (WeatherGadget.qml)"]
        HwPulse["Hardware Pulse (HardwarePulse.qml)"]
        Scratchpad["Ambient Scratchpad (Scratchpad.qml)"]
        DailySpark["Daily Spark (DailySpark.qml)"]
    end

    subgraph State & Persistence ["Central State Management"]
        Manager["GadgetsManager.qml (Singleton)"]
        ConfigJSON["~/.config/quickshell/gadgets.json"]
        ScratchJSON["~/.config/quickshell/scratchpad.json"]
    end

    subgraph Control Surfaces ["Invocation & IPC Interfaces"]
        Launcher["Quickshell Launcher (/gadgets Carousel)"]
        CLI["Quickshell IPC (qs ipc call ...)"]
        Keybinds["Hyprland Keybindings & Scripts"]
    end

    LayerShell & Exclusion --> Mask
    Mask --> MouseArea
    MouseArea --> HighFPS
    HighFPS -->|On Released: Math.round(x, y)| Manager
    HoverControls --> Manager

    DeskClock & Calendar & Weather & HwPulse & Scratchpad & DailySpark --> Manager
    Manager <-->|Async Process read/write| ConfigJSON
    Scratchpad <-->|Async Process read/write| ScratchJSON

    Launcher <-->|Toggle / Preview Cards| Manager
    CLI -->|IPC Handlers| Manager
    Keybinds --> CLI
```

---

## File Structure

```text
quickshell/
├── GadgetsManager.qml                    # Central state manager, coordinate storage & IPC router
├── gadgets.json                         # Default coordinate and visibility state map
├── data/
│   ├── quotes.json                      # Curated dictionary of philosophical & tech quotes
│   └── scratchpad.json                  # Default task items and to-do fallback seed
├── modules/
│   ├── deskclock/
│   │   └── DeskClock.qml                # Monumental 168px digital clock & day progress meter
│   ├── calendar/
│   │   └── Calendar.qml                 # Interactive monthly calendar with month navigation
│   ├── weathergadget/
│   │   └── WeatherGadget.qml            # Live weather telemetry & 2-day forecast card
│   ├── hardwarepulse/
│   │   └── HardwarePulse.qml            # Real-time CPU, RAM, thermal alerts & battery pulse
│   ├── scratchpad/
│   │   └── Scratchpad.qml               # Interactive to-do checklist with inline creation
│   ├── dailyspark/
│   │   └── DailySpark.qml               # Curated quotes card with 3-hour auto-rotation
│   └── launcher/
│       ├── Launcher.qml                 # Launcher container hosting the /gadgets mode
│       └── GadgetCard.qml               # 224x214 px carousel card with live gadget UI mockups
└── scripts/
    ├── hardware-pulse.py                # Telemetry collector (/proc & /sys parser, zero dependencies)
    └── weather.py                       # Weather daemon with caching & wttr.in fallback
```

---

## Core Engineering Principles

### 1. Borderless & Containerless Visual Philosophy
Unlike traditional desktop widgets that wrap content inside heavy translucent glass cards, drop shadows, or bounding borders, Quickshell Desktop Gadgets are completely **borderless and containerless**. Typography, icons, and progress meters float directly over the desktop background. This minimalist design ensures that your wallpaper remains the focal point while ambient information stays legible and unobtrusive.

### 2. Fullscreen Bottom Layer (`WlrLayer.Bottom`)
Each gadget is hosted inside an individual `PanelWindow` configured with:
* `WlrLayershell.layer: WlrLayer.Bottom`: The window renders directly above the desktop wallpaper (`WlrLayer.Background`) but strictly below regular application windows (`WlrLayer.Top` and normal Wayland surfaces). Application windows tile and float across gadgets without any z-order interference.
* `exclusionMode: ExclusionMode.Ignore`: Informs the compositor (Hyprland) that gadgets do not reserve screen space. They cause **zero window layout displacement**, never compressing your tiling columns or shifting panels like Waybar.
* `WlrLayershell.keyboardFocus: WlrKeyboardFocus.None`: The layer shell surface does not trap global keyboard focus, ensuring normal shortcuts continue to function without interruption.

### 3. Dynamic Wayland Input Masking (`mask: Region`)
In Wayland Layer Shell, a transparent fullscreen surface would normally capture all mouse input, blocking clicks to desktop icons, wallpaper menus, or underlying windows. 

To resolve this, every gadget employs dynamic input masking:

```qml
mask: Region {
    item: mainCard
}
```

The compositor restricts hit-testing strictly to the bounding geometry of `mainCard`. Any mouse click outside the active card passes directly through to the desktop background or the window underneath.

### 4. Direct Native Drag ("Drag Anywhere")
Conventional Wayland floating widgets often suffer from severe cursor jitter or rubber-banding during mouse dragging, caused by round-trip latency between client-side drag events and compositor surface repositioning requests.

Quickshell eliminates this bottleneck through a **Direct Native Drag** design:
1. The `PanelWindow` stays anchored fullscreen (`top`, `bottom`, `left`, `right: true`).
2. Inside the window, `mainCard` uses Qt Quick's hardware-accelerated `MouseArea`:
   ```qml
   MouseArea {
       id: dragArea
       anchors.fill: parent
       cursorShape: pressed ? Qt.ClosedHandCursor : (containsMouse ? Qt.OpenHandCursor : Qt.ArrowCursor)
       drag.target: mainCard
       drag.axis: Drag.XAndYAxis
       onPressed: mainCard.isDragging = true
       onReleased: {
           var fx = Math.round(mainCard.x)
           var fy = Math.round(mainCard.y)
           Root.GadgetsManager.setPosition("gadgetId", fx, fy)
           mainCard.isDragging = false
       }
   }
   ```
3. Moving the gadget executes locally on the GPU at your monitor's native refresh rate (144Hz, 165Hz, or 240Hz) with zero compositor round-trips.
4. When released, integer coordinates (`Math.round`) are committed to `GadgetsManager.qml` and saved to disk.

### 5. Discrete Hover Controls
Gadgets do not render permanent title bars or close icons. Instead, moving the mouse over the gadget card smoothly reveals contextual controls via an animated opacity transition (`NumberAnimation { duration: 180 }`):
* **Close Button (`✕`):** Positioned in the upper-right corner. Clicking it invokes `GadgetsManager.setEnabled(id, false)`, hiding the gadget instantly and updating persistent storage.
* **Action Icons:** Gadgets like Daily Spark reveal interactive cycling buttons (`󰑐`) only when hovered.

---

## Detailed Gadget Catalog

### 1. Desk Clock (`DeskClock.qml`)

A monumental digital clock designed to anchor the desktop with large typography, daily progress tracking, and contextual greetings.

```text
┌────────────────────────────────────────────────────────┐
│                                                      ✕ │
│                                                        │
│                        14•28                           │
│                                                        │
│            [========================......]            │
│                          60%                           │
│                                                        │
│              Buenas tardes, seguimos en la lucha.      │
│                                                        │
└────────────────────────────────────────────────────────┘
```

#### Key Capabilities:
* **Monumental Typography:** Time display rendered in 168 px bold digits (scaled +40% over standard displays) using `style: Text.Sunken` and dynamic `Theme.primary` color highlight.
* **Day Progress Meter:** Calculates elapsed daytime fraction ($t_{\text{total}} = h \times 3600 + m \times 60 + s$) relative to the full 86,400-second day:
  $$\text{Progress} = \frac{h \times 3600 + m \times 60 + s}{86400}$$
  Renders a 14 px rounded progress bar with smooth 1000 ms cubic easing (`Easing.OutCubic`) accompanied by an exact percentage readout (e.g. `58%`).
* **Contextual Greeting Engine:** Automatically switches tone across 6 distinct time-of-day slots:
  
  | Time Range | Time Slot | Sample Greetings |
  | :--- | :--- | :--- |
  | `06:00 – 10:59` | Morning | *"Good morning, have a great day."*, *"Rise and shine."*, *"Let's make it count."* |
  | `11:00 – 13:59` | Lunch / Midday | *"Lunch time, a comer como Dios manda."*, *"It's lunch o'clock. Buen provecho."* |
  | `14:00 – 17:59` | Afternoon | *"Buenas tardes, keep going."*, *"Good afternoon. You got this."* |
  | `18:00 – 21:59` | Evening | *"Good evening, you made it."*, *"Buenas noches. We survived another one."* |
  | `22:00 – 02:59` | Bedtime | *"Bro, seriously? A mimir."*, *"It's 22:00. What are you doing?"*, *"Sleep.exe should be running."* |
  | `03:00 – 05:59` | Deep Night / Dawn | *"¿Quién te hizo tanto daño?"*, *"Bro... who hurt you?"*, *"It's 4 AM. We need to talk."* |

---

### 2. Desktop Calendar (`Calendar.qml`)

A clean, interactive monthly calendar matrix providing immediate date awareness without launching an external calendar suite.

```text
┌──────────────────────────────────────────────┐
│                                            ✕ │
│            ‹    October 2026    ›            │
│                     [Today]                  │
│                                              │
│   Sun   Mon   Tue   Wed   Thu   Fri   Sat    │
│                     1     2     3     4      │
│    5     6     7     8     9    10    11      │
│   12    13    14    15    16    17    18      │
│   19    20    21    22    23    24    25      │
│   26    27    28    [29]  30    31           │
└──────────────────────────────────────────────┘
```

#### Key Capabilities:
* **Interactive Navigation:** Dedicated previous (`‹`) and next (`›`) month navigation controls with automatic year roll-over and an instant "Today" reset button.
* **Dynamic Grid Computation:** Automatically calculates days in month (`new Date(year, month + 1, 0).getDate()`) and leading weekday offsets (`new Date(year, month, 1).getDay()`).
* **Active Day Indicator:** Highlights the current date with a rounded `Theme.primary` accent badge and bold high-contrast text. Inactive dates show muted text, with interactive hover highlights across all dates.

---

### 3. Weather Forecast (`WeatherGadget.qml`)

An ambient meteorological station delivering live local conditions and short-term forecasting.

```text
┌──────────────────────────────────────────┐
│                                        ✕ │
│   󰖐  21°       Bogota                    │
│                Partly cloudy             │
│                Feels like 20°  •  62%    │
│                                          │
│   ┌──────────────────┐┌────────────────┐ │
│   │ Tomorrow         ││ Overmorrow     │ │
│   │ 󰖐 20°            ││ 󰖖 19°          │ │
│   └──────────────────┘└────────────────┘ │
└──────────────────────────────────────────┘
```

#### Key Capabilities:
* **Telemetry Engine:** Powered by `quickshell/scripts/weather.py`. Automatically queries `wttr.in` without requiring mandatory API keys, with transparent caching (`~/.cache/weather.json`) and OpenWeatherMap fallback support.
* **Live Weather Data:**
  * Real-time temperature and felt temperature (`feels_like`).
  * Current meteorological condition description and location name.
  * Dynamic Material Design weather icon mapping (`wb_sunny`, `partly_cloudy_day`, `rainy`, `thunderstorm`, etc.).
  * Relative ambient humidity percentage.
* **2-Day Forecast Cards:** Displays cards for Tomorrow and Overmorrow, including weather icons, conditions, and expected temperatures.
* **Update Cadence:** Automatically refreshes every 15 minutes (`900,000 ms`), with instant on-demand refresh available via IPC (`qs ipc call weathergadget refresh`).

---

### 4. Hardware Pulse (`HardwarePulse.qml`)

A minimalist system telemetry monitor tracking hardware load, thermal safety, and power status.

```text
┌────────────────────────────────────────────┐
│ HARDWARE PULSE                      72°C ✕ │
│                                            │
│ 󰍛 CPU                              42.5%  │
│ [==================......................] │
│                                            │
│ 󰘚 RAM                     6.4 / 15.8 GB   │
│ [===================.....................] │
│                                            │
│ 󰂄 BATTERY                 88% (Charging)  │
└────────────────────────────────────────────┘
```

#### Key Capabilities:
* **Ultra-Fast Linux Sysfs Parser:** Driven by `quickshell/scripts/hardware-pulse.py`. Reads `/proc/stat`, `/proc/meminfo`, `/sys/class/thermal/`, and `/sys/class/power_supply/` directly in Python. Requires zero external pip packages and executes in under 5 ms.
* **CPU Load & Reactive Thermal Alerts:**
  * Real-time CPU percentage with a responsive fill bar.
  * Temperature readout (`cpuTemp`).
  * **Reactive Thermal Warning:** When the CPU temperature reaches or exceeds 80°C (`cpuTemp >= 80`), the temperature readout dynamically shifts to high-visibility alert color (`Theme.error`).
* **Memory Telemetry:** Displays currently consumed memory against total physical RAM in GB (`6.4 / 15.8 GB`), accompanied by a proportional load bar.
* **Intelligent Battery Monitor:** Displays charge percentage, charging state (Charging, Discharging, Full), and dynamic battery glyphs (`󰂄`, `󰁹`, `󰂀`). On desktop systems without a battery, the battery row is automatically hidden (`batteryLevel < 0`).
* **Update Interval:** Polls hardware vitals every 3 seconds (`3000 ms`).

---

### 5. Ambient Scratchpad (`Scratchpad.qml`)

A permanent, floating desktop to-do checklist and scratchpad for quick capture of thoughts, tasks, and commands.

```text
┌────────────────────────────────────────────┐
│ SCRATCHPAD                   2 pending   ✕ │
│                                            │
│ 󰄵  Refine Hyprland & Waybar config         │
│ 󰄱  Customize new Quickshell gadgets    [✕] │
│ 󰄱  Audit network security rules            │
│                                            │
│ +  Add new task and press Enter…           │
└────────────────────────────────────────────┘
```

#### Key Capabilities:
* **Interactive Checklist:**
  * Click any task row to toggle completion. Checked tasks receive strikethrough typography (`font.strikeout: true`), dimmed opacity, and an updated checkbox glyph (`󰄵` vs `󰄱`).
  * Hovering over any item reveals an inline deletion button (`✕`) to remove the entry.
* **Inline Task Creation:**
  * Bottom input field with italicized placeholder (`"Add new task and press Enter…"`).
  * Type a note and press `Enter` to append it immediately with a unique timestamp identifier.
* **Live Header Counter:** Displays the number of active uncompleted tasks in real time (e.g., `2 pending`).
* **Bidirectional JSON Persistence:** Reads and writes to `~/.config/quickshell/scratchpad.json` via asynchronous background processes, ensuring tasks survive desktop restarts.

---

### 6. Daily Spark (`DailySpark.qml`)

A desktop quote widget delivering curated philosophy, engineering wisdom, and design principles.

```text
┌────────────────────────────────────────────────────────┐
│                                                      ✕ │
│   “Simplicity is prerequisite for reliability.”        │
│                                                        │
│               — Edsger W. Dijkstra   [󰑐]               │
└────────────────────────────────────────────────────────┘
```

#### Key Capabilities:
* **Curated Wisdom Dictionary:** Reads from `quickshell/data/quotes.json` (fallback `~/.config/quickshell/data/quotes.json`). Features thought leaders including:
  * **Philosophy:** Seneca, Marcus Aurelius, Epictetus, Lao Tzu.
  * **Computer Science & Engineering:** Edsger W. Dijkstra, Linus Torvalds, Alan Kay, Donald Knuth.
  * **Design & Simplicity:** Dieter Rams, Steve Jobs.
* **Automatic 3-Hour Rotation:** Automatically advances to a new quote every 3 hours (`10,800,000 ms`) via an internal timer.
* **Hover Cycle Button:** Hovering over the card reveals an icon button (`󰑐`) next to the author's name, allowing instant manual cycling to the next quote.

---

## State Management & Persistence

All gadget states (visibility and screen coordinates) are centrally managed by the singleton `GadgetsManager.qml` and persisted to `~/.config/quickshell/gadgets.json`.

### `gadgets.json` Schema

```json
{
  "deskclock": {
    "enabled": true,
    "x": 670,
    "y": 100
  },
  "calendar": {
    "enabled": false,
    "x": 1460,
    "y": 650
  },
  "weather": {
    "enabled": false,
    "x": 1480,
    "y": 120
  },
  "hardwarepulse": {
    "enabled": true,
    "x": 80,
    "y": 120
  },
  "scratchpad": {
    "enabled": true,
    "x": 80,
    "y": 650
  },
  "dailyspark": {
    "enabled": true,
    "x": 560,
    "y": 720
  }
}
```

### Persistence Mechanics:
* **Non-Blocking Startup:** `readProc` runs asynchronously during `Component.onCompleted`, merging saved coordinates and flags over default values without freezing Quickshell initialization.
* **Atomic Shell Write:** When a gadget is repositioned or toggled, `GadgetsManager.saveState()` executes an asynchronous shell command with escaped JSON, writing atomically to `~/.config/quickshell/gadgets.json`.
* **State Signal Propagation:** Emits `stateChanged()`, synchronizing all open panels and the launcher carousel simultaneously.

---

## Application Launcher Integration (`/gadgets`)

The desktop gadgets suite is directly integrated into Quickshell's bottom launcher drawer:

1. Open the launcher (`SUPER + Space` or `qs ipc call launcher toggle`).
2. Type `/gadgets`, `/widgets`, or `/gadget` (or trigger it directly via `qs ipc call launcher gadgets`).
3. The launcher smoothly transitions into a horizontal card carousel displaying `GadgetCard.qml` instances for all 6 gadgets.

### Features of the Gadgets Carousel:
* **Real-Time UI Mockups:** Each 224x214 px card renders a dedicated 120 px live visual preview of the gadget's actual appearance and layout.
* **Dynamic Status Badges:** Cards display a green `Active` badge with checkmark or a muted `Hidden` badge indicating the gadget's current desktop state.
* **Interactive Toggling:** Click any card or press `Enter` to instantly show or hide that gadget on the desktop.
* **Smooth Elevations:** Cards feature hover lift animations (`y: -5 px`, `scale: 1.05`) with primary accent glows matching the system theme.

---

## Complete IPC Command Reference

Every gadget and the central manager register dedicated IPC endpoints reachable via the `qs ipc call` utility:

### Central Gadget Manager (`gadgets`)

| Command | Description |
| :--- | :--- |
| `qs ipc call gadgets toggle <id>` | Toggles visibility of the specified gadget (`deskclock`, `calendar`, `weather`, `hardwarepulse`, `scratchpad`, `dailyspark`) |
| `qs ipc call gadgets show <id>` | Enables and displays the specified gadget |
| `qs ipc call gadgets hide <id>` | Disables and hides the specified gadget |

### Individual Gadget Endpoints

| Target | Command | Parameters | Description |
| :--- | :--- | :--- | :--- |
| `deskclock` | `qs ipc call deskclock toggle` | — | Toggle Desk Clock visibility |
| `deskclock` | `qs ipc call deskclock move <x> <y>` | `int x, int y` | Reposition clock to absolute coordinates |
| `calendar` | `qs ipc call calendar toggle` | — | Toggle Desktop Calendar visibility |
| `calendar` | `qs ipc call calendar move <x> <y>` | `int x, int y` | Reposition calendar to absolute coordinates |
| `weathergadget` | `qs ipc call weathergadget toggle` | — | Toggle Weather Forecast visibility |
| `weathergadget` | `qs ipc call weathergadget refresh` | — | Force immediate weather telemetry update |
| `hardwarepulse` | `qs ipc call hardwarepulse toggle` | — | Toggle Hardware Pulse visibility |
| `hardwarepulse` | `qs ipc call hardwarepulse refresh` | — | Force immediate hardware metrics update |
| `scratchpad` | `qs ipc call scratchpad toggle` | — | Toggle Ambient Scratchpad visibility |
| `scratchpad` | `qs ipc call scratchpad add "<text>"` | `string text` | Append a new to-do task remotely via CLI |
| `dailyspark` | `qs ipc call dailyspark toggle` | — | Toggle Daily Spark visibility |
| `dailyspark` | `qs ipc call dailyspark next` | — | Cycle immediately to the next quote |

### Launcher Gadgets Carousel

| Command | Description |
| :--- | :--- |
| `qs ipc call launcher gadgets` | Opens the launcher directly in `/gadgets` carousel mode |

---

## Troubleshooting & Maintenance

??? question "How do I reset all gadgets to their default positions?"
    To restore factory coordinate positions, stop Quickshell and delete or reset the configuration file:
    ```bash
    killall quickshell
    rm ~/.config/quickshell/gadgets.json
    quickshell &
    ```
    Quickshell will regenerate `gadgets.json` with standard balanced coordinates.

??? question "A gadget does not respond to clicks outside its card"
    This indicates that Wayland input masking is working properly. The transparent fullscreen window deliberately passes all clicks through to your wallpaper or underlying windows. Clicks are only captured directly on the widget's content area (`mask: Region { item: mainCard }`).

??? question "Weather widget displays 'Loading...' or fallback data"
    Verify internet connectivity and test the backend script manually in your terminal:
    ```bash
    python3 ~/.config/quickshell/scripts/weather.py
    ```
    If `wttr.in` is temporarily rate-limited, ensure `~/.cache/weather.json` is writable. You can optionally export your OpenWeatherMap key in `~/.config/weather/api_key` and city in `~/.config/weather/city`.

??? question "Hardware Pulse CPU temperature reads 0°C"
    Check your Linux thermal zone permissions:
    ```bash
    ls -l /sys/class/thermal/thermal_zone*/temp
    ```
    On custom kernels or non-standard hardware, verify which thermal zone corresponds to your CPU package and ensure unprivileged read access is permitted.
