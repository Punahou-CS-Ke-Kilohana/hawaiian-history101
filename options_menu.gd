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
