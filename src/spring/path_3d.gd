class_name Spring
extends Node3D

@export_group("Path Settings")
@export var max_points: int = 50
@export var step_distance: float = .5
@export var search_radius: float = 4.0
@export var terrain_mask: int = 1 # Match your ground's collision layer

@onready var path_3d: Path3D = %Path3D

func _ready() -> void:
	# We wait for the physics frame to ensure the terrain is loaded
	# and collision data is ready for raycasting.
	await get_tree().physics_frame
	generate_downhill_path.call_deferred(position)

func generate_downhill_path(start_pos: Vector3) -> void:
	if not path_3d:
		return

	var curve: Curve3D = Curve3D.new()
	curve.up_vector_enabled = true

	var current_pos: Vector3 = start_pos

	# Initial point setup
	var initial_data: Dictionary = find_lowest_neighbor(current_pos)
	add_path_point(curve, current_pos, initial_data.normal)

	for i: int in range(max_points):
		var data: Dictionary = find_lowest_neighbor(current_pos)
		var next_pos: Vector3 = data.position
		var next_normal: Vector3 = data.normal

		# Stop if we hit a flat area or a 'pit' (next point isn't lower)
		if next_pos.is_equal_approx(current_pos) or next_pos.y >= current_pos.y:
			break

		current_pos = next_pos
		add_path_point(curve, current_pos, next_normal)

	path_3d.curve = curve

func add_path_point(curve: Curve3D, global_pos: Vector3, normal: Vector3) -> void:
	var local_pos: Vector3 = to_local(global_pos)
	curve.add_point(local_pos)

	# TILT: Align the path's 'up' with the terrain's surface normal
	var point_idx: int = curve.point_count - 1
	var tilt_angle: float = Vector3.UP.signed_angle_to(normal, Vector3.FORWARD)
	curve.set_point_tilt(point_idx, tilt_angle)

func find_lowest_neighbor(origin: Vector3) -> Dictionary:
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var lowest_point: Vector3 = origin
	var lowest_y: float = origin.y
	var surface_normal: Vector3 = Vector3.UP

	# Sample 8 points in a circle to find the steepest descent
	for i: int in range(8):
		var angle: float = i * (PI / 4.0)
		var dir: Vector3 = Vector3(cos(angle), 0, sin(angle))
		var check_pos: Vector3 = origin + (dir * search_radius)

		# Raycast down to find the ground height at this neighbor
		var ray_start: Vector3 = check_pos + Vector3.UP * 10.0
		var ray_end: Vector3 = check_pos + Vector3.DOWN * 40.0
		var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(ray_start, ray_end, 1 << (terrain_mask - 1))
		var result: Dictionary = space_state.intersect_ray(query)

		if result:
			var hit_pos: Vector3 = result.position
			if hit_pos.y < lowest_y:
				lowest_y = hit_pos.y
				lowest_point = hit_pos
				surface_normal = result.normal

	return {"position": lowest_point, "normal": surface_normal}
