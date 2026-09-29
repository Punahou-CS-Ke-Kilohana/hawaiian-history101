extends Area3D

@export var dialogue_resource: DialogueResource
@export var dialogue_start: String = "start"
@export var balloon_scene: PackedScene

@export var one_time_dialogue: bool = true

var dialogue_finished := false


func action() -> void:
	# If this character's dialogue is one-time and has already happened, do nothing
	if one_time_dialogue and dialogue_finished:
		return

	# Listen for the dialogue ending
	if one_time_dialogue:
		DialogueManager.dialogue_ended.connect(_on_dialogue_ended, CONNECT_ONE_SHOT)

	# Start dialogue
	DialogueManager.show_dialogue_balloon_scene(
		balloon_scene,
		dialogue_resource,
		dialogue_start
	)


func _on_dialogue_ended(_resource: DialogueResource) -> void:
	dialogue_finished = true
	
