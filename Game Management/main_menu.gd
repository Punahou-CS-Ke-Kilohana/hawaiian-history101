extends Control
@onready var options = $"../OptionsMenu"
@onready var pausemenu = $"../../CenterContainer/PauseMenu"

@export var dialogue_resource: DialogueResource
@export var dialogue_start: String = "start"
@export var balloon_scene: PackedScene

@export_file("*.tscn") var game_scene_path: String = "res://node_3d.tscn"

func _ready() -> void:
	get_tree().paused = true
	
func _on_options_pressed() -> void:
	hide()
	options.show()

func _on_quit_pressed() -> void:
	get_tree().quit()
	
func _on_start_pressed() -> void:
	print("1. START BUTTON PRESSED")

	get_tree().paused = false
	GlobalSettings.main_menu = false

	SceneLoader.loading_screen.visible = true
	SceneLoader.loading_screen.set_loading_text("Preparing your journey...")
	SceneLoader.loading_screen.set_progress(0.0)

	await get_tree().process_frame

	print("2. CALLING GAME MANAGER")

	get_node("/root/GameManager").change_to_story()
	
	DialogueManager.show_dialogue_balloon_scene(
		balloon_scene,
		dialogue_resource,
		dialogue_start
	)
	
