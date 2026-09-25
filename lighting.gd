extends DirectionalLight3D

@export var rotation_speed: float
@export var day_length_min: float = 20.0 ## change to how long a day is 
#@export var max_day_energy: float = 1.2
#@export var min_night_energy: float = 0.05
#
#@export var world_env: WorldEnvironment
#
@export var sec_in_day: float
#
#var time_passed: float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	## convert into sec
	sec_in_day = day_length_min * 60
	
	#if not world_env:
		#push_error("World env not assigned")
	
	## speed of day, TAU is godots built in constant for 2 * PI
	rotation_speed = TAU / sec_in_day
	# this is how fast its traveling per second


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#time_passed += delta 
	#var cycle_progress = (sin(time_passed / sec_in_day * TAU) + 1.0) / 2.0
	#
	#var current_energy = lerp(min_night_energy, max_day_energy, cycle_progress)
	#
	#light_energy = current_energy
	#
	#if world_env and world_env.environment:
		#world_env.environment.background_energy_multiplier = current_energy
	rotate_x(rotation_speed * delta)
