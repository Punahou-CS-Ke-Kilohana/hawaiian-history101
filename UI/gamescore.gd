extends Control

@onready var score_label = $ColorRect/score

func show_score():
	visible = true
	print("UI SHOWN: ", visible)

func hide_score():
	visible = false
	print("UI HIDDEN: ", visible)

func update_score(points: int):
	score_label.text = "Points: " + str(points)
