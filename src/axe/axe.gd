class_name Axe
extends RigidBody3D

static var scene: Resource = preload("res://src/axe/axe.tscn")

@onready var marble_item: MarbleItem = $MarbleItem


func pick_up(_hand: MarbleCharacter.INTERACT, _o: Array) -> Array:
	return [self]


func chop(_hand: MarbleCharacter.INTERACT, _o: Array) -> Array:
	return []

func transfer(_hand: MarbleCharacter.INTERACT, _o: Array) -> bool:
	return true


func get_object_verbs(subject_verbs: Array[String]) -> Array[Callable]:
	if subject_verbs.has("pick_up"):
		return [pick_up]
	return []


func get_subject_verbs() -> Array[Callable]:
	return [chop,transfer]


func get_data() -> Dictionary:
	return {
		"name": name,
		"parent": str(get_parent().get_path()) if get_parent() else "",
		"scene_file_path": get_scene_file_path(),
		"warp_speed": marble_item.warp_speed,
		"age": marble_item.age.age,
		"transform": var_to_str(transform),
	}


#don't reference @onready vars
func load_pre_ready(data: Dictionary) -> void:
	if "transform" in data:
		transform = str_to_var(data.transform)


#can reference @onready vars now
func load_post_ready(data: Dictionary) -> void:
	if "turn" in data:
		marble_item.turn = data.turn
	if "age" in data:
		marble_item.age.age = data.age
	if "warp_speed" in data:
		marble_item.warp_speed = data.warp_speed
