extends Area3D

@export var dialogue_resource: DialogueResource
@export var dialogue_start: String = "start"
@export var balloon_scene: PackedScene

func action() -> void:
	DialogueManager.show_dialogue_balloon_scene(
		balloon_scene,
		dialogue_resource,
		dialogue_start
	)
