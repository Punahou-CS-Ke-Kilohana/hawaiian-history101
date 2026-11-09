
extends Node3D

@export var target: Node3D
@export var arrow_height: float = 2.0
@export var blink_speed: float = 2.0
@export var arrival_distance: float = 3.0
@export var halfway_arrival_distance: float = 6.0


@export var can_move : bool = true
@export var can_jump : bool = true

@onready var player = get_parent()


@onready var arrow_mesh: MeshInstance3D = $ArrowMesh
@onready var arrival_panel = $CanvasLayer/Control/ArrivalPanel

var notification_shown = false

var has_arrived = false
var blink_timer: float = 0.0
var arrow_material: StandardMaterial3D


func _ready():
	# Get the arrow's existing material
	var existing_material = arrow_mesh.get_active_material(0)

	if existing_material == null:
		arrow_material = StandardMaterial3D.new()
	else:
		arrow_material = existing_material.duplicate()

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
	# blink_timer += delta

	# if blink_timer >= blink_speed:
		# blink_timer = 0.0
		# arrow_mesh.visible = not arrow_mesh.visible

	# Calculate distance to target
	var distance = global_position.distance_to(target.global_position)

	# Change arrow color based on distance
	if distance <= arrival_distance:
		arrow_material.albedo_color = Color.GREEN

	elif distance <= halfway_arrival_distance:
		arrow_material.albedo_color = Color.GREEN_YELLOW

	else:
		arrow_material.albedo_color = Color.YELLOW
	
	if distance <= arrival_distance and not notification_shown:
		show_arrival_notification()
		notification_shown = true
		
func show_arrival_notification():
	
	player.can_move = false
	player.can_jump = false
	
	arrival_panel.visible = true

	arrival_panel.modulate.a = 0.0

	var tween = create_tween()
	tween.tween_property(
		arrival_panel,
		"modulate:a",
		1.0,
		0.4
	)

	await get_tree().create_timer(2.5).timeout

	var fade = create_tween()
	fade.tween_property(
		arrival_panel,
		"modulate:a",
		0.0,
		0.5
	)
	await fade.finished
	arrival_panel.visible = false
	
	player.can_move = true
	player.can_jump = true
	
		
		
		
