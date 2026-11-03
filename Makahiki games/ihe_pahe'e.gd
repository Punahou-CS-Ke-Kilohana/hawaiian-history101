extends Item
class_name pahehe

@export_group("slide")
@export var  spear_slide_speed_multiplier: int = 3

func slide(direction: Vector3, force: float) -> void:
	prepare_to_throw()

	direction.y = 0.0
	direction = direction.normalized()

	freeze = false
	sleeping = false

	lock_rotation = true

	linear_velocity = direction * force * spear_slide_speed_multiplier
	angular_velocity = Vector3.ZERO
	
func on_picked_up() -> void:
	var player = get_tree().get_first_node_in_group("Player")

	if player:
		remove_collision_exception_with(player)

	freeze = true
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO


func _on_pickuparea_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		body.add_nearby_item(self)


func _on_pickuparea_body_exited(body: Node3D) -> void:
	if body.is_in_group("Player"):
		body.remove_nearby_item(self)


func _on_body_entered(body: Node3D) -> void:
	if body == self or body.is_in_group("Player"):
		return
