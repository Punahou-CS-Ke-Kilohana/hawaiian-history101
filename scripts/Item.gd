
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
