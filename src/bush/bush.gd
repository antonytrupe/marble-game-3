class_name MarbleBush
extends Node3D

#10 years
@export var maturity: int = int(1000 * 60 * 60 * 24 * 360 * (10))

@export var berries :int= 9:
	set(value):
		berries = value
		setup()


##milliseconds
@export var age: float = 0
@export var warp_speed: float = 1

@onready var world :World= $/root/Game/World
#@onready var ageLabel = %AgeLabel

#var rng = RandomNumberGenerator.new()

@onready var b:Array = [
	$BushMeshInstance3D/BerryMeshInstance3D1,
	$BushMeshInstance3D/BerryMeshInstance3D2,
	$BushMeshInstance3D/BerryMeshInstance3D3,
	$BushMeshInstance3D/BerryMeshInstance3D4,
	$BushMeshInstance3D/BerryMeshInstance3D5,
	$BushMeshInstance3D/BerryMeshInstance3D6,
	$BushMeshInstance3D/BerryMeshInstance3D7,
	$BushMeshInstance3D/BerryMeshInstance3D8,
	$BushMeshInstance3D/BerryMeshInstance3D9,
]


func get_actions()->Array:
	return ["pick_berry"]


#func set_birth_date(value):
	#birth_date = value


#func set_extra_age(value):
	#extra_age = value
#
#
#func calculate_age():
	#return world.world_age + extra_age + Time.get_ticks_msec() - birth_date


func save_node()->Dictionary:
	var save_dict:Dictionary = {
		"transform": var_to_str(transform),
		"age": age,
		#"extra_age": extra_age,
	}
	return save_dict


func load_node(node_data:Dictionary)->void:
	transform = str_to_var(node_data["transform"])
	if "age" in node_data:
		age = node_data.age
	#if "extra_age" in node_data:
		#extra_age = node_data.extra_age


func pick_berry()->Dictionary:
	if berries:
		b[berries - 1].hide()
		berries = berries - 1
		#print(GlobalRandom.Items.berry)
		var a :Dictionary= {berry = {}}
		a.berry.quantity = 1
		#print(a)
		return a
	# else:
	return {}


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	setup()


func setup()->void:
	for i:int in range(0, 9):
		if i < berries and b:
			b[i].show()
		else:
			if b:
				b[i].hide()


func _process(_delta:float)->void:
	var s :float= clampf(float(age) / maturity, .1, 1.0)
	scale = Vector3(s, s, s)

	if multiplayer.is_server():
		if berries < 9:
			if randi_range(0, 1000) <= 1:
				print("spawn a berry")
				berries = berries + 1
