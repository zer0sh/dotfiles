# Dotfiles Workflow & Architecture

This guide explains how configuration files are structured between your active system and the version-controlled repository on GitHub.

---

## Direct Source of Truth Philosophy

* **Hyprland:** `~/.config/hypr` is a **real physical directory** (not a symlink). You can edit configuration files directly in place without risk of symlink breakage or intermediate layer issues (see [Hyprland Architecture](../hyprland/index.md)).
* **Quickshell:** `~/.config/quickshell` is also maintained directly on the system for instant QML hot-reloading (see [Quickshell Overview](../quickshell/index.md)).
* **Dotfiles Repository:** `~/dotfiles` serves as the Git repository and backup hub connected to [github.com/zer0sh/dotfiles](https://github.com/zer0sh/dotfiles).
* **Symlinked Applications:** Modular components like [Alacritty](../terminals/alacritty.md), [Zsh](../terminals/zsh.md), and [Fastfetch](../apps/fastfetch.md) link their active system paths directly to `~/dotfiles/`.

---

## How to Backup Hyprland Changes

Whenever you test and stabilize adjustments in your Hyprland configuration and want to commit them to your repository:

1. **Copy live configuration into the dotfiles directory:**
   ```bash
   cp -r ~/.config/hypr/* ~/dotfiles/hypr/
   ```
2. **Review diffs and create atomic commits:**
   Follow [Conventional Commits](https://www.conventionalcommits.org/) standards as documented in [Release Management & SemVer](releases.md):
   ```bash
   cd ~/dotfiles
   git status
   git add hypr/
   git commit -m "feat(hypr): describe your changes"
   ```
3. **Push to GitHub:**
   ```bash
   git push origin main
   ```

---

## Documentation Deployment & UI Architecture (MkDocs)

To preview the documentation locally with live-reload:

```bash
cd ~/dotfiles
mkdocs serve
```

To build and deploy changes directly to GitHub Pages:

```bash
cd ~/dotfiles
mkdocs gh-deploy
```

*(Note: Pushing to `main` also automatically triggers the GitHub Actions workflow defined in `.github/workflows/deploy-docs.yml`, as detailed in [Release Management & SemVer](releases.md)).*

### UI & Navigation Layout

The documentation uses Material for MkDocs enhanced with custom Material 3 and Glassmorphism styling (`docs/stylesheets/extra.css`):
* **Right-Hand Primary Navigation:** The navigation sidebar tree is docked on the right side on desktop viewport sizes (`min-width: 76.25em`), presenting page hierarchy inside a frosted glass card (`backdrop-filter: blur(14px)`).
* **Precise Active Indicators:** Parent section headers remain in clean bold text without intrusive highlight boxes, while only the active target page receives the active accent container pill.
* **Responsive Drawer:** On mobile devices, the navigation switches to a left slide-out Material You navigation drawer triggered from the top app bar.

---

## Related Documentation

* [Release Management & SemVer](releases.md): Semantic versioning, tag automation, and CI/CD pipelines.
* [Hyprland Architecture](../hyprland/index.md): Compositor layout, autostart services, and module directory structure.
* [Quickshell Overview](../quickshell/index.md): QML desktop widget framework and Control Center.
* [Zsh Shell Configuration](../terminals/zsh.md): Interactive shell environment, aliases, and startup optimizations.
* [Documentation Home](../index.md): Complete repository navigation hub.
