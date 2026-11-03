extends Node3D

@export var target: Node3D
@export var arrow_height: float = 2.0
@export var blink_speed: float = 2.0
@export var arrival_distance: float = 3.0
@export var halfway_arrival_distance: float = 6.0

@onready var arrow_mesh = $ArrowMesh

var blink_timer: float = 0.0
var arrow_material: StandardMaterial3D

func _ready():
	arrow_material = arrow_mesh.get_active_material(0)

	if arrow_material == null:
		arrow_material = StandardMaterial3D.new()
	else:
		arrow_material = arrow_material.duplicate()

	arrow_mesh.material_override = arrow_material

func _process(delta):
	if target == null:
		return

	# Keep arrow directly above player
	global_position = get_parent().global_position + Vector3(0, arrow_height, 0)

	# Point toward target
	var direction = target.global_position - global_position
	direction.y = 0

	if direction.length_squared() > 0.001:
		var angle = atan2(-direction.x, -direction.z)
		global_rotation = Vector3(0, angle, 0)

	# Blink arrow
	blink_timer += delta

	if blink_timer >= blink_speed:
		blink_timer = 0.0
		arrow_mesh.visible = not arrow_mesh.visible

	# Change color when reaching target
	var distance = global_position.distance_to(target.global_position)

	if distance <= arrival_distance:
		arrow_material.albedo_color = Color.GREEN
		blink_speed = 0.0
	elif distance <= halfway_arrival_distance:
		arrow_material.albedo_color = Color.GREEN_YELLOW
		blink_speed  = 1.0
	else:
		arrow_material.albedo_color = Color.YELLOW
		blink_speed = 2.0
