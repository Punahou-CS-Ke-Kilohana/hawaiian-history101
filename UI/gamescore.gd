extends Control

@onready var score_label = $ColorRect/score

func update_score(points: int) -> void:
	score_label.text = "Points: " + str(points)
