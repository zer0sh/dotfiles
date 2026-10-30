# Notifications & OSDs

This guide details the architecture, screen positioning, and animation dynamics for **floating notification toasts** and **on-screen display (OSD) cards** (Volume, Brightness, and Song Transition OSD) in [Quickshell](index.md) running on the [Hyprland compositor](../hyprland/index.md).

---

## Design Parameters and Dynamics

All floating indicators follow a standardized behavioral contract:

1. **Dynamic Island Integration with Waybar:**
   * **Placement:** Anchored to the top of the screen and centered horizontally (`anchors.top: true`, `anchors.horizontalCenter: parent.horizontalCenter`).
   * **Top Anchor:** Directly docked beneath Waybar (`topMargin: Root.Theme.shelfHeight`, 36 px) with zero dead space.
   * **Concave Shoulders:** Dual hardware-accelerated concave fillets (`QtQuick.Shapes` with a 28 px radius and `PathArc`) smoothly bridge Waybar's horizontal lower edge with the toast container's vertical shoulders.
   * **Corner Radii:** Square top corners (`topLeftRadius: 0`, `topRightRadius: 0`) and generously rounded bottom corners (`bottomLeftRadius: 28`, `bottomRightRadius: 28`).
   * **Surface Finish:** Borderless translucent glass surface (`border.width: 1`, hairline outline) with exact opacity and color parity (`alpha 0.80`, `Qt.rgba(panelBg.r, panelBg.g, panelBg.b, 0.80)`) matching Waybar's `window#waybar` background (`alpha(@bg, 0.80)` on `#0A0A0C`). Both the notification cards and the concave shoulder fillets share this identical alpha channel, eliminating darker contrast boundaries.
2. **Theming:** Colors, translucency, and accents are rendered dynamically using [Matugen Dynamic Palette Tokens](../apps/matugen.md#core-color-roles) (`_shelfBgColor`, `primary`, `textPrimary`, `textSecondary`).
3. **Entrance Animation (Emergence from Waybar):**
   * Encapsulated within a clipped viewport (`clip: true`) so notifications physically slide out from beneath Waybar.
   * Translates from `_slideY: -height` to `0` over 280 ms using `Easing.OutCubic` acceleration.
   * Fades in opacity from `0` to `1` over 200 ms using `Easing.OutQuad`.
4. **Queue Dynamics:** When a new notification arrives, it prepends to the stack (`insert(0)`) and fluidly pushes older active notifications downward using `move: Transition`.
5. **Dismissal Animation:** Gently moves upward (`to: -height`) and fades out (`opacity: 0`) before unmounting from the model.
6. **LayerShell Surface Lifecycle & Input Masking:**
   * **Dynamic Loader Lifecycle:** The `PanelWindow` is instantiated via a `Loader { active: toastModel.count > 0 }`. When no toasts are active, the surface is completely unmapped from the Wayland compositor, eliminating stale layer surfaces.
   * **Targeted Surface Dimensions:** Anchored at `anchors.top: true` with `implicitWidth: 440` and dynamic height (`Math.min(700, Root.Theme.shelfHeight + toastCol.implicitHeight + 40)`).
   * **Layer `Top`:** Placed on `WlrLayer.Top`, preventing pointer grabs and focus disruption on normal desktop windows.
   * **Input Masking:** Uses `mask: Region { item: toastWrapper }` to restrict mouse interaction strictly to active notification cards and their concave fillets. All surrounding monitor areas pass pointer events directly through to underlying windows.

---

## Visual Reference

Top-center notification toasts, each rendering the originating application, title, and body:

![Notification Toasts](../assets/images/quickshell/notifications-toast.png)

Volume and brightness OSD cards sharing the same placement, geometry, and surface tokens:

![Volume OSD](../assets/images/quickshell/osd-volume.png)

![Brightness OSD](../assets/images/quickshell/osd-brightness.png)

---

## Source Files Map

| Component | Source File | Responsibility |
| :--- | :--- | :--- |
| **Notification Service** | `modules/notifications/NotificationService.qml` | DBus server claiming `org.freedesktop.Notifications`, history store, and Waybar count signal sync. |
| **Toast Window** | `modules/notifications/NotificationToastLayer.qml` | Top floating window with Waybar Dynamic Island fillets, model prepending (`insert(0)`), and column move transition. |
| **Notification Toast Card** | `modules/notifications/NotificationPopup.qml` | Dynamic Island styled card, slide-down appearance, and dismissal animations. |
| **Collapsible Notification Card** | `modules/controlcenter/ControlCenter.qml` | Embedded collapsible drawer with `Notifications • ( # )` title, 180° rotating toggle chevron, Clear all button, and scrollable card feed. |
| **Notification Feed Item** | `modules/notifications/NotificationItem.qml` | Individual notification item styling in the Control Center drawer. |
| **Volume OSD** | `modules/osd/VolumeOsd.qml` | Listens to PipeWire sink changes and animates top-center card. |
| **Brightness OSD** | `modules/osd/BrightnessOsd.qml` | Listens to `brightnessctl` and animates top-center card. |
| **Song Transition Toast** | `modules/osd/MusicOsd.qml` | Dynamic Island popup anchored to Waybar displaying thumbnail art, track title, and artist on MPRIS track transitions. |
| **Media Source Selector** | `modules/mediaselector/MediaSelector.qml` | Centered Dynamic Island dropdown panel with dual concave fillets, allowing live selection between Automatic and specific MPRIS players. |
| **Unified Music Player** | `modules/launcher/Launcher.qml` | Bottom-docked non-modal interactive player accessible via `/music` or `SUPER + M` (see [Launcher & Wallpapers Guide](launcher-wallpapers.md)). |

---

## Making Future Adjustments

### Adjusting Vertical Distance
Edit `topMargin` in `toastWrapper`:
```qml
anchors.topMargin: Root.Theme.shelfHeight // Docked flush against Waybar
```

### Changing Animation Speed
Inside the `appearAnim` block:
```qml
NumberAnimation {
    target: root; property: "_slideY"
    from: -Math.max(60, card.height); to: 0; duration: 280; easing.type: Easing.OutCubic
}
```

### Live Testing
* **Trigger notification:**
  ```bash
  notify-send "Test" "Smooth Dynamic Island slide-down animation"
  ```
* **Trigger volume OSD:**
  ```bash
  wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
  ```
* **Battery & Charger Notifications:** Handled by the background daemon `~/.config/hypr/scripts/battery-notify` (started in `autostart.conf`). It triggers native Quickshell Dynamic Island toasts:
  * Charger connection (`󰂄 Charger Connected`) and disconnection (`󰂃 Charger Disconnected`).
  * Low battery warning at 20% (`󰁺 Low Battery (20%)`, normal urgency).
  * Critical battery alert at 10% (`󰂎 Critical Battery (10%)!`, critical urgency with MD3 error accent stripe and indicator dot).

---

## Related Documentation

* [Waybar Status Bar](../apps/waybar.md): Top status bar geometry and vertical alignment with floating toasts.
* [Quickshell Overview](index.md): Main widget architecture, Control Center, and component index.
* [Hyprland Keybindings](../hyprland/keybinds.md): Audio, brightness, and utility shortcut bindings.
* [Hyprland Architecture](../hyprland/index.md): Autostart order and compositor lifecycle hooks.
* [Matugen Theming Engine](../apps/matugen.md): Dynamic surface and accent token definitions.
* [Screen Shaders](../hyprland/shaders.md): Visual filters toggled from the notification drawer and control center.
