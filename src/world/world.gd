class_name World
extends Node3D

@onready var characters: Node = %Characters
@onready var flora: Node = %Flora
@onready var fauna: Node = %Fauna
@onready var terra: Node = %Terra
@onready var warp_monuments: Node = %WarpMonuments


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		print("world quit")


func get_ground_y(x: float, z: float) -> float:
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var origin: Vector3 = Vector3(x, 100, z) # Start high up
	var end: Vector3 = Vector3(x, -100, z) # Point down
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(origin, end)
	query.collision_mask = 1
	var result: Dictionary = space_state.intersect_ray(query)
	if result:
		return result.position.y
	return 0.0 # Default if nothing hit


func underworld_raiser(nodes: Array[Node]) -> void:
#	warp monuments
	for n: Node3D in nodes:
		var y: float = get_ground_y(n.position.x, n.position.z)
		#print("%s y:%s" % [n.name, y])
		n.position.y = y
