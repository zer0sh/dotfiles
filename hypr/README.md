# Configuración de Hyprland

Esta es la configuración modular para Hyprland. Se basa en archivos separados para facilitar el mantenimiento y la legibilidad.

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
Servicios y aplicaciones que se inician con la sesión (ej. barra de estado, fondo de pantalla, agentes de autenticación).

### 🔲 Ventanas (`window.conf`)
Reglas de ventanas (Window Rules) y gestión de layouts (Dwindle/Master).

### ⚙️ Variables & Misc (`variables.conf` & `miscellaneous.conf`)
Configuraciones globales como sensibilidad del ratón, layout del teclado y opciones misceláneas de Hyprland.

## Herramientas Adicionales
- **Scripts:** Ubicados en `scripts/` para control de volumen, brillo y filtros.
- **Shaders:** Ubicados en `shaders/` para efectos visuales personalizados.
- **Idle & Lock:** `hypridle.conf` y `hyprlock.conf` para la gestión de energía y bloqueo de pantalla.
