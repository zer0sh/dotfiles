# Atajos de Teclado (Keybindings)

Todos los atajos se encuentran centralizados en [`binds.conf`](file:///home/zero/.config/hypr/binds.conf). La tecla modificadora principal es `SUPER` (`$mainMod`).

---

## 🚀 Aplicaciones y Sistema

| Atajo | Acción | Comando / Destino |
| :--- | :--- | :--- |
| `SUPER + Enter` | Abrir terminal | `alacritty` |
| `SUPER + E` | Abrir explorador de archivos | `nautilus` |
| `SUPER + Space` | Lanzador de aplicaciones | `wofi --show drun` |
| `SUPER + Q` | Cerrar ventana activa | `killactive` |
| `SUPER + SHIFT + R` | Recargar Hyprland | `hyprctl reload` |
| `SUPER + L` | Bloquear pantalla | `hyprlock` |
| `SUPER + P` | Editor gráfico de monitores | `nwg-displays` |
| `SUPER + X` | Ejecutar app con permisos root | `scripts/sudo-launcher` |

---

## 📸 Capturas y Grabación

| Atajo | Acción | Script / Herramienta |
| :--- | :--- | :--- |
| `Print` | Captura de pantalla completa | `scripts/screenshot` (guarda + portapapeles) |
| `SUPER + S` | Capturar área seleccionada | `scripts/screenshot area` |
| `SUPER + SHIFT + O` | Reconocimiento de texto (OCR) | `scripts/ocr` |
| `SUPER + ALT + R` | Alternar grabación de pantalla | `scripts/record` |

---

## 🎛️ Quickshell y Widgets

| Atajo | Acción | Evento IPC |
| :--- | :--- | :--- |
| `CTRL + ALT + Del` | Menú de apagado (Power Menu) | `quickshell ipc call powermenu toggle` |
| `SUPER + W` | Selector de fondo de pantalla | `quickshell ipc call wallpaper toggle` |
| `SUPER + M` | Mini reproductor de música | `quickshell ipc call miniplayer toggle` |
| `F1` | Overlay de atajos rápidos | `quickshell ipc call shortcuts toggle` |

---

## 🎨 Filtros y Shaders de Pantalla

| Atajo | Filtro aplicado | Script |
| :--- | :--- | :--- |
| `SUPER + B` | Alternar shader ON / OFF | `scripts/filter toggle` |
| `SUPER + CTRL + 1` | Sepia Vintage | `scripts/filter sepia` |
| `SUPER + CTRL + 2` | Blanco y Negro | `scripts/filter bw` |
| `SUPER + CTRL + 3` | Film Noir | `scripts/filter noir` |
| `SUPER + CTRL + 4` | Vintage desgastado | `scripts/filter vintage` |
| `SUPER + CTRL + 5` | Colores vívidos | `scripts/filter vivid` |
| `SUPER + CTRL + 0` | Desactivar filtros | `scripts/filter off` |
