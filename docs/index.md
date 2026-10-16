# zer0sh Dotfiles

Bienvenido a la documentación oficial del entorno de escritorio de **zer0sh**, construido sobre **Hyprland** (Wayland) y personalizado con **Quickshell**, **Waybar**, **Kitty / Alacritty**, y **Zsh**.

---

## 🎯 Filosofía del Entorno

* **Modularidad estricta:** Ningún archivo de configuración gigante. Cada aspecto (atajos, monitores, animaciones, servicios de inicio) se gestiona en su propio módulo.
* **Fuente de verdad en vivo:** La configuración activa de Hyprland reside directamente en `~/.config/hypr/` como una carpeta real e independiente, facilitando pruebas directas sin fricción de symlinks intermediarios.
* **Integración visual cohesiva:** Paleta generada mediante temas centralizados consumidos por Quickshell, Hyprland, Waybar y emuladores de terminal.
* **Notificaciones y OSDs modernos:** Superficies flotantes en la parte superior central de la pantalla con desplazamiento fluido y transiciones ligeras.

---

## 🚀 Módulos Documentados

* [**Hyprland**](hyprland/index.md): Arquitectura modular, layout de monitores y configuración de reglas.
* [**Atajos de Teclado**](hyprland/keybinds.md): Chuleta completa de atajos y utilidades.
* [**Shaders y Filtros**](hyprland/shaders.md): Efectos GLSL (Sepia, B&W, Noir, Vintage, Vivid).
* [**Quickshell**](quickshell/index.md): Panel de control One UI y widgets de sistema.
* [**Notificaciones y OSDs**](quickshell/osd-notifications.md): Posicionamiento top-center y animaciones de deslizamiento.
* [**Flujo de Dotfiles**](dotfiles/workflow.md): Gestión del repositorio, copias de seguridad y sincronización con GitHub.
