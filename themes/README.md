# Centralized Themes

`current/` contains the outputs of the active theme. These files are not edited manually.

`~/.config/matugen/templates/` contains the templates that generate those outputs. The file `~/.config/matugen/config.toml` registers each component.

## Generate a test palette

```bash
matugen image "$HOME/Pictures/walls/wallpaper.jpg" \
  --config "$HOME/.config/matugen/config.toml" \
  --mode dark --source-color-index 0
```
