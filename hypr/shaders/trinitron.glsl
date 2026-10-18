#version 320 es
precision highp float;

in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

void main() {
    // Trinitron: cylindrical aperture grille screen (flat in Y, subtle horizontal curvature in X)
    vec2 cc = v_texcoord - 0.5;
    float distH = cc.x * cc.x;
    vec2 uv = vec2(v_texcoord.x + cc.x * (distH * 0.025), v_texcoord.y);

    if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
        fragColor = vec4(0.0, 0.0, 0.0, 1.0);
        return;
    }

    // Horizontal chromatic deflection aberration
    float ca = cc.x * 0.0016;
    float r = texture(tex, vec2(uv.x + ca, uv.y)).r;
    float g = texture(tex, uv).g;
    float b = texture(tex, vec2(uv.x - ca, uv.y)).b;
    float a = texture(tex, uv).a;
    vec3 col = vec3(r, g, b);

    // Aperture Grille: vertical continuous RGB phosphor stripes authentic to Sony Trinitron
    float px = uv.x * 1920.0 * 3.14159265;
    vec3 grille = vec3(0.5) + vec3(0.5) * sin(vec3(px, px - 2.094395, px + 2.094395));
    col *= mix(vec3(1.0), grille * 1.25, 0.16);

    // Uniform horizontal scanlines
    float scanline = sin(uv.y * 1200.0 * 3.14159265 * 0.5) * 0.032;
    col -= scanline;

    // Classic Trinitron tension damping wires at 33% and 66% screen height
    float wire1 = smoothstep(0.0012, 0.0, abs(uv.y - 0.333));
    float wire2 = smoothstep(0.0012, 0.0, abs(uv.y - 0.666));
    col *= (1.0 - (wire1 + wire2) * 0.07);

    // Trinitron contrast response: deep blacks, phosphor luminescence and rich saturation
    col = pow(col, vec3(1.04));
    col *= vec3(1.02, 1.01, 1.04);
    col *= 1.05; // luminance compensation

    // Subtle cylindrical vignette
    float vig = clamp(1.0 - distH * 0.35, 0.0, 1.0);
    col *= vig;

    fragColor = vec4(clamp(col, 0.0, 1.0), a);
}
