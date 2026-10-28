
class_name Item
extends RigidBody3D

@export var held_scale: Vector3 = Vector3.ONE
@export var held_position: Vector3 = Vector3.ZERO
@export var held_rotation: Vector3 = Vector3.ZERO

var original_collision_layer: int
var original_collision_mask: int

func _ready() -> void:
	original_collision_layer = collision_layer
	original_collision_mask = collision_mask

func pickup(player: Node3D) -> void:
	if not player.has_method("equip_item"):
		return

	player.remove_nearby_item(self)

	if self.has_method("on_picked_up"):
		self.call("on_picked_up")

	player.equip_item(self)

func equip_to(hand: Node3D) -> void:
	freeze = true
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO

	collision_layer = 0
	collision_mask = 0

	reparent(hand, false)

	position = held_position
	rotation = held_rotation
	scale = held_scale

	visible = true

func prepare_to_throw() -> void:
	reparent(get_tree().current_scene, true)

	collision_layer = original_collision_layer
	collision_mask = original_collision_mask

	freeze = false
	

@export_category("Ground Movement")
@export_enum("Disk", "Spear") var ground_behavior: int = 0

@export var disk_spin_speed: float = 30.0
@export var spear_slide_speed_multiplier: float = 1.0


func roll(direction: Vector3, force: float) -> void:
	reparent(get_tree().current_scene, true)

	freeze = false
	sleeping = false

	# Keep the movement parallel to the ground.
	direction.y = 0.0
	direction = direction.normalized()

	linear_velocity = direction * force

	if ground_behavior == 0:
		# Disk: spin around its horizontal rolling axis.
		var roll_axis := Vector3.UP.cross(direction).normalized()
		angular_velocity = roll_axis * disk_spin_speed
	else:
		# Spear: slide forward without deliberately spinning.
		linear_velocity = direction * force * spear_slide_speed_multiplier
		angular_velocity = Vector3.ZERO
