class_name Trinket
extends RigidBody3D

static var scene: Resource = preload("res://src/trinket/trinket.tscn")

@export_range(1, 100, 1, "or_greater") var value: float = 1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass  # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


#region interactions
func get_subject_verbs() -> Array[Callable]:
	return [transfer]


func transfer(_hand: MarbleCharacter.INTERACT, _o: Array) -> bool:
	return true


func get_object_verbs(subject_verbs: Array[String]) -> Array[Callable]:
	var verbs: Array[Callable] = []
	if subject_verbs.has("pick_up"):
		verbs.append(pick_up)
	return verbs

func pick_up(_hand: MarbleCharacter.INTERACT, _o: Array) -> Array:
	return [self]

#endregion

#region persistance functions
func get_data() -> Dictionary:
	return {
		"name": name,
		"parent": str(get_parent().get_path()) if get_parent() else "",
		"scene_file_path": get_scene_file_path(),
		"transform": var_to_str(transform),
	}


#don't reference @onready vars
func load_pre_ready(data: Dictionary) -> void:
	if "transform" in data:
		transform = str_to_var(data.transform)


#can reference @onready vars now
func load_post_ready(data: Dictionary) -> void:
	pass

	#endregion
