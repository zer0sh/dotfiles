# Quickshell y Centro de Control

Quickshell es el motor de widgets gráficos sobre Wayland utilizado en este entorno. Proporciona una interfaz inspirada en One UI con superficies translúcidas, esquinas redondeadas y controles interactivos.

---

## 📱 Módulos de Quickshell

* **Centro de Control (`modules/controlcenter/`):**
  * Toggles de Wi-Fi, Bluetooth, DND, Modo Avión, Cafeína, Perfiles de Energía, Night Light y Shaders.
  * Sliders continuos de volumen y brillo.
  * Acceso directo a selector de temas y estado de batería.
* **Notificaciones y Toasts (`modules/notifications/`):**
  * Servidor DBus propio (`org.freedesktop.Notifications`).
  * Capa flotante superior central para notificaciones en vivo.
  * Historial acumulado accesible desde Waybar o atajo de teclado.
* **Portapapeles (`modules/clipboard/`):**
  * Historial visual integrado con `cliphist`.
* **DeskClock y Calendario (`modules/deskclock/`, `modules/calendar/`):**
  * Reloj decorativo de escritorio y visualizador de eventos de calendario.
* **Mini Reproductor (`modules/osd/MiniPlayer.qml`):**
  * Control compacto de reproducción musical MPRIS en pantalla.

---

## 🔄 Recarga y Validación

Para verificar la integridad del código QML o reiniciar el entorno:

```bash
# Validar sintaxis sin reiniciar
~/.config/quickshell/restart-quickshell.sh --validate

# Reiniciar Quickshell en vivo
~/.config/quickshell/restart-quickshell.sh
```
