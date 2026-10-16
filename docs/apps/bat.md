# Bat Syntax Pager & Cat Clone

`bat` is a modern replacement for the traditional Unix `cat` command, enhanced with syntax highlighting for hundreds of programming and markup languages, Git modification badges, automatic terminal detection, and customizable paging styles.

---

## File Structure & Paths

* **Repository configuration:** `~/dotfiles/bat/config`
* **Target symlink:** `~/.config/bat/config` -> `~/dotfiles/bat/config`
* **Debian binary:** `/usr/bin/batcat`
* **Local symlink:** `~/.local/bin/bat` -> `/usr/bin/batcat`
* **Shell alias:** `alias cat='batcat'` (configured in `~/dotfiles/zsh/zshrc_aliases`)

---

## Configuration (`config`)

The active configuration resides in `~/.config/bat/config`:

```ini
--style=header
--color=always
--wrap=never
--paging=never
--tabs=4
```

### Parameter Breakdown

* `--style=header`: Displays a compact header containing the file path and file type metadata above the file contents, omitting line number grids to keep terminal output clean and easily selectable for copying.
* `--color=always`: Guarantees syntax highlighting is rendered even when piping or redirecting stdout where color tags are accepted.
* `--wrap=never`: Prevents long lines of code from auto-wrapping across multiple visual rows, maintaining formatting integrity.
* `--paging=never`: Emulates traditional `cat` by streaming output directly to the terminal stdout without piping into a pager like `less`. This eliminates extra keypresses (`q`) when viewing short files or running shell scripts.
* `--tabs=4`: Standardizes tab stop indentation to 4 characters.

---

## Debian Packaging & Binary Resolution

On Debian and Ubuntu systems, the executable binary is packaged as `batcat` by the package manager (`apt install bat`) to prevent naming collisions with a legacy Debian package.

To provide a seamless workflow across different distributions and tools:

1. **Local Symlink:** The dotfiles deployment script creates a symlink in `~/.local/bin/bat` pointing to `/usr/bin/batcat`.
2. **Shell Alias:** `alias cat='batcat'` in `~/.zshrc_aliases` replaces default `cat` calls transparently.
3. **Plain Cat Fallback:** When pure unformatted POSIX `cat` behavior is required, invoke `\cat` or `/bin/cat`.

---

## Common Commands & Usage Patterns

```bash
# View file with syntax highlighting and file header
cat file.py
bat file.py

# View with full line numbers and git modifications grid
bat --style=full file.py

# Highlight piped input explicitly specifying language
curl -s https://api.github.com | bat -l json

# Inspect Git diff modifications directly in the file
bat --diff file.rs

# List available syntax highlighting themes
bat --list-themes
```

---

## Related Documentation

* [Zsh Shell Configuration](../terminals/zsh.md): Interactive shell aliases, plugin ecosystem, and startup cache.
* [Alacritty Terminal](../terminals/alacritty.md): Monospace typography and dynamic color scheme rendering.
* [Fastfetch Telemetry](fastfetch.md): Hardware information tool running alongside terminal utilities.
* [Documentation Home](../index.md): Central navigation portal for the entire dotfiles documentation.
