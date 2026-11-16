extends Control

@onready var score_label: Label = $ColorRect/score

var current_points = 0

func _ready():
	update_score()
	hide()

func show_score():
	show()

func hide_score():
	hide()

func add_points(amount: int):
	current_points += amount
	update_score()

func update_score():
	score_label.text = "Points: " + str(current_points)
