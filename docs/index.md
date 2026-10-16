# zer0sh Dotfiles

Welcome to the official documentation for **zer0sh's** desktop environment, built on **Hyprland** (Wayland) and customized with **Quickshell**, **Waybar**, **Kitty / Alacritty**, and **Zsh**.

---

## 🎯 Design Philosophy

* **Strict Modularity:** No monolithic configuration files. Every concern (keybindings, monitor layouts, animations, autostart services) is isolated into its own dedicated file.
* **Direct Live Source of Truth:** The live Hyprland configuration resides directly in `~/.config/hypr/` as a real, independent directory, allowing seamless live edits without symlink friction.
* **Cohesive Visual Integration:** Centralized palettes generated across Quickshell, Hyprland borders, Waybar, and terminal emulators.
* **Fluid Modern OSDs & Notifications:** Floating surfaces anchored at the top-center of the screen, featuring smooth downward slide-in transitions and fluid stack displacement.

---

## 🚀 Documentation Overview

* [**Hyprland Architecture**](hyprland/index.md): Modular structure, monitor layout, and window rules.
* [**Keybindings**](hyprland/keybinds.md): Comprehensive shortcut cheatsheet for apps, utilities, and widgets.
* [**Shaders & Screen Filters**](hyprland/shaders.md): Custom post-processing GLSL shaders (Sepia, Noir, Vintage, Vivid).
* [**Quickshell Control Center**](quickshell/index.md): One UI inspired quick-settings panel and system widgets.
* [**Notifications & OSDs**](quickshell/osd-notifications.md): Top-center positioning, slide-down animations, and queue dynamics.
* [**Dotfiles Workflow**](dotfiles/workflow.md): Repository management, local-first philosophy, and GitHub synchronization.
