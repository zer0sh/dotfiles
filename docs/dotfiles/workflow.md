# Dotfiles Workflow & Architecture

This guide explains how configuration files are structured between your active system and the version-controlled repository on GitHub.

---

## 🏛️ Direct Source of Truth Philosophy

* **Hyprland:** `~/.config/hypr` is a **real physical directory** (not a symlink). You can edit configuration files directly in place without risk of symlink breakage or intermediate layer issues.
* **Dotfiles Repository:** `~/dotfiles` serves as the Git repository and backup hub connected to [github.com/zer0sh/dotfiles](https://github.com/zer0sh/dotfiles).

---

## 🔄 How to Backup Hyprland Changes

Whenever you test and stabilize adjustments in your Hyprland configuration and want to commit them to your repository:

1. **Copy live configuration into the dotfiles directory:**
   ```bash
   cp -r ~/.config/hypr/* ~/dotfiles/hypr/
   ```
2. **Review diffs and create atomic commits:**
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

## 📦 Documentation Deployment (MkDocs)

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

*(Note: Pushing to `main` also automatically triggers the GitHub Actions workflow defined in `.github/workflows/deploy-docs.yml`).*
