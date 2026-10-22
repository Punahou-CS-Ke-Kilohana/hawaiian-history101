extends Node3D


func finish_level():
	get_parent().get_parent()._on_level_completed()
