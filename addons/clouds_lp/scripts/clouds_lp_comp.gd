@tool
class_name CloudsLP
extends CompositorEffect

## Print debug messages to log/output.[br]
## [br][color=white]Note:[/color] Errors are still logged while debug is
## disabled.
@export var debug_output := false
## [code]In-Editor[/code] Cloud rendering resolution down scaling ratio.[br]
## Does not impact atmoshpere.[br]
## [br][color=yellow]Warning:[/color] Major performance impact closer to
## [code]Native[/code].[br]
## [br][color=white]Note:[/color] Recommend lower resolutions for editor to
## reduce resouce load while working, compositor can be toggled on/off with
## [member CloudsLP.enabled] (near bottom).[br] 
## [br][color=white]Note:[/color] For in-game resolution, see
## [member CloudsLP.scale_down_power].
## For more performance control, see [member CloudsLP.cloud_quality] profile.
@export_enum("Native", "Half", "Quarter", "Eighth", "Sixteenth", "Thirtysecond") var scale_down_power_editor: int = 3:
	set(value):
		scale_down_power_editor = value
		if Engine.is_editor_hint():
			_mutex.lock()
			_scaled_down = 1 << scale_down_power_editor
			_longterm_uniforms_good = false
			_mutex.unlock()
## [code]In-Game[/code] Cloud rendering resolution down scaling ratio.[br]
## Does not impact atmoshpere.[br]
## [br][color=yellow]Warning:[/color] Major performance impact closer to
## [code]Native[/code].[br]
## [br][color=white]Note:[/color] For more performance control, see
## [member CloudsLP.cloud_quality] profile.[br]
## [br][color=white]Note:[/color] Changing this will reallocate buffer data.
@export_enum("Native", "Half", "Quarter", "Eighth", "Sixteenth", "Thirtysecond") var scale_down_power: int = 2:
	set(value):
		scale_down_power = value
		if not Engine.is_editor_hint():
			_mutex.lock()
			_scaled_down = 1 << scale_down_power
			_longterm_uniforms_good = false
			_mutex.unlock()
## Reload shader files once.[br]
## Auto resets back to [code]false[/code] (it's like a button).
@export var reload := false:
	set(value):
		reload = false
		if value:
			_mutex.lock()
			_reload_shaders = true
			_mutex.unlock()
### Write PNGs (see Output) for debugging.
#@export var write_debug := false:
	#set(value):
		#write_debug = false
		#if value:
			#_mutex.lock()
			#_req_write_debug = true
			#_mutex.unlock()
## Render atmosphere.[br]
## Overrides [member CloudsLP.profile].
@export var atmo_enabled := true
## Render clouds.[br]
## Overrides [member CloudsLP.profile].
@export var cloud_enabled := true
## Render cloud atmospheric lighting.[br]
## Overrides [member CloudsLP.profile].
@export var cloud_atmo_light_enabled := true
## Reset cloud animation time back to [code]0[/code].[br]
## Auto resets back to [code]false[/code] (it's like a button).[br]
## [br][color=white]Note:[/color] See [member CloudsLP.profile] > [code]Clouds > Animation[/code] section for
## animation configuration.
@export var cloud_animation_reset := false:
	set(value):
		cloud_animation_reset = false
		if value:
			_cloud_anim_time = 0.0
## Force flat world ([code]Y[/code] axis is altitude).[br]
## [member CloudsLP.position] will be used as sea-level.[br]
## [br][color=white]Note:[/color] Changing this will reload shaders.
@export var flat_world := false:
	set(value):
		flat_world = value
		_mutex.lock()
		_reload_shaders = true
		_mutex.unlock()
## Optional distance limit, useful for simple cloud sampling.[br]
## [br][color=white]Note:[/color] ignored for values <= [code]0.0[/code].
@export var max_distance := 0.0
## Planet position in world-space.[br]
## For [member CloudsLP.flat_world] the [code]Y[/code] component is sea-level.
@export var position := Vector3.ZERO
## [code]Light3D[/code] to drive lighting color and positioning.[br]
## [br][color=white]Note:[/color] For non-directional lights, range and
## attenuation are ignored.[br]
## [br][color=yellow]Warning:[/color] The [code]Light3D[/code] should not be a
## child of the compositor's subtree. Compositor scene awareness is limited,
## so a relative path must be resolved to find the actual node instance. This
## is done during initialization or anytime the [code]Light3D[/code]'s path
## changes.[br]
## [br][color=white]Note:[/color] Assigning a different light source will
## reload shadders.
@export_custom(PROPERTY_HINT_NODE_PATH_VALID_TYPES, "Light3D") var light_source: NodePath:
	set(value):
		light_source = value
		_light_source = null
		_mutex.lock()
		_reload_shaders = true
		_mutex.unlock()
## Cloud Quality Profile.[br]
## [br][color=yellow]Warning:[/color] Performance impacting.[br]
## [br][color=white]Note:[/color] See [member CloudsLP.scale_down_power] for
## more performance control.[br]
## [br][color=white]Note:[/color] Assigning a different quality profile will
## reload shadders.
@export var cloud_quality: CloudQualityProfile:
	set(value):
		cloud_quality = value
		_mutex.lock()
		_reload_shaders = true
		_mutex.unlock()
## Atmosphere and Cloud Profile.[br]
## [br][color=white]Note:[/color] Assigning a different profile will reload
## shadders.
@export var profile: AtmosphereProfile:
	set(value):
		profile = value
		_mutex.lock()
		_reload_shaders = true
		_mutex.unlock()
@export_group("Compute Shaders", "shdr")
## res://addons/clouds_lp/shaders/scale_down_depth.glsl
@export var shdr_downscaler_file: RDShaderFile = preload("uid://casp2y4tv6pc5")
## res://addons/clouds_lp/shaders/cloud_compute.glsl
@export var shdr_clouds_file: RDShaderFile = preload("uid://gkuc4rs1xftu")
## res://addons/clouds_lp/shaders/cloud_compute_flat.glsl
@export var shdr_clouds_flat_file: RDShaderFile = preload("uid://cyu4k4xd4ou3e")
## res://addons/clouds_lp/shaders/scale_up_bilinear_box.glsl[br]
## [color=white]Altenatives:[/color][br]
## res://addons/clouds_lp/shaders/sclae_up_raw.glsl
@export var shdr_upscaler_file: RDShaderFile = preload("uid://bxdhxwue5ip2x")
## res://addons/clouds_lp/shaders/atmo_compute.glsl
@export var shdr_atmo_file: RDShaderFile = preload("uid://k8gfd23cyxdt")
## res://addons/clouds_lp/shaders/atmo_compute_flat.glsl
@export var shdr_atmo_flat_file: RDShaderFile = preload("uid://cb200h5c71etn")

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
var _reload_shaders := true
var _longterm_uniforms_good := false
var _scaled_down := 1
var _ovrd_anim_time := 0.0
var _cloud_anim_time := 0.0
var _mutex := Mutex.new()
var _light_source: Light3D
var _last_size: Vector2i
var _scaled_size: Vector2i
var _config_data: PackedByteArray


## Returns the first [CloudsLP] instance in [param node]'s compositor effects.[br]
## Returns [constant null] if no instance found.[br]
## Asserts [param node] and [param node] has [Compositor] property.
static func get_from_node(node: Node) -> CloudsLP:
	assert(node, "Node cannot be null")
	var comp: Compositor = node.get("compositor")
	assert(comp, "Node %s does not have a Compositor. Node should be like WorldEnvironment or Camera3D" % node)
	
	for effect in comp.compositor_effects:
		if effect is CloudsLP:
			return effect
	
	return null


# Called when this resource is constructed.
func _init() -> void:
	#region initial kicks to tigger set() calls
	if Engine.is_editor_hint():
		scale_down_power_editor = scale_down_power_editor
	else:
		scale_down_power = scale_down_power
	#endregion
	_setup()

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		if is_instance_valid(self):
			_cleanup()


## Overrides all animation times with [param time].[br]
## Ignored if set to [code]0.0[/code] or any disabled animations.[br]
## [br][color=yellow]Warning:[/color] Using this prevents animations from
## honoring pause settings like [member CloudsLP.profile] > [code]Clouds > Animation > Pausable[/code]
## ([member AtmosphereProfile.cld_a_pausable]); pausing will be time will be up to you.
func override_anim_time(time: float) -> void:
	_ovrd_anim_time = time


func _setup() -> void:
	# Defaults
	access_resolved_color = true
	access_resolved_depth = true
	
	_rd = RenderingServer.get_rendering_device()


func _cleanup(shaders := true, data := true) -> void:
	_print_debug("Cleanup (shaders %s | data %s)" % [shaders, data])
	
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
	_print_debug("Load and Init shaders...")
	
	if light_source and not _light_source:
		_find_light_instance()
		if not _light_source:
			_push_error("Could not find light source \"%s\", make sure light source is not in compositor's subtree, reassign light source, and reload" % light_source)
	
	_print_debug("Loading Resources (shaders recompiling)...")
	
	if not profile:
		_push_error("Missing profile (check Profile)")
		return false
	
	if cloud_enabled and profile.planet_has_clouds and not cloud_quality:
		_push_error("Missing cloud quality profile (check Cloud Quality)")
		return false
	
	if not (profile.cld_ns_height and profile.cld_ns_mask and profile.cld_ns_large and profile.cld_ns_medium and profile.cld_ns_small and profile.cld_ns_wisp):
		_push_error("Missing textures (check Profile > Clouds > Noise)")
		return false
	
	if not (shdr_downscaler_file and shdr_clouds_file and shdr_upscaler_file and shdr_atmo_file):
		_push_error("Missing shader files (check Shaders > * Files)")
		return false
	
	var shader_scale_down_spirv := shdr_downscaler_file.get_spirv()
	if not shader_scale_down_spirv: return false
	_shader_scale_down = _rd.shader_create_from_spirv(shader_scale_down_spirv)
	
	var shader_clouds_spirv: RDShaderSPIRV
	if flat_world:
		shader_clouds_spirv = shdr_clouds_flat_file.get_spirv()
	else:
		shader_clouds_spirv = shdr_clouds_file.get_spirv()
	if not shader_clouds_spirv: return false
	_shader_clouds = _rd.shader_create_from_spirv(shader_clouds_spirv)
	
	var shader_scale_up_spirv := shdr_upscaler_file.get_spirv()
	if not shader_scale_up_spirv: return false
	_shader_scale_up = _rd.shader_create_from_spirv(shader_scale_up_spirv)
	
	var shader_atmo_spirv: RDShaderSPIRV
	if flat_world:
		shader_atmo_spirv = shdr_atmo_flat_file.get_spirv()
	else:
		shader_atmo_spirv = shdr_atmo_file.get_spirv()
	if not shader_atmo_spirv: return false
	_shader_atmo = _rd.shader_create_from_spirv(shader_atmo_spirv)
	
	_pipeline_pass_1 = _rd.compute_pipeline_create(_shader_scale_down)
	_pipeline_pass_2 = _rd.compute_pipeline_create(_shader_clouds)
	_pipeline_pass_3 = _rd.compute_pipeline_create(_shader_scale_up)
	_pipeline_pass_4 = _rd.compute_pipeline_create(_shader_atmo)
	
	_print_debug("Ready (Load and Init)")
	return _pipeline_pass_1.is_valid() and \
			_pipeline_pass_2.is_valid() and \
			_pipeline_pass_3.is_valid() and \
			_pipeline_pass_4.is_valid()


func _alloc_longterm_data(size: Vector2i) -> void:
	_cleanup(false, true)  # Cleanup data only
	_print_debug("Allocating longterm data...")
	
	if not _config_data or _config_data.size() != 272:
		_config_data = PackedByteArray()
		_config_data.resize(272)
	
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
	_print_debug("Ready (longterm data)")


func _render_callback(_p_effect_callback_type: int, p_render_data: RenderData) -> void:
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
			_print_debug("Allocate triggered by stale uniforms")
		elif not _last_size.x != size.x or _last_size.y != size.y:
			_print_debug("Allocate triggered by resolution change (last %s): %s" % [_last_size, size])
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
	height_uniform.add_id(RenderingServer.texture_get_rd_texture(profile.cld_ns_height.get_rid()))
	
	var noise_mask_uniform := RDUniform.new()
	noise_mask_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
	noise_mask_uniform.binding = 11
	noise_mask_uniform.add_id(_sampler_linear)
	noise_mask_uniform.add_id(RenderingServer.texture_get_rd_texture(profile.cld_ns_mask.get_rid()))
	
	var noise_l_uniform := RDUniform.new()
	noise_l_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
	noise_l_uniform.binding = 12
	noise_l_uniform.add_id(_sampler_linear)
	noise_l_uniform.add_id(RenderingServer.texture_get_rd_texture(profile.cld_ns_large.get_rid()))
	
	var noise_m_uniform := RDUniform.new()
	noise_m_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
	noise_m_uniform.binding = 13
	noise_m_uniform.add_id(_sampler_linear)
	noise_m_uniform.add_id(RenderingServer.texture_get_rd_texture(profile.cld_ns_medium.get_rid()))
	
	var noise_s_uniform := RDUniform.new()
	noise_s_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
	noise_s_uniform.binding = 14
	noise_s_uniform.add_id(_sampler_linear)
	noise_s_uniform.add_id(RenderingServer.texture_get_rd_texture(profile.cld_ns_small.get_rid()))
	
	var noise_wisp_uniform := RDUniform.new()
	noise_wisp_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
	noise_wisp_uniform.binding = 15
	noise_wisp_uniform.add_id(_sampler_linear)
	noise_wisp_uniform.add_id(RenderingServer.texture_get_rd_texture(profile.cld_ns_wisp.get_rid()))
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
				_print_debug("Try save...")
				_req_write_debug = false
				_debug_save_rd_texture.call_deferred(_clouds_low, _scaled_size, "cloud_low_color", Image.FORMAT_RGBA16)
				_debug_save_rd_texture.call_deferred(_depth_low, _scaled_size, "cloud_low_depth", Image.FORMAT_RH)
				_debug_save_rd_texture.call_deferred(_clouds_high, size, "cloud_high_color")
				_debug_save_rd_texture.call_deferred(_depth_high, size, "cloud_high_depth", Image.FORMAT_RH)
			_mutex.unlock()


func _update_config_data() -> void:
	var idx := 0
	var linear_color: Color
	
	if profile.cld_a_enabled:
		if _ovrd_anim_time != 0.0:
			_cloud_anim_time = _ovrd_anim_time
		elif not profile.cld_a_pausable or not (Engine.get_main_loop() as SceneTree).paused:
			_cloud_anim_time += -1.0 if profile.cld_a_reverse else 1.0
	
	var light_position: Vector3
	if _light_source:
		if _light_source is not DirectionalLight3D:
			light_position = _light_source.global_position
		else:
			light_position = _light_source.quaternion * Vector3.BACK * 1000.0 \
						   * (maxf(profile.planet_radius, 1.0) + profile.atmo_height) \
						   + position
	else:
		var default_dir := Vector3.UP if flat_world else Vector3.RIGHT
		light_position = default_dir * 1000.0 \
					   * (maxf(profile.planet_radius, 1.0) + profile.atmo_height) \
					   + position
	_config_data.encode_float(idx, light_position.x); idx += 4
	_config_data.encode_float(idx, light_position.y); idx += 4
	_config_data.encode_float(idx, light_position.z); idx += 4
	_config_data.encode_float(idx, max_distance); idx += 4
	
	var z_clip_offset := 0.0
	if flat_world:
		z_clip_offset = -0.01
	_config_data.encode_float(idx, position.x); idx += 4
	_config_data.encode_float(idx, position.y); idx += 4
	_config_data.encode_float(idx, position.z); idx += 4
	_config_data.encode_float(idx, profile.planet_radius + z_clip_offset); idx += 4
	
	_config_data.encode_float(idx, profile.atmo_height); idx += 4
	_config_data.encode_float(idx, profile.cld_s_beers_factor); idx += 4
	_config_data.encode_float(idx, profile.cld_s_powder_factor); idx += 4
	_config_data.encode_float(idx, profile.cld_s_light_pen); idx += 4
	
	_config_data.encode_float(idx, profile.cld_nsa_threshold.x); idx += 4
	_config_data.encode_float(idx, profile.cld_nsa_threshold.y); idx += 4
	_config_data.encode_float(idx, profile.cld_s_density_factor); idx += 4
	_config_data.encode_float(idx, profile.cld_nsa_layer_falloff); idx += 4
	
	_config_data.encode_float(idx, profile.cld_nsa_scale.x); idx += 4
	_config_data.encode_float(idx, profile.cld_nsa_scale.y); idx += 4
	_config_data.encode_float(idx, profile.cld_nsa_scale.z); idx += 4
	_config_data.encode_float(idx, profile.cld_nsa_global_scale); idx += 4
	
	linear_color = profile.cld_s_color.srgb_to_linear()
	_config_data.encode_float(idx, linear_color.r); idx += 4
	_config_data.encode_float(idx, linear_color.g); idx += 4
	_config_data.encode_float(idx, linear_color.b); idx += 4
	_config_data.encode_s32(idx, cloud_quality.steps); idx += 4
	
	_config_data.encode_float(idx, cloud_quality.step_scalar); idx += 4
	_config_data.encode_float(idx, cloud_quality.step_size); idx += 4
	_config_data.encode_float(idx, cloud_quality.deband_noise); idx += 4
	_config_data.encode_float(idx, cloud_quality.deband_noise_scalar); idx += 4
	
	_config_data.encode_float(idx, profile.cld_nsa_offset.x); idx += 4
	_config_data.encode_float(idx, profile.cld_nsa_offset.y); idx += 4
	_config_data.encode_float(idx, profile.cld_nsa_offset.z); idx += 4
	_config_data.encode_float(idx, profile.cld_nsa_wisp_factor); idx += 4
	
	_config_data.encode_float(idx, profile.cld_nsa_mask_offset.x); idx += 4
	_config_data.encode_float(idx, profile.cld_nsa_mask_offset.y); idx += 4
	_config_data.encode_float(idx, profile.cld_s_light_scatter); idx += 4
	_config_data.encode_float(idx, profile.cld_nsa_scale.w); idx += 4
	
	_config_data.encode_float(idx, profile.cld_a_position_rate.x); idx += 4
	_config_data.encode_float(idx, profile.cld_a_position_rate.y); idx += 4
	_config_data.encode_float(idx, profile.cld_a_position_rate.z); idx += 4
	_config_data.encode_float(idx, profile.cld_a_detail_rate); idx += 4
	
	_config_data.encode_float(idx, profile.cld_a_mask_rate.x); idx += 4
	_config_data.encode_float(idx, profile.cld_a_mask_rate.y); idx += 4
	_config_data.encode_float(idx, _cloud_anim_time); idx += 4
	_config_data.encode_float(idx, 0.0); idx += 4
	
	linear_color = profile.atmo_s_color_direct.srgb_to_linear()
	linear_color = Color.WHITE - linear_color  # Convert to Rayleigh Absorption
	_config_data.encode_float(idx, linear_color.r); idx += 4
	_config_data.encode_float(idx, linear_color.g); idx += 4
	_config_data.encode_float(idx, linear_color.b); idx += 4
	_config_data.encode_float(idx, profile.atmo_p_light_absorb); idx += 4
	
	linear_color = profile.atmo_s_color_tangent.srgb_to_linear()
	linear_color = Color.WHITE - linear_color  # Convert to Mie Absorption
	_config_data.encode_float(idx, linear_color.r); idx += 4
	_config_data.encode_float(idx, linear_color.g); idx += 4
	_config_data.encode_float(idx, linear_color.b); idx += 4
	_config_data.encode_float(idx, profile.atmo_s_star_glow); idx += 4
	
	var light_color := Color.WHITE
	if _light_source:
		light_color = _light_source.light_color
	linear_color = light_color.srgb_to_linear()
	_config_data.encode_float(idx, linear_color.r); idx += 4
	_config_data.encode_float(idx, linear_color.g); idx += 4
	_config_data.encode_float(idx, linear_color.b); idx += 4
	_config_data.encode_float(idx, profile.atmo_p_density_falloff); idx += 4
	
	_config_data.encode_float(idx, profile.atmo_s_sunset_start); idx += 4
	_config_data.encode_float(idx, profile.atmo_s_sunset_max); idx += 4
	_config_data.encode_float(idx, profile.atmo_p_density); idx += 4
	_config_data.encode_float(idx, profile.atmo_p_overhead_scatter); idx += 4
	
	_config_data.encode_float(idx, 0.0); idx += 4
	_config_data.encode_float(idx, 0.0); idx += 4
	_config_data.encode_float(idx, profile.atmo_s_haze_start); idx += 4
	_config_data.encode_float(idx, profile.atmo_s_haze_max); idx += 4
	
	_config_data.encode_float(idx, float(atmo_enabled and profile.planet_has_atmosphere)); idx += 4
	_config_data.encode_float(idx, float(cloud_enabled and profile.planet_has_clouds)); idx += 4
	_config_data.encode_float(idx, float(cloud_atmo_light_enabled)); idx += 4
	_config_data.encode_float(idx, 0.0); idx += 4
	
	if _config_data_rid.is_valid():
		_rd.buffer_update(_config_data_rid, 0, _config_data.size(), _config_data)
	else:
		_config_data_rid = _rd.uniform_buffer_create(_config_data.size(), _config_data)


func _find_light_instance() -> void:
	if not light_source: return
	
	_print_debug("Attempt to resolve light source from compositor relative path: \"%s\"" % light_source)
	var scene_tree: SceneTree = Engine.get_main_loop()
	if not scene_tree:
		_print_debug("Could not get scene tree from Engine.get_main_loop()")
		return
	_light_source = null
	
	var root_node: Node = null
	if Engine.is_editor_hint():
		root_node = scene_tree.edited_scene_root
	elif scene_tree.root.get_child_count() > 0:
		root_node = scene_tree.root.get_child(0)
	if not root_node:
		_print_debug("Could not get scene root from tree %s" % scene_tree)
	if not root_node.is_node_ready():
		_print_debug("Waiting for root node to be ready %s" % root_node)
		await root_node.ready
	
	# Resolve unknown rel NodePath to absolute
	# Compositor NodePath is unaware of self in scene tree, but can walk back
	var skip: Array[StringName] = [".", ".."]
	var cur_name: StringName
	var cur_name_index := 0
	for i in range(light_source.get_name_count()):
		cur_name = light_source.get_name(i)
		if cur_name not in skip:
			cur_name_index = i
			break
	if not cur_name: return
	
	# Search for parent
	var parents: Array[Node] = root_node.find_children(cur_name)
	if not parents:
		_push_error("Failed to locate Light Source parent by relative path")
		return
	if len(parents) > 1:
		_push_warn("Potential for incorrect Light Source from relative path, suggest giving the Light's parent \"%s\" a unique name" % cur_name)
	
	# Find light from parent using remaining NodePath
	if cur_name_index < light_source.get_name_count() - 1:
		for parent in parents:
			_light_source = parent.get_node_or_null(light_source.slice(cur_name_index + 1))
			if _light_source:
				break  # Correct source found
	else:
		if len(parents) > 1:
			_push_error("Failed to locate unique Light Source by relative path")
			return
		_light_source = parents[0]


func _debug_save_rd_texture(tex_rid: RID, size: Vector2i, fname := "clouds_lp_debug", format: Image.Format = Image.FORMAT_RGBAH) -> void:
	if not _rd:
		_push_error("No Render Device")
		return
	if not tex_rid.is_valid():
		_push_error("Invalid RID for image")
		return
	var image_data := _rd.texture_get_data(tex_rid, 0)
	if not image_data:
		_push_error("No image data for %s" % tex_rid)
		return
	var test_image := Image.create_from_data(size.x, size.y, false, format, image_data)
	if not test_image:
		_push_error("No image found :(")
		return
	var filename := "user://%s.png" % fname
	test_image.save_png(filename)
	_print_debug("Saved to '%s'" % filename)


func _print_debug(msg: String) -> void:
	if not debug_output: return
	print("[CloudsLP] %s" % msg)


func _push_warn(msg: String) -> void:
	push_warning("[CloudsLP] %s" % msg)


func _push_error(msg: String) -> void:
	push_error("[CloudsLP] %s" % msg)
