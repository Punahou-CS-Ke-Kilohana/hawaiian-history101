extends WorldEnvironment

@export var cloud_speed: float = 0.01
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if environment:
		environment.sky_rotation.y += cloud_speed * delta
	pass
