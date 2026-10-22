---
hide:
  - navigation
---

# zer0sh Dotfiles

Welcome to the official documentation for **zer0sh's** desktop environment, built on **Hyprland** (Wayland) and customized with **Quickshell**, **Waybar**, **Kitty / Alacritty**, and **Zsh**.

[Quick Install](dotfiles/workflow.md){ .md-button .md-button--primary }
[View Repository](https://github.com/zer0sh/dotfiles){ .md-button }

---

## Design Philosophy

<div class="grid cards" markdown>

-   :material-puzzle-outline:{ .lg .middle } **Strict Modularity**

    ---

    No monolithic configuration files. Every concern (keybindings, monitor layouts, animations, autostart services) is isolated into its own dedicated file.

-   :material-database-sync-outline:{ .lg .middle } **Direct Live Source of Truth**

    ---

    The live Hyprland configuration resides directly in `~/.config/hypr/` as a real, independent directory, allowing seamless live edits without symlink friction.

-   :material-palette-swatch-outline:{ .lg .middle } **Cohesive Visual Integration**

    ---

    Centralized palettes generated across Quickshell, Hyprland borders, Waybar, and terminal emulators.

-   :material-layers-triple-outline:{ .lg .middle } **Fluid Modern OSDs & Notifications**

    ---

    Floating surfaces anchored at the top-center of the screen, featuring smooth downward slide-in transitions and fluid stack displacement.

</div>

---

## Documentation Overview

Explore the complete modular guide:

<div class="grid cards" markdown>

-   :material-dock-window:{ .lg .middle } **Hyprland Ecosystem**

    ---

    Wayland tiling compositor configuration, modular orchestrator, and display layouts.

    * [Architecture Overview](hyprland/index.md)
    * [Keybindings Catalog](hyprland/keybinds.md)
    * [XWayland & Window Rules](hyprland/xwayland.md)
    * [GLSL Post-Processing Shaders](hyprland/shaders.md)
    * [Hyprlock & Idle Security](hyprland/hyprlock.md)

-   :material-view-dashboard-outline:{ .lg .middle } **Quickshell & Widgets**

    ---

    Wayland-native QML interface layer with One UI inspired control cards and telemetry.

    * [Control Center Architecture](quickshell/index.md)
    * [Top-Center OSDs & Notifications](quickshell/osd-notifications.md)

-   :material-rocket-launch-outline:{ .lg .middle } **Launchers & Styling Engine**

    ---

    Application execution, dynamic color palette generation, and telemetry displays.

    * [Waybar Status Bar](apps/waybar.md)
    * [Wofi M3 Launcher](apps/wofi.md)
    * [Matugen Theming Engine](apps/matugen.md)
    * [Fastfetch System Telemetry](apps/fastfetch.md)
    * [Bat Syntax Pager](apps/bat.md)

-   :material-console:{ .lg .middle } **Terminals & Shell**

    ---

    Hardware-accelerated terminal emulation and lightning-fast interactive shell workflow.

    * [Kitty Terminal](terminals/kitty.md)
    * [Alacritty Terminal](terminals/alacritty.md)
    * [Zsh Shell Configuration](terminals/zsh.md)

-   :material-git:{ .lg .middle } **Dotfiles & Version Control**

    ---

    Backup methodology, live source of truth workflow, and automated release pipeline.

    * [Philosophy & Workflow](dotfiles/workflow.md)
    * [Release Management & SemVer](dotfiles/releases.md)

</div>
