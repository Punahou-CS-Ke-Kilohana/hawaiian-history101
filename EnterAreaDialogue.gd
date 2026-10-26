
extends Area3D

@export var dialogue_resource: DialogueResource
@export var dialogue_start: String = "start"
@export var balloon_scene: PackedScene

var triggered := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	print("Body detected: ", body.name)
	print("Body groups: ", body.get_groups())
	print("Parent: ", body.get_parent().name if body.get_parent() else "None")
	
	if not body.is_in_group("Player"):
		return
	
	if triggered:
		return


	triggered = true

	# Stop player movement before starting the dialogue.
	if body.get("dialogue_lock") != null:
		body.set("dialogue_lock", true)

	if body is CharacterBody3D:
		body.velocity = Vector3.ZERO

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	DialogueManager.show_dialogue_balloon_scene(
		balloon_scene,
		dialogue_resource,
		dialogue_start
	)
