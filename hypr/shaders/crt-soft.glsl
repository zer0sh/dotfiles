#version 320 es
precision highp float;

in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

void main() {
    // Reduced curvature for minimal distortion and clean text readability
    vec2 cc = v_texcoord - 0.5;
    float dist = dot(cc, cc);
    vec2 uv = v_texcoord + cc * (dist * 0.055);

    // Clean outer screen boundaries
    if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
        fragColor = vec4(0.0, 0.0, 0.0, 1.0);
        return;
    }

    // Chromatic aberration slightly boosted (+5%)
    vec2 caOffset = cc * (dist * 0.02625 + 0.00315);
    float r = texture(tex, uv + caOffset).r;
    float g = texture(tex, uv).g;
    float b = texture(tex, uv - caOffset).b;
    float a = texture(tex, uv).a;
    vec3 color = vec3(r, g, b);

    // Fine, dense scanlines (higher frequency, gentle intensity)
    float scanline = sin(uv.y * 1100.0) * 0.028;
    color -= scanline;

    // Soft edge vignette
    float vignette = clamp(1.0 - dist * 0.85, 0.0, 1.0);
    color *= vignette;

    // Balanced phosphor brightness
    color = pow(color, vec3(0.96)) * 1.02;

    fragColor = vec4(clamp(color, 0.0, 1.0), a);
}
