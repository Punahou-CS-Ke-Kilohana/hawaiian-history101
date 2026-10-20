extends CharacterBody3D

func _physics_process(delta: float) -> void:
	# Apply gravity so the NPC stays on the ground
	if not is_on_floor():
		velocity += get_gravity() * delta

		velocity.z = 0
		velocity.y = 0

		move_and_slide()
