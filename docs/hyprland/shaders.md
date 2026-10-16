# Screen Shaders & Filters

The setup includes custom GLSL shaders applied directly by the Hyprland compositor via `hyprctl keyword decoration:screen_shader`.

---

## Available Shaders

| Shader | GLSL File | Visual Description |
| :--- | :--- | :--- |
| **Sepia** | `sepia.glsl` | Warm, golden 1930s style tone. |
| **Black & White** | `bw.glsl` | Crisp, clean grayscale without added grain. |
| **Film Noir** | `noir.glsl` | Dramatic, high-contrast monochrome with film grain. |
| **Vintage** | `vintage.glsl` | Faded aged sepia with subtle vignette and texture. |
| **Vivid** | `vivid.glsl` | Boosted saturation and heightened contrast. |
| **Off** | `off.glsl` | Passthrough shader with zero color alteration. |

---

## Quickshell Integration

Inside the [Quickshell Control Center](../quickshell/index.md):
* The main circular toggle button serves as an **On / Off** switch (`filter toggle`).
* The three-dot button `⋯` cycles to the next available shader (`filter next`):
  ```text
  Off -> Sepia -> B&W -> Noir -> Vintage -> Vivid -> Off
  ```
* Active state is persisted in `/tmp/hypr-bw-filter` for real-time widget label synchronization.
* Shaders can also be triggered directly using keyboard shortcuts configured in [Keybindings](keybinds.md#screen-filters-and-shaders) (`SUPER + B`, `SUPER + CTRL + [1-5]`).

---

## Related Documentation

* [Hyprland Keybindings](keybinds.md): Keybindings for toggling and selecting GLSL screen shaders.
* [Quickshell Control Center](../quickshell/index.md): FeatureTile toggles, sliders, and ambient desktop integration.
* [Hyprland Architecture](index.md): Master orchestrator and decoration configuration.
