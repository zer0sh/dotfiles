# zer0sh Dotfiles - Hyprland & Material Design 3

Personal, modular dotfiles for a modern Wayland desktop environment on Debian GNU/Linux 13 (Trixie), built around **Hyprland**, **Quickshell**, **Waybar**, **Alacritty**, and **Matugen**. Designed for high productivity, fluid animations, and automated maintenance by both human developers and AI coding agents.

Online Documentation Wiki: https://zer0sh.github.io/dotfiles/

---

## Highlights

* **Dynamic Material You Theming (Matugen):** Wallpaper-driven palette generation propagating real-time color schemes across Hyprland borders, Waybar, Wofi, Alacritty, Kitty, Hyprlock, and Quickshell.
* **Modern Desktop Shell & Notifications (Quickshell):** Floating notifications and system OSDs (volume, brightness, media) anchored at the top-center with smooth downward slide-in transitions and queue displacement.
* **Modular Hyprland Setup:** Clean separation of concerns (monitors, autostart, window rules, decorations, keybindings) paired with custom post-processing GLSL shaders.
* **Material Design 3 App Launcher (Wofi):** Three pre-configured design presets (Card, Spotlight, Grid), seamless toggle behavior (`SUPER + Space`), and terminal font unification (`BlexMono Nerd Font`).
* **Optimized Shell & Terminal:** Ultra-fast Zsh startup (~50ms) with lightweight plugins, custom single-line prompt with path shrinking and Git status, paired with Alacritty.
* **Comprehensive Wiki & Automated Releases:** Technical documentation published to GitHub Pages, semantic versioning (SemVer), and automated GitHub Releases with packaged archives.

---

## Directory Structure

```text
dotfiles/
├── alacritty/       # Primary GPU-accelerated terminal (BlexMono Nerd Font)
├── bat/             # Cat clone with syntax highlighting and git integration
├── btop/            # Resource monitor with custom themes
├── fastfetch/       # System telemetry layout and custom ASCII logo
├── hypr/            # Modular Hyprland compositor configs and GLSL shaders
├── kitty/           # Secondary terminal emulator configuration
├── matugen/         # Material You color generator config and templates
├── quickshell/      # QML-based desktop shell, control center, and OSDs
├── vim/             # Minimal Vim configuration (.vimrc)
├── waybar/          # Modular Waybar status bar configuration
├── wofi/            # Application launcher presets and switch-preset script
├── yazi/            # Fast terminal file manager written in Rust
├── zsh/             # Modular Zsh config (~50ms), custom prompts, and aliases
├── docs/            # MkDocs Material technical wiki source files
├── scripts/         # Maintenance and SemVer release helper scripts
└── .github/         # CI/CD workflows for GitHub Pages and Releases
```

---

## Online Documentation

The full technical guide, component architecture, keyboard shortcut cheatsheet, and customization tutorials are available at:

**https://zer0sh.github.io/dotfiles/**

### Key Wiki Topics

* [**Hyprland Architecture & Keybindings**](https://zer0sh.github.io/dotfiles/hyprland/): Compositor structure and comprehensive shortcut cheatsheet.
* [**Post-Processing Shaders**](https://zer0sh.github.io/dotfiles/hyprland/shaders/): GLSL screen filters (Sepia, Noir, Vintage, Vivid).
* [**Quickshell Control Center & OSDs**](https://zer0sh.github.io/dotfiles/quickshell/): Control center widgets, top-center notification toasts, and volume/brightness OSDs.
* [**Matugen Theming Engine**](https://zer0sh.github.io/dotfiles/apps/matugen/): Palette generation, template mapping, and central theme store.
* [**Wofi Application Launcher**](https://zer0sh.github.io/dotfiles/apps/wofi/): Presets, toggle script, and font unification.
* [**Fastfetch Telemetry**](https://zer0sh.github.io/dotfiles/apps/fastfetch/): Custom hardware information layout and ASCII logo.
* [**Terminal Setup (Alacritty & Zsh)**](https://zer0sh.github.io/dotfiles/terminals/alacritty/): Hardware acceleration, custom prompt, and cache optimizations.
* [**Release Management & SemVer**](https://zer0sh.github.io/dotfiles/dotfiles/releases/): Semantic versioning, tag triggers, and release automation.

---

## Installation & Deployment

To deploy these dotfiles on a fresh Debian/Ubuntu/Arch installation:

```bash
# 1. Clone repository
git clone https://github.com/zer0sh/dotfiles.git ~/dotfiles
cd ~/dotfiles

# 2. Run the deployment installer
./install.sh
```

### What `install.sh` Does

1. **Safe Symlinks:** Links configurations from `~/dotfiles/<app>` to `~/.config/<app>` and Zsh dotfiles (`~/.zshrc`, `~/.zshrc_aliases`).
2. **Automatic Timestamped Backups:** Any pre-existing configurations are safely renamed to `*.bak` or `*.bak_YYYYMMDD_HHMMSS` before symlinking.
3. **Bloat-Free Zsh Plugins:** Shallow-clones only essential plugins (`zsh-autosuggestions`, `zsh-syntax-highlighting`, `zsh-completions`, `zsh-history-substring-search`) into `~/.zsh/plugins/`.
4. **Environment Check:** Verifies recommended CLI dependencies (`fzf`, `zoxide`, `bat`, `matugen`).

---

## Release Management & SemVer

This repository follows [Semantic Versioning](https://semver.org/) (`vMAJOR.MINOR.PATCH`).

Creating and pushing a new release:

```bash
# Automated release helper (interactive)
./scripts/release.sh

# Or directly:
./scripts/release.sh patch   # v1.0.0 -> v1.0.1
./scripts/release.sh minor   # v1.0.0 -> v1.1.0
./scripts/release.sh major   # v1.0.0 -> v2.0.0
```

When a tag matching `v*.*.*` is pushed to GitHub:
1. GitHub Actions triggers the release workflow (`.github/workflows/release.yml`).
2. It packages standalone `.tar.gz` and `.zip` archives.
3. It generates an automated changelog from Conventional Commits.
4. It publishes the release assets on GitHub and deploys updated documentation.

---

## AI Agent Integration

This repository adheres to strict conventions defined in `AGENTS.md` for AI pair-programming assistants:
* Local-first execution and safety boundaries.
* Conventional Commits (`feat:`, `fix:`, `style:`, `docs:`, `refactor:`, `chore:`).
* Zero-emoji policy across code, documentation, and commits.
* Bidirectional synchronization between dotfiles, MkDocs wiki, and Obsidian vault (`~/Workspace/vault/`).
