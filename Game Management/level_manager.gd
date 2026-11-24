
extends Node
class_name LevelManager

signal level_changed(level_index: int, player_location: Vector3)
signal level_completed

# Store paths instead of PackedScenes.
@export var levels: Array[String] = []

@onready var level_container: Node = self

var current_level: int = -1
var current_level_instance: Node = null


func start_level(level_index: int) -> void:

	print("A. START_LEVEL CALLED")
	print("B. LEVELS ARRAY SIZE: ", levels.size())

	# Check that the requested level exists.
	if level_index < 0 or level_index >= levels.size():
		print("ERROR: INVALID LEVEL INDEX")
		return

	var scene_path: String = levels[level_index]
	print("C. SCENE PATH: ", scene_path)

	var loader = get_node("/root/SceneLoader")

	# Begin threaded loading.
	print("D. STARTING THREADED REQUEST")

	var error = ResourceLoader.load_threaded_request(scene_path)
	print("E. REQUEST RESULT: ", error)

	if error != OK:
		print("ERROR: THREADED REQUEST FAILED")
		return

	# Track loading progress.
	var progress: Array = []
	var last_percentage: int = -1

	while true:

		var status = ResourceLoader.load_threaded_get_status(
			scene_path,
			progress
		)

		if not progress.is_empty():

			var percentage: int = int(progress[0] * 100.0)

			if percentage != last_percentage:

				loader.loading_screen.set_progress(progress[0])

				print("LOADING: ", percentage, "%")

				last_percentage = percentage

		if status == ResourceLoader.THREAD_LOAD_LOADED:
			break

		if status == ResourceLoader.THREAD_LOAD_FAILED:
			print("ERROR: LOADING FAILED")
			return

		if status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			print("ERROR: INVALID RESOURCE")
			return

		await get_tree().process_frame

	print("G. RESOURCE LOADED")

	# Retrieve the completed PackedScene.
	var packed_scene = ResourceLoader.load_threaded_get(scene_path)

	if not packed_scene is PackedScene:
		print("ERROR: NOT A PACKED SCENE")
		return

	# Instantiate and add the level.
	current_level_instance = packed_scene.instantiate()

	level_container.add_child(current_level_instance)

	print("H. LEVEL INSTANTIATED")

	# Find the player.
	var player = current_level_instance.get_node_or_null(
		"ProtoController"
	)

	if player == null:
		print("ERROR: PROTOCONTROLLER NOT FOUND")
		return

	# Find and activate the gameplay camera.
	var camera := player.get_node_or_null(
		"Head/Main Camera"
	) as Camera3D

	if camera == null:
		push_error("LevelManager: Gameplay camera not found.")
		return

	camera.make_current()

	print("CAMERA: ACTIVATED")

	# Update the current level.
	current_level = level_index

	level_changed.emit(
		current_level,
		player.position
	)

	# Find the IslandTerrain generator.
	var terrain: Node = _find_island_terrain(
		current_level_instance
	)

	if terrain != null:

		print("TERRAIN: FOUND GENERATOR")

		# Wait for the initial visible terrain LOD meshes.
		await terrain.call(
			"prepare_initial_lods",
			camera
		)

	else:

		push_warning(
			"LevelManager: IslandTerrain generator not found."
		)

	print("TERRAIN: INITIAL PREPARATION FINISHED")

	# Wait for the completed terrain to be drawn.
	await get_tree().process_frame
	await RenderingServer.frame_post_draw

	print("J. HIDING LOADING SCREEN")

	loader.loading_screen.hide()

	print("LOADING SCREEN HIDDEN")


# =========================================================
# FIND ISLAND TERRAIN
# =========================================================

func _find_island_terrain(root: Node) -> Node:

	# Check the root itself first.
	var root_script = root.get_script()

	if root_script != null:
		if root_script.resource_path.ends_with("IslandTerrain.gd"):
			return root

	# Search through the level's descendants.
	var candidates = root.find_children(
		"*",
		"Node",
		true,
		false
	)

	for candidate in candidates:

		var terrain_script = candidate.get_script()

		if terrain_script != null:

			if terrain_script.resource_path.ends_with(
				"IslandTerrain.gd"
			):
				return candidate

	return null


# =========================================================
# LEVEL MANAGEMENT
# =========================================================

func has_next_level() -> bool:

	return current_level + 1 < levels.size()


func get_current_level() -> Node:

	return current_level_instance
