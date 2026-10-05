@tool
extends MeshInstance3D

## Procedural island terrain generator.
##
## Scene hierarchy expected:
##
## Terrain (MeshInstance3D)
## └── StaticBody3D
##     └── CollisionShape3D
##
## The script automatically creates:
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
## The master heightmap is the source of truth for:
##   - terrain geometry
##   - terrain LODs
##   - terrain collision
##   - shoreline masks

const TERRAIN_SHADER = preload("res://Terrain/terrain_shader.gdshader")

# =====================================================================
# GENERAL
# =====================================================================

@export_category("General")

@export var generate_on_ready: bool = true

@export var seed: int = 12345:
	set(value):
		seed = value
		if is_inside_tree() and generate_on_ready:
			generate()

@export_range(33, 1025, 2)
var resolution: int = 257:
	set(value):
		# Keep resolution odd so terrain has a clear center.
		if value % 2 == 0:
			value += 1

		resolution = value

		if is_inside_tree() and generate_on_ready:
			generate()

@export var world_size: float = 400.0:
	set(value):
		world_size = max(value, 1.0)

		if is_inside_tree() and generate_on_ready:
			generate()


# =====================================================================
# TERRAIN CHUNKS / LOD
# =====================================================================

@export_category("Terrain Chunks & LOD")

## Number of chunks along each axis.
##
## 4 = 16 total chunks
## 8 = 64 total chunks
@export_range(1, 16, 1)
var chunks_per_axis: int = 4:
	set(value):
		chunks_per_axis = max(value, 1)

		if is_inside_tree() and generate_on_ready:
			generate()

## Number of LOD levels.
##
## LOD 0 = full resolution
## LOD 1 = every 2nd sample
## LOD 2 = every 4th sample
## LOD 3 = every 8th sample
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
var lod_update_interval: float = 0.15

## Adds a small vertical skirt around chunk edges.
##
## This helps hide tiny cracks between different LOD levels.
@export var lod_skirts_enabled: bool = true

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

		if is_inside_tree() and generate_on_ready:
			generate()


# =====================================================================
# ISLAND SHAPE
# =====================================================================

@export_category("Island Shape")

@export_range(0.1, 2.0, 0.01)
var island_width: float = 0.95:
	set(value):
		island_width = value

		if is_inside_tree() and generate_on_ready:
			generate()

@export_range(0.1, 2.0, 0.01)
var island_length: float = 0.75:
	set(value):
		island_length = value

		if is_inside_tree() and generate_on_ready:
			generate()

@export_range(0.0, 1.0, 0.01)
var coastline_start: float = 0.62:
	set(value):
		coastline_start = value

		if is_inside_tree() and generate_on_ready:
			generate()

@export_range(0.0, 0.5, 0.01)
var coastline_strength: float = 0.16:
	set(value):
		coastline_strength = value

		if is_inside_tree() and generate_on_ready:
			generate()


# =====================================================================
# TERRAIN NOISE
# =====================================================================

@export_category("Terrain Noise")

@export var terrain_frequency: float = 0.008:
	set(value):
		terrain_frequency = value

		if is_inside_tree() and generate_on_ready:
			generate()

@export_range(1, 8, 1)
var terrain_octaves: int = 5:
	set(value):
		terrain_octaves = value

		if is_inside_tree() and generate_on_ready:
			generate()

@export_range(0.0, 1.0, 0.01)
var terrain_detail_strength: float = 0.20:
	set(value):
		terrain_detail_strength = value

		if is_inside_tree() and generate_on_ready:
			generate()

@export var detail_frequency: float = 0.035:
	set(value):
		detail_frequency = value

		if is_inside_tree() and generate_on_ready:
			generate()


# =====================================================================
# EROSION-STYLE TERRAIN
# =====================================================================

@export_category("Erosion Style")

@export var erosion_enabled: bool = true:
	set(value):
		erosion_enabled = value

		if is_inside_tree() and generate_on_ready:
			generate()

## Overall erosion/ridge frequency.
@export var erosion_frequency: float = 0.018:
	set(value):
		erosion_frequency = value

		if is_inside_tree() and generate_on_ready:
			generate()

@export_range(1, 8, 1)
var erosion_octaves: int = 5:
	set(value):
		erosion_octaves = value

		if is_inside_tree() and generate_on_ready:
			generate()

@export_range(0.0, 2.0, 0.01)
var erosion_strength: float = 0.45:
	set(value):
		erosion_strength = value

		if is_inside_tree() and generate_on_ready:
			generate()

## Domain warp makes ridges bend and break up instead of looking
## like simple parallel noise ridges.
@export_range(0.0, 100.0, 0.5)
var erosion_warp_strength: float = 25.0:
	set(value):
		erosion_warp_strength = value

		if is_inside_tree() and generate_on_ready:
			generate()

@export var erosion_warp_frequency: float = 0.025:
	set(value):
		erosion_warp_frequency = value

		if is_inside_tree() and generate_on_ready:
			generate()

## Controls how aggressively low areas are carved into valleys.
@export_range(0.0, 2.0, 0.01)
var erosion_valley_strength: float = 0.45:
	set(value):
		erosion_valley_strength = value

		if is_inside_tree() and generate_on_ready:
			generate()


# =====================================================================
# MOUNTAINS
# =====================================================================

@export_category("Mountains")

@export var mountains_enabled: bool = true:
	set(value):
		mountains_enabled = value

		if is_inside_tree() and generate_on_ready:
			generate()

@export var mountain_center: Vector2 = Vector2(0.0, -15.0):
	set(value):
		mountain_center = value

		if is_inside_tree() and generate_on_ready:
			generate()

@export var mountain_radius: float = 140.0:
	set(value):
		mountain_radius = value

		if is_inside_tree() and generate_on_ready:
			generate()

@export var mountain_falloff: float = 0.7:
	set(value):
		mountain_falloff = value

		if is_inside_tree() and generate_on_ready:
			generate()

@export_range(0.0, 2.0, 0.01)
var mountain_strength: float = 1.0:
	set(value):
		mountain_strength = value

		if is_inside_tree() and generate_on_ready:
			generate()


# =====================================================================
# BEACH / SAND
# =====================================================================

@export_category("Beach & Sand")

## Original beach-width control.
@export var beach_width: float = 5.0:
	set(value):
		beach_width = value
		_update_material_parameters()

## NEW:
## Maximum terrain height at which sand can appear.
##
## Example:
##
## Water Level = 2
## Sand Height = 10
##
## Sand can therefore cover terrain from the shoreline to
## approximately 10 world units above the water.
@export var sand_height: float = 10.0:
	set(value):
		sand_height = max(value, water_level)

		_update_material_parameters()

## Controls how softly sand transitions into dirt.
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

## PNG / Texture2D inputs.
##
## These are intentionally back to the original workflow.
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

var terrain_noise: FastNoiseLite
var coastline_noise: FastNoiseLite
var detail_noise: FastNoiseLite
var mountain_noise: FastNoiseLite
var erosion_noise: FastNoiseLite

var terrain_material: ShaderMaterial

var chunks_root: Node3D

var chunk_records: Array[Dictionary] = []

var lod_timer: float = 0.0


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
# GENERATE
# =====================================================================

func generate() -> void:

	if resolution < 3:
		return

	if chunks_per_axis < 1:
		chunks_per_axis = 1

	_create_noise_generators()

	_generate_heightmap()

	_create_material()

	_generate_chunks()

	_generate_collision()

	_update_chunk_lods()


# =====================================================================
# NOISE
# =====================================================================

func _create_noise_generators() -> void:

	terrain_noise = FastNoiseLite.new()

	terrain_noise.seed = seed
	terrain_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	terrain_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	terrain_noise.fractal_octaves = terrain_octaves
	terrain_noise.frequency = terrain_frequency


	coastline_noise = FastNoiseLite.new()

	coastline_noise.seed = seed + 100
	coastline_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	coastline_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	coastline_noise.fractal_octaves = 3
	coastline_noise.frequency = 0.004


	detail_noise = FastNoiseLite.new()

	detail_noise.seed = seed + 200
	detail_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	detail_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	detail_noise.fractal_octaves = 3
	detail_noise.frequency = detail_frequency


	mountain_noise = FastNoiseLite.new()

	mountain_noise.seed = seed + 300
	mountain_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	mountain_noise.fractal_type = FastNoiseLite.FRACTAL_RIDGED
	mountain_noise.fractal_octaves = 5
	mountain_noise.frequency = 0.012


	# ---------------------------------------------------------------
	# EROSION
	# ---------------------------------------------------------------

	erosion_noise = FastNoiseLite.new()

	erosion_noise.seed = seed + 400
	erosion_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	erosion_noise.fractal_type = FastNoiseLite.FRACTAL_RIDGED
	erosion_noise.fractal_octaves = erosion_octaves
	erosion_noise.frequency = erosion_frequency

	erosion_noise.domain_warp_enabled = true
	erosion_noise.domain_warp_amplitude = erosion_warp_strength
	erosion_noise.domain_warp_frequency = erosion_warp_frequency
	erosion_noise.domain_warp_fractal_octaves = 3


# =====================================================================
# HEIGHTMAP
# =====================================================================

func _generate_heightmap() -> void:

	heights.resize(
		resolution * resolution
	)

	for z in range(resolution):

		for x in range(resolution):

			var uv_x := (
				float(x) /
				float(resolution - 1)
			)

			var uv_z := (
				float(z) /
				float(resolution - 1)
			)

			var world_x := (
				uv_x - 0.5
			) * world_size

			var world_z := (
				uv_z - 0.5
			) * world_size


			heights[
				z * resolution + x
			] = _calculate_height(
				world_x,
				world_z
			)


# =====================================================================
# HEIGHT CALCULATION
# =====================================================================

func _calculate_height(
	world_x: float,
	world_z: float
) -> float:

	var normalized_position := Vector2(
		world_x /
		(world_size * 0.5 * island_width),

		world_z /
		(world_size * 0.5 * island_length)
	)

	var distance := normalized_position.length()


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
		coastline_start *
		coastline_radius,

		coastline_radius,

		distance
	)

	island_mask = clamp(
		island_mask,
		0.0,
		1.0
	)


	# ---------------------------------------------------------------
	# Large terrain
	# ---------------------------------------------------------------

	var large_noise := terrain_noise.get_noise_2d(
		world_x,
		world_z
	)

	large_noise = (
		large_noise * 0.5 +
		0.5
	)

	large_noise = pow(
		large_noise,
		1.7
	)


	# ---------------------------------------------------------------
	# Detail
	# ---------------------------------------------------------------

	var detail := detail_noise.get_noise_2d(
		world_x,
		world_z
	)

	detail = (
		detail * 0.5 +
		0.5
	)


	var terrain_value = lerp(
		large_noise,
		detail,
		terrain_detail_strength
	)


	# ---------------------------------------------------------------
	# Erosion-style terrain
	# ---------------------------------------------------------------

	if erosion_enabled:

		var erosion_value := erosion_noise.get_noise_2d(
			world_x,
			world_z
		)

		erosion_value = (
			erosion_value * 0.5 +
			0.5
		)


		var ridges := erosion_value

		var valleys := 1.0 - erosion_value

		var valley_carve := (
			valleys *
			valleys *
			erosion_valley_strength
		)


		var erosion_result = clamp(
			ridges -
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


	# ---------------------------------------------------------------
	# Mountains
	# ---------------------------------------------------------------

	var mountain_mask := 0.0

	if mountains_enabled:

		var mountain_distance := Vector2(
			world_x,
			world_z
		).distance_to(
			mountain_center
		)


		mountain_mask = 1.0 - smoothstep(
			mountain_radius *
			mountain_falloff,

			mountain_radius,

			mountain_distance
		)


		mountain_mask = clamp(
			mountain_mask,
			0.0,
			1.0
		)


		var mountain_value := mountain_noise.get_noise_2d(
			world_x,
			world_z
		)

		mountain_value = (
			mountain_value * 0.5 +
			0.5
		)

		mountain_value = pow(
			mountain_value,
			1.15
		)


		terrain_value = lerp(
			terrain_value,

			max(
				terrain_value,
				mountain_value
			),

			mountain_mask *
			mountain_strength
		)


	# ---------------------------------------------------------------
	# Height
	# ---------------------------------------------------------------

	var terrain_height = (
		terrain_value *
		maximum_height
	)


	# ---------------------------------------------------------------
	# Flatten coast
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


	var meshes: Array[ArrayMesh] = []

	for lod in range(lod_levels):

		var chunk_mesh := _generate_chunk_mesh(
			chunk_x,
			chunk_z,
			lod
		)

		meshes.append(chunk_mesh)


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


	# ---------------------------------------------------------------
	# LOD sample spacing.
	# ---------------------------------------------------------------

	var step := 1 << lod


	# ---------------------------------------------------------------
	# Build X sample positions.
	# Always include the chunk boundary.
	# ---------------------------------------------------------------

	var x_samples: Array[int] = []

	var x := start_x

	while x <= end_x:

		x_samples.append(x)

		x += step


	if x_samples.is_empty() or x_samples.back() != end_x:
		x_samples.append(end_x)


	# ---------------------------------------------------------------
	# Build Z sample positions.
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

	for zi in z_samples:

		for xi in x_samples:

			var height_index := (
				zi * resolution +
				xi
			)


			var uv_x := (
				float(xi) /
				float(resolution - 1)
			)

			var uv_z := (
				float(zi) /
				float(resolution - 1)
			)


			var world_x := (
				uv_x - 0.5
			) * world_size

			var world_z := (
				uv_z - 0.5
			) * world_size


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


			normals.append(
				_calculate_normal(
					xi,
					zi
				)
			)


			uvs.append(
				Vector2(
					uv_x,
					uv_z
				)
			)


			# -------------------------------------------------------
			# Vertex color:
			#
			# R = shoreline mask
			# G = beach/sand mask
			# B = unused
			# A = 1
			# -------------------------------------------------------

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


				shoreline_mask *= _get_island_mask(
					world_x,
					world_z
				)


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
# NORMAL
# =====================================================================

func _calculate_normal(
	x: int,
	z: int
) -> Vector3:

	var left_x = max(
		x - 1,
		0
	)

	var right_x = min(
		x + 1,
		resolution - 1
	)


	var up_z = max(
		z - 1,
		0
	)

	var down_z = min(
		z + 1,
		resolution - 1
	)


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


	var cell_size := (
		world_size /
		float(resolution - 1)
	)


	var dx := (
		right_height -
		left_height
	)

	var dz := (
		down_height -
		up_height
	)


	return Vector3(
		-dx / max(cell_size, 0.001),
		2.0,
		-dz / max(cell_size, 0.001)
	).normalized()


# =====================================================================
# ISLAND MASK
# =====================================================================

func _get_island_mask(
	world_x: float,
	world_z: float
) -> float:

	var normalized_position := Vector2(
		world_x /
		(world_size * 0.5 * island_width),

		world_z /
		(world_size * 0.5 * island_length)
	)


	var distance := normalized_position.length()


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
# COLLISION
# =====================================================================

func _generate_collision() -> void:

	# ---------------------------------------------------------------
	# IMPORTANT:
	#
	# We deliberately use the user's existing collision hierarchy.
	#
	# Terrain
	# └── StaticBody3D
	#     └── CollisionShape3D
	# ---------------------------------------------------------------

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


	# ---------------------------------------------------------------
	# Preserve the same collision conversion used by the original
	# working implementation.
	# ---------------------------------------------------------------

	var cell_size := (
		world_size /
		float(resolution - 1)
	)


	for i in range(
		heights.size()
	):

		collision_data[i] = (
			heights[i] /
			cell_size
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


		if record["lod"] != lod:

			var meshes: Array = record["meshes"]

			chunk.mesh = meshes[lod]

			record["lod"] = lod

			chunk_records[i] = record


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
