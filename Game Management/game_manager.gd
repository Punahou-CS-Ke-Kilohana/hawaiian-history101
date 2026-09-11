extends Node
class_name GameManager

enum GameMode {
	HOME,
	STORY,
	MULTIPLAYER
}

@export_category("Scenes")
@export var home_scene: PackedScene
@export var story_scene: PackedScene
@export var multiplayer_scene: PackedScene

@onready var mode_container: Node = self

var current_mode: GameMode = GameMode.HOME
var current_scene: Node = null


func _ready() -> void:
	# Start at the home screen.
	change_to_story()


# ============================================================
# Mode Transitions
# ============================================================

func change_to_home() -> void:
	change_mode(GameMode.HOME)


func change_to_story() -> void:
	change_mode(GameMode.STORY)


func change_to_multiplayer() -> void:
	change_mode(GameMode.MULTIPLAYER)


func change_mode(new_mode: GameMode) -> void:
	if current_mode == new_mode and current_scene != null:
		return

	var scene_to_load: PackedScene = _get_scene_for_mode(new_mode)

	if scene_to_load == null:
		push_error("No scene assigned for game mode: %s" % GameMode.keys()[new_mode])
		return

	_unload_current_scene()

	current_mode = new_mode
	current_scene = scene_to_load.instantiate()

	mode_container.add_child(current_scene)


# ============================================================
# Scene Management
# ============================================================

func _unload_current_scene() -> void:
	if current_scene == null:
		return

	current_scene.queue_free()
	current_scene = null

	await get_tree().process_frame


func _get_scene_for_mode(mode: GameMode) -> PackedScene:
	match mode:
		GameMode.HOME:
			return home_scene

		GameMode.STORY:
			return story_scene

		GameMode.MULTIPLAYER:
			return multiplayer_scene

		_:
			return null


# ============================================================
# Utility
# ============================================================

func get_current_mode() -> GameMode:
	return current_mode


func get_current_scene() -> Node:
	return current_scene


func is_home() -> bool:
	return current_mode == GameMode.HOME


func is_story() -> bool:
	return current_mode == GameMode.STORY


func is_multiplayer() -> bool:
	return current_mode == GameMode.MULTIPLAYER
