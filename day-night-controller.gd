extends Node3D

@export var sun: DirectionalLight3D
@export var moon: DirectionalLight3D

@export var day_length_min: float = 2.0

var rotation_speed: float


func _ready() -> void:
	rotation_speed = TAU / (day_length_min * 60.0)


func _process(delta: float) -> void:
	# Rotate the sun
	sun.rotate_x(rotation_speed * delta)

	# Keep the moon exactly opposite the sun
	moon.rotation = sun.rotation
	moon.rotate_x(PI)

	# Get the direction each light is pointing
	var sun_direction := -sun.global_transform.basis.z
	var moon_direction := -moon.global_transform.basis.z

	# Sun is active only when above the horizon
	#sun.visible = sun_direction.y > 0.0

	# Moon is active only when above the horizon
	#moon.visible = moon_direction.y > 0.0
