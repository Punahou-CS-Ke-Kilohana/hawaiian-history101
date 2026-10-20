
extends Node3D

@export var player: CharacterBody3D

@onready var camera: Camera3D = $"Head/Main Camera"
@onready var throw_origin: Node3D = $hand

@onready var arc: MeshInstance3D = $arc
@onready var landing_marker: MeshInstance3D = $landing

var arc_mesh := ImmediateMesh.new()
var arc_material := StandardMaterial3D.new()

@export var max_time: float = 3.0
@export var step: float = 0.05
@export var gravity: float = 9.8


func _ready() -> void:
	arc.mesh = arc_mesh

	arc_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	arc_material.albedo_color = Color.RED
	arc.material_override = arc_material

	arc_material.no_depth_test = false
	arc_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	arc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	arc.visible = false
	landing_marker.visible = false

	if player == null:
		push_error("Trajectory: Player reference is not assigned!")
		return

	camera = player.get_node_or_null("Head/Main Camera") as Camera3D
	throw_origin = player.get_node_or_null("hand") as Node3D

	if camera == null:
		push_error("Trajectory: Could not find Main Camera under Player.")

	if throw_origin == null:
		push_error("Trajectory: Could not find hand under Player.")



func _process(_delta: float) -> void:
	if player == null:
		return

	var item = player.get("equipped_item")

	if item == null:
		arc.visible = false
		landing_marker.visible = false
		return

	if not player.get("is_charging_throw"):
		arc.visible = false
		landing_marker.visible = false
		return

	print("Charging detected!")

	if camera == null or throw_origin == null:
		print("ERROR: Camera or throw origin is missing!")
		return

	var charge_time: float = player.get("throw_charge_time")
	var max_charge: float = player.get("max_charge_time")
	var min_force: float = player.get("min_throw_force")
	var max_force: float = player.get("max_throw_force")

	var ratio: float = clampf(charge_time / max_charge, 0.0, 1.0)
	var force: float = lerpf(min_force, max_force, ratio)

	var start: Vector3 = throw_origin.global_position
	start += Vector3.UP * 0.5
	var velocity: Vector3 = -camera.global_transform.basis.z * force

	print("Drawing trajectory at: ", start)

	draw_trajectory(start, velocity, item)



func draw_trajectory(
	start: Vector3,
	velocity: Vector3,
	item: RigidBody3D
) -> void:
	arc_mesh.clear_surfaces()
	arc_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, arc_material)

	var pos: Vector3 = start
	var vel: Vector3 = velocity
	var space := get_world_3d().direct_space_state

	var exclude: Array[RID] = [item.get_rid(), player.get_rid()]
	var query := PhysicsRayQueryParameters3D.new()
	query.exclude = exclude
	query.collision_mask = 0xFFFFFFFF

	var found_hit := false
	var steps: int = maxi(1, int(max_time / step))

	for i in range(steps):
		var next_pos: Vector3 = pos + vel * step
		vel += Vector3.DOWN * gravity * step

		query.from = pos
		query.to = next_pos

		var hit: Dictionary = space.intersect_ray(query)

		arc_mesh.surface_add_vertex(arc.to_local(pos))

		if not hit.is_empty():
			var hit_pos: Vector3 = hit["position"]
			var hit_normal: Vector3 = hit["normal"]

			arc_mesh.surface_add_vertex(arc.to_local(hit_pos))

			landing_marker.global_position = hit_pos + hit_normal * 0.02
			landing_marker.visible = true
			found_hit = true
			break

		pos = next_pos

	arc_mesh.surface_end()
	arc.visible = true

	if not found_hit:
		landing_marker.visible = false


func hide_trajectory() -> void:
	arc.visible = false
	landing_marker.visible = false
