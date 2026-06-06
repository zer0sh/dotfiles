#version 320 es
precision highp float;

in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

void main() {
    vec4 pix = texture(tex, v_texcoord);

    float gray = dot(pix.rgb, vec3(0.299, 0.587, 0.114));
    vec3 vivid = mix(vec3(gray), pix.rgb, 1.3);

    vivid *= vec3(1.0, 0.98, 0.95);

    vivid = clamp(pow(vivid, vec3(0.9)), 0.0, 1.0);

    float grain = (fract(sin(dot(v_texcoord * 100.0, vec2(12.9898, 78.233))) * 43758.5453) - 0.5) * 0.07;

    fragColor = vec4(vivid + grain, pix.a);
}
