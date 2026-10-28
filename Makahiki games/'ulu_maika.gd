extends Item
class_name ulumaika
# set held rotation to be 89.8 for best roll  (idk why)
@export var roll_force: float = 40.0
@export var spin_speed: float = 25.0

var has_been_rolled: bool = false


func roll(direction: Vector3, force: float) -> void:
	prepare_to_throw()

	direction.y = 0.0
	direction = direction.normalized()

	linear_velocity = direction * force

	# Horizontal axis perpendicular to travel.
	var roll_axis := Vector3.UP.cross(direction).normalized()
	angular_velocity = roll_axis * disk_spin_speed


func on_picked_up() -> void:
	has_been_rolled = false
	freeze = true
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO

func _on_pickuparea_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
						body.add_nearby_item(self)


func _on_pickuparea_body_exited(body: Node3D) -> void:
	if body.is_in_group("Player"):
		body.remove_nearby_item(self)
