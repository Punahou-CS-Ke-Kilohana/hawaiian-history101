
extends Node

const LOADING_SCREEN = preload("res://Loading_Screen.tscn")

var loading_screen: CanvasLayer
var is_loading = false


func _ready():
	print("SCENELOADER IS RUNNING")

	loading_screen = LOADING_SCREEN.instantiate()

	get_tree().root.add_child.call_deferred(loading_screen)

	await get_tree().process_frame

	print("IS IN TREE: ", loading_screen.is_inside_tree())
	print("IS READY: ", loading_screen.is_node_ready())
	print("LOADING TEXT: ", loading_screen.get_node_or_null("Control/LoadingText"))

	loading_screen.layer = 100
	loading_screen.visible = false


func change_scene(path: String):
	if is_loading:
		return

	is_loading = true
	loading_screen.visible = true
	loading_screen.set_loading_text("Loading your journey...")
	loading_screen.set_progress(0.0)

	# Give the loading screen a frame to appear
	await get_tree().process_frame

	var error = ResourceLoader.load_threaded_request(path)

	if error != OK:
		push_error("Could not start loading: " + path)
		loading_screen.visible = false
		is_loading = false
		return

	var progress = []

	while true:
		var status = ResourceLoader.load_threaded_get_status(path, progress)

		if progress.size() > 0:
			loading_screen.set_progress(progress[0])

		if status == ResourceLoader.THREAD_LOAD_LOADED:
			break

		elif status == ResourceLoader.THREAD_LOAD_FAILED:
			push_error("Scene failed to load: " + path)
			loading_screen.visible = false
			is_loading = false
			return

		elif status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			push_error("Invalid scene path: " + path)
			loading_screen.visible = false
			is_loading = false
			return

		await get_tree().process_frame

	var packed_scene = ResourceLoader.load_threaded_get(path)

	if packed_scene is PackedScene:
		get_tree().change_scene_to_packed(packed_scene)

		await get_tree().process_frame

		loading_screen.visible = false
		is_loading = false
