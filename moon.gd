extends DirectionalLight3D

@export var rotation_speed: float
@export var day_length_min: float = 2.0
@export var sec_in_day: float

func _ready() -> void:
	sec_in_day = day_length_min * 60.0
	rotation_speed = TAU / sec_in_day

func _process(delta: float) -> void:
	rotate_x(-rotation_speed * delta)

	if rotation_degrees.x >= 0.0 and rotation_degrees.x < 180.0:
		show()
	else:
		hide()
