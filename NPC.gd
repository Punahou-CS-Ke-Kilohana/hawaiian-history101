extends CharacterBody3D

func _physics_process(delta: float) -> void:
	# Apply gravity so the NPC stays on the ground
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Prevent horizontal movement
	velocity.x = 0
	velocity.z = 0

	move_and_slide()
