extends Control
@onready var options = $"../../OptionsMenu"

func pause():
	GlobalSettings.show_ui_buttons = false
	get_tree().paused = true
	show()

func resume():
	GlobalSettings.show_ui_buttons = true
	get_tree().paused = false
	hide()
	options.hide()

func testEsc():
	if Input.is_action_just_pressed("esc") and GlobalSettings.main_menu == false and GlobalSettings.can_pause == true:
		if get_tree().paused == false:
			pause()
		else:
			resume()
		
func _on_resume_pressed() -> void:
	resume()

func _on_options_pressed() -> void:
	hide()
	options.show()

func _on_quit_pressed() -> void:
	get_tree().quit()
	
func _process(delta):
	testEsc()
