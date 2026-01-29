class_name Axe
extends RigidBody3D

@onready var marble_item: MarbleItem = $MarbleItem


func pick_up()->void:
	pass

func get_data() -> Dictionary:
	return {
		"name": name,
		"warp_speed": marble_item.warp_speed,
		"age": marble_item.age.age,
		#"turn": marble_item.turn,
		"transform": var_to_str(transform),
	}


func get_actions()->Array:
	return ['chop']


#don't reference @onready vars
func load_pre_ready(node_data: Dictionary) -> void:
	pass


#can reference @onready vars now
func load_post_ready(node_data: Dictionary) -> void:
	#transform = str_to_var(node_data["transform"])
	if "transform" in node_data:
		transform = str_to_var(node_data.transform)
	if "turn" in node_data:
		marble_item.turn = node_data.turn
	if "age" in node_data:
		marble_item.age.age = node_data.age
	if "warp_speed" in node_data:
		marble_item.warp_speed = node_data.warp_speed
