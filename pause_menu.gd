extends Control


func pause():
	get_tree().paused = true
	show()
	##pause_menu_buttons.show()

func resume():
	get_tree().paused = false
	hide()

func testEsc():
	if Input.is_action_just_pressed("esc") and get_tree().pasued == false:
		pause()
	elif Input.is_action_just_pressed("esc") and get_tree().paused:
		resume()
		

func _on_resume_pressed() -> void:
	resume()


func _on_options_pressed() -> void:
	##pause_menu_buttons.hide()
	pass


func _on_quit_pressed() -> void:
	get_tree().quit()
