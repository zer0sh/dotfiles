# Zen Browser Dynamic Theming

Zen Browser is integrated into the dynamic Material You theming pipeline using [Matugen](matugen.md) templates. The templates render harmonic colors extracted from the active wallpaper into the browser profile, covering the browser chrome (sidebar, tabs, toolbar, urlbar, panels, menus) and the internal `about:` pages. The templates are adapted from the [InioX/matugen-themes](https://github.com/InioX/matugen-themes) Zen Browser section (MIT license).

---

## Requirements

| Requirement | Minimum | Purpose | Validate with |
| :--- | :--- | :--- | :--- |
| **Zen Browser** | 1.14 or newer | Firefox-based browser with a profile at `~/.zen` | `zen --version` |
| **matugen** | 4.x | Renders the Material Design 3 palette from a wallpaper | `command -v matugen` |
| **Matugen engine config** | any | Provides `~/.config/matugen/config.toml` and `~/.config/matugen/templates/` | `test -f "$HOME/.config/matugen/config.toml"` |
| **curl** | any | Downloads the templates (manual installation only) | `command -v curl` |
| **bash or zsh** | any | Runs the snippets of this guide | `echo $0` |
| **Profile stylesheet pref** | `true` | Loads `userChrome.css` / `userContent.css` (off by default since Zen 1.14) | `about:config` entry `toolkit.legacyUserProfileCustomizations.stylesheets` |

No `sudo` privileges are required. The integration does not modify browser binaries or installation directories; it only touches files inside the user profile and the matugen configuration.

---

## File Structure and Paths

| Action | Path | Notes |
| :--- | :--- | :--- |
| Create | `~/dotfiles/matugen/templates/zen-userchrome.css` | Chrome UI template (source of truth in the repository) |
| Create | `~/dotfiles/matugen/templates/zen-usercontent.css` | Internal `about:` pages template |
| Modify (backup first) | `~/dotfiles/matugen/config.toml` | Registers `[templates.zen-userchrome]` and `[templates.zen-usercontent]` |
| Create (rendered by matugen) | `~/.zen/xbjonc67.Default Profile/chrome/zen-userChrome.css` | Output of the chrome template |
| Create (rendered by matugen) | `~/.zen/xbjonc67.Default Profile/chrome/zen-userContent.css` | Output of the content template |
| Create (entry file) | `~/.zen/xbjonc67.Default Profile/chrome/userChrome.css` | Single `@import` line pointing at the rendered chrome file |
| Create (entry file) | `~/.zen/xbjonc67.Default Profile/chrome/userContent.css` | Single `@import` line pointing at the rendered content file |
| Modify (append) | `~/.zen/xbjonc67.Default Profile/user.js` | Enables `toolkit.legacyUserProfileCustomizations.stylesheets` |
| Create | `~/dotfiles/scripts/setup-zen-matugen.sh` | Deployment and verification automation |
| Modify | `~/dotfiles/install.sh` | Runs the setup script when Zen Browser is detected |

The profile folder name (`xbjonc67.Default Profile`) is specific to this machine. Resolve the active profile of any installation with:

```bash
grep -E "^Path=|^IsRelative=|^Default=1" "$HOME/.zen/profiles.ini"
```

Note: unlike every other consumer, the Zen outputs are rendered directly into
the profile `chrome/` folder instead of `~/.config/themes/current/`, because
Zen (like every Firefox fork) only loads stylesheets from the profile. The
generated files are plain static CSS, so nothing else consumes the central
theme store for this target.

---

## Dynamic Matugen Architecture

```
Wallpaper Image (.png / .jpg)
          |
          v
   [ matugen image ]
          |
          +--> evaluates ~/.config/matugen/templates/zen-userchrome.css
          |        -> ~/.zen/<profile>/chrome/zen-userChrome.css
          |        -> imported by ~/.zen/<profile>/chrome/userChrome.css
          |
          +--> evaluates ~/.config/matugen/templates/zen-usercontent.css
                   -> ~/.zen/<profile>/chrome/zen-userContent.css
                   -> imported by ~/.zen/<profile>/chrome/userContent.css
          |
          v
Zen Browser UI (sidebar, tabs, toolbar, urlbar, panels, about: pages)
```

---

## Theme Coverage

### Chrome template (`zen-userchrome.css`)

| Token | Applied to |
| :--- | :--- |
| `colors.background.default` | Main browser background, tab bar, app content navbar |
| `colors.primary_container.default` | `--zen-primary-color` (Zen accent variable) |
| `colors.primary.default` | Toolbar icon fill, selected tab text, urlbar selection, panel icons |
| `colors.surface_container.default` | Sidebar tree, workspaces button, urlbar field, arrow panels |
| `colors.on_background.default` | Toolbar, urlbar and panel text |
| `colors.on_surface_variant.default` | Urlbar suggestion URLs |
| `colors.on_primary.default` | Urlbar selection text |

### Content template (`zen-usercontent.css`)

Overrides the Firefox in-content variables used by `about:preferences`,
`about:addons`, `about:config`, `about:logins`, `about:support` and the rest of
the internal pages: link and focus colors, buttons, inputs, checkboxes, radios,
tables, cards, scrollbars, selection highlight and the `about:preferences`
sidebar.

---

## Reload Strategy

`userChrome.css` and `userContent.css` are read **only at browser startup**.
After every wallpaper change the palette is regenerated automatically, but Zen
must be fully restarted to display it:

1. Close every Zen window (the process must exit completely).
2. Open Zen again from the application launcher.

An in-app relaunch (`about:profiles` restart or the built-in restart action)
is known to leave stale stylesheets in some Zen releases; a manual full
restart is the reliable method.

---

## Automatic Installation (Dotfiles)

The integration is deployed by the standard dotfiles routine:

```bash
~/dotfiles/install.sh
```

Or manually at any time with the standalone script:

```bash
~/dotfiles/scripts/setup-zen-matugen.sh
```

The script resolves the default profile from `profiles.ini` (native and Flatpak
installations are supported), creates the `chrome/` folder, backs up and
patches the entry files, enables the stylesheet preference in `user.js`,
regenerates the palette from the stored wallpaper, and prints a verification
report. It is idempotent: running it twice never duplicates the `@import`
lines or the preference.

---

## Manual Installation: Zen Browser Theme Integration

Standalone instructions to add the Zen Browser theme integration to an
existing matugen installation without cloning the full dotfiles repository.
This is the second application of the manual installation format pioneered in
[Matugen (VS Code pilot)](matugen.md#manual-installation-vs-code-theme-integration-pilot).

All snippets are compatible with `bash` and `zsh`, use explicit paths (no glob
patterns), quote every path (Zen profile folders usually contain spaces), and
are safe to paste into an interactive shell.

### Step 1: Validate prerequisites

Run the checks. Every line must report `OK` before continuing. The preference
used to load profile stylesheets is validated in Step 7:

```bash
command -v matugen >/dev/null 2>&1 && echo "matugen       : OK" || echo "matugen       : MISSING"
command -v curl >/dev/null 2>&1 && echo "curl          : OK" || echo "curl          : MISSING"
test -f "$HOME/.zen/profiles.ini" && echo "zen registry  : OK" || echo "zen registry  : MISSING"
test -d "$HOME/.config/matugen/templates" && echo "templates dir : OK" || echo "templates dir : MISSING"
test -f "$HOME/.config/matugen/config.toml" && echo "config.toml   : OK" || echo "config.toml   : MISSING"
echo "profile pref  : CHECK MANUALLY (expected MISSING, Step 7 enables it)"
```

The profile stylesheet preference (`toolkit.legacyUserProfileCustomizations.stylesheets`) lives inside the profile, which is resolved in Step 2, so it is validated there instead.

If a line reports `MISSING`:

* `matugen`: install it from <https://github.com/InioX/matugen>.
* `curl`: install it with your package manager (`apt install curl` on Debian).
* `zen registry`: install Zen Browser, or create the file with
  `touch "$HOME/.zen/profiles.ini"` only if you manage the profile manually.
* `templates dir`: create it with `mkdir -p "$HOME/.config/matugen/templates"`.
* `config.toml`: create an empty one with `touch "$HOME/.config/matugen/config.toml"`.

### Step 2: Locate the active profile

```bash
grep -E "^Path=|^IsRelative=|^Default=1" "$HOME/.zen/profiles.ini"
```

Identify the `Path=` value of the block marked with `Default=1`. From this
point on, replace `<profile-path>` in every snippet with that value, keeping
the double quotes (profile names contain spaces). Example for this machine:

```bash
PROFILE_DIR="$HOME/.zen/xbjonc67.Default Profile"
test -d "$PROFILE_DIR" && echo "profile dir   : OK" || echo "profile dir   : MISSING"
```

### Step 3: Back up the files that will be modified

The only existing files altered by this procedure are `config.toml`, the entry
files (`userChrome.css` / `userContent.css`, when they already exist) and
`user.js`. Backups carry the exact date and time of the operation:

```bash
BACKUP_STAMP="$(date +%Y%m%d-%H%M%S)"
test -f "$HOME/.config/matugen/config.toml" && cp -p "$HOME/.config/matugen/config.toml" "$HOME/.config/matugen/config.toml.$BACKUP_STAMP.bak"
test -f "$PROFILE_DIR/chrome/userChrome.css" && cp -p "$PROFILE_DIR/chrome/userChrome.css" "$PROFILE_DIR/chrome/userChrome.css.$BACKUP_STAMP.bak"
test -f "$PROFILE_DIR/chrome/userContent.css" && cp -p "$PROFILE_DIR/chrome/userContent.css" "$PROFILE_DIR/chrome/userContent.css.$BACKUP_STAMP.bak"
test -f "$PROFILE_DIR/user.js" && cp -p "$PROFILE_DIR/user.js" "$PROFILE_DIR/user.js.$BACKUP_STAMP.bak"
echo "Backups created with stamp: $BACKUP_STAMP"
```

If template files from a previous attempt already exist, they are backed up
the same way before being replaced:

```bash
test -f "$HOME/.config/matugen/templates/zen-userchrome.css" && cp -p "$HOME/.config/matugen/templates/zen-userchrome.css" "$HOME/.config/matugen/templates/zen-userchrome.css.$BACKUP_STAMP.bak"
test -f "$HOME/.config/matugen/templates/zen-usercontent.css" && cp -p "$HOME/.config/matugen/templates/zen-usercontent.css" "$HOME/.config/matugen/templates/zen-usercontent.css.$BACKUP_STAMP.bak"
```

### Step 4: Create the template files

Download both templates directly from the repository:

```bash
mkdir -p "$HOME/.config/matugen/templates"
curl -fsSL -o "$HOME/.config/matugen/templates/zen-userchrome.css" "https://raw.githubusercontent.com/zer0sh/dotfiles/main/matugen/templates/zen-userchrome.css"
curl -fsSL -o "$HOME/.config/matugen/templates/zen-usercontent.css" "https://raw.githubusercontent.com/zer0sh/dotfiles/main/matugen/templates/zen-usercontent.css"
```

Alternatively, copy the file contents manually from the repository pages
([zen-userchrome.css](https://github.com/zer0sh/dotfiles/blob/main/matugen/templates/zen-userchrome.css),
[zen-usercontent.css](https://github.com/zer0sh/dotfiles/blob/main/matugen/templates/zen-usercontent.css))
into the destination paths shown above.

Confirm both files exist and are not empty:

```bash
test -s "$HOME/.config/matugen/templates/zen-userchrome.css" && echo "zen-userchrome.css : OK" || echo "zen-userchrome.css : MISSING"
test -s "$HOME/.config/matugen/templates/zen-usercontent.css" && echo "zen-usercontent.css : OK" || echo "zen-usercontent.css : MISSING"
```

### Step 5: Register the templates in `config.toml`

Edit the block below **before pasting it**: replace both occurrences of
`<profile-path>` with the value obtained in Step 2. The block is idempotent:
it appends the sections only when they are not already registered, and the
heredoc delimiter is quoted, so no variable or shell expansion happens inside
it:

```bash
if grep -q "^\[templates.zen-userchrome\]" "$HOME/.config/matugen/config.toml"; then
    echo "Already registered in config.toml, nothing to do."
else
    cat >> "$HOME/.config/matugen/config.toml" <<'EOF'

# Zen Browser (imported by <profile>/chrome/userChrome.css and userContent.css)
[templates.zen-userchrome]
input_path = "~/.config/matugen/templates/zen-userchrome.css"
output_path = "~/.zen/<profile-path>/chrome/zen-userChrome.css"

[templates.zen-usercontent]
input_path = "~/.config/matugen/templates/zen-usercontent.css"
output_path = "~/.zen/<profile-path>/chrome/zen-userContent.css"
EOF
    echo "Registered in config.toml."
fi
```

### Step 6: Create the `chrome/` folder and the entry files

The entry files contain a single `@import` each, pointing at the rendered
template with an **absolute** path. Relative imports are ignored by Firefox
style sheets, so the path must start with `/home/<user>`:

```bash
mkdir -p "$PROFILE_DIR/chrome"
BACKUP_STAMP="$(date +%Y%m%d-%H%M%S)"
for entry in userChrome.css userContent.css; do
    target="zen-$entry"
    import_line="$(printf '@import url("%s");' "$PROFILE_DIR/chrome/$target")"
    if [ -f "$PROFILE_DIR/chrome/$entry" ] && grep -Fq "$target" "$PROFILE_DIR/chrome/$entry"; then
        echo "$entry already imports $target."
    elif [ -f "$PROFILE_DIR/chrome/$entry" ]; then
        cp -p "$PROFILE_DIR/chrome/$entry" "$PROFILE_DIR/chrome/$entry.$BACKUP_STAMP.bak"
        printf '%s\n%s\n' "$import_line" "$(cat "$PROFILE_DIR/chrome/$entry")" > "$PROFILE_DIR/chrome/$entry"
        echo "Updated $entry (backup created)."
    else
        printf '%s\n' "$import_line" > "$PROFILE_DIR/chrome/$entry"
        echo "Created $entry."
    fi
done
```

The import line is prepended because CSS ignores `@import` rules placed after
any style rule. Personal customizations that already exist in the entry files
are preserved below the import.

### Step 7: Enable the profile stylesheet preference

Zen disables profile stylesheets by default since v1.14 (aligned with the
Firefox default). Either toggle it in the browser:

1. Open `about:config` in the address bar.
2. Search for `toolkit.legacyUserProfileCustomizations.stylesheets`.
3. Set it to `true`.

or persist it from the shell (the `user.js` file is re-applied on every
startup, so the preference can never be flipped back by an update):

```bash
PREF='toolkit.legacyUserProfileCustomizations.stylesheets'
if grep -Fq "\"$PREF\", true" "$PROFILE_DIR/user.js" 2>/dev/null; then
    echo "Preference already enabled in user.js."
else
    printf 'user_pref("%s", true);\n' "$PREF" >> "$PROFILE_DIR/user.js"
    echo "Preference appended to user.js."
fi
```

### Step 8: Generate the colors

Replace the wallpaper path with your own absolute path. The
`--source-color-index 0` flag disables the interactive color picker, so the
command also works from keybindings or non-interactive shells:

```bash
matugen image "/absolute/path/to/your-wallpaper.jpg" --mode dark --source-color-index 0
test -f "$HOME/.zen/xbjonc67.Default Profile/chrome/zen-userChrome.css" && echo "rendered chrome  : OK" || echo "rendered chrome  : MISSING"
test -f "$HOME/.zen/xbjonc67.Default Profile/chrome/zen-userContent.css" && echo "rendered content : OK" || echo "rendered content : MISSING"
```

Adjust `<profile-path>` in both paths if your profile folder differs.

### Step 9: Restart Zen Browser

Close every Zen window and open it again from the application launcher. The
theme is applied at startup only.

### Step 10: Verification

```bash
test -s "$PROFILE_DIR/chrome/zen-userChrome.css" && echo "chrome file   : OK" || echo "chrome file   : MISSING"
test -s "$PROFILE_DIR/chrome/zen-userContent.css" && echo "content file  : OK" || echo "content file  : MISSING"
grep -Fq "zen-userChrome.css" "$PROFILE_DIR/chrome/userChrome.css" && echo "chrome import : OK" || echo "chrome import : MISSING"
grep -Fq "zen-userContent.css" "$PROFILE_DIR/chrome/userContent.css" && echo "content import: OK" || echo "content import: MISSING"
grep -Fq "\"toolkit.legacyUserProfileCustomizations.stylesheets\", true" "$PROFILE_DIR/user.js" 2>/dev/null && echo "preference    : OK" || echo "preference    : MISSING (or set manually in about:config)"
grep -q "{{" "$PROFILE_DIR/chrome/zen-userChrome.css" 2>/dev/null && echo "rendered css  : TEMPLATE VARIABLES LEFT" || echo "rendered css  : OK"
```

The last check reports `TEMPLATE VARIABLES LEFT` when matugen has not
processed the templates yet; run Step 8 again in that case.

### Troubleshooting

* **Nothing changed after the restart:** open `about:config` and confirm that
  `toolkit.legacyUserProfileCustomizations.stylesheets` is `true`. If it was
  toggled after the browser was opened, restart Zen completely (close every
  window instead of using an in-app relaunch, which is known to keep stale
  stylesheets in some releases).
* **The import has no effect:** verify that the `@import` line is the first
  statement of `userChrome.css` / `userContent.css`. Imports placed after a
  style rule are ignored by the CSS specification.
* **Colors did not change after a wallpaper switch:** run Step 8 again and
  confirm the output paths registered in `config.toml` match your profile
  folder exactly, including spaces.
* **Template placeholders visible in the rendered file:** the `output_path`
  registered in `config.toml` does not match the file imported by the entry
  files; fix the path and regenerate.
* **Inspect the applied styles:** press `Ctrl+Alt+Shift+I` to open the Browser
  Toolbox and check that `zen-userChrome.css` is listed in the style editor.
* **Restore the previous configuration:** copy the backups created in Steps 3
  and 6 back over the original files using the exact names printed by the
  backup commands, then restart Zen.

---

## Related Documentation

* [Matugen Engine](matugen.md): Palette generation, central theme store and orchestration script.
* [Hyprland Compositor](../hyprland/index.md): Window manager border theming and reload signals.
* [Quickshell Control Center](../quickshell/index.md): Real-time wallpaper selector that triggers palette regeneration.
* [Steam Client Theming](steam.md): Post-hook based consumer for comparison.
* [Alacritty Terminal](../terminals/alacritty.md): Consumer with automatic live reload (contrast with Zen, which requires a restart).
