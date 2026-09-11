extends Node
class_name LevelManager

signal level_changed(level_index: int)
signal level_completed

@export var levels: Array[PackedScene] = []

@onready var level_container: Node = self

var current_level: int = -1
var current_level_instance: Node = null


func start_level(level_index: int) -> void:
	if level_index < 0 or level_index >= levels.size():
		push_error("Invalid level index: %d" % level_index)
		return

	# Remove the previous level.
	if current_level_instance:
		current_level_instance.queue_free()
		current_level_instance = null

	# Wait until the old level has actually been removed.
	await get_tree().process_frame

	# Create the new level.
	current_level_instance = levels[level_index].instantiate()
	level_container.add_child(current_level_instance)

	current_level = level_index

	level_changed.emit(current_level)


func has_next_level() -> bool:
	return current_level + 1 < levels.size()


func get_current_level() -> Node:
	return current_level_instance
