#version 320 es
precision highp float;

in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

void main() {
    vec4 pix = texture(tex, v_texcoord);
    float gray = dot(pix.rgb, vec3(0.299, 0.587, 0.114));

    fragColor = vec4(vec3(gray), pix.a);
}
