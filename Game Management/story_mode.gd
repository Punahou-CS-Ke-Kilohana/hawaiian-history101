extends Node
class_name StoryMode

@onready var level_manager: LevelManager = $LevelManager
@onready var level_transition = $LevelTransition


func _ready() -> void:
	level_manager.level_completed.connect(_on_level_completed)

	# Load the first level.
	level_manager.start_level(0)

	# Wait for the level to enter the scene tree.
	await get_tree().process_frame
	await get_tree().process_frame

	# Activate the first level's gameplay camera.
	_activate_gameplay_camera()


func _activate_gameplay_camera() -> void:
	if level_manager.get_child_count() == 0:
		push_error("StoryMode: No level loaded at startup.")
		return

	var level := level_manager.get_child(0)
	var player := level.get_node_or_null(
	    "ProtoController"
	) as CharacterBody3D

	if player == null:
		push_error("StoryMode: ProtoController not found.")
		return

	var camera := player.get_node_or_null(
	    "Head/Main Camera"
	) as Camera3D

	if camera == null:
		push_error("StoryMode: Main Camera not found.")
		return

	camera.visible = true
	camera.make_current()


func _on_level_completed() -> void:
	if level_manager.has_next_level():
		var next_index: int = level_manager.current_level + 1
		await _transition_to_next_level(next_index)
	else:
		finish_story()


func _transition_to_next_level(level_index: int) -> void:
	# Keep the current level loaded while the camera pulls away.
	var current_player := _get_current_player()

	if current_player == null:
		push_error("StoryMode: Current player not found.")
		return

	var current_position: Vector3 = current_player.global_position

	# The transition script calls back to change levels
	# once the camera reaches the overhead map view.
	await level_transition.transition_to_level(
		current_position,
		"LEVEL " + str(level_index + 1),
		func():
			level_manager.start_level(level_index)
	)


func _get_current_player() -> CharacterBody3D:
	if level_manager.get_child_count() == 0:
		return null

	return level_manager.get_child(0).get_node_or_null(
        "ProtoController"
	) as CharacterBody3D


func finish_story() -> void:
	print("Story complete!")
