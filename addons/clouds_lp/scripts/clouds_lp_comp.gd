@tool
class_name CloudsLP
extends CompositorEffect

## 2^[code]scale_down_power[/code] (ex: 0: native, 1: half, 2: quarter, ...)
@export_enum("Native", "Half", "Quarter", "Eighth", "Sixteenth", "Thirtysecond") var scale_down_power_editor: int = 3:
	set(value):
		scale_down_power_editor = value
		if Engine.is_editor_hint():
			_mutex.lock()
			_scaled_down = 1 << scale_down_power_editor
			_longterm_uniforms_good = false
			_mutex.unlock()
## 2^[code]scale_down_power[/code] (ex: 0: native, 1: half, 2: quarter, ...)
@export_enum("Native", "Half", "Quarter", "Eighth", "Sixteenth", "Thirtysecond") var scale_down_power: int = 2:
	set(value):
		scale_down_power = value
		if not Engine.is_editor_hint():
			_mutex.lock()
			_scaled_down = 1 << scale_down_power
			_longterm_uniforms_good = false
			_mutex.unlock()
## Force reload of shader files.
@export var reload := false:
	set(value):
		_mutex.lock()
		reload = false
		_reload_shaders = true
		_mutex.unlock()
## Write PNGs (see Output) for debugging.
@export var write_debug := false:
	set(value):
		_mutex.lock()
		write_debug = false
		_req_write_debug = value
		_mutex.unlock()
## Force disable atmosphere.
## Overrides [code]Profile[/code].
@export var atmo_enabled := true
## Force disable clouds.
## Overrides [code]Profile[/code].
@export var cloud_enabled := true
## Force disable cloud atmospheric lighting.[br]
## Overrides [code]Profile[/code].
@export var cloud_atmo_light_enabled := true
## Optional distance limit, useful for simple cloud sampling.[br]
## [color=white]Note:[/color] ignored for values <= 0.0.
@export var max_distance := 0.0
@export var position := Vector3.ZERO
@export var light_position := Vector3.ZERO
@export var light_color := Color.WHITE
## Cloud Quality Profile.
@export var cloud_quality: CloudQualityProfile:
	set(value):
		_mutex.lock()
		cloud_quality = value
		_reload_shaders = true
		_mutex.unlock()
## Atmosphere and Cloud Profile.
@export var profile: AtmosphereProfile:
	set(value):
		_mutex.lock()
		profile = value
		_reload_shaders = true
		_mutex.unlock()
@export_group("Compute Shaders", "shdr")
@export var shdr_downscaler_file: RDShaderFile
@export var shdr_clouds_file: RDShaderFile
@export var shdr_upscaler_file: RDShaderFile
@export var shdr_atmo_file: RDShaderFile

var _rd: RenderingDevice
var _shader_scale_down: RID
var _shader_clouds: RID
var _shader_scale_up: RID
var _shader_atmo: RID
var _pipeline_pass_1: RID
var _pipeline_pass_2: RID
var _pipeline_pass_3: RID
var _pipeline_pass_4: RID
var _sampler_linear: RID
var _sampler_linear_nr: RID
var _sampler_linear_mir: RID
var _sampler_nearest: RID
var _sampler_nearest_nr: RID
var _config_data_rid: RID
var _clouds_high: RID
var _clouds_low: RID
var _depth_high: RID
var _depth_low: RID

var _req_write_debug := false
var _reload_shaders := false
var _longterm_uniforms_good := false
var _scaled_down := 1
var _mutex := Mutex.new()
var _last_size: Vector2i
var _scaled_size: Vector2i
var _config_data: PackedByteArray


# Called when this resource is constructed.
func _init() -> void:
	#region initial kicks to tigger set() calls
	if Engine.is_editor_hint():
		scale_down_power_editor = scale_down_power_editor
	else:
		scale_down_power = scale_down_power
	#endregion
	_setup.call_deferred()


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		if is_instance_valid(self):
			_cleanup()


func _setup() -> void:
	# Defaults
	access_resolved_color = true
	access_resolved_depth = true
	
	_rd = RenderingServer.get_rendering_device()
	_load_and_init()


func _cleanup(shaders := true, data := true) -> void:
	print("Cleanup (shaders %s | data %s)" % [shaders, data])
	
	if shaders:
		# Pipelines are auto cleared with corresponding shaders; but being explicit
		if _pipeline_pass_1.is_valid():
			_rd.free_rid(_pipeline_pass_1)
		_pipeline_pass_1 = RID()
		if _pipeline_pass_2.is_valid():
			_rd.free_rid(_pipeline_pass_2)
		_pipeline_pass_2 = RID()
		if _pipeline_pass_3.is_valid():
			_rd.free_rid(_pipeline_pass_3)
		_pipeline_pass_3 = RID()
		if _pipeline_pass_4.is_valid():
			_rd.free_rid(_pipeline_pass_4)
		_pipeline_pass_4 = RID()
		if _shader_scale_down.is_valid():
			_rd.free_rid(_shader_scale_down)
		_shader_scale_down = RID()
		if _shader_clouds.is_valid():
			_rd.free_rid(_shader_clouds)
		_shader_clouds = RID()
		if _shader_scale_up.is_valid():
			_rd.free_rid(_shader_scale_up)
		_shader_scale_up = RID()
		if _shader_atmo.is_valid():
			_rd.free_rid(_shader_atmo)
		_shader_atmo = RID()
	
	if data:
		if _config_data_rid.is_valid():
			_rd.free_rid(_config_data_rid)
		_config_data_rid = RID()
		if _sampler_linear.is_valid():
			_rd.free_rid(_sampler_linear)
		_sampler_linear = RID()
		if _sampler_linear_nr.is_valid():
			_rd.free_rid(_sampler_linear_nr)
		_sampler_linear_nr = RID()
		if _sampler_linear_mir.is_valid():
			_rd.free_rid(_sampler_linear_mir)
		_sampler_linear_mir = RID()
		if _sampler_nearest.is_valid():
			_rd.free_rid(_sampler_nearest)
		_sampler_nearest = RID()
		if _sampler_nearest_nr.is_valid():
			_rd.free_rid(_sampler_nearest_nr)
		_sampler_nearest_nr = RID()
		if _clouds_high.is_valid():
			_rd.free_rid(_clouds_high)
		_clouds_high = RID()
		if _clouds_low.is_valid():
			_rd.free_rid(_clouds_low)
		_clouds_low = RID()
		if _depth_high.is_valid():
			_rd.free_rid(_depth_high)
		_depth_high = RID()
		if _depth_low.is_valid():
			_rd.free_rid(_depth_low)
		_depth_low = RID()


func _load_and_init() -> bool:
	_cleanup(true, false)  # Cleanup shaders only
	print("Loading Resources (shaders recompiling)...")
	
	if not profile:
		push_error("Missing profile (check Profile)")
		return false
	
	if cloud_enabled and profile.planet_has_clouds and not cloud_quality:
		push_error("Missing cloud quality profile (check Cloud Quality)")
		return false
	
	if not (profile.ns_height and profile.ns_mask and profile.ns_large and profile.ns_medium and profile.ns_small and profile.ns_wisp):
		push_error("Missing textures (check Profile > Clouds > Noise)")
		return false
	
	if not (shdr_downscaler_file and shdr_clouds_file and shdr_upscaler_file and shdr_atmo_file):
		push_error("Missing shader files (check Shaders > * Files)")
		return false
	
	var shader_scale_down_spirv := shdr_downscaler_file.get_spirv()
	if not shader_scale_down_spirv: return false
	_shader_scale_down = _rd.shader_create_from_spirv(shader_scale_down_spirv)
	
	var shader_clouds_spirv := shdr_clouds_file.get_spirv()
	if not shader_clouds_spirv: return false
	_shader_clouds = _rd.shader_create_from_spirv(shader_clouds_spirv)
	
	var shader_scale_up_spirv := shdr_upscaler_file.get_spirv()
	if not shader_scale_up_spirv: return false
	_shader_scale_up = _rd.shader_create_from_spirv(shader_scale_up_spirv)
	
	var shader_atmo_spirv := shdr_atmo_file.get_spirv()
	if not shader_atmo_spirv: return false
	_shader_atmo = _rd.shader_create_from_spirv(shader_atmo_spirv)
	
	_pipeline_pass_1 = _rd.compute_pipeline_create(_shader_scale_down)
	_pipeline_pass_2 = _rd.compute_pipeline_create(_shader_clouds)
	_pipeline_pass_3 = _rd.compute_pipeline_create(_shader_scale_up)
	_pipeline_pass_4 = _rd.compute_pipeline_create(_shader_atmo)
	
	print("Ready")
	return _pipeline_pass_1.is_valid() and \
			_pipeline_pass_2.is_valid() and \
			_pipeline_pass_3.is_valid() and \
			_pipeline_pass_4.is_valid()


func _alloc_longterm_data(size: Vector2i) -> void:
	_cleanup(false, true)  # Cleanup data only
	print("Allocating longterm data...")
	
	if not _config_data or _config_data.size() != 224:
		_config_data = PackedByteArray()
		_config_data.resize(224)
	
	var sampler_linear_state := RDSamplerState.new()
	sampler_linear_state.min_filter = RenderingDevice.SAMPLER_FILTER_LINEAR
	sampler_linear_state.mag_filter = RenderingDevice.SAMPLER_FILTER_LINEAR
	sampler_linear_state.repeat_u = RenderingDevice.SAMPLER_REPEAT_MODE_REPEAT
	sampler_linear_state.repeat_v = RenderingDevice.SAMPLER_REPEAT_MODE_REPEAT
	sampler_linear_state.repeat_w = RenderingDevice.SAMPLER_REPEAT_MODE_REPEAT
	_sampler_linear = _rd.sampler_create(sampler_linear_state)
	
	var sampler_linear_nr_state := RDSamplerState.new()
	sampler_linear_nr_state.min_filter = RenderingDevice.SAMPLER_FILTER_LINEAR
	sampler_linear_nr_state.mag_filter = RenderingDevice.SAMPLER_FILTER_LINEAR
	sampler_linear_nr_state.repeat_u = RenderingDevice.SAMPLER_REPEAT_MODE_CLAMP_TO_EDGE
	sampler_linear_nr_state.repeat_v = RenderingDevice.SAMPLER_REPEAT_MODE_CLAMP_TO_EDGE
	sampler_linear_nr_state.repeat_w = RenderingDevice.SAMPLER_REPEAT_MODE_CLAMP_TO_EDGE
	_sampler_linear_nr = _rd.sampler_create(sampler_linear_nr_state)
	
	var sampler_linear_mir_state := RDSamplerState.new()
	sampler_linear_mir_state.min_filter = RenderingDevice.SAMPLER_FILTER_LINEAR
	sampler_linear_mir_state.mag_filter = RenderingDevice.SAMPLER_FILTER_LINEAR
	sampler_linear_mir_state.repeat_u = RenderingDevice.SAMPLER_REPEAT_MODE_MIRRORED_REPEAT
	sampler_linear_mir_state.repeat_v = RenderingDevice.SAMPLER_REPEAT_MODE_MIRRORED_REPEAT
	sampler_linear_mir_state.repeat_w = RenderingDevice.SAMPLER_REPEAT_MODE_MIRRORED_REPEAT
	_sampler_linear_mir = _rd.sampler_create(sampler_linear_mir_state)
	
	var sampler_nearest_state := RDSamplerState.new()
	sampler_nearest_state.min_filter = RenderingDevice.SAMPLER_FILTER_NEAREST
	sampler_nearest_state.mag_filter = RenderingDevice.SAMPLER_FILTER_NEAREST
	sampler_nearest_state.repeat_u = RenderingDevice.SAMPLER_REPEAT_MODE_REPEAT
	sampler_nearest_state.repeat_v = RenderingDevice.SAMPLER_REPEAT_MODE_REPEAT
	sampler_nearest_state.repeat_w = RenderingDevice.SAMPLER_REPEAT_MODE_REPEAT
	_sampler_nearest = RenderingServer.get_rendering_device().sampler_create(sampler_nearest_state)
	
	var sampler_nearest_nr_state := RDSamplerState.new()
	sampler_nearest_nr_state.min_filter = RenderingDevice.SAMPLER_FILTER_NEAREST
	sampler_nearest_nr_state.mag_filter = RenderingDevice.SAMPLER_FILTER_NEAREST
	sampler_nearest_nr_state.repeat_u = RenderingDevice.SAMPLER_REPEAT_MODE_CLAMP_TO_EDGE
	sampler_nearest_nr_state.repeat_v = RenderingDevice.SAMPLER_REPEAT_MODE_CLAMP_TO_EDGE
	sampler_nearest_nr_state.repeat_w = RenderingDevice.SAMPLER_REPEAT_MODE_CLAMP_TO_EDGE
	_sampler_nearest_nr = RenderingServer.get_rendering_device().sampler_create(sampler_nearest_nr_state)
	
	_scaled_size = (Vector2(size) / _scaled_down).ceil()
	var size_area := size.x * size.y
	var scaled_size_area := _scaled_size.x * _scaled_size.y
	
	var clouds_data := PackedByteArray()
	clouds_data.resize(size_area * 4 * 2)  # RGBA channels, 2 bytes
	var clouds_format := RDTextureFormat.new()
	clouds_format.format = RenderingDevice.DATA_FORMAT_R16G16B16A16_SFLOAT
	clouds_format.width = size.x
	clouds_format.height = size.y
	clouds_format.usage_bits = RenderingDevice.TEXTURE_USAGE_STORAGE_BIT | \
							  RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT
	
	var scaled_clouds_data := PackedByteArray()
	scaled_clouds_data.resize(scaled_size_area * 4 * 2)  # RGBA channels, 2 bytes
	var scaled_clouds_format := RDTextureFormat.new()
	scaled_clouds_format.format = RenderingDevice.DATA_FORMAT_R16G16B16A16_SFLOAT
	scaled_clouds_format.width = _scaled_size.x
	scaled_clouds_format.height = _scaled_size.y
	scaled_clouds_format.usage_bits = RenderingDevice.TEXTURE_USAGE_STORAGE_BIT | \
							  RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT
	
	var depth_data := PackedByteArray()
	depth_data.resize(size_area * 2)  # Single channel, 2 bytes
	var depth_format := RDTextureFormat.new()
	depth_format.format = RenderingDevice.DATA_FORMAT_R16_SFLOAT
	depth_format.width = size.x
	depth_format.height = size.y
	depth_format.usage_bits = RenderingDevice.TEXTURE_USAGE_STORAGE_BIT | \
							  RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT
	
	var scaled_depth_data := PackedByteArray()
	scaled_depth_data.resize(scaled_size_area * 2)  # Single channel, 2 bytes
	var scaled_depth_format := RDTextureFormat.new()
	scaled_depth_format.format = RenderingDevice.DATA_FORMAT_R16_SFLOAT
	scaled_depth_format.width = _scaled_size.x
	scaled_depth_format.height = _scaled_size.y
	scaled_depth_format.usage_bits = RenderingDevice.TEXTURE_USAGE_STORAGE_BIT | \
							  RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT
	
	_clouds_high = _rd.texture_create(clouds_format, RDTextureView.new(), [clouds_data])
	_clouds_low = _rd.texture_create(scaled_clouds_format, RDTextureView.new(), [scaled_clouds_data])
	_depth_high = _rd.texture_create(depth_format, RDTextureView.new(), [depth_data])
	_depth_low = _rd.texture_create(scaled_depth_format, RDTextureView.new(), [scaled_depth_data])
	
	_longterm_uniforms_good = true
	print("Ready")


func _render_callback(_p_effect_callback_type: int, p_render_data: RenderData) -> void:
	if Engine.is_editor_hint():
		_mutex.lock()
		if _reload_shaders:
			_reload_shaders = false
			_load_and_init()
			_mutex.unlock()
			return
		_mutex.unlock()
	if not (_rd and _pipeline_pass_1.is_valid() and _pipeline_pass_2.is_valid() and _pipeline_pass_3.is_valid() and _pipeline_pass_4.is_valid()):
		return
	
	var scene_ubo := p_render_data.get_render_scene_data().get_uniform_buffer()
	var render_scene_buffers: RenderSceneBuffersRD = p_render_data.get_render_scene_buffers()
	if not render_scene_buffers: return
	
	var size := render_scene_buffers.get_internal_size()
	if size.x == 0 and size.y == 0: return
	
	#region uniforms
	_mutex.lock()
	if not _longterm_uniforms_good or _last_size.x != size.x or _last_size.y != size.y:
		if not _longterm_uniforms_good:
			print("Allocate triggered by stale uniforms")
		if not _last_size.x != size.x or _last_size.y != size.y:
			print("Allocate triggered by resolution change (last %s): %s" % [_last_size, size])
		_alloc_longterm_data(size)
	_mutex.unlock()
	_last_size = size
	_update_config_data()
	
	var dsize_full := Vector3i(ceili(size.x / 8.0), ceili(size.y / 8.0), 1)
	var dsize_scaled := Vector3i(ceili(_scaled_size.x / 8.0), ceili(_scaled_size.y / 8.0), 1)
	
	var push_constant := PackedByteArray()
	push_constant.resize(16)  # 4 x 4 bytes
	push_constant.encode_float(0, _scaled_size.x)
	push_constant.encode_float(4, _scaled_size.y)
	push_constant.encode_float(8, _scaled_down)
	push_constant.encode_float(12, 0.0)
	
	var scene_ubo_uniform := RDUniform.new()
	scene_ubo_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_UNIFORM_BUFFER
	scene_ubo_uniform.binding = 3
	scene_ubo_uniform.add_id(scene_ubo)
	
	var config_uniform := RDUniform.new()
	config_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_UNIFORM_BUFFER
	config_uniform.binding = 4
	config_uniform.add_id(_config_data_rid)
	
	var depth_low_uniform: RDUniform = RDUniform.new()
	depth_low_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	depth_low_uniform.binding = 5
	depth_low_uniform.add_id(_depth_low)
	
	var clouds_low_uniform: RDUniform = RDUniform.new()
	clouds_low_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	clouds_low_uniform.binding = 6
	clouds_low_uniform.add_id(_clouds_low)
	
	var depth_high_uniform: RDUniform = RDUniform.new()
	depth_high_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	depth_high_uniform.binding = 7
	depth_high_uniform.add_id(_depth_high)
	
	var clouds_high_uniform: RDUniform = RDUniform.new()
	clouds_high_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	clouds_high_uniform.binding = 8
	clouds_high_uniform.add_id(_clouds_high)
	
	var height_uniform := RDUniform.new()
	height_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
	height_uniform.binding = 10
	height_uniform.add_id(_sampler_linear_nr)
	height_uniform.add_id(RenderingServer.texture_get_rd_texture(profile.ns_height.get_rid()))
	
	var noise_mask_uniform := RDUniform.new()
	noise_mask_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
	noise_mask_uniform.binding = 11
	noise_mask_uniform.add_id(_sampler_linear)
	noise_mask_uniform.add_id(RenderingServer.texture_get_rd_texture(profile.ns_mask.get_rid()))
	
	var noise_l_uniform := RDUniform.new()
	noise_l_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
	noise_l_uniform.binding = 12
	noise_l_uniform.add_id(_sampler_linear)
	noise_l_uniform.add_id(RenderingServer.texture_get_rd_texture(profile.ns_large.get_rid()))
	
	var noise_m_uniform := RDUniform.new()
	noise_m_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
	noise_m_uniform.binding = 13
	noise_m_uniform.add_id(_sampler_linear)
	noise_m_uniform.add_id(RenderingServer.texture_get_rd_texture(profile.ns_medium.get_rid()))
	
	var noise_s_uniform := RDUniform.new()
	noise_s_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
	noise_s_uniform.binding = 14
	noise_s_uniform.add_id(_sampler_linear)
	noise_s_uniform.add_id(RenderingServer.texture_get_rd_texture(profile.ns_small.get_rid()))
	
	var noise_wisp_uniform := RDUniform.new()
	noise_wisp_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
	noise_wisp_uniform.binding = 15
	noise_wisp_uniform.add_id(_sampler_linear)
	noise_wisp_uniform.add_id(RenderingServer.texture_get_rd_texture(profile.ns_wisp.get_rid()))
	#endregion
	
	var view_count := render_scene_buffers.get_view_count()
	for view in range(view_count):
		var color_image := render_scene_buffers.get_color_layer(view)
		var depth_image := render_scene_buffers.get_depth_layer(view)
		
		#region on-demand uniforms
		var depth_image_uniform: RDUniform = RDUniform.new()
		depth_image_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
		depth_image_uniform.binding = 1
		depth_image_uniform.add_id(_sampler_nearest_nr)
		depth_image_uniform.add_id(depth_image)
		
		var color_image_uniform: RDUniform = RDUniform.new()
		color_image_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
		color_image_uniform.binding = 2
		color_image_uniform.add_id(color_image)
		#endregion
		
		#region assign uniforms to shaders
		var uniform_set_pass_1 := UniformSetCacheRD.get_cache(
			_shader_scale_down, 0, [
				depth_image_uniform, depth_low_uniform, scene_ubo_uniform
			])
		
		var uniform_set_pass_2 := UniformSetCacheRD.get_cache(
			_shader_clouds, 0, [
				depth_low_uniform, clouds_low_uniform,
				scene_ubo_uniform, config_uniform,
				height_uniform, noise_mask_uniform,
				noise_l_uniform, noise_m_uniform, noise_s_uniform,
				noise_wisp_uniform
			])
		
		var uniform_set_pass_3 := UniformSetCacheRD.get_cache(
			_shader_scale_up, 0, [
				depth_low_uniform, depth_high_uniform,
				clouds_low_uniform, clouds_high_uniform, scene_ubo_uniform
			])
		
		var uniform_set_pass_4 := UniformSetCacheRD.get_cache(
			_shader_atmo, 0, [
				depth_image_uniform, color_image_uniform,
				depth_high_uniform, clouds_high_uniform,
				scene_ubo_uniform, config_uniform
			])
		#endregion
		
		var compute_list := _rd.compute_list_begin()
		_rd.compute_list_bind_compute_pipeline(compute_list, _pipeline_pass_1)
		_rd.compute_list_bind_uniform_set(compute_list, uniform_set_pass_1, 0)
		_rd.compute_list_set_push_constant(compute_list, push_constant, push_constant.size())
		_rd.compute_list_dispatch(compute_list, dsize_scaled.x, dsize_scaled.y, dsize_scaled.z)
		
		_rd.compute_list_add_barrier(compute_list)
		_rd.compute_list_bind_compute_pipeline(compute_list, _pipeline_pass_2)
		_rd.compute_list_bind_uniform_set(compute_list, uniform_set_pass_2, 0)
		_rd.compute_list_set_push_constant(compute_list, push_constant, push_constant.size())
		_rd.compute_list_dispatch(compute_list, dsize_scaled.x, dsize_scaled.y, dsize_scaled.z)
		
		_rd.compute_list_add_barrier(compute_list)
		_rd.compute_list_bind_compute_pipeline(compute_list, _pipeline_pass_3)
		_rd.compute_list_bind_uniform_set(compute_list, uniform_set_pass_3, 0)
		_rd.compute_list_set_push_constant(compute_list, push_constant, push_constant.size())
		_rd.compute_list_dispatch(compute_list, dsize_full.x, dsize_full.y, dsize_full.z)
		
		_rd.compute_list_add_barrier(compute_list)
		_rd.compute_list_bind_compute_pipeline(compute_list, _pipeline_pass_4)
		_rd.compute_list_bind_uniform_set(compute_list, uniform_set_pass_4, 0)
		_rd.compute_list_dispatch(compute_list, dsize_full.x, dsize_full.y, dsize_full.z)
		_rd.compute_list_end()
		
		if Engine.is_editor_hint():
			_mutex.lock()
			if _req_write_debug:
				print("Try save...")
				_req_write_debug = false
				_debug_save_rd_texture.call_deferred(_clouds_high, size, "color")
				_debug_save_rd_texture.call_deferred(_depth_high, size, "depth", Image.FORMAT_RH)
			_mutex.unlock()


func _debug_save_rd_texture(tex_rid: RID, size: Vector2i, fname := "clouds_lp_debug", format: Image.Format = Image.FORMAT_RGBAH) -> void:
	if not _rd:
		push_error("No Render Device")
		return
	if not tex_rid.is_valid():
		push_error("Invalid RID for image")
		return
	var image_data := _rd.texture_get_data(tex_rid, 0)
	if not image_data:
		push_error("No image data for %s" % tex_rid)
		return
	var test_image := Image.create_from_data(size.x, size.y, false, format, image_data)
	if not test_image:
		push_error("No image found :(")
		return
	var filename := "user://%s.png" % fname
	test_image.save_png(filename)
	print("Saved to '%s'" % filename)


func _update_config_data() -> void:
	var idx := 0
	var linear_color: Color
	_config_data.encode_float(idx, light_position.x); idx += 4
	_config_data.encode_float(idx, light_position.y); idx += 4
	_config_data.encode_float(idx, light_position.z); idx += 4
	_config_data.encode_float(idx, max_distance); idx += 4
	
	_config_data.encode_float(idx, position.x); idx += 4
	_config_data.encode_float(idx, position.y); idx += 4
	_config_data.encode_float(idx, position.z); idx += 4
	_config_data.encode_float(idx, profile.planet_radius); idx += 4
	
	_config_data.encode_float(idx, profile.atmo_height); idx += 4
	_config_data.encode_float(idx, profile.cld_beers_factor); idx += 4
	_config_data.encode_float(idx, profile.cld_powder_factor); idx += 4
	_config_data.encode_float(idx, profile.cld_light_pen); idx += 4
	
	_config_data.encode_float(idx, profile.ns_adj_threshold.x); idx += 4
	_config_data.encode_float(idx, profile.ns_adj_threshold.y); idx += 4
	_config_data.encode_float(idx, profile.cld_density_factor); idx += 4
	_config_data.encode_float(idx, profile.ns_adj_layer_falloff); idx += 4
	
	_config_data.encode_float(idx, profile.ns_adj_scale.x); idx += 4
	_config_data.encode_float(idx, profile.ns_adj_scale.y); idx += 4
	_config_data.encode_float(idx, profile.ns_adj_scale.z); idx += 4
	_config_data.encode_float(idx, profile.ns_adj_global_scale); idx += 4
	
	linear_color = profile.cld_color.srgb_to_linear()
	_config_data.encode_float(idx, linear_color.r); idx += 4
	_config_data.encode_float(idx, linear_color.g); idx += 4
	_config_data.encode_float(idx, linear_color.b); idx += 4
	_config_data.encode_s32(idx, cloud_quality.steps); idx += 4
	
	_config_data.encode_float(idx, cloud_quality.step_scalar); idx += 4
	_config_data.encode_float(idx, cloud_quality.min_step_size); idx += 4
	_config_data.encode_float(idx, cloud_quality.deband_noise); idx += 4
	_config_data.encode_float(idx, cloud_quality.deband_noise_scalar); idx += 4
	
	_config_data.encode_float(idx, profile.ns_adj_offset.x); idx += 4
	_config_data.encode_float(idx, profile.ns_adj_offset.y); idx += 4
	_config_data.encode_float(idx, profile.ns_adj_offset.z); idx += 4
	_config_data.encode_float(idx, profile.ns_adj_wisp_factor); idx += 4
	
	_config_data.encode_float(idx, profile.ns_adj_mask_offset.x); idx += 4
	_config_data.encode_float(idx, profile.ns_adj_mask_offset.y); idx += 4
	_config_data.encode_float(idx, profile.cld_light_scatter); idx += 4
	_config_data.encode_float(idx, profile.ns_adj_scale.w); idx += 4
	
	linear_color = profile.atmo_color_direct.srgb_to_linear()
	linear_color = Color.WHITE - linear_color  # Convert to Rayleigh
	_config_data.encode_float(idx, linear_color.r); idx += 4
	_config_data.encode_float(idx, linear_color.g); idx += 4
	_config_data.encode_float(idx, linear_color.b); idx += 4
	_config_data.encode_float(idx, profile.atmo_light_pen); idx += 4
	
	linear_color = profile.atmo_color_tangent.srgb_to_linear()
	linear_color = Color.WHITE - linear_color  # Convert to Mie
	_config_data.encode_float(idx, linear_color.r); idx += 4
	_config_data.encode_float(idx, linear_color.g); idx += 4
	_config_data.encode_float(idx, linear_color.b); idx += 4
	_config_data.encode_float(idx, profile.atmo_star_glow); idx += 4
	
	linear_color = light_color.srgb_to_linear()
	_config_data.encode_float(idx, linear_color.r); idx += 4
	_config_data.encode_float(idx, linear_color.g); idx += 4
	_config_data.encode_float(idx, linear_color.b); idx += 4
	_config_data.encode_float(idx, profile.atmo_density_falloff); idx += 4
	
	_config_data.encode_float(idx, 0.0); idx += 4
	_config_data.encode_float(idx, 0.0); idx += 4
	_config_data.encode_float(idx, 0.0); idx += 4
	_config_data.encode_float(idx, profile.atmo_refract_bend); idx += 4
	
	_config_data.encode_float(idx, float(atmo_enabled and profile.planet_has_atmosphere)); idx += 4
	_config_data.encode_float(idx, float(cloud_enabled and profile.planet_has_clouds)); idx += 4
	_config_data.encode_float(idx, float(cloud_atmo_light_enabled)); idx += 4
	_config_data.encode_float(idx, 0.0); idx += 4
	
	if _config_data_rid.is_valid():
		_rd.buffer_update(_config_data_rid, 0, _config_data.size(), _config_data)
	else:
		_config_data_rid = _rd.uniform_buffer_create(_config_data.size(), _config_data)
