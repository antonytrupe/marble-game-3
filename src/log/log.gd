class_name MarbleLog
extends RigidBody3D

static var scene: Resource = preload("res://src/log/log.tscn")

@onready var age: MarbleAge = $MarbleAge


func _ready() -> void:
	await get_tree().physics_frame

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


func get_data() -> Dictionary:
	var data: Dictionary = {
		"name": name,
		"parent": str(get_parent().get_path()) if get_parent() else "",
		"scene_file_path": get_scene_file_path(),
		"transform": var_to_str(transform),
		"age": age.age,
	}
	return data


func load_pre_ready(data: Dictionary) -> void:
	if "transform" in data:
		transform = str_to_var(data.transform)


func load_post_ready(data: Dictionary) -> void:
	if "age" in data:
		age.age = data.age
