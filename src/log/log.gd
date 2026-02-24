class_name MarbleLog
extends RigidBody3D

static var scene: Resource = preload("res://src/log/log.tscn")
@export var log_scale: float = 1
#@export var warp_speed: float = 1

#var turn:int=0

#@onready var age: MarbleAge = $MarbleAge
@onready var mesh_instance_3d: MeshInstance3D = %MeshInstance3D
@onready var collision_shape_3d: CollisionShape3D = %CollisionShape3D
@onready var server: Server = $/root/Game/Server


func debug(...args: Array) -> void:
	Debug.debug.emit(args)


func _ready() -> void:
	await get_tree().physics_frame

	var s: float = clampf(log_scale, .01, 1.0)
	#TODO don't scale the collisionbody
	scale = Vector3(s, s, s)
	#mesh_instance_3d.scale = Vector3(s, s, s)
	#collision_shape_3d.scale=Vector3(s, s, s)

	# Get the cylinder's local Y axis in world space
	var local_up: Vector3 = global_transform.basis.y.normalized()

	# Compare it to the world's up vector (Vector3.UP is 0, 1, 0)
	var alignment: float = local_up.dot(Vector3.UP)

	if alignment > 0.99:
		print("The cylinder is vertical!")
		freeze = false
		apply_impulse(Vector3(randi_range(-100, 100), 0, randi_range(-100, 100)).normalized() * 1000, Vector3(0, 8, 0))
	elif alignment < 0.1:
		print("The cylinder has fallen over.")


func get_object_verbs(subject_verbs: Array[String]) -> Array[Callable]:
	var verbs: Array[Callable] = []
	if subject_verbs.has("saw"):
		verbs.append(saw)
	if subject_verbs.has("pick_up"):
		verbs.append(pick_up)
	return verbs


func pick_up(_hand: MarbleCharacter.INTERACT, _o: Array) -> Array:
	return [ self ]


func saw(_hand: MarbleCharacter.INTERACT, _o: Array) -> Array:
	debug('log saw')
	server.spawn_cant(transform, scale.x)
	queue_free()
	Persistance.delete.emit(self )
	return []


func is_server() -> bool:
	return multiplayer.is_server()


func get_data() -> Dictionary:
	var data: Dictionary = {
		"name": name,
		"parent": str(get_parent().get_path()) if get_parent() else "",
		"scene_file_path": get_scene_file_path(),
		"transform": var_to_str(transform),
		#"age": age.age,
		"log_scale": log_scale
	}
	return data


func load_pre_ready(data: Dictionary) -> void:
	if "transform" in data:
		transform = str_to_var(data.transform)
	if "log_scale" in data:
		log_scale = log_scale

func load_post_ready(_data: Dictionary) -> void:
	pass
	#if "age" in data:
		#age.age = data.age
