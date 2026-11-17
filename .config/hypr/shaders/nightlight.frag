#version 300 es
precision mediump float;
in vec2 v_texcoord;
layout(location = 0) out vec4 fragColor;
uniform sampler2D tex;

void main() {
    vec4 pixColor = texture(tex, v_texcoord);
    // Warm night light: reduce blue channel and gently soften green
    pixColor.g *= 0.88;
    pixColor.b *= 0.70;
    fragColor = pixColor;
}
