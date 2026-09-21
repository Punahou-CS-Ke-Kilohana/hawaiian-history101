extends Control
@onready var options = $"../OptionsMenu"
@onready var pausemenu = $"../../CenterContainer/PauseMenu"

@export_file("*.tscn") var game_scene_path: String = "res://node_3d.tscn"

func _ready() -> void:
	get_tree().paused = true
	
func _on_options_pressed() -> void:
	hide()
	options.show()

func _on_quit_pressed() -> void:
	get_tree().quit()
	
func _on_start_pressed() -> void:
	get_tree().paused = false
	hide()
	GlobalSettings.main_menu = false 
