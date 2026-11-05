
extends Node3D

## Manages terrain chunk loading around the active player.
##
## This script should be a sibling of the terrain generator.
##
## Responsibilities:
## - Detect the active player.
## - Determine the player's current chunk.
## - Load chunks within render distance.
## - Unload chunks outside render distance.
## - Avoid unnecessary updates while the player stays in place.
## - Leave terrain generation and LOD creation to the terrain generator.


# =====================================================================
# REFERENCES
# =====================================================================

@export_category("References")

## Reference to the sibling terrain generator.
@export var terrain_generator: MeshInstance3D


## Optional manually assigned player.
## If empty, the script uses _get_current_player().
@export var player_override: CharacterBody3D


# =====================================================================
# CHUNK SETTINGS
# =====================================================================

@export_category("Chunk Settings")

## Number of chunks around the player that remain loaded.
##
## 1 = immediate neighboring chunks.
## 2 = a larger surrounding area.
## 3 = a considerably larger surrounding area.
@export_range(1, 16, 1)
var render_distance: int = 2


## Additional distance before an already-loaded chunk is unloaded.
##
## This prevents chunks repeatedly loading and unloading
## when the player moves near the render-distance boundary.
@export_range(0, 4, 1)
var unload_buffer: int = 1


## If enabled, chunks are loaded in a circular radius.
##
## If disabled, chunks use a square radius like Minecraft.
@export var circular_loading: bool = false


# =====================================================================
# UPDATE SETTINGS
# =====================================================================

@export_category("Update Settings")

## How frequently the manager checks the player position.
@export_range(0.05, 2.0, 0.05)
var update_interval: float = 0.25


## Automatically begin managing chunks when the scene starts.
@export var manage_on_ready: bool = true


# =====================================================================
# INTERNAL DATA
# =====================================================================

var update_timer: float = 0.0

var active_chunks: Dictionary = {}

var last_player_chunk: Vector2i = Vector2i(-999999, -999999)

var initialized: bool = false


# =====================================================================
# READY
# =====================================================================

func _ready() -> void:

	if manage_on_ready:
		_update_chunks(true)


# =====================================================================
# PROCESS
# =====================================================================

func _process(delta: float) -> void:

	if not is_inside_tree():
		return

	update_timer += delta

	if update_timer < update_interval:
		return

	update_timer = 0.0

	_update_chunks()


# =====================================================================
# PLAYER DETECTION
# =====================================================================

func _get_current_player() -> CharacterBody3D:

	if player_override != null:
		if is_instance_valid(player_override):
			return player_override

	var manager = get_node_or_null(
		"/root/GameManager"
	)

	if manager == null or manager.get_child_count() == 0:
		return null

	var level_manager = manager.get_child(0).get_node_or_null(
		"LevelManager"
	)

	if level_manager == null or level_manager.get_child_count() == 0:
		return null

	var level = level_manager.get_child(0)

	return level.get_node_or_null(
		"ProtoController"
	) as CharacterBody3D


# =====================================================================
# UPDATE CHUNKS
# =====================================================================

func _update_chunks(force_update: bool = false) -> void:

	if terrain_generator == null:
		return

	if not is_instance_valid(terrain_generator):
		return

	var player := _get_current_player()

	if player == null:
		return

	var chunks_per_axis: int = int(
		terrain_generator.get("chunks_per_axis")
	)

	var world_size: float = float(
		terrain_generator.get("world_size")
	)

	if chunks_per_axis <= 0 or world_size <= 0.0:
		return

	# ---------------------------------------------------------------
	# Convert the player's global position into terrain-local space.
	# ---------------------------------------------------------------

	var player_local_position: Vector3 = (
		terrain_generator.to_local(
			player.global_position
		)
	)

	var chunk_size: float = (
		world_size / float(chunks_per_axis)
	)

	# ---------------------------------------------------------------
	# Determine the player's current chunk.
	# ---------------------------------------------------------------

	var player_chunk_x: int = floori(
		(player_local_position.x + world_size * 0.5)
		/ chunk_size
	)

	var player_chunk_z: int = floori(
		(player_local_position.z + world_size * 0.5)
		/ chunk_size
	)

	var current_player_chunk := Vector2i(
		player_chunk_x,
		player_chunk_z
	)

	# ---------------------------------------------------------------
	# Skip updates if the player hasn't changed chunks.
	# ---------------------------------------------------------------

	if not force_update and initialized:

		if current_player_chunk == last_player_chunk:
			return

	# ---------------------------------------------------------------
	# Initial setup: unload every chunk before loading the nearby ones.
	# ---------------------------------------------------------------

	if not initialized:

		for chunk_z in range(chunks_per_axis):
			for chunk_x in range(chunks_per_axis):

				_set_chunk_state(
					chunk_x,
					chunk_z,
					false
				)

		last_player_chunk = current_player_chunk
		initialized = true

	# ---------------------------------------------------------------
	# Determine which chunks should remain loaded.
	# ---------------------------------------------------------------

	for chunk_z in range(chunks_per_axis):

		for chunk_x in range(chunks_per_axis):

			var chunk_position := Vector2i(
				chunk_x,
				chunk_z
			)

			var offset := Vector2(
				chunk_x - player_chunk_x,
				chunk_z - player_chunk_z
			)

			var distance: float

			if circular_loading:
				distance = offset.length()
			else:
				distance = max(
					abs(offset.x),
					abs(offset.y)
				)

			var currently_loaded: bool = active_chunks.get(
				chunk_position,
				false
			)

			# Already-loaded chunks get a larger unload radius.
			var allowed_distance: float = float(render_distance)

			if currently_loaded:
				allowed_distance += float(unload_buffer)

			var should_load: bool = (
				distance <= allowed_distance
			)

			# -------------------------------------------------------
			# Only update chunks whose state has changed.
			# -------------------------------------------------------

			if should_load == currently_loaded:
				continue

			_set_chunk_state(
				chunk_x,
				chunk_z,
				should_load
			)


# =====================================================================
# SET CHUNK STATE
# =====================================================================

func _set_chunk_state(
	chunk_x: int,
	chunk_z: int,
	loaded: bool
) -> void:

	var chunk_position := Vector2i(
		chunk_x,
		chunk_z
	)

	# Tell the terrain generator to handle the actual chunk.
	if not terrain_generator.has_method("set_chunk_loaded"):
		push_error(
			"ChunkManager: Terrain generator is missing " +
			"set_chunk_loaded(). Apply the integration patch."
		)
		return

	terrain_generator.call(
		"set_chunk_loaded",
		chunk_x,
		chunk_z,
		loaded
	)

	active_chunks[chunk_position] = loaded


# =====================================================================
# MANUAL REFRESH
# =====================================================================

## Forces the manager to recalculate all chunk states.
func refresh_chunks() -> void:

	initialized = false

	active_chunks.clear()

	_update_chunks(true)


## Returns whether a particular chunk is currently loaded.
func is_chunk_loaded(
	chunk_x: int,
	chunk_z: int
) -> bool:

	return active_chunks.get(
		Vector2i(chunk_x, chunk_z),
		false
	)
