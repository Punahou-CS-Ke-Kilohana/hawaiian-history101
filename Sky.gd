extends DirectionalLight3D

@export var rotation_speed: float
@export var day_length_min: float = 24.0
@export var sec_in_day: float

func _ready() -> void:
	sec_in_day = day_length_min * 60.0
	rotation_speed = TAU / sec_in_day

func _process(delta: float) -> void:
	rotate_x(rotation_speed * delta)
#
	var light_direction := -global_transform.basis.z

	if light_direction.y < 0.0 && light_direction.y > -180:
		light_energy = 1.0
	else:
		light_energy = 0.0
