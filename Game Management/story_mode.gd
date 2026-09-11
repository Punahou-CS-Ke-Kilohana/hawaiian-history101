extends Node
class_name StoryMode

@onready var level_manager: LevelManager = $LevelManager
@onready var transition_animation: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	level_manager.level_changed.connect(_on_level_changed)
	level_manager.level_completed.connect(_on_level_completed)

	# Start the story.
	level_manager.start_level(0)


func _on_level_changed(_level_index: int) -> void:
	# This is where transition effects can be added later.
	#
	# For example:
	# transition_animation.play("fade_out")
	# await transition_animation.animation_finished
	#
	# level_manager.change_level(...)
	#
	# transition_animation.play("fade_in")
	pass


func _on_level_completed() -> void:
	change_to_next_level()


func change_to_next_level() -> void:
	if level_manager.has_next_level():
		transition_to_level(level_manager.current_level + 1)
	else:
		finish_story()


func transition_to_level(level_index: int) -> void:
	# Placeholder until the transition animation is configured.
	#
	# Later this can become something like:
	#
	# transition_animation.play("fade_out")
	# await transition_animation.animation_finished
	#
	# level_manager.start_level(level_index)
	#
	# transition_animation.play("fade_in")

	level_manager.start_level(level_index)


func finish_story() -> void:
	print("Story complete!")

	# Eventually this could tell the main GameManager
	# to return to the menu, credits, etc.
