import ./private/backend
import ./app
import ./gfx

proc gfx_context*(): ContextDesc =
  result.color_format = color_format()
  result.depth_format = depth_format()
  result.sample_count = sample_count()
  result.gl.force_gles2 = gles2()
  when sokol_backend == "METAL":
    result.metal.device                = metal_get_device()
    result.metal.renderpass_descriptor = metal_get_renderpass_descriptor
    result.metal.drawable              = metal_get_drawable
  elif sokol_backend == "D3D11":
    result.d3d11.device             = d3d11_get_device()
    result.d3d11.device_context     = d3d11_get_device_context()
    result.d3d11.render_target_view = d3d11_get_render_target_view
    result.d3d11.depth_stencil_view = d3d11_get_depth_stencil_view
  elif sokol_backend == "WGPU":
    result.wgpu.device             = wgpu_get_device()
    result.wgpu.render_view        = wgpu_get_render_view
    result.wgpu.resolve_view       = wgpu_get_resolve_view
    result.wgpu.depth_stencil_view = wgpu_get_depth_stencil_view