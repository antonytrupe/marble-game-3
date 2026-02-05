class_name Stump
extends RigidBody3D

static var scene: Resource = preload("res://src/stump/stump.tscn")
#@export var maturity: int = MarbleAge.SECONDS_IN_YEAR * 8
@export var stump_scale:float=1
#@onready var age: MarbleAge = %MarbleAge
@onready var collision_shape_3d: CollisionShape3D = %CollisionShape3D
@onready var mesh_instance_3d: MeshInstance3D = %MeshInstance3D

func _ready()->void:
	var s: float = clampf(stump_scale, .01, 1.0)
	#TODO don't scale the collisionbody
	#mesh_instance_3d.scale = Vector3(s, s, s)
	#collision_shape_3d.scale=Vector3(s, s, s)
	scale = Vector3(s, s, s)

func get_data() -> Dictionary:
	var save_dict: Dictionary = {
		"name": name,
		"parent": str(get_parent().get_path()) if get_parent() else "",
		"scene_file_path": get_scene_file_path(),
		"transform": var_to_str(transform),
		#"age": age.age,
		"stump_scale":stump_scale
	}
	return save_dict


func load_pre_ready(data: Dictionary) -> void:
	if "transform" in data:
		transform = str_to_var(data.transform)
	if "stump_scale" in data:
		stump_scale = data.stump_scale


func load_post_ready(_data: Dictionary) -> void:
	pass
	#if "age" in data:
		#age.age = data.age
