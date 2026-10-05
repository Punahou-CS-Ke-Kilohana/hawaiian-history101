extends Node3D

@onready var sun: DirectionalLight3D = $Sun
@onready var moon: DirectionalLight3D = $moon

@export var day_length_min: float = 24.0

var rotation_speed: float


func _ready() -> void:
	rotation_speed = TAU / (day_length_min * 60.0)

	# Start with the sun directly overhead.
	sun.rotation_degrees.x = 0.0

	# Put the moon opposite the sun.
	moon.rotation = sun.rotation
	moon.rotate_x(PI)


func _process(delta: float) -> void:
	# Rotate the sun.
	sun.rotate_x(rotation_speed * delta)

	# Keep the moon opposite the sun.
	moon.rotation = sun.rotation
	moon.rotate_x(PI)

	# Get the directions.
	var sun_direction := -sun.global_transform.basis.z
	var moon_direction := -moon.global_transform.basis.z

	# Day
	if sun_direction.y < 0.0 && sun_direction.y > -180.0:
		sun.light_energy = 1.0
		moon.light_energy = 0.0

	# Night
	else:
		sun.light_energy = 0.0
		moon.light_energy = 0.55
