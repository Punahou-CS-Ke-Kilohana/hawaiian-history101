extends Item ## middle click to pick up

@export var roll_force: float = 30.0
var has_been_rolled := false


func roll(direction: Vector3, force: float) -> void:
	has_been_rolled = true
	# Detach from the player's hand and restore physics.
	prepare_to_roll()
	linear_velocity = direction.normalized() * force
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_pickuparea_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		body.add_nearby_item(self)


func _on_pickuparea_body_exited(body: Node3D) -> void:
	if body.is_in_group("Player"):
		body.remove_nearby_item(self)
