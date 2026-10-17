# Temas centralizados

`current/` contiene las salidas del tema activo. No se editan manualmente.

`~/.config/matugen/templates/` contiene las plantillas que generan esas
salidas. El archivo `~/.config/matugen/config.toml` registra cada componente.

## Generar una paleta de prueba

```bash
matugen image "$HOME/Pictures/walls/wallpaper.jpg" \
  --config "$HOME/.config/matugen/config.toml" \
  --mode dark --source-color-index 0
```

Waybar, Wofi y Kitty ya consumen estas salidas centralizadas. Los bordes de
Hyprland y Quickshell se conectarán después de validar la recarga. El mapa
completo y las reglas para agregar destinos están en
[`../hypr/MATUGEN.md`](../hypr/MATUGEN.md).
