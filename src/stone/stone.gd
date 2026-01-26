class_name Stone
extends RigidBody3D


#@export var birth_date: int = 0:
	#set = set_birth_date
#@export var extra_age: int = 0:
	#set = set_extra_age

var brittleness: float
var hardness: float
var sharpness: float
#var mass:float
var volume: float

@onready var world: World = $/root/Game/World

static var category: String = "Stone"

@export var age: float = Time.get_unix_time_from_system()
@export var warp_speed: int = 1
	#set = _set_warp_speed

#var calculated_age: int:
	#get = calculate_age


func _ready() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	brittleness = rng.randi_range(1, 100)
	hardness = rng.randi_range(1, 100)


func _process(delta: float) -> void:
	age += delta * warp_speed

func craft(player: MarbleCharacter, loot: Dictionary) -> Dictionary:
	#print('%s stone crafting' % player.name, self)
	var result: Dictionary = {}
	for item_name: String in loot.keys():
		var item:Node = player.inventory[item_name]
		#print(item)
		if item.category == "Stone":
			if item.hardness < hardness:
				print("old sharpness:", item.sharpness)
				item.sharpness += (item.brittleness / 100.0) * (hardness / 100.0)
				print("new sharpness:", item.sharpness)
				player.skillup('knapping', 1)
			elif item.hardness > hardness:
				print('break tool')
		result[item.name] = item
	return result


func pick_up() -> Dictionary:
	hide()
	queue_free()

	var d: Dictionary = save_node()
	d.erase('transform')

	return {d.name: d}


func get_actions() -> Array:
	print(get_parent().get_class())
	var actions: Array = []
	if get_parent().name == 'Terra':
		actions.append('pick_up')
	elif get_parent().is_class('MarbleCharacter'):
		actions.append('knap')
	return actions


#func set_birth_date(value):
	#birth_date = value
#
#
#func set_extra_age(value):
	#extra_age = value


#func calculate_age():
	#return world.world_age + extra_age + Time.get_ticks_msec() - birth_date


func toDictionary() -> Dictionary:
	return save_node()


func save_node() -> Dictionary:
	var save_dict: Dictionary = {
		transform = var_to_str(transform),
		#birth_date = birth_date,
		age = age,
		warp_speed = warp_speed,
		name = name,
		category = category,
		"class" = get_class(),
		scene_file_path = get_scene_file_path(),
		hardness = hardness,
		sharpness = sharpness,
		brittleness = brittleness,

	}
	if get_parent():
		save_dict.parent = get_parent().get_path()
	return save_dict


func load_node(node_data: Dictionary) -> void:
	if node_data.has("transform"):
		transform = str_to_var(node_data["transform"])
	for p: String in node_data:
		if p in self and p not in ['transform']:
			self[p] = node_data[p]
