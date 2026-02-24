class_name Cant
extends RigidBody3D

static var scene: Resource = preload("res://src/cant/cant.tscn")

@onready var server: Server = $/root/Game/Server

func debug(...args: Array) -> void:
	Debug.debug.emit(args)


func pick_up(_hand: MarbleCharacter.INTERACT, _o: Array) -> Array:
	return [ self ]


func get_object_verbs(subject_verbs: Array[String]) -> Array[Callable]:
	var verbs: Array[Callable] = []
	if subject_verbs.has("saw"):
		verbs.append(saw)
	if subject_verbs.has("pick_up"):
		verbs.append(pick_up)
	return verbs


func saw(_hand: MarbleCharacter.INTERACT, _o: Array) -> Array:
	debug('log saw')
	server.spawn_board(transform, scale.x)
	queue_free()
	Persistance.delete.emit(self )
	return []


func load_pre_ready(data: Dictionary) -> void:
	if "transform" in data:
		transform = str_to_var(data.transform)


func get_data() -> Dictionary:
	var data: Dictionary = {
		"name": name,
		"parent": str(get_parent().get_path()) if get_parent() else "",
		"scene_file_path": get_scene_file_path(),
		"transform": var_to_str(transform),
		#"age": age.age,
		#"log_scale":log_scale
	}
	return data
