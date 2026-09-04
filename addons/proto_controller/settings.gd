extends Control

@onready var settings =$TextureButton/settings
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func when_texture_button_pressed() -> void:
	get_tree().paused = true 
	settings.visible = true 
	
func resume_pressed() -> void:
	get_tree().paused = false 
	settings.visible = false 
