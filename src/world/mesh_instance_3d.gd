#@tool
extends MeshInstance3D

@onready var world: World = $".."

@export var size := 512
var noise := FastNoiseLite.new()
var st := SurfaceTool.new()

func _ready() -> void:
	randomize()
	noise.seed = 1 # randi()
	noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	noise.fractal_octaves = 3
	noise.domain_warp_fractal_lacunarity = 6.0
	position.x -= size / 2.0
	position.z -= size / 2.0
	generateMap()

func generateMap() -> void:
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for z in range(size + 1):
		for x in range(size + 1):
			var y: float = abs(noise.get_noise_2d(x, z)) * 32.0 - 10
			st.set_color(Color(0.0, 0.4, 0.0, 1.0))
			st.set_uv(Vector2(0, 0))
			st.add_vertex(Vector3(x, y, z))

	# 2. Define Triangles using Indices
	for z in range(size):
		for x in range(size):
			var vert = z * (size + 1) + x
			st.add_index(vert)
			st.add_index(vert + 1)
			st.add_index(vert + size + 1)

			st.add_index(vert + 1)
			st.add_index(vert + size + 2)
			st.add_index(vert + size + 1)

	# 3. Commit to Mesh
	st.generate_normals()
	st.generate_tangents()

	mesh = st.commit()
	# IMPORTANT: You MUST tell the material to use these colors
	var material = StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material_override = material

	create_trimesh_collision()
