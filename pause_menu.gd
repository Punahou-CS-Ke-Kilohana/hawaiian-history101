extends Control

func pause():
	get_tree().paused = true
	show()

func resume():
	get_tree().paused = false
	hide()

func testEsc():
	if Input.is_action_just_pressed("esc") and get_tree().paused == false:
		pause()
	elif Input.is_action_just_pressed("esc") and get_tree().paused:
		resume()
		
func _on_resume_pressed() -> void:
	resume()

func _on_options_pressed() -> void:
	pass

func _on_quit_pressed() -> void:
	get_tree().quit()
	
func _process(delta):
	testEsc()
