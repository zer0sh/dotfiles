# Sistema de temas con Matugen

Este documento define el contrato de colores para que los temas nuevos se puedan
crear y mantener sin modificar cada aplicación de forma aislada.

## Estado actual

La integración dinámica todavía no está activada. Actualmente:

- `quickshell/Theme.qml` contiene las seis paletas manuales y es la fuente de
  verdad del panel de control.
- `quickshell/scripts/apply-theme.sh` traduce una paleta manual a Waybar,
  Kitty, Rofi y los bordes activos de Hyprland.
- Wofi (`wofi/style.css`) importa `themes/current/wofi.css` dinámicamente con estilos Material Design 3.
- El fondo se cambia desde `WallpaperSection.qml` usando `swaybg`.

Matugen está instalado y se usará para generar una paleta a partir del fondo,
pero primero se mantendrá un modo reversible: el tema manual seguirá disponible
como respaldo mientras se valida el resultado.

## Mapa de componentes

La paleta generada debe alimentar estos componentes, en este orden:

| Componente | Archivo o salida | Colores que consume | Recarga |
|---|---|---|---|
| Quickshell / panel | `quickshell/MatugenPalette.qml` lee `themes/current/palette.json` | fondo, superficies, contenedores, primario, texto, estados semánticos, sliders | reiniciar o recargar Quickshell |
| Waybar | `themes/current/waybar.css`, importado por `waybar/colors.css` | fondo, texto, acento, warning, crítico, charging | `pkill -SIGUSR2 waybar` |
| Wofi | `themes/current/wofi.css`, importado por `wofi/style.css` | fondo translúcido, superficie de entrada, texto, selección/acento | nueva instancia |
| Kitty | `themes/current/kitty.conf`, incluido por `kitty/kitty.conf` | fondos, texto, cursor, selección, ANSI 16 colores, rango 256, pestañas y marcas | `pkill -SIGUSR1 kitty` (post_hook de Matugen) |
| Hyprland | bordes en `hyprland.conf` / `hyprctl keyword` | borde activo e inactivo | `hyprctl reload` o `hyprctl keyword` |
| Hyprlock | `themes/current/hyprlock.conf`, incluido por `hyprlock.conf` | texto, fondo secundario, acento, error y atención | próximo bloqueo de pantalla |
| Rofi heredado | `rofi/themes/colors.rasi` | fondo, contenedor, acento y texto | nueva instancia |
| Notificaciones | Quickshell `NotificationService` | solo estados visuales del panel; DND no cambia de color | recarga de Quickshell |
| Cursores | `themes/current/cursor-theme` e `~/.icons/default/index.theme` | Temas `Bibata-Material-*` emparejados con CIEDE2000 por `color_match.py` (SakibShahariar) | `hyprctl setcursor` y `gsettings set cursor-theme` |

## Roles de color

Cada tema debe tener, como mínimo, estos roles. Los nombres de Matugen se
mantendrán en la plantilla para evitar inventar nombres distintos por app.

| Rol del sistema | Uso en la interfaz | Referencia Matugen inicial |
|---|---|---|
| `background` | fondo principal y shelf | `colors.background.default` |
| `surface` | panel flotante y superficies base | `colors.surface.default` |
| `surface_container` | botones inactivos y grupos | `colors.surface_container.default` |
| `surface_container_high` | hover y controles secundarios | `colors.surface_container_high.default` |
| `surface_bright` | borde/realce discreto | `colors.surface_bright.default` |
| `primary` | controles activos, selección y borde activo | `colors.primary.default` |
| `primary_container` | fondo activo con menos contraste | `colors.primary_container.default` |
| `on_surface` | texto principal e iconos | `colors.on_surface.default` |
| `on_surface_variant` | texto secundario y metadatos | `colors.on_surface_variant.default` |
| `outline` | bordes sutiles | `colors.outline.default` |
| `error` | errores y estados críticos | `colors.error.default` |
| `tertiary` | charging, estados auxiliares y detalles | `colors.tertiary.default` |

Los colores de estado como Wi-Fi conectado, grabación y DND deben conservar
contraste semántico. No se colorearán todos los botones con `primary` al mismo
tiempo: el acento queda reservado para estados activos o acciones relevantes.
En este escritorio, los iconos y textos de controles activos se fuerzan a un
tono claro para mantener la lectura visual de los temas manuales, aunque
Matugen genere un `on_primary` oscuro por contraste matemático.

## Qué no debe generar Matugen

Matugen solo debe generar valores de color. Estos valores permanecen en la
configuración de cada aplicación:

- radios, tamaños, espaciado y forma circular de `CircleToggle`;
- transparencia y blur del panel;
- tipografías y tamaños de fuente;
- iconos y etiquetas;
- comportamiento de Wi-Fi, DND, shaders, energía y grabación;
- distribución de Waybar y reglas de ventanas de Hyprland.

## Flujo previsto

1. Elegir un fondo desde `WallpaperSection.qml`.
2. Ejecutar Matugen en modo oscuro con ese archivo.
3. Generar salidas para Waybar, Wofi, Kitty, Hyprland y una paleta consumible
   por Quickshell.
4. Recargar únicamente las aplicaciones que lo necesiten.
5. Mantener el último tema manual como fallback si Matugen falla.

La configuración es `~/.config/matugen/config.toml` y sus plantillas
vivirán en `~/.config/matugen/templates/`. Las plantillas se versionarán junto
con esta documentación para que agregar otro tema sea cambiar el fondo o los
parámetros de Matugen, no editar cinco archivos a mano.

## Crear o ajustar un tema

Antes de activarlo globalmente:

```bash
matugen image "$HOME/Pictures/walls/wallpaper.jpg" --mode dark \
  --source-color-index 0 --dry-run --show-colors
```

`--source-color-index 0` evita el selector interactivo cuando se ejecuta desde
un atajo o desde Quickshell. El índice se puede cambiar si el primer color
extraído no representa bien el fondo.

Cuando la paleta sea satisfactoria, se quitará `--dry-run` y se validarán en
este orden Waybar, Wofi, Kitty, Hyprland y finalmente Quickshell. Para agregar
un nuevo destino hay que añadir una plantilla en `~/.config/matugen/templates/`,
registrarla en `config.toml`, indicar su comando de recarga y actualizar la
tabla de componentes de este documento.

## Referencia oficial

- [Matugen](https://github.com/InioX/matugen): genera paletas Material You y
  permite usar plantillas.
- [Configuración y plantillas](https://github.com/InioX/matugen/wiki/Configuration):
  formato de `config.toml`, salidas y `post_hook`.
- [FAQ de Hyprland](https://github.com/InioX/matugen/wiki/FAQ): sintaxis para
  bordes `rgb`/`rgba`.
