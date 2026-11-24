extends CanvasLayer

@onready var progress_bar: ProgressBar = $Control/ProgressBar
@onready var loading_text: Label = $Control/LoadingText
@onready var tip_label: Label = $Control/Tiplabel
@onready var progress_label: Label = $Control/ProgressLabel

func _ready():
	print("LOADING SCREEN READY")
	print("Progress Bar: ", progress_bar)
	print("Loading Text: ", loading_text)
	print("Tip Label: ", tip_label)

	visible = false


func set_progress(value: float):
	var percentage = int(value * 100.0)
	progress_bar.value = percentage
	progress_label.text = str(percentage) + "%"



func set_loading_text(message: String):
	if loading_text == null:
		push_error("LoadingText node not found!")
		return

	loading_text.text = message
