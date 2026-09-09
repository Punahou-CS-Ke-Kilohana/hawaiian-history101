extends Control

func resume():
	get_tree().paused = false
	
func pause():
	get_tree().paused = true 
	
func testEsc():
	if Input.is.action_just_pressed("ui_canceled") and get_tree().pasued == false:
		paused()
		
