extends Item

@export var throw_force: float = 20.0
@export var damage: int = 10

var has_been_thrown := false
var has_hit := false


func throw(direction: Vector3):
	has_been_thrown = true
	has_hit = false
	freeze = false
	
	linear_velocity = direction.normalized() * throw_force


func _physics_process(_delta):
	if not has_been_thrown or has_hit:
		return
	
	# Rotate the spear to face the direction it is moving
	if linear_velocity.length() > 0.1:
		look_at(global_position + linear_velocity, Vector3.UP)


func _on_body_entered(body):
	if not has_been_thrown or has_hit:
		return
	
	has_hit = true
	
	# Deal damage if the object can take damage
	if body.has_method("take_damage"):
		body.take_damage(damage)
	
	# Stop the spear
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	freeze = true


func _on_pickuparea_body_entered(body: Node3D) -> void:
	print("Pickup area detected: ", body.name)
	
	if body.is_in_group("Player"):
		print("Player is near the spear!")
		body.add_nearby_item(self)


func _on_pickuparea_body_exited(body: Node3D) -> void:
	if body.is_in_group("Player"):
		print("Player left the spear!")
		body.remove_nearby_item(self)
