extends MeshInstance3D

@export var size: int = 512
@export var noise_seed: int = 1

var noise: FastNoiseLite = FastNoiseLite.new()
var st: SurfaceTool = SurfaceTool.new()

@onready var world: World = $/root/Game/World
@onready var navigation_region_3d: NavigationRegion3D = %NavigationRegion3D
#@onready var spring: Spring = $"../Spring"
#@onready var spring: Spring = %Spring

#const SPRING_SCENE: PackedScene = preload("res://src/spring/spring.tscn")


func _ready() -> void:
	randomize()
	noise.seed = noise_seed # randi()
	noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	noise.fractal_octaves = 3
	noise.domain_warp_fractal_lacunarity = 6.0
	position.x -= size / 2.0
	position.z -= size / 2.0
	generate_map()

	#var spring:Spring=SPRING_SCENE.instantiate()
	#world.add_child(spring)
	#spring.position.y=24
	#await spring.ready
	#await get_tree().physics_frame
	#spring.generate_downhill_path(spring.global_position)


func generate_map() -> void:
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for z: int in range(size + 1):
		for x: int in range(size + 1):
			var y: float = abs(noise.get_noise_2d(x, z)) * 32.0 - 10 + x * 0.05
			st.set_color(Color(0.0, 0.4, 0.0, 1.0))
			st.set_uv(Vector2(0, 0))
			st.add_vertex(Vector3(x, y, z))

	# 2. Define Triangles using Indices
	for z: int in range(size):
		for x: int in range(size):
			var vert: int = z * (size + 1) + x
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
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material_override = material

	var static_body: StaticBody3D = StaticBody3D.new()
	static_body.position = position
	static_body.set_collision_layer_value(1, true)


	var physics_material: PhysicsMaterial = PhysicsMaterial.new()
	physics_material.bounce = 0.0
	physics_material.absorbent = true
	physics_material.friction = 1.0
	static_body.physics_material_override = physics_material

	#add_child(static_body)
	var collision_shape: CollisionShape3D = CollisionShape3D.new()

	static_body.add_child(collision_shape)
	var shape: ConcavePolygonShape3D = mesh.create_trimesh_shape()
	collision_shape.shape = shape
	navigation_region_3d.add_child.call_deferred(static_body)

	navigation_region_3d.bake_navigation_mesh.call_deferred()
