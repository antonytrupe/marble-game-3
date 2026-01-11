class_name World
extends Node3D

@onready var characters = %Characters
@onready var flora: Node = %Flora
@onready var fauna: Node3D = %Fauna
@onready var terra = %Terra
@onready var warp_monuments: Node = %WarpMonuments


func _ready() -> void:
	pass


func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		print("world quit")


func get_ground_y(x: float, z: float) -> float:
	var space_state = get_world_3d().direct_space_state
	var origin = Vector3(x, 100, z) # Start high up
	var end = Vector3(x, -100, z) # Point down
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	query.collision_mask = 1
	var result = space_state.intersect_ray(query)
	if result:
		return result.position.y
	return 0.0 # Default if nothing hit

func underworld_raiser(nodes: Array[Node]):
#	warp monuments
	for n: Node3D in nodes:
		var y = get_ground_y(n.position.x, n.position.z)
		#print("%s y:%s" % [n.name, y])
		n.position.y = y
