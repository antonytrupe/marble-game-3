class_name Saw
extends RigidBody3D


static var scene: Resource = preload("res://src/saw/saw.tscn")


func get_object_verbs(subject_verbs: Array[String]) -> Array[Callable]:
	if subject_verbs.has("pick_up"):
		return [pick_up]
	return []


func get_subject_verbs() -> Array[Callable]:
	return [saw]


func pick_up(_hand: MarbleCharacter.INTERACT, _o: Array) -> Array:
	return [ self ]


func saw(_hand: MarbleCharacter.INTERACT, _o: Array) -> Array:
	return []


#don't reference @onready vars
func load_pre_ready(data: Dictionary) -> void:
	if "transform" in data:
		transform = str_to_var(data.transform)


func get_data() -> Dictionary:
	return {
		"name": name,
		"parent": str(get_parent().get_path()) if get_parent() else "",
		"scene_file_path": get_scene_file_path(),
		#"warp_speed": marble_item.warp_speed,
		#"age": marble_item.age.age,
		"transform": var_to_str(transform),
	}
