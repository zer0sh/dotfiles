# Arquitectura de Hyprland

Hyprland está configurado mediante una estructura modular estricta. El archivo principal `hyprland.conf` no define atajos ni propiedades individuales; únicamente actúa como director de orquesta mediante directivas `source =`.

---

## Estructura de Módulos

```text
~/.config/hypr/
├── hyprland.conf         # Punto de entrada (solo importa módulos)
├── binds.conf            # Atajos de teclado y ratón
├── monitors.conf         # Resoluciones y posición de pantallas (nwg-displays)
├── workspaces.conf       # Asignación de escritorios virtuales
├── autostart.conf        # Procesos exec-once al iniciar sesión
├── animations.conf       # Curvas de animación Bezier
├── decoration.conf       # Bordes, sombras, blur y gaps
├── miscellaneous.conf    # Repetición de teclado y comportamiento del layout
├── window.conf           # Reglas de ventanas (windowrule / windowrulev2)
├── hyprlock.conf         # Pantalla de bloqueo
├── hypridle.conf         # Gestión de inactividad
├── scripts/              # Utilidades ejecutables (OCR, screenshots, filtros)
└── shaders/              # Shaders GLSL de postprocesamiento
```

---

## Punto de Entrada (`hyprland.conf`)

```ini
# Monitor layout gestionado por nwg-displays
source = $HOME/.config/hypr/monitors.conf

source = $HOME/.config/hypr/variables.conf
source = $HOME/.config/hypr/binds.conf
source = $HOME/.config/hypr/window.conf
source = $HOME/.config/hypr/decoration.conf

# Paleta centralizada generada por tema activo
source = $HOME/.config/themes/current/hyprland.conf

source = $HOME/.config/hypr/animations.conf
source = $HOME/.config/hypr/miscellaneous.conf
source = $HOME/.config/hypr/autostart.conf
```

---

## Servicios de Inicio (`autostart.conf`)

* **Quickshell:** Carga el entorno de widgets, OSDs y panel de control.
* **Waybar:** Barra superior de estado.
* **Polkit:** `systemctl --user start hyprpolkitagent` para elevación de privilegios gráfica.
* **Cliphist:** Historial de portapapeles para texto e imágenes.
* **Wallpaper:** Restauración automática con `$HOME/.config/hypr/scripts/restore-wallpaper`.
