extends Control

@onready var pauseMenu = $"../PauseMenu"
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func back() -> void:
	hide()

func testEsc():
	if Input.is_action_just_pressed("esc"):
		back()
		
func _process(delta):
	testEsc()

func _on_volume_2_changed(value):
	AudioServer.set_bus_volume_db(0,value/5)

func _on_screen_mode_item_selected(index):
	match index: 
		0:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		1:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func _on_sensitivity_2_changed() -> void:
	pass # Replace with function body.
