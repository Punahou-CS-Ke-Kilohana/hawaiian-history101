extends Node3D

var points = 0

var gamescore_scene = preload("res://UI/gamescore.tscn")
var gamescore

func _ready():
	gamescore = gamescore_scene.instantiate()
	get_tree().current_scene.add_child(gamescore)

	print("Created GameScore: ", gamescore.get_instance_id())

	gamescore.hide_score()

func _on_middle_body_entered(body: Node3D) -> void:
	if body.is_in_group("scoring_objects"):
		points += 1
		gamescore.add_points(1)

		print("Total points: ", points)
