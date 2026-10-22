extends Node

## Godot 4.4+
## Attach to a Node named LevelTransition.

signal transition_started
signal map_revealed(level_name: String)
signal transition_finished

# --------------------------------------------------
# NODE REFERENCES
# --------------------------------------------------

var player_path: NodePath = ^"../Player"
var camera_path: NodePath = ^"../Player/Head/Camera3D"
var title_path: NodePath = ^"TransitionUI/LevelTitle"
var marker_path: NodePath = ^"TransitionUI/DestinationMarker"

# --------------------------------------------------
# MAP CAMERA SETTINGS
# --------------------------------------------------

@export_group("Map Camera")

## Height of the camera above the world.
@export var map_camera_height: float = 100.0

## World X and Z position of the map camera.
## Vector2.x = world X; Vector2.y = world Z.
@export var map_camera_xy: Vector2 = Vector2.ZERO

## World point the camera looks toward in map mode.
@export var map_focus_height: float = 0.0

## Field of view while viewing the island.
@export_range(20.0, 100.0, 1.0)
var map_camera_fov: float = 65.0

# --------------------------------------------------
# ANIMATION SETTINGS
# --------------------------------------------------

@export_group("Transition Timing")

@export_range(0.1, 10.0, 0.1)
var pull_away_duration: float = 1.5

@export_range(0.1, 10.0, 0.1)
var rise_duration: float = 2.5

@export_range(0.0, 30.0, 0.1)
var map_hold_duration: float = 2.5

@export_range(0.1, 10.0, 0.1)
var travel_duration: float = 2.0

@export_range(0.1, 10.0, 0.1)
var descent_duration: float = 2.5

## How far the camera moves away from the player initially.
@export var pull_away_offset: Vector3 = Vector3(0.0, 2.0, 7.0)

## Extra height above the destination before descending.
@export var descent_height: float = 18.0

## Camera field of view during normal first-person gameplay.
@export_range(30.0, 110.0, 1.0)
var gameplay_camera_fov: float = 75.0

# --------------------------------------------------
# UI SETTINGS
# --------------------------------------------------

@export_group("Transition UI")

@export var title_prefix: String = ""
@export var title_suffix: String = ""
@export var marker_screen_offset: Vector2 = Vector2.ZERO


@export_group("Loading Overlay")

## Image displayed over the entire screen during level loading.
@export var loading_image: Texture2D

## Optional background color if no image is assigned.
@export var loading_background: Color = Color.BLACK

var loading_layer: CanvasLayer
var loading_rect: TextureRect

# --------------------------------------------------
# INTERNAL STATE
# --------------------------------------------------

var player: CharacterBody3D
var camera: Camera3D
var level_title: Label
var destination_marker: Control

var transition_camera: Camera3D
var busy: bool = false

var saved_camera_parent: Node
var saved_camera_transform: Transform3D
var saved_camera_fov: float

var saved_camera_player_transform: Transform3D

var saved_player_process: bool
var saved_player_physics_process: bool
var saved_player_position: Vector3

var destination: Vector3
var current_tween: Tween


func _ready() -> void:
	
	level_title = get_node_or_null(title_path) as Label
	destination_marker = get_node_or_null(marker_path) as Control

	if level_title != null:
		level_title.visible = false

	if destination_marker != null:
		destination_marker.visible = false

	transition_camera = Camera3D.new()
	transition_camera.name = "TransitionCamera"
	# Never use the transition camera during normal gameplay.
	transition_camera.current = false
	transition_camera.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(transition_camera)

	# Ensure it cannot take over the viewport during startup.
	transition_camera.clear_current()
	
	_create_loading_overlay()


# ==================================================
# PUBLIC FUNCTION
# ==================================================

## Call with:
## await $LevelTransition.transition_to_level(
##     Vector3(120, 5, -80),
##     "LEVEL 2"
## )
##
## new_player_location is the destination player's WORLD position.
## level_name is the text displayed over the map.
##
## The function returns after the transition is complete.
func transition_to_level(
	new_player_location: Vector3,
	level_name: String,
	change_level: Callable = Callable()
) -> void:
	# StoryMode
	# |_LevelManager
	# |__Level_#
	# |___ProtoController
	# |____Head
	# |_____Main Camera
	# |_LevelTransition (This)

	
	player = _get_current_player()
	camera = _get_player_camera(player)
	
	
	
	if busy:
		push_warning("LevelTransition: A transition is already running.")
		return

	if player == null or camera == null:
		push_error("LevelTransition: Missing player or camera.")
		return

	busy = true
	destination = new_player_location

	transition_started.emit()

	_save_game_state()
	_disable_player()

	# Transfer camera control to our independent transition camera.
	var original_global_transform := camera.global_transform
	camera.current = false

	transition_camera.global_transform = original_global_transform
	transition_camera.fov = saved_camera_fov
	transition_camera.current = true

	# Hide the original camera while the transition is running.
	camera.visible = false

	# ----------------------------------------------
	# PHASE 1: PULL AWAY FROM THE PLAYER
	# ----------------------------------------------

	var away_position := (
		original_global_transform.origin
		+ player.global_basis * pull_away_offset
	)

	await _animate_camera(
		away_position,
		original_global_transform.basis,
		pull_away_duration
	)

	# ----------------------------------------------
	# PHASE 2: RISE ABOVE THE ISLAND
	# ----------------------------------------------

	var map_position := Vector3(
		map_camera_xy.x,
		map_camera_height,
		map_camera_xy.y
	)

	var map_focus := Vector3(
		map_camera_xy.x,
		map_focus_height,
		map_camera_xy.y
	)

	var map_basis := _look_at_basis(map_position, map_focus)

	await _animate_camera(
		map_position,
		map_basis,
		rise_duration,
		map_camera_fov
	)
	
	

	# ----------------------------------------------
	# PHASE 3: SHOW MAP, TITLE AND DESTINATION
	# ----------------------------------------------
	# Camera has reached the overhead map view.

	if level_title != null:
		level_title.visible = false

	# Cover the screen before changing the level.
	loading_layer.visible = true

	# Ensure the overlay gets rendered before loading begins.
	await RenderingServer.frame_post_draw

	# Change levels underneath the overlay.
	if change_level.is_valid():
		change_level.call()

	# Wait for the new level to enter the scene tree.
	await get_tree().process_frame
	await RenderingServer.frame_post_draw

	# Reacquire the new player and camera here.
	
	# Keep the loading overlay visible while preparing the descent.
	if level_title != null:
		level_title.text = title_prefix + level_name + title_suffix
		level_title.visible = true

	if destination_marker != null:
		destination_marker.visible = true
		_update_destination_marker()

	map_revealed.emit(level_name)

	# Hold the overhead view before changing levels.
	await get_tree().create_timer(map_hold_duration/2).timeout

	# Change the actual level while the camera remains overhead.
	if change_level.is_valid():
		change_level.call()

	# Allow the new level to enter the scene tree.
	await get_tree().process_frame

	# Find the player belonging to the new level.
	var manager := get_parent().get_node_or_null("LevelManager")

	if manager == null or manager.get_child_count() == 0:
		push_error("LevelTransition: New level was not loaded.")
		busy = false
		return

	player = manager.get_child(0).get_node_or_null(
	    "ProtoController"
	) as CharacterBody3D

	if player == null:
		push_error("LevelTransition: New player not found.")
		busy = false
		return

	camera = player.get_node_or_null(
	    "Head/Main Camera"
	) as Camera3D

	if camera == null:
		push_error("LevelTransition: New gameplay camera not found.")
		busy = false
		return

	# Use the new player's actual spawn position.
	destination = player.global_position

	# Save the new player's camera state for restoration.
	saved_camera_transform = camera.transform
	saved_camera_fov = camera.fov
	saved_camera_player_transform = (
		player.global_transform.affine_inverse()
		* camera.global_transform
	)

	# Keep the new player locked during the remaining cinematic.
	player.set_process(false)
	player.set_physics_process(false)
	camera.current = false
	camera.visible = false
	
	loading_layer.visible = false
	
	await get_tree().create_timer(map_hold_duration/2).timeout
	loading_layer.visible = false

	# ----------------------------------------------
	# PHASE 4: MOVE TOWARD THE NEW LOCATION
	# ----------------------------------------------

	if level_title != null:
		level_title.visible = false

	# Move the player while their controls remain locked.
	# The transition camera remains independent of the player.
	player.global_position = destination

	var above_destination := Vector3(
		destination.x,
		destination.y + descent_height,
		destination.z
	)

	var descent_basis := _look_at_basis(
		above_destination,
		destination
	)

	await _animate_camera(
		above_destination,
		descent_basis,
		travel_duration
	)
	
	player = get_parent().get_node("LevelManager").get_child(0).get_node("ProtoController")
	camera = player.get_node("Head/Main Camera")

	# ----------------------------------------------
	# PHASE 5: DESCEND INTO FIRST-PERSON VIEW
	# ----------------------------------------------

	# Aim toward the destination as the camera descends.
	# The final view will be restored to the player's
	# own Camera3D transform.
	var target_player_camera_transform := (
		player.global_transform
		* saved_camera_player_transform
	)

	var final_camera_transform := Transform3D(
		target_player_camera_transform.basis,
		target_player_camera_transform.origin
	)

	await _animate_camera(
		final_camera_transform.origin,
		final_camera_transform.basis,
		descent_duration,
		gameplay_camera_fov
	)
	
	camera.make_current()
	transition_camera.clear_current()

	player.global_position = destination
	_restore_player()

	# Reveal the new level.
	loading_layer.visible = false

	busy = false
	transition_finished.emit()

	# ----------------------------------------------
	# PHASE 6: RESTORE GAMEPLAY
	# ----------------------------------------------
	
	player = get_parent().get_node("LevelManager").get_child(0).get_node("ProtoController")
	camera = player.get_node("Head/Main Camera")

	if destination_marker != null:
		destination_marker.visible = false

	camera.transform = saved_camera_transform
	camera.fov = saved_camera_fov
	camera.visible = true

	# Make the gameplay camera active before clearing
	# the transition camera.
	camera.make_current()
	transition_camera.clear_current()

	player.global_position = destination
	_restore_player()

	busy = false
	transition_finished.emit()



func _get_current_player() -> CharacterBody3D:
	var manager := get_parent().get_node_or_null(
	    "LevelManager"
	)

	if manager == null or manager.get_child_count() == 0:
		push_error("LevelTransition: No active level found.")
		return null

	var level := manager.get_child(0)

	return level.get_node_or_null(
        "ProtoController"
	) as CharacterBody3D


func _get_player_camera(
	target_player: CharacterBody3D
) -> Camera3D:
	if target_player == null:
		return null

	return target_player.get_node_or_null(
        "Head/Main Camera"
	) as Camera3D


func _create_loading_overlay() -> void:
	loading_layer = CanvasLayer.new()
	loading_layer.name = "LoadingOverlay"
	loading_layer.layer = 100
	loading_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(loading_layer)

	if loading_image != null:
		loading_rect = TextureRect.new()
		loading_rect.name = "LoadingImage"
		loading_rect.texture = loading_image
		loading_rect.stretch_mode = TextureRect.STRETCH_SCALE
		loading_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		loading_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		loading_rect.set_anchors_and_offsets_preset(
			Control.PRESET_FULL_RECT
		)
		loading_layer.add_child(loading_rect)
	else:
		var background := ColorRect.new()
		background.name = "LoadingBackground"
		background.color = loading_background
		background.mouse_filter = Control.MOUSE_FILTER_IGNORE
		background.set_anchors_and_offsets_preset(
			Control.PRESET_FULL_RECT
		)
		loading_layer.add_child(background)

	loading_layer.visible = false
	
	
# ==================================================
# CAMERA ANIMATION HELPERS
# ==================================================

func _animate_camera(
	target_position: Vector3,
	target_basis: Basis,
	duration: float,
	target_fov: float = -1.0
) -> void:
	if current_tween != null and current_tween.is_running():
		current_tween.kill()

	var tween := create_tween()
	current_tween = tween

	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(
		transition_camera,
		"global_position",
		target_position,
		duration
	)

	tween.tween_property(
		transition_camera,
		"global_basis",
		target_basis,
		duration
	)

	if target_fov > 0.0:
		tween.tween_property(
			transition_camera,
			"fov",
			target_fov,
			duration
		)

	await tween.finished


func _look_at_basis(
	from_position: Vector3,
	target_position: Vector3
) -> Basis:
	var direction := target_position - from_position

	if direction.length_squared() < 0.0001:
		return Basis.IDENTITY

	return Basis.looking_at(direction.normalized(), Vector3.UP)


# ==================================================
# MAP MARKER
# ==================================================

func _update_destination_marker() -> void:
	if destination_marker == null:
		return

	if transition_camera == null:
		return

	# Converts the world destination into screen coordinates.
	var screen_position := (
		transition_camera.unproject_position(destination)
	)

	destination_marker.position = (
		screen_position
		- destination_marker.size * 0.5
		+ marker_screen_offset
	)


# ==================================================
# PLAYER CONTROL
# ==================================================

func _save_game_state() -> void:
	saved_camera_parent = camera.get_parent()
	saved_camera_transform = camera.transform
	saved_camera_fov = camera.fov

	# Preserve the camera's complete position relative to
	# the player, including the Head node's offset/rotation.
	saved_camera_player_transform = (
		player.global_transform.affine_inverse()
		* camera.global_transform
	)

	saved_player_process = player.is_processing()
	saved_player_physics_process = player.is_physics_processing()
	saved_player_position = player.global_position


func _disable_player() -> void:
	player.set_process(false)
	player.set_physics_process(false)

	# Prevent a locked first-person player from retaining
	# a captured mouse during the cinematic.
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _restore_player() -> void:
	# Explicitly restore player movement.
	player.set_process(true)
	player.set_physics_process(true)

	# Clear any leftover movement from the previous level.
	player.velocity = Vector3.ZERO
	
	player.dialogue_lock = false
	player.can_move = true
	player.can_jump = true

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
