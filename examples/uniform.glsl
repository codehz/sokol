#pragma sokol @vs vs
in vec4 position;

void main() {
  gl_Position = position;
}
#pragma sokol @end

#pragma sokol @fs fs
uniform ColorInput {
  vec3 color;
};
out vec4 frag_color;

void main() { frag_color = vec4(color, 1); }
#pragma sokol @end

#pragma sokol @program uniform_demo vs fs
