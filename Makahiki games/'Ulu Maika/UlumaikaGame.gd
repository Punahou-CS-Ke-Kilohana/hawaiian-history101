extends Node3D

var points = 0

func _ready() -> void:
	pass


func _process(delta: float) -> void:
	pass


func _on_middle_body_entered(body: Node3D) -> void:
	if body.is_in_group("scoring_objects"):
		points += 1
		print("Points: ", points)

		if points >= 12:
			print("YOU WIN!")
			get_tree().change_scene_to_file("res://win_screen.tscn")
