# Shaders y Filtros de Pantalla

El entorno incluye shaders GLSL personalizados aplicados directamente por el compositor Hyprland mediante la directiva `hyprctl keyword decoration:screen_shader`.

---

## Shaders Disponibles

| Shader | Archivo GLSL | Efecto visual |
| :--- | :--- | :--- |
| **Sepia** | `sepia.glsl` | Tono cálido clásico inspirado en fotografía de los años 30. |
| **Blanco y Negro** | `bw.glsl` | Escala de grises pura sin grano. |
| **Film Noir** | `noir.glsl` | Alto contraste dramático con grano cinematográfico. |
| **Vintage** | `vintage.glsl` | Sepia envejecido con viñeta y textura. |
| **Vivid** | `vivid.glsl` | Saturación realzada y tonos vibrantes. |
| **Off** | `off.glsl` | Passthrough sin efectos (pantalla natural). |

---

## Control desde el Panel de Quickshell

En el panel de control de Quickshell:
* El botón circular actúa como interruptor **On / Off**.
* El botón de tres puntos `⋯` rota al siguiente filtro (`filter next`):
  ```text
  Off → Sepia → B&W → Noir → Vintage → Vivid → Off
  ```
* El estado actual se persiste en `/tmp/hypr-bw-filter`.
