extends DirectionalLight3D

@export var rotation_speed: float
@export var day_length_min: float = 20.0 ## change to how long a day is 
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	## convert into sec
	var sec = day_length_min * 60
	
	## speed of day, TAU is godots built in constant for 2 * PI
	rotation_speed= TAU / sec 
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	rotate_x(rotation_speed * delta)
	pass
