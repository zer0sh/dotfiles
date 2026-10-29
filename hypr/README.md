# Configuración de Hyprland y Quickshell

Configuración modular para Hyprland y Quickshell. El panel de control usa una composición inspirada en One UI: superficies flotantes, controles circulares, cápsulas grandes y separación generosa entre grupos.

## Módulos Principales

### 🖥️ Monitores (`hyprland.conf`)
Configuración de resoluciones, tasas de refresco y posiciones.
- Configuración actual: `eDP-1, 1920x1200@60, 0x0, 1`

### ⌨️ Keybinds (`binds.conf`)
Define todos los atajos de teclado para la gestión de ventanas, ejecución de aplicaciones y controles de sistema.

### 🎨 Apariencia (`decoration.conf` & `animations.conf`)
- **Decoración:** Bordes, sombras, blur y opacidad.
- **Animaciones:** Curvas de Bezier y configuraciones de movimiento para ventanas y capas.

### 🚀 Autostart (`autostart.conf`)
Servicios y aplicaciones que se inician con la sesión (barra, fondo de pantalla, Quickshell, `hypridle` y clipboard).

### 🔲 Ventanas (`window.conf`)
Reglas de ventanas (Window Rules) y gestión de layouts (Dwindle/Master).

### ⚙️ Variables & Misc (`variables.conf` & `miscellaneous.conf`)
Configuraciones globales como sensibilidad del ratón, layout del teclado y opciones misceláneas de Hyprland.

## Herramientas Adicionales
- **Scripts:** Ubicados en `scripts/` para control de volumen, brillo, filtros y notificaciones de batería y cargador (`battery-notify`).
- **Shaders:** Ubicados en `shaders/` para efectos visuales personalizados.
- **Idle & Lock:** `hypridle.conf` y `hyprlock.conf` para la gestión de energía y bloqueo de pantalla.

## Panel de control de Quickshell

El panel se abre desde el área de estado de Waybar o con:

```bash
qs ipc call controlcenter toggle
```

### Estilo y geometría

- Panel flotante de 410 px de ancho.
- Radio exterior de 32 px.
- Fondo basado en `Theme.surface` con alpha `0.80`.
- Blur gestionado por Hyprland mediante `layerrule` para `quickshell:*`.
- Cuatro controles principales en la primera fila: Wi-Fi, Bluetooth, DND y Airplane.
- Los controles principales usan `CircleToggle.qml` y círculos de 60 px.
- Wi-Fi y Bluetooth tienen un botón `⋯` para abrir sus páginas detalladas.
- Audio también usa un botón circular con acceso `⋯` a salida/entrada.
- Volumen y brillo usan cápsulas compactas de 46 px con icono circular y porcentaje.

### Controles disponibles

- **Wi-Fi:** intenta primero reutilizar el perfil guardado de NetworkManager; solo solicita contraseña si falla.
- **Bluetooth:** activa/desactiva Bluetooth y abre su página detallada desde `⋯`.
- **DND:** controla directamente el `NotificationService` de Quickshell. Oculta los avisos emergentes, pero conserva el historial.
- **Airplane:** activa o desactiva Wi-Fi y Bluetooth conjuntamente.
- **Caffeine:** usa `systemd-inhibit` para evitar suspensión e inactividad mientras está activo.
- **Power:** rota entre `Balanced`, `Performance` y `Power Saver` mediante `powerprofilesctl`.
- **Night Light:** usa `wlsunset` para aplicar una temperatura cálida de pantalla.
- **Shader:** el círculo funciona como On/Off; el botón `⋯` cambia entre los shaders disponibles.

### Dependencias opcionales

```bash
sudo apt install power-profiles-daemon wlsunset
```

`power-profiles-daemon` proporciona `powerprofilesctl`. `wlsunset` proporciona Night Light en Wayland.

### Archivos principales de Quickshell

- `shell.qml`: instancia los módulos.
- `Theme.qml`: colores, radios, tamaños y espaciado.
- `modules/controlcenter/ControlCenter.qml`: estado, acciones y composición principal.
- `modules/controlcenter/CircleToggle.qml`: botón circular reutilizable.
- `modules/controlcenter/VolumeSection.qml`: control de volumen.
- `modules/controlcenter/BrightnessSection.qml`: control de brillo.
- `modules/controlcenter/WifiSection.qml`: redes y perfiles guardados.
- `modules/notifications/NotificationService.qml`: notificaciones y DND.

## Sistema de temas

La guía de referencia para el sistema de colores está en
[`MATUGEN.md`](./MATUGEN.md). Allí se documentan los componentes que deben
recibir color, los roles comunes, las recargas necesarias y el procedimiento
para crear temas nuevos con Matugen.

La integración dinámica basada en el wallpaper está preparada a nivel de
diseño, pero aún no está activada globalmente: se conserva el sistema manual
como fallback mientras se valida la paleta generada.
