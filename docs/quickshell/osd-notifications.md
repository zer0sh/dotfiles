# Notifications & OSDs

This guide details the architecture, screen positioning, and animation dynamics for **floating notification toasts** and **on-screen display (OSD) cards** (Volume, Brightness, Music, and Mini Player) in Quickshell for Hyprland.

---

## 📐 Design Parameters & Dynamics

All floating indicators follow a standardized behavioral contract:

1. **Screen Placement:** Top of the screen, horizontally centered (`anchors.top: true`, `anchors.horizontalCenter: parent.horizontalCenter`).
2. **Top Margin:** `topMargin: 46 px` (reserves a comfortable visual gap beneath Waybar's 36 px height).
3. **Entrance Animation (Downward Slide):**
   * Translates from `_slideY: -28` to `0` over 260–280 ms using `Easing.OutCubic` acceleration.
   * Fades in opacity from `0` to `1` over 220 ms using `Easing.OutQuad`.
4. **Queue Dynamics:** When a new notification arrives, it occupies the top slot and fluidly pushes older active notifications downward using `move: Transition`.
5. **Dismissal Animation:** Gently moves upward (`to: -20`) and fades out (`opacity: 0`) before unmounting from the model.

---

## 📂 Source Files Map

| Component | Source File | Responsibility |
| :--- | :--- | :--- |
| **Toast Window** | `modules/notifications/NotificationToastLayer.qml` | Overlay window, model prepending (`insert(0)`), and column move transition. |
| **Notification Card** | `modules/notifications/NotificationPopup.qml` | Card styling, slide-down appearance, and dismissal animations. |
| **Volume OSD** | `modules/osd/VolumeOsd.qml` | Listens to PipeWire sink changes and animates top-center card. |
| **Brightness OSD** | `modules/osd/BrightnessOsd.qml` | Listens to `brightnessctl` and animates top-center card. |
| **Music Track Toast** | `modules/osd/MusicOsd.qml` | Automatic top-center popup on MPRIS track transition. |
| **Mini Music Player** | `modules/osd/MiniPlayer.qml` | Interactive player triggered via `SUPER + M`. |

---

## 🛠️ Making Future Adjustments

### Adjusting Vertical Distance
Edit `topMargin` in the container `Item` or `toastCol`:
```qml
anchors.topMargin: 46 // Increase to push further down, decrease to lift closer to bar
```

### Changing Animation Speed
Inside the `appearAnim` block:
```qml
NumberAnimation {
    target: osdCard; property: "_slideY"
    from: -28; to: 0; duration: 260; easing.type: Easing.OutCubic
}
```

### Live Testing
* **Trigger notification:**
  ```bash
  notify-send "Test" "Smooth slide-down animation"
  ```
* **Trigger volume OSD:**
  ```bash
  wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
  ```
