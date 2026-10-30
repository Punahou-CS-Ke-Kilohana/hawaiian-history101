extends Item
class_name pahehe

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
