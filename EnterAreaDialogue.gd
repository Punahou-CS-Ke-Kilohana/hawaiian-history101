extends Area3D

@export var dialogue_resource: DialogueResource
@export var dialogue_start: String = "start"
@export var balloon_scene: PackedScene

var triggered := false

func _on_body_shape_entered(body_rid: RID, body: Node3D, body_shape_index: int, local_shape_index: int) -> void:

	if triggered:
		return

	if body.is_in_group("Player"):
		triggered = true
		
		DialogueManager.show_dialogue_balloon_scene(
			balloon_scene,
			dialogue_resource,
			dialogue_start
		)
