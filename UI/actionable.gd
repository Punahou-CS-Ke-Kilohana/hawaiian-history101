
extends Area3D

@export var dialogue_resource: DialogueResource
@export var cannot_talk: DialogueResource
@export var dialogue_start: String = "start"
@export var balloon_scene: PackedScene

@export var one_time_dialogue: bool = true

@export_group("Quest Settings")
@export var gives_quest: bool = false
@export var quest_number: int = 1
@export var quest_title: String = "Quest 1"
@export_multiline var quest_description: String = "Find the missing sword."

var dialogue_finished := false


func action() -> void:
	if gives_quest and quest_number != QuestManager.current_quest_number:
		DialogueManager.show_dialogue_balloon_scene(
		balloon_scene,
		cannot_talk,
		dialogue_start
	)
		return

	if one_time_dialogue and dialogue_finished:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		return

	if one_time_dialogue:
		DialogueManager.dialogue_ended.connect(
			_on_dialogue_ended, CONNECT_ONE_SHOT
		)

	DialogueManager.show_dialogue_balloon_scene(
		balloon_scene,
		dialogue_resource,
		dialogue_start
	)


func _on_dialogue_ended(_resource: DialogueResource) -> void:
	if gives_quest:
		QuestManager.give_quest(
			quest_number,
			quest_title,
			quest_description
		)

	dialogue_finished = true
