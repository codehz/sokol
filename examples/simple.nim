import sokol/[app, gfx, glue, tools]
import macros

compileshader staticRead "simple.glsl"

macro dump(it: typed) =
  echo treerepr it.getImpl

dump triangle

var vertices = [
  0.0f,  0.5f, 0.5f, 1.0f, 0.0f, 0.0f, 1.0f,
  0.5f, -0.5f, 0.5f, 0.0f, 1.0f, 0.0f, 1.0f,
  -0.5f, -0.5f, 0.5f, 0.0f, 0.0f, 1.0f, 1.0f
]

var bufferdesc = BufferDesc(data: vertices, label: "triangle-vertices")
var bindings: Bindings
var pipeline: Pipeline
var layout = LayoutDesc()
layout.attrs[0].format = vf_float3
layout.attrs[1].format = vf_float4
var passAction: PassAction
passAction.colors[0] = ColorAttachmentAction(action: action_clear, color: Color(r: 0.0, g: 0.0, b: 0.0, a: 1.0))

define_app:
  init:
    gfx.setup Desc(context: gfx_context())
    bindings.vertex_buffers[0] = gfx.make bufferdesc
    let shd = gfx.make triangle
    pipeline = gfx.make PipelineDesc(
      shader: shd,
      layout: layout,
      label: "triangle-pipeline"
    )
  frame:
    begin_default_pass passAction, width(), height()
    apply_pipeline pipeline
    apply_bindings bindings
    draw(0, 3, 1)
    end_pass()
    commit()
  cleanup:
    gfx.shutdown()
  app_desc.window_title = "simple"