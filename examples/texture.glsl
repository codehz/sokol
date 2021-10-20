#pragma sokol @vs vs
in vec4 position;
in vec2 uv;

out vec2 vuv;

void main() {
  gl_Position = position;
  vuv = uv;
}
#pragma sokol @end

#pragma sokol @fs fs
uniform sampler2D tex;
in vec2 vuv;
out vec4 frag_color;

void main() { frag_color = texture(tex, vuv); }
#pragma sokol @end

#pragma sokol @program triangle vs fs