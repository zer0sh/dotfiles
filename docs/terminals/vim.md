# Vim Configuration

Vim serves as the modal terminal text editor in this environment, configured with modern UI ergonomics, SynthWave '84 syntax highlighting, vim-airline status bar theming, NERDTree file explorer, and full system clipboard synchronization under Debian and Wayland.

---

## File Structure & Paths

* **Repository configuration:** `~/dotfiles/vim/vimrc`
* **Vim directory & plugins:** `~/dotfiles/vim/dot-vim`
* **Active user symlinks:**
  * `~/.vimrc` -> `~/dotfiles/vim/vimrc`
  * `~/.vim` -> `~/dotfiles/vim/dot-vim`

---

## System Dependencies (Debian / Wayland)

To enable seamless copy/paste integration with Wayland and manage plugins, the following packages are required on Debian:

```bash
sudo apt install vim-gtk3 wl-clipboard
```

* **`vim-gtk3`:** Replaces the default `vim.basic` binary with a version compiled with `+clipboard` and `+xterm_clipboard`. This activates `set clipboard=unnamedplus` in terminal sessions without launching a graphical window.
* **`wl-clipboard`:** Provides `wl-copy` and `wl-paste` command-line tools for native clipboard buffer management in Wayland / Hyprland.
* **`git` & `curl`:** Required by the `vim-plug` package manager to fetch and update plugin repositories.

---

## Plugin Architecture (vim-plug)

Plugins are managed via `junegunn/vim-plug` stored in `~/.vim/autoload/plug.vim` and cloned into `~/.vim/plugged/`:

* **`preservim/nerdtree`:** Tree-style directory viewer and file explorer.
* **`artanikin/vim-synthwave84`:** Vibrant 80s neon synthwave color scheme with true color support.
* **`vim-airline/vim-airline`:** Lightweight, customizable bottom statusline.
* **`vim-airline/vim-airline-themes`:** Theme collection for vim-airline (configured to `synthwave84`).

---

## Key Settings & Ergonomics

### Usability & Editing
* **Indentation:** 2-space soft tabs (`tabstop=2`, `shiftwidth=2`, `expandtab`).
* **Line numbers:** Absolute line numbering enabled (`number`).
* **Search:** Incremental and case-smart searching (`incsearch`, `hlsearch`, `ignorecase`, `smartcase`).
* **True Color:** 24-bit RGB colors enabled when supported by the terminal emulator (`termguicolors`).
* **Mouse:** Full pointer support for scrolling and cursor positioning across all modes (`mouse=a`).
* **Clipboard:** Centralized synchronization with the system clipboard (`clipboard=unnamedplus`).

---

## Keybindings & Floating Help

| Keybinding | Mode | Action |
| :--- | :--- | :--- |
| `Ctrl + n` | Normal | Toggle NERDTree explorer sidebar |
| `F1` | Normal | Open floating cheat sheet popup (`:Atajos`) |
| `q` / `Esc` / `Enter` | Normal (Popup) | Close floating cheat sheet popup |

---

## Related Documentation

* [Alacritty Terminal](alacritty.md): GPU-accelerated terminal running Vim.
* [Zsh Shell](zsh.md): Interactive shell environment with aliases and CLI tooling.
* [Hyprland Compositor](../hyprland/index.md): Wayland desktop environment hosting terminal sessions.
