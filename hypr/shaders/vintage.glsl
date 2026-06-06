#version 320 es
precision highp float;

in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

void main() {
    vec4 pix = texture(tex, v_texcoord);
    float gray = dot(pix.rgb, vec3(0.299, 0.587, 0.114));

    vec3 sepia = vec3(gray) * vec3(1.1, 0.85, 0.65);
    sepia = mix(sepia, vec3(0.7, 0.65, 0.6), 0.15);

    float grain = (fract(sin(dot(v_texcoord * 50.0, vec2(12.9898, 78.233))) * 43758.5453) - 0.5) * 0.05;

    fragColor = vec4(sepia + grain, pix.a);
}
