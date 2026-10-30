extends Node3D

@export var target: Node3D
@export var arrow_height: float = 2.0

func _process(_delta):
	if target == null:
		return

	# Keep arrow directly above player
	global_position = get_parent().global_position + Vector3(0, arrow_height, 0)

	# Point toward target
	var direction = target.global_position - global_position
	direction.y = 0

	if direction.length_squared() > 0.001:
		var angle = atan2(-direction.x, -direction.z)
		global_rotation = Vector3(0, angle, 0)
