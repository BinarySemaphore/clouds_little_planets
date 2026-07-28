extends Camera3D

@export var auto_align: Node3D
@export var local_turning := false
@export var move_speed := 5.0
@export var turn_speed := 1.5
## Only applies with [code]auto_align[/code].[br]
## Values less than [color=white]zero[/color] disable minimum.
@export var min_altitude := -1.0


func _process(delta: float) -> void:
	var actual_move_speed := move_speed
	var glb_move := Vector3.ZERO
	var rel_move := Vector3.ZERO
	var rel_rotate := Vector3.ZERO
	
	if Input.is_physical_key_pressed(KEY_W): rel_move.z = -1
	if Input.is_physical_key_pressed(KEY_S): rel_move.z = 1
	if Input.is_physical_key_pressed(KEY_A): rel_move.x = -1
	if Input.is_physical_key_pressed(KEY_D): rel_move.x = 1
	if local_turning:
		if Input.is_physical_key_pressed(KEY_Q): rel_move.y = 1
		if Input.is_physical_key_pressed(KEY_Z): rel_move.y = -1
	else:
		if Input.is_physical_key_pressed(KEY_Q): glb_move.y = 1
		if Input.is_physical_key_pressed(KEY_Z): glb_move.y = -1
	
	if Input.is_physical_key_pressed(KEY_UP): rel_rotate.x = 1
	if Input.is_physical_key_pressed(KEY_DOWN): rel_rotate.x = -1
	if Input.is_physical_key_pressed(KEY_LEFT): rel_rotate.y = 1
	if Input.is_physical_key_pressed(KEY_RIGHT): rel_rotate.y = -1
	
	if Input.is_physical_key_pressed(KEY_SHIFT): actual_move_speed *= 5
	if Input.is_physical_key_pressed(KEY_CTRL): actual_move_speed *= 0.25
	
	glb_move = (glb_move + (quaternion * rel_move)).normalized()
	rel_rotate = rel_rotate.normalized()
	
	position += glb_move * actual_move_speed * delta
	if auto_align:
		# Enforce local_turning
		if not local_turning:
			local_turning = true
		
		var rel_pos := global_position - auto_align.global_position
		var old_back := basis.z
		var up := rel_pos.normalized()
		if min_altitude >= 0.0:
			if rel_pos.length() < min_altitude:
				position = up * min_altitude
		
		var right := Plane(up).project(basis.x).normalized()
		# Check orthogonal, otherwise use alt axis as fallback
		if right.is_zero_approx() or not is_zero_approx(absf(up.dot(right))):
			right = Plane(up).project(basis.z).normalized()
		var back := right.cross(up).normalized()
		basis = Basis(right, up, back)
		quaternion = Quaternion(back, old_back) * quaternion
	if local_turning:
		var delta_quat := Quaternion(Vector3.UP, rel_rotate.y * turn_speed * delta)
		delta_quat *= Quaternion(Vector3.RIGHT, rel_rotate.x * turn_speed * delta)
		quaternion *= delta_quat
	else:
		rotation += rel_rotate * turn_speed * delta
