class_name Board
extends RigidBody3D

static var scene: Resource = preload("res://src/board/board.tscn")

@onready var server: Server = $/root/Game/Server


func get_object_verbs(subject_verbs: Array) -> Array[Callable]:
	var verbs: Array[Callable] = []
	if subject_verbs.has("pick_up"):
		verbs.append(pick_up)
	return verbs


func pick_up(_hand: MarbleCharacter.INTERACT, _o: Array) -> Array:
	return [ self ]


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
