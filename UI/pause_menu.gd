extends Control
@onready var options = $"../../CanvasLayer/OptionsMenu"
@onready var pausemenu = $"."
func pause():
	get_tree().paused = true
	show()

func resume():
	get_tree().paused = false
	hide()

func testEsc():
	if Input.is_action_just_pressed("esc") and get_tree().paused == false and GlobalSettings.main_menu == false:
		pause()
	elif Input.is_action_just_pressed("esc") and get_tree().paused == true and GlobalSettings.main_menu == false:
		resume()
		
func _on_resume_pressed() -> void:
	resume()

func _on_options_pressed() -> void:
	hide()
	options.show()
	pass

func _on_quit_pressed() -> void:
	get_tree().quit()
	
func _process(delta):
	testEsc()
