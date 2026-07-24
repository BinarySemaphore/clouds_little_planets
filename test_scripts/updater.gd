@tool
extends Node

@export var env: WorldEnvironment
@export var star: Node3D

var _clouds_lp: CloudsLP


func _ready() -> void:
	_find_clouds_lp_effect()
	_update_light_source()
	if star.has_signal("position_changed"):
		star.position_changed.connect(_update_light_source)


func _find_clouds_lp_effect() -> void:
	_clouds_lp = null
	if env and env.compositor and env.compositor.compositor_effects:
		for effect in env.compositor.compositor_effects:
			if effect is CloudsLP:
				_clouds_lp = effect
				break
	if not _clouds_lp:
		push_error("Unable to find CloudsLP in WorldEnvironment.Compositor.CompositorEffects: %s" % env)


func _update_light_source() -> void:
	if star and _clouds_lp:
		_clouds_lp.light_position = star.global_position
