#version 320 es
precision highp float;

in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

void main() {
    // Subtle CRT barrel curvature
    vec2 cc = v_texcoord - 0.5;
    float dist = dot(cc, cc);
    vec2 uv = v_texcoord + cc * (dist * 0.08);

    // Black borders outside curved cathode ray tube screen
    if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
        fragColor = vec4(0.0, 0.0, 0.0, 1.0);
        return;
    }

    // Chromatic aberration: radial RGB separation accentuated at edges
    vec2 caOffset = cc * (dist * 0.025 + 0.003);
    float r = texture(tex, uv + caOffset).r;
    float g = texture(tex, uv).g;
    float b = texture(tex, uv - caOffset).b;
    float a = texture(tex, uv).a;
    vec3 color = vec3(r, g, b);

    // Subtle horizontal scanlines
    float scanline = sin(uv.y * 650.0) * 0.045;
    color -= scanline;

    // CRT corner vignette
    float vignette = clamp(1.0 - dist * 1.05, 0.0, 1.0);
    color *= vignette;

    // Light phosphor glow boost
    color = pow(color, vec3(0.94)) * 1.03;

    fragColor = vec4(clamp(color, 0.0, 1.0), a);
}
