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

Explore the core modules of the environment:

<div class="grid cards" markdown>

-   :material-dock-window:{ .lg .middle } **[Hyprland Architecture](hyprland/index.md)**

    ---

    Modular structure, monitor layouts, keybindings, window rules, and custom GLSL post-processing shaders.

-   :material-view-dashboard-outline:{ .lg .middle } **[Quickshell & System OSD](quickshell/index.md)**

    ---

    One UI inspired control center, system telemetry widgets, audio sliders, and fluid top-center notification queue.

-   :material-rocket-launch-outline:{ .lg .middle } **[Launchers & System Tools](apps/wofi.md)**

    ---

    Material Design 3 application launcher with dynamic presets, Swaync notification service, and Fastfetch hardware telemetry.

-   :material-console:{ .lg .middle } **[Terminals & Shell](terminals/alacritty.md)**

    ---

    Hardware-accelerated terminal emulation with Alacritty and Kitty, powered by dynamic palettes and Zsh Prezto workflow.

</div>
