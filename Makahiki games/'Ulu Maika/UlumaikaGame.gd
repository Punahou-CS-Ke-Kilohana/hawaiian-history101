extends Node3D

var points = 0

var gamescore_scene = preload("res://UI/gamescore.tscn")
var gamescore
func _ready() -> void:
	gamescore = gamescore_scene.instantiate()
	get_tree().root.add_child(gamescore)
	gamescore.update_score(points)


func _process(delta: float) -> void:
	pass


func _on_middle_body_entered(body: Node3D) -> void:
	if body.is_in_group("scoring_objects"):
		points += 1

		gamescore.update_score(points)

		print("Points: ", points)

		if points >= 12:
			print("YOU WIN!")
