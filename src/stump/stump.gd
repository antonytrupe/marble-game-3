class_name Stump
extends RigidBody3D

static var scene: Resource = preload("res://src/stump/stump.tscn")
@export var maturity: int = MarbleAge.SECONDS_IN_YEAR * 8

@onready var age: MarbleAge = %MarbleAge


func get_data() -> Dictionary:
	var save_dict: Dictionary = {
		"name": name,
		"parent": str(get_parent().get_path()) if get_parent() else "",
		"scene_file_path": get_scene_file_path(),
		"transform": var_to_str(transform),
		"age": age.age,
	}
	return save_dict


func load_pre_ready(data: Dictionary) -> void:
	if "transform" in data:
		transform = str_to_var(data.transform)


func load_post_ready(data: Dictionary) -> void:
	if "age" in data:
		age.age = data.age
