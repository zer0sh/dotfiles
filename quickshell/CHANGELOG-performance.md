# Registro de cambios de rendimiento

## 2026-08-27

- `modules/osd/MiniPlayer.qml`: el polling MPRIS solo se ejecuta mientras el mini reproductor está abierto.
- `modules/controlcenter/MusicSection.qml`: el polling MPRIS solo se ejecuta mientras el centro de control está visible.
- `modules/controlcenter/ControlCenter.qml`: conecta `panelVisible` con `MusicSection`.
- `modules/osd/MusicOsd.qml`: usa `postTrackChanged` y `playbackStateChanged` para reaccionar a cambios de MPRIS.
- `modules/osd/MusicOsd.qml`: el polling de descubrimiento se redujo a una comprobación cada 10 segundos, únicamente para detectar reproductores nuevos o eliminados.
- `hypr/animations.conf`: la entrada de ventanas cambió de `bounce` a `smooth` y aumentó su velocidad de 3 a 7 para reducir la sensación de retraso al abrir aplicaciones.
- `hypr/animations.conf`: la velocidad de entrada de ventanas aumentó de 7 a 12 tras la prueba, manteniendo la curva `smooth`.
- `hypr/animations.conf`: la velocidad de entrada bajó de 12 a 1, el mínimo distinto de cero, porque el valor anterior se percibía más lento.
- `hypr/animations.conf`: `windowsIn` cambió a la curva `default` y `fade` a velocidad 1 con curva `default`, para reducir al mínimo la demora visual al abrir ventanas.
- `hypr/binds.conf`: el atajo de terminal ahora usa `kitty --single-instance` para abrir nuevas ventanas en el proceso existente y evitar arrancar Kitty desde cero.
- `kitty/kitty.conf`: Kitty se configuró temporalmente para lanzar Bash puro con `/bin/bash --noprofile --norc`, sin cargar archivos de configuración, para comparar el tiempo de inicio con Zsh.
- `hypr/binds.conf`: el atajo `Super + Enter` cambió temporalmente de Kitty a Alacritty para comparar el tiempo de apertura de la primera terminal.
- `matugen/config.toml`: se añadió una salida de paleta para Alacritty.
- `matugen/templates/alacritty.toml`: nueva plantilla con los colores, fuente y selección derivados de la misma paleta que Kitty.
- `alacritty/alacritty.toml`: Alacritty importa la paleta generada desde `themes/current`.
- `alacritty/alacritty.toml`: se movió `import` dentro de `[general]` para eliminar el aviso de opción obsoleta en Alacritty 0.15.
- `alacritty/alacritty.toml`: se activó explícitamente `live_config_reload` para que el tema generado se aplique a ventanas existentes.
- `themes/apply-matugen.sh`: dejó de intentar aplicar colores en vivo a Kitty; Alacritty usa ahora el archivo generado y su recarga automática.
- `quickshell/scripts/apply-theme.sh`: los temas manuales de Quickshell también generan `themes/current/alacritty.toml` usando la misma paleta ANSI que Kitty.
- `alacritty/alacritty.toml`: se añadió opacidad 0.92 y solicitud de blur para integrar Alacritty visualmente con Hyprland.

## Copias de seguridad

- Copia previa a la modificación de señales: `backups/20260827-173940/`.
- Copia previa al ajuste de animaciones: `backups/20260827-174256/animations.conf`.
- Copia previa al segundo ajuste de animaciones: `backups/20260827-174352/animations.conf`.
- Copia previa al tercer ajuste de animaciones: `backups/20260827-174442/animations.conf`.
- Copia previa al cuarto ajuste de animaciones: `backups/20260827-174625/animations.conf`.
- Copia previa al ajuste del bind de Kitty: `backups/20260827-175255/binds.conf`.
- Copia previa a la prueba con Bash puro: `backups/20260827-180039/kitty.conf`.
- Copia previa al cambio de terminal a Alacritty: `backups/20260827-180340/binds.conf`.
- Copia previa a la integración de Alacritty con Matugen: `backups/20260827-181318/matugen-config.toml`.
- Copia previa a la corrección de `import` de Alacritty: `backups/20260827-181606/alacritty.toml`.
- Copia previa a la integración del cambio de tema en Alacritty: `backups/20260827-181810/`.
- Copia previa al ajuste de transparencia/blur de Alacritty: `backups/20260827-182052/alacritty.toml`.
