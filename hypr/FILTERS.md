# Filters / Shaders

## Crear un nuevo filtro

### 1. Crear el shader GLSL

En `~/.config/hypr/shaders/` creá un archivo `.glsl`:

```glsl
#version 320 es
precision highp float;

in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

void main() {
    vec4 pix = texture(tex, v_texcoord);

    // --- tu efecto acá ---
    // pix.rgb son los canales rojo, verde, azul (0.0 - 1.0)
    // pix.a es el canal alpha (dejalo como está)

    fragColor = vec4(pix.rgb, pix.a);
}
```

### 2. Agregarlo al script de filtros

En `~/.config/hypr/scripts/filter`, añadí un nuevo case:

```bash
    mifiltro)
        apply_shader "Mi Filtro" "$SHADER_DIR/mifiltro.glsl"
        ;;
```

Y actualizá la línea de ayuda al final:

```bash
echo "Uso: $0 {sepia|bw|noir|vintage|vivid|mifiltro|off|toggle|status}"
```

### 3. Agregar atajo de teclado (opcional)

En `~/.config/hypr/binds.conf`:

```
bind = $mainMod CTRL, 6, exec, $HOME/.config/hypr/scripts/filter mifiltro
```

### 4. Recargar

```
SUPER + SHIFT + R
```

o

```
hyprctl reload
```

---

## Efectos útiles

| Efecto | Código |
|--------|--------|
| **Brillo** | `pix.rgb *= 1.2;` |
| **Contraste** | `pix.rgb = clamp((pix.rgb - 0.5) * 1.3 + 0.5, 0.0, 1.0);` |
| **Saturación** | `float g = dot(pix.rgb, vec3(0.299, 0.587, 0.114)); pix.rgb = mix(vec3(g), pix.rgb, 1.3);` |
| **Tinte** | `pix.rgb *= vec3(1.1, 0.95, 0.8);` (rojo/verde/azul) |
| **Grano** | `float g = (fract(sin(dot(v_texcoord * 100.0, vec2(12.9898, 78.233))) * 43758.5453) - 0.5) * 0.05; pix.rgb += g;` |
| **Viñeta** | `float v = 1.0 - length(v_texcoord - 0.5) * 0.7; v = clamp(v, 0.0, 1.0); pix.rgb *= v;` |
| **Blanco y negro** | `float g = dot(pix.rgb, vec3(0.299, 0.587, 0.114)); pix.rgb = vec3(g);` |

---

## Shaders disponibles

| Modo | Archivo | Efecto |
|------|---------|--------|
| `sepia` | `sepia.glsl` | B&N + tono marrón cálido + grano |
| `bw` | `bw.glsl` | Blanco y negro puro |
| `noir` | `noir.glsl` | Alto contraste + viñeta + grano |
| `vintage` | `vintage.glsl` | Sepia desgastado + grano |
| `vivid` | `vivid.glsl` | Colores intensos + grano |
| `off` | `off.glsl` | Sin efecto (passthrough) |
