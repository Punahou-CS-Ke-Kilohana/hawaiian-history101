extends Control

@onready var pauseMenu = $"../PauseMenu"
@onready var sensitivity_label : Label = $Panel/ScrollContainer/VBoxContainer/HBoxContainer2/Sensitivity3
@onready var sensitivity_slider: HSlider = $Panel/ScrollContainer/VBoxContainer/HBoxContainer2/Sensitivity2
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	sensitivity_slider.value = GlobalSettings.sensitivity
	update_sensitivity_label(GlobalSettings.sensitivity)
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

func update_sensitivity_label(val: float) -> void:
	sensitivity_label.text = str(snapped(val, 0.001) * 1000)


func _on_sensitivity_2_value_changed(value: float) -> void:
	GlobalSettings.sensitivity = value
	update_sensitivity_label(value)
