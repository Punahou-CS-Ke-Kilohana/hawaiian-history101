extends Control

@onready var score_label : Label = $ColorRect/score

var this_is_visible = false
var current_points = 0


func _ready():
	update_score()
	update_visibility()

func show_score():
	show()
	this_is_visible = true
	score_label.show()
	score_label.get_parent().show()
	update_visibility()
	update_score()


func hide_score():
	this_is_visible = false
	update_visibility()
	print("Score hidden")


func add_points(amount: int):
	current_points += amount
	update_score()


func update_score():
	score_label.text = "Points: " + str(current_points)
	score_label.visible = true
	score_label.modulate = Color.RED
	score_label.z_index = 100

	print("Text: ", score_label.text)
	print("Label size: ", score_label.size)
	print("Label position: ", score_label.global_position)
	print("Label visible: ", score_label.is_visible_in_tree())
	score_label.text = "Points: " + str(current_points)
	print(score_label.text)
	print("Current points: ", current_points)


func update_visibility():
	visible = this_is_visible
