class_name Axe
extends RigidBody3D

static var scene: Resource = preload("res://src/axe/axe.tscn")

@onready var marble_item: MarbleItem = $MarbleItem


func pick_up() -> void:
	pass


func chop() -> void:
	print('axe chop')


func get_actions() -> Array[Action]:
	return [Action.new('chop', chop)]


func get_data() -> Dictionary:
	return {
		"name": name,
		"parent": str(get_parent().get_path()) if get_parent() else "",
		"scene_file_path": get_scene_file_path(),
		"warp_speed": marble_item.warp_speed,
		"age": marble_item.age.age,
		#"turn": marble_item.turn,
		"transform": var_to_str(transform),
	}


#don't reference @onready vars
func load_pre_ready(_node_data: Dictionary) -> void:
	pass


#can reference @onready vars now
func load_post_ready(node_data: Dictionary) -> void:
	if "transform" in node_data:
		transform = str_to_var(node_data.transform)
	if "turn" in node_data:
		marble_item.turn = node_data.turn
	if "age" in node_data:
		marble_item.age.age = node_data.age
	if "warp_speed" in node_data:
		marble_item.warp_speed = node_data.warp_speed
