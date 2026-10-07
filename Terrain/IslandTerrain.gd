@tool
extends MeshInstance3D

## Procedural island terrain generator.
##
## Main features:
## - Procedural island
## - Curved Hawaiian-style mountain range
## - Sharp ridges / deep valleys
## - Lazy chunk LOD generation
## - Cached heightmap normals
## - Cached shoreline/sand data
## - Coalesced editor regeneration
## - Heightmap collision
##
## Scene hierarchy:
##
## Terrain (MeshInstance3D)
## └── StaticBody3D
##     └── CollisionShape3D
##
## The generated terrain uses:
##
## Terrain
## ├── StaticBody3D
## │   └── CollisionShape3D
## │
## └── TerrainChunks
##     ├── Chunk_0_0
##     ├── Chunk_0_1
##     └── ...
##
## The heightmap remains the single source of truth for:
## - terrain geometry
## - LODs
## - collision
## - shoreline masks
## - terrain normals


const TERRAIN_SHADER = preload("res://Terrain/terrain_shader.gdshader")


# =====================================================================
# GENERAL
# =====================================================================

@export_category("General")

@export var generate_on_ready: bool = true

## When enabled, inspector property changes request a regeneration.
##
## Regeneration is deferred and coalesced, so changing several settings
## quickly only produces one regeneration instead of many.
@export var auto_regenerate: bool = true


@export var seed: int = 12345:
	set(value):
		seed = value
		_request_generate()


@export_range(33, 1025, 2)
var resolution: int = 257:
	set(value):

		if value % 2 == 0:
			value += 1

		resolution = value
		_request_generate()


@export var world_size: float = 400.0:
	set(value):

		world_size = max(value, 1.0)
		_request_generate()


# =====================================================================
# TERRAIN CHUNKS / LOD
# =====================================================================

@export_category("Terrain Chunks & LOD")

@export_range(1, 16, 1)
var chunks_per_axis: int = 4:
	set(value):

		chunks_per_axis = max(value, 1)
		_request_generate()


@export_range(1, 4, 1)
var lod_levels: int = 4


@export var lod_camera: Camera3D

@export_range(0.0, 5000.0, 1.0)
var lod_distance_1: float = 150.0

@export_range(0.0, 5000.0, 1.0)
var lod_distance_2: float = 350.0

@export_range(0.0, 10000.0, 1.0)
var lod_distance_3: float = 700.0


@export_range(0.02, 1.0, 0.01)
var lod_update_interval: float = 0.20


## Number of new LOD meshes allowed to be generated during one
## LOD update.
##
## Lower values reduce frame spikes when the camera moves into
## previously unseen LOD ranges.
@export_range(1, 8, 1)
var lod_mesh_generation_budget: int = 2


@export var lod_skirts_enabled: bool = false

@export_range(0.1, 20.0, 0.1)
var lod_skirt_depth: float = 2.0


# =====================================================================
# WATER / HEIGHT
# =====================================================================

@export_category("Water & Height")

@export var water_level: float = 2.0:
	set(value):

		water_level = value
		_update_material_parameters()


@export var maximum_height: float = 45.0:
	set(value):

		maximum_height = value
		_request_generate()


# =====================================================================
# ISLAND SHAPE
# =====================================================================

@export_category("Island Shape")

@export_range(0.1, 2.0, 0.01)
var island_width: float = 0.95:
	set(value):

		island_width = value
		_request_generate()


@export_range(0.1, 2.0, 0.01)
var island_length: float = 0.75:
	set(value):

		island_length = value
		_request_generate()


@export_range(0.0, 1.0, 0.01)
var coastline_start: float = 0.62:
	set(value):

		coastline_start = value
		_request_generate()


@export_range(0.0, 0.5, 0.01)
var coastline_strength: float = 0.16:
	set(value):

		coastline_strength = value
		_request_generate()


# =====================================================================
# TERRAIN NOISE
# =====================================================================

@export_category("Terrain Noise")

@export var terrain_frequency: float = 0.0055:
	set(value):

		terrain_frequency = value
		_request_generate()


@export_range(1, 8, 1)
var terrain_octaves: int = 3:
	set(value):

		terrain_octaves = value
		_request_generate()


@export_range(0.0, 1.0, 0.01)
var terrain_detail_strength: float = 0.08:
	set(value):

		terrain_detail_strength = value
		_request_generate()


@export var detail_frequency: float = 0.018:
	set(value):

		detail_frequency = value
		_request_generate()


# =====================================================================
# TERRAIN SMOOTHING
# =====================================================================

@export_category("Terrain Smoothing")

## One pass is normally enough.
##
## Higher values can noticeably soften the sharp ridges.
@export_range(0, 3, 1)
var height_smoothing_passes: int = 1:
	set(value):

		height_smoothing_passes = value
		_request_generate()


@export_range(0.0, 1.0, 0.05)
var height_smoothing_strength: float = 0.45:
	set(value):

		height_smoothing_strength = value
		_request_generate()


# =====================================================================
# EROSION STYLE
# =====================================================================

@export_category("Erosion Style")

@export var erosion_enabled: bool = true:
	set(value):

		erosion_enabled = value
		_request_generate()


@export var erosion_frequency: float = 0.010:
	set(value):

		erosion_frequency = value
		_request_generate()


@export_range(1, 6, 1)
var erosion_octaves: int = 2:
	set(value):

		erosion_octaves = value
		_request_generate()


@export_range(0.0, 2.0, 0.01)
var erosion_strength: float = 0.20:
	set(value):

		erosion_strength = value
		_request_generate()


@export_range(0.0, 100.0, 0.5)
var erosion_warp_strength: float = 12.0:
	set(value):

		erosion_warp_strength = value
		_request_generate()


@export var erosion_warp_frequency: float = 0.012:
	set(value):

		erosion_warp_frequency = value
		_request_generate()


@export_range(0.0, 2.0, 0.01)
var erosion_valley_strength: float = 0.20:
	set(value):

		erosion_valley_strength = value
		_request_generate()


# =====================================================================
# HAWAIIAN MOUNTAINS
# =====================================================================

@export_category("Hawaiian Mountains")

@export var mountains_enabled: bool = true:
	set(value):

		mountains_enabled = value
		_request_generate()


## Center of the mountain system.
##
## The range generally runs along the X axis through this point.
@export var mountain_center: Vector2 = Vector2(0.0, -15.0):
	set(value):

		mountain_center = value
		_request_generate()


## Length of the major mountain range.
##
## The actual length is automatically clamped so it stays inside
## the island.
@export_range(40.0, 400.0, 1.0)
var mountain_range_length: float = 320.0:
	set(value):

		mountain_range_length = value
		_request_generate()


## Keeps the ends of the mountain away from the coastline.
@export_range(0.0, 100.0, 1.0)
var mountain_range_end_margin: float = 20.0:
	set(value):

		mountain_range_end_margin = value
		_request_generate()


# ---------------------------------------------------------------------
# Main mountain mass
# ---------------------------------------------------------------------

## Width of the overall mountain mass.
##
## This is deliberately larger than the individual ridges.
@export_range(15.0, 140.0, 1.0)
var mountain_mass_width: float = 62.0:
	set(value):

		mountain_mass_width = value
		_request_generate()


## Overall mountain height.
@export_range(0.0, 2.0, 0.01)
var mountain_strength: float = 1.0:
	set(value):

		mountain_strength = value
		_request_generate()


## Controls the steepness of the large-scale mountain sides.
@export_range(0.5, 5.0, 0.05)
var mountain_slope_power: float = 2.2:
	set(value):

		mountain_slope_power = value
		_request_generate()


# ---------------------------------------------------------------------
# Curvature
# ---------------------------------------------------------------------

## Amount of large-scale sideways movement in the mountain spine.
@export_range(0.0, 80.0, 1.0)
var mountain_curve_amplitude: float = 24.0:
	set(value):

		mountain_curve_amplitude = value
		_request_generate()


## Number of broad bends along the range.
@export_range(0.1, 2.0, 0.05)
var mountain_curve_frequency: float = 0.65:
	set(value):

		mountain_curve_frequency = value
		_request_generate()


## Smaller irregular movement in the mountain spine.
@export_range(0.0, 40.0, 1.0)
var mountain_curve_noise_strength: float = 12.0:
	set(value):

		mountain_curve_noise_strength = value
		_request_generate()


# ---------------------------------------------------------------------
# Sharp ridges
# ---------------------------------------------------------------------

## Strength of the sharp internal ridges.
@export_range(0.0, 1.0, 0.01)
var mountain_ridge_strength: float = 0.72:
	set(value):

		mountain_ridge_strength = value
		_request_generate()


## Higher values create narrower, sharper ridges.
@export_range(0.5, 8.0, 0.05)
var mountain_ridge_sharpness: float = 3.2:
	set(value):

		mountain_ridge_sharpness = value
		_request_generate()


## Number/scale of the secondary ridges.
##
## Lower = larger ridges.
## Higher = more numerous ridges.
@export_range(0.005, 0.08, 0.001)
var mountain_ridge_frequency: float = 0.026:
	set(value):

		mountain_ridge_frequency = value
		_request_generate()


## Controls how elongated the ridges are along the mountain range.
@export_range(0.1, 3.0, 0.05)
var mountain_ridge_length_scale: float = 0.45:
	set(value):

		mountain_ridge_length_scale = value
		_request_generate()


## Irregularity of the ridge field.
@export_range(0.0, 2.0, 0.01)
var mountain_ridge_warp: float = 0.65:
	set(value):

		mountain_ridge_warp = value
		_request_generate()


# ---------------------------------------------------------------------
# Deep valleys
# ---------------------------------------------------------------------

## Strength of the cuts between ridges.
@export_range(0.0, 1.0, 0.01)
var mountain_valley_strength: float = 0.72:
	set(value):

		mountain_valley_strength = value
		_request_generate()


## Makes valleys narrower and deeper.
@export_range(0.5, 6.0, 0.05)
var mountain_valley_sharpness: float = 2.8:
	set(value):

		mountain_valley_sharpness = value
		_request_generate()


# ---------------------------------------------------------------------
# Ridge variation
# ---------------------------------------------------------------------

## Variation in height along the main range.
@export_range(0.0, 1.0, 0.01)
var mountain_height_variation: float = 0.30:
	set(value):

		mountain_height_variation = value
		_request_generate()


## Small-scale roughness on the mountain surface.
@export_range(0.0, 0.5, 0.01)
var mountain_surface_noise: float = 0.12:
	set(value):

		mountain_surface_noise = value
		_request_generate()


# ---------------------------------------------------------------------
# Pass / dip
# ---------------------------------------------------------------------

## Position of the broad lower section.
##
## -1 = left
##  0 = center
## +1 = right
@export_range(-1.0, 1.0, 0.01)
var mountain_dip_position: float = 0.0:
	set(value):

		mountain_dip_position = value
		_request_generate()


## Width of the gentler section.
@export_range(0.05, 0.50, 0.01)
var mountain_dip_width: float = 0.20:
	set(value):

		mountain_dip_width = value
		_request_generate()


## Height reduction at the pass.
@export_range(0.0, 0.80, 0.01)
var mountain_dip_strength: float = 0.30:
	set(value):

		mountain_dip_strength = value
		_request_generate()


## Broadens the mountain around the pass.
##
## This makes the pass genuinely easier rather than simply putting
## a dent into the top.
@export_range(1.0, 3.0, 0.05)
var mountain_dip_width_multiplier: float = 1.75:
	set(value):

		mountain_dip_width_multiplier = value
		_request_generate()


# =====================================================================
# BEACH / SAND
# =====================================================================

@export_category("Beach & Sand")

@export var beach_width: float = 5.0:
	set(value):

		beach_width = value
		_update_material_parameters()


@export var sand_height: float = 10.0:
	set(value):

		sand_height = max(value, water_level)
		_update_material_parameters()


@export var sand_blend: float = 2.5:
	set(value):

		sand_blend = max(value, 0.01)
		_update_material_parameters()


# =====================================================================
# SHORELINE / FOAM
# =====================================================================

@export_category("Shoreline / Foam")

@export var shoreline_enabled: bool = true:
	set(value):

		shoreline_enabled = value
		_update_material_parameters()


@export var shoreline_foam_width: float = 4.0:
	set(value):

		shoreline_foam_width = max(value, 0.01)
		_update_material_parameters()


@export_range(0.0, 2.0, 0.01)
var shoreline_foam_strength: float = 0.7:
	set(value):

		shoreline_foam_strength = value
		_update_material_parameters()


@export var shoreline_foam_color: Color = Color(
	0.92,
	0.98,
	1.0,
	1.0
):
	set(value):

		shoreline_foam_color = value
		_update_material_parameters()


@export_range(0.0, 1.0, 0.01)
var shoreline_foam_noise_strength: float = 0.25:
	set(value):

		shoreline_foam_noise_strength = value
		_update_material_parameters()


@export var shoreline_foam_noise_scale: float = 0.08:
	set(value):

		shoreline_foam_noise_scale = value
		_update_material_parameters()


# =====================================================================
# MATERIAL
# =====================================================================

@export_category("Terrain Material")

@export var sand_texture: Texture2D:
	set(value):

		sand_texture = value
		_update_material_parameters()


@export var dirt_texture: Texture2D:
	set(value):

		dirt_texture = value
		_update_material_parameters()


@export var grass_texture: Texture2D:
	set(value):

		grass_texture = value
		_update_material_parameters()


@export var rock_texture: Texture2D:
	set(value):

		rock_texture = value
		_update_material_parameters()


@export var texture_scale: float = 14.0:
	set(value):

		texture_scale = value
		_update_material_parameters()


@export var dirt_height: float = 14.0:
	set(value):

		dirt_height = value
		_update_material_parameters()


@export var grass_height: float = 26.0:
	set(value):

		grass_height = value
		_update_material_parameters()


@export var rock_height: float = 34.0:
	set(value):

		rock_height = value
		_update_material_parameters()


@export_range(0.0, 1.0, 0.01)
var rock_slope_threshold: float = 0.58:
	set(value):

		rock_slope_threshold = value
		_update_material_parameters()


@export_range(0.01, 1.0, 0.01)
var rock_slope_blend: float = 0.18:
	set(value):

		rock_slope_blend = value
		_update_material_parameters()


@export_range(0.01, 10.0, 0.01)
var height_blend: float = 2.5:
	set(value):

		height_blend = value
		_update_material_parameters()


# =====================================================================
# INTERNAL DATA
# =====================================================================

var heights: PackedFloat32Array

## Precomputed normal for every master heightmap sample.
var height_normals: PackedVector3Array

## Precomputed island mask for every sample.
var island_masks: PackedFloat32Array

## Cached world coordinates.
var world_x_values: PackedFloat32Array
var world_z_values: PackedFloat32Array


var terrain_noise: FastNoiseLite
var coastline_noise: FastNoiseLite
var detail_noise: FastNoiseLite

var erosion_noise: FastNoiseLite

var mountain_ridge_noise: FastNoiseLite
var mountain_curve_noise: FastNoiseLite
var mountain_surface_noise_generator: FastNoiseLite


var terrain_material: ShaderMaterial

var chunks_root: Node3D

var chunk_records: Array[Dictionary] = []

var lod_timer: float = 0.0

var generate_queued: bool = false

var generating: bool = false


# =====================================================================
# READY
# =====================================================================

func _ready() -> void:

	if generate_on_ready:
		generate()


# =====================================================================
# PROCESS
# =====================================================================

func _process(delta: float) -> void:

	if not is_inside_tree():
		return

	lod_timer += delta

	if lod_timer >= lod_update_interval:

		lod_timer = 0.0

		_update_chunk_lods()


# =====================================================================
# REGENERATION REQUEST
# =====================================================================

func _request_generate() -> void:

	if not auto_regenerate:
		return

	if not is_inside_tree():
		return

	if generating:
		return

	if generate_queued:
		return

	generate_queued = true

	call_deferred("_deferred_generate")


func _deferred_generate() -> void:

	generate_queued = false

	if not is_inside_tree():
		return

	generate()


# =====================================================================
# GENERATE
# =====================================================================

func generate() -> void:

	if generating:
		return

	if resolution < 3:
		return

	generating = true
	generate_queued = false

	chunks_per_axis = max(
		chunks_per_axis,
		1
	)

	_create_noise_generators()

	_prepare_coordinate_cache()

	_generate_heightmap()

	_build_heightmap_cache()

	_create_material()

	_generate_chunks()

	_generate_collision()

	_update_chunk_lods()

	generating = false


# =====================================================================
# NOISE SETUP
# =====================================================================

func _create_noise_generators() -> void:

	# ---------------------------------------------------------------
	# Main terrain
	# ---------------------------------------------------------------

	terrain_noise = FastNoiseLite.new()

	terrain_noise.seed = seed
	terrain_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	terrain_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	terrain_noise.fractal_octaves = terrain_octaves
	terrain_noise.fractal_gain = 0.5
	terrain_noise.frequency = terrain_frequency


	# ---------------------------------------------------------------
	# Coastline
	# ---------------------------------------------------------------

	coastline_noise = FastNoiseLite.new()

	coastline_noise.seed = seed + 100
	coastline_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	coastline_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	coastline_noise.fractal_octaves = 2
	coastline_noise.frequency = 0.004


	# ---------------------------------------------------------------
	# Fine terrain
	# ---------------------------------------------------------------

	detail_noise = FastNoiseLite.new()

	detail_noise.seed = seed + 200
	detail_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	detail_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	detail_noise.fractal_octaves = 2
	detail_noise.frequency = detail_frequency


	# ---------------------------------------------------------------
	# Erosion
	# ---------------------------------------------------------------

	erosion_noise = FastNoiseLite.new()

	erosion_noise.seed = seed + 400
	erosion_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	erosion_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	erosion_noise.fractal_octaves = erosion_octaves
	erosion_noise.fractal_gain = 0.5
	erosion_noise.frequency = erosion_frequency

	erosion_noise.domain_warp_enabled = true
	erosion_noise.domain_warp_type = FastNoiseLite.DOMAIN_WARP_SIMPLEX_REDUCED
	erosion_noise.domain_warp_amplitude = erosion_warp_strength
	erosion_noise.domain_warp_frequency = erosion_warp_frequency
	erosion_noise.domain_warp_fractal_octaves = 2


	# ===============================================================
	# HAWAIIAN RIDGE NOISE
	# ===============================================================
	#
	# Ridged fractal noise is intentionally used here.
	#
	# FastNoiseLite supports FRACTAL_RIDGED specifically for creating
	# ridge-like terrain.
	# ===============================================================

	mountain_ridge_noise = FastNoiseLite.new()

	mountain_ridge_noise.seed = seed + 500
	mountain_ridge_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	mountain_ridge_noise.fractal_type = FastNoiseLite.FRACTAL_RIDGED
	mountain_ridge_noise.fractal_octaves = 3
	mountain_ridge_noise.fractal_gain = 0.55
	mountain_ridge_noise.frequency = mountain_ridge_frequency

	mountain_ridge_noise.domain_warp_enabled = true
	mountain_ridge_noise.domain_warp_type = FastNoiseLite.DOMAIN_WARP_SIMPLEX_REDUCED
	mountain_ridge_noise.domain_warp_amplitude = mountain_ridge_warp
	mountain_ridge_noise.domain_warp_frequency = 0.025
	mountain_ridge_noise.domain_warp_fractal_octaves = 2


	# ---------------------------------------------------------------
	# Large-scale mountain curve
	# ---------------------------------------------------------------

	mountain_curve_noise = FastNoiseLite.new()

	mountain_curve_noise.seed = seed + 600
	mountain_curve_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	mountain_curve_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	mountain_curve_noise.fractal_octaves = 2
	mountain_curve_noise.frequency = 0.008


	# ---------------------------------------------------------------
	# Small mountain surface variation
	# ---------------------------------------------------------------

	mountain_surface_noise_generator = FastNoiseLite.new()

	mountain_surface_noise_generator.seed = seed + 700
	mountain_surface_noise_generator.noise_type = FastNoiseLite.TYPE_SIMPLEX
	mountain_surface_noise_generator.fractal_type = FastNoiseLite.FRACTAL_FBM
	mountain_surface_noise_generator.fractal_octaves = 2
	mountain_surface_noise_generator.frequency = 0.045


# =====================================================================
# COORDINATE CACHE
# =====================================================================

func _prepare_coordinate_cache() -> void:

	world_x_values.resize(resolution)
	world_z_values.resize(resolution)


	var half_size := world_size * 0.5

	var step := (
		world_size /
		float(resolution - 1)
	)


	for i in range(resolution):

		world_x_values[i] = (
			float(i) * step -
			half_size
		)

		world_z_values[i] = (
			float(i) * step -
			half_size
		)


# =====================================================================
# HEIGHTMAP
# =====================================================================

func _generate_heightmap() -> void:

	var total := resolution * resolution

	heights.resize(total)

	for z in range(resolution):

		var world_z := world_z_values[z]

		for x in range(resolution):

			var world_x := world_x_values[x]

			var index := (
				z * resolution +
				x
			)

			heights[index] = _calculate_height(
				world_x,
				world_z
			)


	_smooth_heightmap()


# =====================================================================
# HEIGHTMAP CACHE
# =====================================================================

func _build_heightmap_cache() -> void:

	var total := resolution * resolution

	height_normals.resize(total)
	island_masks.resize(total)


	var cell_size := (
		world_size /
		float(resolution - 1)
	)


	# ---------------------------------------------------------------
	# Island masks
	# ---------------------------------------------------------------

	for z in range(resolution):

		var world_z := world_z_values[z]

		for x in range(resolution):

			var world_x := world_x_values[x]

			var index := (
				z * resolution +
				x
			)

			island_masks[index] = _calculate_island_mask(
				world_x,
				world_z
			)


	# ---------------------------------------------------------------
	# Normals
	# ---------------------------------------------------------------

	for z in range(resolution):

		for x in range(resolution):

			var index := (
				z * resolution +
				x
			)

			var left_x = max(x - 1, 0)
			var right_x = min(x + 1, resolution - 1)

			var up_z = max(z - 1, 0)
			var down_z = min(z + 1, resolution - 1)


			var left_height := heights[
				z * resolution +
				left_x
			]

			var right_height := heights[
				z * resolution +
				right_x
			]

			var up_height := heights[
				up_z * resolution +
				x
			]

			var down_height := heights[
				down_z * resolution +
				x
			]


			var dx := (
				right_height -
				left_height
			)

			var dz := (
				down_height -
				up_height
			)


			height_normals[index] = Vector3(
				-dx / max(cell_size, 0.001),
				2.0,
				-dz / max(cell_size, 0.001)
			).normalized()


# =====================================================================
# HEIGHTMAP SMOOTHING
# =====================================================================

func _smooth_heightmap() -> void:

	if height_smoothing_passes <= 0:
		return


	for pass_index in range(height_smoothing_passes):

		var source := heights.duplicate()


		for z in range(resolution):

			var up_z = max(z - 1, 0)
			var down_z = min(z + 1, resolution - 1)


			for x in range(resolution):

				var left_x = max(x - 1, 0)
				var right_x = min(x + 1, resolution - 1)


				var center := source[
					z * resolution +
					x
				]

				var left := source[
					z * resolution +
					left_x
				]

				var right := source[
					z * resolution +
					right_x
				]

				var up := source[
					up_z * resolution +
					x
				]

				var down := source[
					down_z * resolution +
					x
				]

				var up_left := source[
					up_z * resolution +
					left_x
				]

				var up_right := source[
					up_z * resolution +
					right_x
				]

				var down_left := source[
					down_z * resolution +
					left_x
				]

				var down_right := source[
					down_z * resolution +
					right_x
				]


				var smoothed := (
					center * 4.0 +

					left * 2.0 +
					right * 2.0 +
					up * 2.0 +
					down * 2.0 +

					up_left +
					up_right +
					down_left +
					down_right
				) / 16.0


				var index := (
					z * resolution +
					x
				)


				heights[index] = lerp(
					center,
					smoothed,
					height_smoothing_strength
				)


				heights[index] = max(
					heights[index],
					water_level
				)


# =====================================================================
# HEIGHT CALCULATION
# =====================================================================

func _calculate_height(
	world_x: float,
	world_z: float
) -> float:

	var normalized_x := (
		world_x /
		(world_size * 0.5 * island_width)
	)

	var normalized_z := (
		world_z /
		(world_size * 0.5 * island_length)
	)


	var island_distance := Vector2(
		normalized_x,
		normalized_z
	).length()


	# ---------------------------------------------------------------
	# Coastline
	# ---------------------------------------------------------------

	var coastline_value := coastline_noise.get_noise_2d(
		world_x,
		world_z
	)


	var coastline_radius := (
		1.0 +
		coastline_value *
		coastline_strength
	)


	var island_mask := 1.0 - smoothstep(
		coastline_start * coastline_radius,
		coastline_radius,
		island_distance
	)


	island_mask = clamp(
		island_mask,
		0.0,
		1.0
	)


	# ---------------------------------------------------------------
	# Base terrain
	# ---------------------------------------------------------------

	var large_noise := (
		terrain_noise.get_noise_2d(
			world_x,
			world_z
		) * 0.5 +
		0.5
	)


	large_noise = pow(
		large_noise,
		1.65
	)


	var detail := (
		detail_noise.get_noise_2d(
			world_x,
			world_z
		) * 0.5 +
		0.5
	)


	var terrain_value = lerp(
		large_noise,
		detail,
		terrain_detail_strength
	)


	# ---------------------------------------------------------------
	# Erosion
	# ---------------------------------------------------------------

	if erosion_enabled:

		var erosion_value := (
			erosion_noise.get_noise_2d(
				world_x,
				world_z
			) * 0.5 +
			0.5
		)


		var valleys := 1.0 - erosion_value

		var valley_carve := (
			valleys *
			valleys *
			erosion_valley_strength
		)


		var erosion_result = clamp(
			erosion_value -
			valley_carve,
			0.0,
			1.0
		)


		terrain_value = lerp(
			terrain_value,
			terrain_value * 0.55 +
			erosion_result * 0.45,
			erosion_strength
		)


	# ===============================================================
	# HAWAIIAN MOUNTAIN RANGE
	# ===============================================================

	if mountains_enabled:

		var mountain_height := _calculate_mountain_height(
			world_x,
			world_z,
			island_mask
		)


		terrain_value = lerp(
			terrain_value,
			max(
				terrain_value,
				mountain_height
			),
			smoothstep(
				0.03,
				0.22,
				island_mask
			)
		)


	# ---------------------------------------------------------------
	# Final height
	# ---------------------------------------------------------------

	var terrain_height = (
		terrain_value *
		maximum_height
	)


	# ---------------------------------------------------------------
	# Coast flattening
	# ---------------------------------------------------------------

	var beach_mask := smoothstep(
		0.0,
		0.20,
		island_mask
	)


	terrain_height *= beach_mask


	# ---------------------------------------------------------------
	# Island falloff
	# ---------------------------------------------------------------

	terrain_height *= pow(
		island_mask,
		1.35
	)


	return water_level + terrain_height


# =====================================================================
# MOUNTAIN HEIGHT
# =====================================================================

func _calculate_mountain_height(
	world_x: float,
	world_z: float,
	island_mask: float
) -> float:

	# ---------------------------------------------------------------
	# Safe range length
	# ---------------------------------------------------------------

	var island_half_width := (
		world_size *
		0.5 *
		island_width
	)


	var safe_half_length = max(
		island_half_width -
		mountain_range_end_margin,
		1.0
	)


	var range_half_length = min(
		mountain_range_length * 0.5,
		safe_half_length
	)


	# ---------------------------------------------------------------
	# Position along range
	# ---------------------------------------------------------------

	var range_t = (
		world_x -
		mountain_center.x
	) / range_half_length


	var clamped_t = clamp(
		range_t,
		-1.0,
		1.0
	)


	# ---------------------------------------------------------------
	# Curved mountain spine
	#
	# The sine creates the broad bend.
	# Noise adds irregular movement so it doesn't look mathematical.
	# ---------------------------------------------------------------

	var broad_curve := sin(
		clamped_t *
		PI *
		mountain_curve_frequency
	)


	var small_curve := (
		mountain_curve_noise.get_noise_1d(
			world_x
		) *
		mountain_curve_noise_strength
	)


	var spine_z := (
		mountain_center.y +

		broad_curve *
		mountain_curve_amplitude +

		small_curve
	)


	# ---------------------------------------------------------------
	# Fade the ends
	# ---------------------------------------------------------------

	var range_distance = abs(
		clamped_t
	)


	var end_fade := 1.0 - smoothstep(
		0.78,
		1.0,
		range_distance
	)


	# ---------------------------------------------------------------
	# Dip / pass
	# ---------------------------------------------------------------

	var dip_distance = (
		clamped_t -
		mountain_dip_position
	)


	var dip_width = max(
		mountain_dip_width,
		0.01
	)


	var dip := exp(
		-(
			dip_distance *
			dip_distance
		) /
		(
			dip_width *
			dip_width
		)
	)


	# ---------------------------------------------------------------
	# Local mountain width
	# ---------------------------------------------------------------

	var local_width = lerp(
		mountain_mass_width,
		mountain_mass_width *
		mountain_dip_width_multiplier,
		dip
	)


	# ---------------------------------------------------------------
	# Distance from mountain spine
	# ---------------------------------------------------------------

	var across_distance = abs(
		world_z -
		spine_z
	)


	var across_t = clamp(
		across_distance /
		max(local_width, 0.001),
		0.0,
		1.0
	)


	# ---------------------------------------------------------------
	# Large mountain envelope
	#
	# This gives us the underlying mountain mass.
	# ---------------------------------------------------------------

	var broad_mass := 1.0 - smoothstep(
		0.0,
		1.0,
		across_t
	)


	broad_mass = pow(
		broad_mass,
		mountain_slope_power
	)


	# ===============================================================
	# RIDGE FIELD
	# ===============================================================
	#
	# This is the part that makes the mountain stop looking like a
	# cylinder.
	#
	# The noise coordinates are deliberately stretched:
	#
	# X = long direction of mountain range
	# Z = shorter direction across mountain
	#
	# This encourages long ridges while still allowing them to bend,
	# merge and break apart.
	# ===============================================================

	var ridge_x := (
		world_x *
		mountain_ridge_length_scale
	)


	var ridge_z := (
		world_z
	)


	var ridge_noise := mountain_ridge_noise.get_noise_2d(
		ridge_x,
		ridge_z
	)


	# FastNoiseLite ridged noise is already ridge-shaped.
	#
	# Normalize and sharpen it.
	var ridge_value = clamp(
		ridge_noise,
		0.0,
		1.0
	)


	ridge_value = pow(
		ridge_value,
		mountain_ridge_sharpness
	)


	# ---------------------------------------------------------------
	# Additional distance-based sharpening.
	#
	# Near the main crest we want narrower, more pronounced ridges.
	# ---------------------------------------------------------------

	var ridge_core := 1.0 - smoothstep(
		0.05,
		0.65,
		across_t
	)


	ridge_core = pow(
		ridge_core,
		1.25
	)


	# ---------------------------------------------------------------
	# Deep valley cuts
	#
	# Turning the ridged field into a contrast-heavy mask produces
	# sharp ridges separated by deep grooves.
	# ---------------------------------------------------------------

	var valley_value = 1.0 - ridge_value

	valley_value = pow(
		clamp(
			valley_value,
			0.0,
			1.0
		),
		mountain_valley_sharpness
	)


	var ridge_terrain = lerp(
		1.0,
		ridge_value,
		mountain_ridge_strength
	)


	ridge_terrain = lerp(
		ridge_terrain,
		ridge_terrain * (
			1.0 -
			valley_value *
			mountain_valley_strength
		),
		0.75
	)


	# ---------------------------------------------------------------
	# Surface roughness
	# ---------------------------------------------------------------

	var surface_noise := (
		mountain_surface_noise_generator.get_noise_2d(
			world_x,
			world_z
		) * 0.5 +
		0.5
	)


	surface_noise = lerp(
		1.0,
		surface_noise,
		mountain_surface_noise
	)


	# ---------------------------------------------------------------
	# Height variation along the range
	#
	# This prevents the mountain from having the same height all
	# the way along the line.
	# ---------------------------------------------------------------

	var height_variation_noise := (
		mountain_curve_noise.get_noise_1d(
			world_x * 0.55
		) * 0.5 +
		0.5
	)


	var height_variation = lerp(
		1.0 - mountain_height_variation,
		1.0,
		height_variation_noise
	)


	# ---------------------------------------------------------------
	# Pass / dip height reduction
	# ---------------------------------------------------------------

	var dip_height = lerp(
		1.0,
		1.0 - mountain_dip_strength,
		dip
	)


	# ---------------------------------------------------------------
	# Combine
	# ---------------------------------------------------------------

	var mountain = (
		broad_mass *

		lerp(
			1.0,
			ridge_terrain,
			0.85
		) *

		lerp(
			0.65,
			1.0,
			ridge_core
		) *

		surface_noise *

		height_variation *

		dip_height *

		end_fade
	)


	# ---------------------------------------------------------------
	# Stronger transition into surrounding terrain.
	# ---------------------------------------------------------------

	var mountain_presence := smoothstep(
		0.0,
		0.18,
		island_mask
	)


	mountain *= mountain_presence


	return clamp(
		mountain *
		mountain_strength,
		0.0,
		1.0
	)


# =====================================================================
# ISLAND MASK
# =====================================================================

func _calculate_island_mask(
	world_x: float,
	world_z: float
) -> float:

	var normalized_x := (
		world_x /
		(world_size * 0.5 * island_width)
	)

	var normalized_z := (
		world_z /
		(world_size * 0.5 * island_length)
	)


	var distance := Vector2(
		normalized_x,
		normalized_z
	).length()


	var coastline_value := coastline_noise.get_noise_2d(
		world_x,
		world_z
	)


	var coastline_radius := (
		1.0 +
		coastline_value *
		coastline_strength
	)


	var mask := 1.0 - smoothstep(
		coastline_start *
		coastline_radius,

		coastline_radius,

		distance
	)


	return clamp(
		mask,
		0.0,
		1.0
	)


# =====================================================================
# CHUNK ROOT
# =====================================================================

func _clear_chunks() -> void:

	if chunks_root != null:

		if is_instance_valid(chunks_root):
			chunks_root.queue_free()

		chunks_root = null


	chunk_records.clear()


func _generate_chunks() -> void:

	_clear_chunks()


	chunks_root = Node3D.new()
	chunks_root.name = "TerrainChunks"

	add_child(chunks_root)


	if Engine.is_editor_hint():
		chunks_root.owner = get_tree().edited_scene_root


	for chunk_z in range(chunks_per_axis):

		for chunk_x in range(chunks_per_axis):

			_create_chunk(
				chunk_x,
				chunk_z
			)


# =====================================================================
# CREATE CHUNK
# =====================================================================

func _create_chunk(
	chunk_x: int,
	chunk_z: int
) -> void:

	var chunk := MeshInstance3D.new()

	chunk.name = "Chunk_%d_%d" % [
		chunk_x,
		chunk_z
	]


	chunks_root.add_child(chunk)


	if Engine.is_editor_hint():
		chunk.owner = get_tree().edited_scene_root


	# ---------------------------------------------------------------
	# IMPORTANT PERFORMANCE CHANGE:
	#
	# Do NOT create all LOD meshes here.
	#
	# Each chunk gets an array of empty slots. The required LOD is
	# created only when the camera actually needs it.
	# ---------------------------------------------------------------

	var meshes: Array = []

	for i in range(lod_levels):
		meshes.append(null)


	var chunk_center := _get_chunk_center(
		chunk_x,
		chunk_z
	)


	chunk.material_override = terrain_material


	chunk_records.append({
		"node": chunk,
		"meshes": meshes,
		"center": chunk_center,
		"lod": -1
	})


# =====================================================================
# CHUNK CENTER
# =====================================================================

func _get_chunk_center(
	chunk_x: int,
	chunk_z: int
) -> Vector3:

	var chunk_size := (
		world_size /
		float(chunks_per_axis)
	)


	return Vector3(
		(
			chunk_x + 0.5
		) * chunk_size -
		world_size * 0.5,

		0.0,

		(
			chunk_z + 0.5
		) * chunk_size -
		world_size * 0.5
	)


# =====================================================================
# CHUNK MESH
# =====================================================================

func _generate_chunk_mesh(
	chunk_x: int,
	chunk_z: int,
	lod: int
) -> ArrayMesh:

	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()


	var total_cells := resolution - 1


	var start_x := int(
		floor(
			float(chunk_x * total_cells) /
			float(chunks_per_axis)
		)
	)


	var end_x := int(
		floor(
			float((chunk_x + 1) * total_cells) /
			float(chunks_per_axis)
		)
	)


	var start_z := int(
		floor(
			float(chunk_z * total_cells) /
			float(chunks_per_axis)
		)
	)


	var end_z := int(
		floor(
			float((chunk_z + 1) * total_cells) /
			float(chunks_per_axis)
		)
	)


	var step := 1 << lod


	# ---------------------------------------------------------------
	# X samples
	# ---------------------------------------------------------------

	var x_samples: Array[int] = []

	var x := start_x

	while x <= end_x:

		x_samples.append(x)
		x += step


	if x_samples.is_empty() or x_samples.back() != end_x:
		x_samples.append(end_x)


	# ---------------------------------------------------------------
	# Z samples
	# ---------------------------------------------------------------

	var z_samples: Array[int] = []

	var z := start_z

	while z <= end_z:

		z_samples.append(z)
		z += step


	if z_samples.is_empty() or z_samples.back() != end_z:
		z_samples.append(end_z)


	# ---------------------------------------------------------------
	# Vertices
	# ---------------------------------------------------------------

	var inverse_resolution := (
		1.0 /
		float(resolution - 1)
	)


	for zi in z_samples:

		var world_z := world_z_values[zi]

		var uv_z := (
			float(zi) *
			inverse_resolution
		)


		for xi in x_samples:

			var world_x := world_x_values[xi]

			var uv_x := (
				float(xi) *
				inverse_resolution
			)


			var height_index := (
				zi * resolution +
				xi
			)


			var height := heights[
				height_index
			]


			vertices.append(
				Vector3(
					world_x,
					height,
					world_z
				)
			)


			# -------------------------------------------------------
			# Cached normal.
			#
			# This used to be calculated separately for every LOD.
			# -------------------------------------------------------

			normals.append(
				height_normals[
					height_index
				]
			)


			uvs.append(
				Vector2(
					uv_x,
					uv_z
				)
			)


			# -------------------------------------------------------
			# Cached island mask.
			# -------------------------------------------------------

			var island_mask := island_masks[
				height_index
			]


			var shoreline_mask := 0.0


			if shoreline_enabled:

				var distance_from_water = abs(
					height -
					water_level
				)


				shoreline_mask = 1.0 - smoothstep(
					0.0,
					max(
						shoreline_foam_width,
						0.001
					),
					distance_from_water
				)


				shoreline_mask *= island_mask


			var sand_mask := 1.0 - smoothstep(
				sand_height - sand_blend,
				sand_height + sand_blend,
				height
			)


			colors.append(
				Color(
					shoreline_mask,
					sand_mask,
					0.0,
					1.0
				)
			)


	# ---------------------------------------------------------------
	# Indices
	# ---------------------------------------------------------------

	var grid_width := x_samples.size()


	for z_index in range(
		z_samples.size() - 1
	):

		for x_index in range(
			x_samples.size() - 1
		):

			var i := (
				z_index *
				grid_width +
				x_index
			)


			var top_left := i
			var top_right := i + 1

			var bottom_left := (
				i +
				grid_width
			)

			var bottom_right := (
				i +
				grid_width +
				1
			)


			indices.append(top_left)
			indices.append(top_right)
			indices.append(bottom_left)


			indices.append(top_right)
			indices.append(bottom_right)
			indices.append(bottom_left)


	# ---------------------------------------------------------------
	# ArrayMesh
	# ---------------------------------------------------------------

	var arrays := []

	arrays.resize(
		Mesh.ARRAY_MAX
	)


	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices


	var generated_mesh := ArrayMesh.new()


	generated_mesh.add_surface_from_arrays(
		Mesh.PRIMITIVE_TRIANGLES,
		arrays
	)


	return generated_mesh


# =====================================================================
# COLLISION
# =====================================================================

func _generate_collision() -> void:

	var body := get_node_or_null(
		"StaticBody3D"
	) as StaticBody3D


	if body == null:

		push_error(
			"Terrain: StaticBody3D was not found. " +
			"Expected Terrain/StaticBody3D/CollisionShape3D."
		)

		return


	var collision := body.get_node_or_null(
		"CollisionShape3D"
	) as CollisionShape3D


	if collision == null:

		push_error(
			"Terrain: CollisionShape3D was not found."
		)

		return


	var height_shape := HeightMapShape3D.new()


	height_shape.map_width = resolution
	height_shape.map_depth = resolution


	var collision_data := PackedFloat32Array()

	collision_data.resize(
		heights.size()
	)


	var cell_size := (
		world_size /
		float(resolution - 1)
	)


	var inverse_cell_size = (
		1.0 /
		max(cell_size, 0.001)
	)


	for i in range(
		heights.size()
	):

		collision_data[i] = (
			heights[i] *
			inverse_cell_size
		)


	height_shape.map_data = collision_data

	collision.shape = height_shape

	collision.scale = Vector3(
		cell_size,
		cell_size,
		cell_size
	)

	collision.position = Vector3.ZERO


# =====================================================================
# MATERIAL
# =====================================================================

func _create_material() -> void:

	if terrain_material == null:

		terrain_material = ShaderMaterial.new()

		terrain_material.shader = TERRAIN_SHADER


	_update_material_parameters()


func _update_material_parameters() -> void:

	if terrain_material == null:
		return


	terrain_material.set_shader_parameter(
		"water_level",
		water_level
	)


	terrain_material.set_shader_parameter(
		"beach_height",
		water_level + beach_width
	)


	terrain_material.set_shader_parameter(
		"sand_height",
		sand_height
	)


	terrain_material.set_shader_parameter(
		"sand_blend",
		sand_blend
	)


	terrain_material.set_shader_parameter(
		"dirt_height",
		dirt_height
	)


	terrain_material.set_shader_parameter(
		"grass_height",
		grass_height
	)


	terrain_material.set_shader_parameter(
		"rock_height",
		rock_height
	)


	terrain_material.set_shader_parameter(
		"rock_slope_threshold",
		rock_slope_threshold
	)


	terrain_material.set_shader_parameter(
		"rock_slope_blend",
		rock_slope_blend
	)


	terrain_material.set_shader_parameter(
		"height_blend",
		height_blend
	)


	terrain_material.set_shader_parameter(
		"texture_scale",
		texture_scale
	)


	terrain_material.set_shader_parameter(
		"shoreline_enabled",
		shoreline_enabled
	)


	terrain_material.set_shader_parameter(
		"shoreline_foam_width",
		shoreline_foam_width
	)


	terrain_material.set_shader_parameter(
		"shoreline_foam_strength",
		shoreline_foam_strength
	)


	terrain_material.set_shader_parameter(
		"shoreline_foam_color",
		shoreline_foam_color
	)


	terrain_material.set_shader_parameter(
		"shoreline_foam_noise_strength",
		shoreline_foam_noise_strength
	)


	terrain_material.set_shader_parameter(
		"shoreline_foam_noise_scale",
		shoreline_foam_noise_scale
	)


	if sand_texture != null:

		terrain_material.set_shader_parameter(
			"sand_texture",
			sand_texture
		)


	if dirt_texture != null:

		terrain_material.set_shader_parameter(
			"dirt_texture",
			dirt_texture
		)


	if grass_texture != null:

		terrain_material.set_shader_parameter(
			"grass_texture",
			grass_texture
		)


	if rock_texture != null:

		terrain_material.set_shader_parameter(
			"rock_texture",
			rock_texture
		)


# =====================================================================
# LOD
# =====================================================================

func _update_chunk_lods() -> void:

	if chunk_records.is_empty():
		return


	var camera := lod_camera


	if camera == null:
		camera = get_viewport().get_camera_3d()


	if camera == null:
		return


	var camera_position := camera.global_position

	var generation_budget := lod_mesh_generation_budget


	for i in range(
		chunk_records.size()
	):

		var record := chunk_records[i]

		var chunk: MeshInstance3D = record["node"]


		if not is_instance_valid(chunk):
			continue


		var center: Vector3 = record["center"]


		var distance := Vector2(
			camera_position.x -
			center.x,

			camera_position.z -
			center.z
		).length()


		var lod := _get_lod_for_distance(
			distance
		)


		lod = clamp(
			lod,
			0,
			lod_levels - 1
		)


		var meshes: Array = record["meshes"]

		var target_mesh = meshes[lod]


		# -----------------------------------------------------------
		# Lazy LOD creation.
		# -----------------------------------------------------------

		if target_mesh == null:

			if generation_budget <= 0:
				continue

			target_mesh = _generate_chunk_mesh(
				int(
					i % chunks_per_axis
				),
				int(
					floor(
						float(i) /
						float(chunks_per_axis)
					)
				),
				lod
			)


			meshes[lod] = target_mesh

			record["meshes"] = meshes

			generation_budget -= 1


		if record["lod"] != lod:

			chunk.mesh = target_mesh

			record["lod"] = lod

			chunk_records[i] = record


# =====================================================================
# LOD DISTANCE
# =====================================================================

func _get_lod_for_distance(
	distance: float
) -> int:

	if distance < lod_distance_1:
		return 0


	if distance < lod_distance_2:

		return min(
			1,
			lod_levels - 1
		)


	if distance < lod_distance_3:

		return min(
			2,
			lod_levels - 1
		)


	return min(
		3,
		lod_levels - 1
	)
