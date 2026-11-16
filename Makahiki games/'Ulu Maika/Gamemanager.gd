extends Node3D

var points = 0

func _on_middle_body_entered(body: Node3D) -> void:
	if body.is_in_group("scoring_objects"):
		points += 1

		var player = get_tree().get_first_node_in_group("Player")

		if player != null:
			player.gamescore.add_points(1)

		print("Total points: ", points)
