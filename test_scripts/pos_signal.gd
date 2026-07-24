@tool
extends Node3D

signal position_changed()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		position_changed.emit()
