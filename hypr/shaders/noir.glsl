#version 320 es
precision highp float;

in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

void main() {
    vec4 pix = texture(tex, v_texcoord);
    float gray = dot(pix.rgb, vec3(0.299, 0.587, 0.114));

    gray = pow(gray, 1.4);

    float dist = length(v_texcoord - 0.5);
    float vignette = 1.0 - dist * 0.7;
    vignette = clamp(vignette, 0.0, 1.0);

    float grain = (fract(sin(dot(v_texcoord * 100.0, vec2(12.9898, 78.233))) * 43758.5453) - 0.5) * 0.03;

    vec3 noir = vec3(gray) + grain;
    fragColor = vec4(noir * vignette, pix.a);
}
