extends Item
class_name ulumaika

@export var roll_force: float = 90.0
@export var spin_speed: float = 25.0

var has_been_rolled: bool = false


func roll(direction: Vector3, force: float) -> void:
	prepare_to_throw()

	var player = get_tree().get_first_node_in_group("Player")

	if player:
		add_collision_exception_with(player)

	direction.y = 0.0
	direction = direction.normalized()
	linear_velocity = direction * force

	var roll_axis := Vector3.UP.cross(direction).normalized()
	angular_velocity = roll_axis * spin_speed


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


func _on_body_entered(body: Node3D) -> void:
	if body == self:
		return

	if body.is_in_group("Player"):
		return
