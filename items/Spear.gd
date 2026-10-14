
extends Item ##middle click to pick up 

@export var throw_force: float = 30.0
@export var damage: int = 10

var has_been_thrown := false
var has_hit := false


func throw(direction: Vector3) -> void:
	has_been_thrown = true
	has_hit = false

	# Detach from the player's hand and restore physics
	prepare_to_throw()

	linear_velocity = direction.normalized() * throw_force


func _physics_process(_delta: float) -> void:
	if not has_been_thrown or has_hit:
		return

	# Rotate the spear to face its direction of movement
	if linear_velocity.length() > 0.1:
		look_at(global_position + linear_velocity, Vector3.UP)


func _on_body_entered(body: Node3D) -> void:
	print("body entered")
	if not has_been_thrown or has_hit:
		return
		
	if body.is_in_group("Player"):
		return
	has_hit = true

	if body.has_method("take_damage"):
		body.take_damage(damage)

	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	freeze = true


func _on_pickuparea_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		body.add_nearby_item(self)


func _on_pickuparea_body_exited(body: Node3D) -> void:
	if body.is_in_group("Player"):
		body.remove_nearby_item(self)
