# Notificaciones y OSDs

Esta guía documenta la arquitectura, el posicionamiento y el sistema de animaciones para las **notificaciones flotantes (toasts)** y los **OSDs** (Volumen, Brillo, Música y MiniPlayer) en Quickshell para Hyprland.

---

## 📐 Parámetros de Diseño y Comportamiento

Todos los elementos emergentes comparten una especificación unificada:

1. **Posición en pantalla:** Parte superior centrada horizontalmente (`anchors.top: true`, `anchors.horizontalCenter: parent.horizontalCenter`).
2. **Margen superior:** `topMargin: 46 px` (deja un respiro visual debajo de Waybar).
3. **Animación de entrada (Slide Down):**
   * Desplazamiento desde `_slideY: -28` hasta `0` en 260–280 ms con aceleración `Easing.OutCubic`.
   * Desvanecimiento de opacidad progresivo de `0` a `1` en 220 ms con `Easing.OutQuad`.
4. **Desplazamiento fluido en cola:** Al recibir una notificación nueva, esta toma la posición superior y empuja automáticamente las notificaciones anteriores hacia abajo mediante `move: Transition`.
5. **Animación de salida:** Retroceso suave hacia arriba (`to: -20`) y desvanecimiento (`opacity: 0`) antes de desmontarse.

---

## 📂 Archivos Involucrados

| Componente | Archivo Fuente | Propósito |
| :--- | :--- | :--- |
| **Contenedor Toasts** | `modules/notifications/NotificationToastLayer.qml` | Ventana overlay, inserción al inicio y transición de la columna. |
| **Tarjeta Notificación** | `modules/notifications/NotificationPopup.qml` | Diseño de la tarjeta, animación slide-down y fade-out al descartar. |
| **OSD de Volumen** | `modules/osd/VolumeOsd.qml` | OSD que responde a cambios en PipeWire / audio. |
| **OSD de Brillo** | `modules/osd/BrightnessOsd.qml` | OSD que responde a `brightnessctl`. |
| **OSD de Canción** | `modules/osd/MusicOsd.qml` | Toast automático al cambiar de pista en MPRIS. |
| **Mini Reproductor** | `modules/osd/MiniPlayer.qml` | Widget interactivo de reproducción (`SUPER + M`). |

---

## 🛠️ Ajustes Futuros

### Cambiar la distancia superior
Modifica `topMargin` en el contenedor `Item` o `toastCol`:
```qml
anchors.topMargin: 46 // Aumentar para bajar, reducir para subir
```

### Cambiar la velocidad de la animación
En el bloque `appearAnim`:
```qml
NumberAnimation {
    target: osdCard; property: "_slideY"
    from: -28; to: 0; duration: 260; easing.type: Easing.OutCubic
}
```

### Pruebas en vivo
* **Notificaciones:**
  ```bash
  notify-send "Prueba" "Desplazamiento suave hacia abajo"
  ```
* **Volumen:**
  ```bash
  wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
  ```
