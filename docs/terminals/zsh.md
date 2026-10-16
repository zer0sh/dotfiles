# Zsh Shell Configuration

Zsh serves as the interactive login shell across all terminal sessions (such as [Alacritty](alacritty.md)), optimized for instant startup times, intelligent history handling, asynchronous-like autosuggestions, and streamlined Git integration within the [Dotfiles Architecture](../dotfiles/workflow.md).

---

## File Locations & Symlinks

* **Configuration root:** `~/dotfiles/zsh/zshrc` -> `~/.zshrc`
* **Aliases:** `~/dotfiles/zsh/zshrc_aliases` -> `~/.zshrc_aliases`
* **Custom Prompts:** `~/dotfiles/zsh/prompts/` -> `~/.zsh/prompts/`
* **Plugin storage:** `~/.zsh/plugins/` (managed via `~/dotfiles/install.sh`, see [Dotfiles Workflow](../dotfiles/workflow.md))
* **Private overrides:** `~/.zshrc_private` (local machine only, unversioned)

---

## Startup Performance & Completion Cache

To eliminate the latency commonly associated with heavy frameworks like Oh-My-Zsh or Prezto, the configuration implements lightweight, native Zsh mechanisms with a 24-hour cache check on the completion dump:

```zsh
autoload -Uz compinit
setopt extendedglob
if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh+24) ]]; then
    compinit
else
    compinit -C
fi
```

* **Cache check (`#qN.mh+24`):** If the compiled completion dump (`.zcompdump`) was modified within the last 24 hours, `compinit -C` runs directly, bypassing expensive filesystem scans.
* **Measured startup time:** ~120 ms for cold interactive start with all active plugins and completions loaded.

---

## Completion Menu & Visual Styling

The completion system is styled to match the dark terminal palette with interactive arrow navigation and detailed process inspection:

* **Tab menu navigation:** `zstyle ':completion:*' menu select=2` enables interactive visual grid selection upon pressing `Tab`.
* **Case-insensitive matching:** Matches lowercase queries against uppercase files and handles dot/underscore boundaries automatically.
* **Process kill helper:** Provides highlighted process listing (`PID`, `%CPU`, `TTY`, `TIME`, `CMD`) when running `kill <Tab>`.
* **Colorization:** Synchronized with `$LS_COLORS` evaluated via `dircolors -b`.

---

## History Configuration & Privacy

```zsh
HISTSIZE=20000
SAVEHIST=20000
HISTFILE=~/.zsh_history

setopt hist_ignore_all_dups     # Remove older duplicates if a new command is recorded
setopt hist_save_no_dups        # Never write consecutive duplicate entries
setopt hist_ignore_space        # Commands prefixed with leading whitespace are excluded from history
setopt hist_reduce_blanks       # Strip superfluous whitespace before writing
setopt share_history            # Interactively share history across concurrent terminal tabs
setopt inc_append_history       # Append history entries immediately upon command execution
```

> The `hist_ignore_space` setting enables safe command execution containing tokens, passwords, or secrets by simply prepending a space to the command line.

---

## Lightweight Plugin Ecosystem

All plugins are cloned as shallow submodules under `~/.zsh/plugins/` during `install.sh` without external plugin managers:

1. **`zsh-autosuggestions`:**
   * Suggests commands as you type based on your shell history and completions.
   * Keybinding: `Ctrl + Space` triggers `autosuggest-accept`.
2. **`zsh-history-substring-search`:**
   * Type any substring and cycle through previous matches using `Up` and `Down` arrow keys.
3. **`zsh-syntax-highlighting`:**
   * Provides real-time syntax validation (green for valid commands/paths, red for invalid commands).
   * Loaded strictly as the final plugin to ensure accurate terminal tokenization.
4. **`zsh-completions`:**
   * Additional third-party completion definitions added to `fpath` prior to `compinit`.

---

## CLI Integrations

The shell dynamically verifies and activates installed modern CLI utilities:

* **`fzf`:** Activated via `eval "$(fzf --zsh)"` providing fuzzy reverse search (`Ctrl + R`) and fuzzy path completion (`Ctrl + T`).
* **`zoxide`:** Smart directory jumper activated via `eval "$(zoxide init zsh)"` using the `z` command.
* **`lsd`:** Modern `ls` alternative with icons, tree views, and color schemes aliased to `ls`, `ll` (`lsd -la`), and `lt` (`lsd --tree`).
* **`batcat` / `bat`:** Syntax-highlighted pager replacement aliased to `cat`.

---

## Custom Prompts

Custom prompts reside in `~/dotfiles/zsh/prompts/` and are registered via Zsh's built-in `promptinit` system.

### 1. Minimal (`prompt minimal`) - Default
A fast, single-line prompt featuring:
* Compressed path notation (`_shrink_path`): Converts deep paths like `~/Workspace/personal/project` into `~/W/p/project` to preserve horizontal terminal width.
* Git status (`vcs_info`): Displays branch name in red, with `*` for unstaged changes and `+` for staged changes.
* Exit code indicator: Changes prompt symbol to green `›` on exit `0` and red `› [code]` on non-zero return codes.
* Right prompt (`RPROMPT`): Displays current timestamp (`HH:MM`) in muted grey.

### 2. Macbar (`prompt macbar`) - Alternative
A two-line aesthetic prompt:
* Line 1: Full directory path with Git branch badge in brackets.
* Line 2: Indented prompt symbol (`λ`), green on success and red on failure.
* Right prompt: Git branch icon (`󰊢`) and timestamp.

---

## Key Aliases Reference

| Alias | Target Command | Description |
| :--- | :--- | :--- |
| `ls` | `lsd` | Directory listing with icons |
| `ll` | `lsd -la` | Detailed directory listing |
| `lt` | `lsd --tree` | Tree directory representation |
| `cat` | `batcat` | File inspection with syntax highlighting |
| `v` | `vim` | Fast text editor launch |
| `gs` | `git status` | Short Git status |
| `ga` | `git add` | Stage changes |
| `gc` | `git commit -m` | Commit with message |
| `gp` | `git push` | Push to remote |
| `gl` | `git pull` | Pull from remote |
| `gd` | `git diff` | Diff working directory |
| `glog` | `git log --oneline --graph --decorate` | Compact Git graph history |
| `cwd` | `pwd \| wl-copy \| cliphist store` | Copy current path to Wayland clipboard (integrated with [Quickshell Clipboard Manager](../quickshell/index.md)) |

---

## Related Documentation

* [Alacritty Terminal](alacritty.md): Monospace configuration, font rendering, and live config reload.
* [Fastfetch Telemetry](../apps/fastfetch.md): System hardware diagnostics and desktop branding.
* [Hyprland Keybindings Catalog](../hyprland/keybinds.md): Keyboard shortcuts for spawning terminals and quick runners.
* [Dotfiles Workflow & Architecture](../dotfiles/workflow.md): Git backup, symlink strategies, and installation scripting.
* [Quickshell Overview](../quickshell/index.md): One UI desktop widgets, notifications, and clipboard manager.
