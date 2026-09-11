extends MeshInstance3D


const depth := 4


func _ready() -> void:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()

	var heights: PackedFloat32Array = [
		0, 0, 0, 0,
		0, 1, 1, 0,
		0, 1, 1, 0,
		0, 0, 0, 0
	]

	# Create vertices and UVs
	for z in range(depth):
		for x in range(depth):
			var index := z * depth + x
			var y := heights[index]

			vertices.append(Vector3(x, y, z))

			uvs.append(Vector2(
				float(x) / float(depth - 1),
				float(z) / float(depth - 1)
			))

			normals.append(Vector3.ZERO)

	# Create triangles
	for z in range(depth - 1):
		for x in range(depth - 1):
			var top_left := z * depth + x
			var top_right := top_left + 1
			var bottom_left := (z + 1) * depth + x
			var bottom_right := bottom_left + 1

			# Winding order is important.
			# These triangles face upward (+Y).

			# Triangle 1
			add_triangle(
				top_left,
				bottom_left,
				top_right,
				vertices,
				normals,
				indices
			)

			# Triangle 2
			add_triangle(
				top_right,
				bottom_left,
				bottom_right,
				vertices,
				normals,
				indices
			)


	# Normalize all vertex normals
	for i in range(normals.size()):
		normals[i] = normals[i].normalized()

	# Build mesh
	var mesh_data := []
	mesh_data.resize(ArrayMesh.ARRAY_MAX)

	mesh_data[ArrayMesh.ARRAY_VERTEX] = vertices
	mesh_data[ArrayMesh.ARRAY_NORMAL] = normals
	mesh_data[ArrayMesh.ARRAY_TEX_UV] = uvs
	mesh_data[ArrayMesh.ARRAY_INDEX] = indices

	var array_mesh := ArrayMesh.new()

	array_mesh.add_surface_from_arrays(
		Mesh.PRIMITIVE_TRIANGLES,
		mesh_data
	)

	mesh = array_mesh


func add_triangle(
	a: int,
	b: int,
	c: int,
	vertices: PackedVector3Array,
	normals: PackedVector3Array,
	indices: PackedInt32Array
) -> void:

	indices.append(a)
	indices.append(b)
	indices.append(c)

	var edge_1 := vertices[b] - vertices[a]
	var edge_2 := vertices[c] - vertices[a]

	var normal := edge_2.cross(edge_1).normalized()

	normals[a] += normal
	normals[b] += normal
	normals[c] += normal


func _process(delta: float) -> void:
	pass
