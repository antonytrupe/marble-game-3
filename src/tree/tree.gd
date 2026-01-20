#@tool
class_name MarbleTree
extends Node3D

const APPLE_SCENE = preload("res://src/apple/apple.tscn")

@export var maturity: int = MarbleAge.SECONDS_IN_YEAR * 8
@export var warp_speed: float = 1

var turn = 0

@onready var age: MarbleAge = $MarbleAge
@onready var warp_detector: WarpDetector = $WarpDetectorArea3D
@onready var label_3d: Label3D = $Label3D
@onready var left_leaves: MeshInstance3D = $Trunk/LeftLeaves
@onready var flora = $/root/Game/World/Flora

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	#print('tool')
	#age.age += _delta * warp_speed
	var r = float(age.age) / float(maturity)
	var s = clampf(r, .01, 1.0)
	scale = Vector3(s, s, s)
	label_3d.text = "Age:%.f\nWarp:%.f\nScale:%.2f" % [age.age, warp_speed, scale.x]


#delta is in seconds
func _physics_process(delta: float):
	if is_server():
		age.age += delta * warp_speed
		@warning_ignore("narrowing_conversion")
		var new_turn: int = age.age / MarbleAge.SECONDS_IN_TURN + 1
		_start_turn(range(self.turn + 1, new_turn + 1))
		self.turn = new_turn


func _start_turn(_turns):
	#print('starting turn %.f'%turn)
	#if the tree mature, then it can grow apples
	if age.age > maturity:
		#apples start growing in March
		if age.get_month() == 0:
			var i = randi_range(1, 800)
			if i == 1:
				#pass
				_add_apple()


func _add_apple():
	#print("add apple")
	var x = - abs(randfn(0, 1))
	var y = randfn(0, 1)
	var z = randfn(0, 1)
	var l = sqrt(x * x + y * y + z * z)
	var apple: Apple = APPLE_SCENE.instantiate()
	apple.name = apple.name + "%010d" % randi()
	#apple.position = Vector3(x / l, y / l, z / l) * 3
	#print(apple.position)
	apple.position = left_leaves.global_position + Vector3(x / l, y / l, z / l) * 3
	#left_leaves.add_child(apple)
	flora.add_child(apple)


func is_server() -> bool:
	return multiplayer.is_server()


func get_data():
	var save_dict = {
		"transform": var_to_str(transform),
		"age": age.age,
		"turn": turn,
		"warp_speed": warp_speed,
	}
	return save_dict


func load_node(node_data):
	#transform = str_to_var(node_data["transform"])
	if "age" in node_data:
		age.age = node_data.age
	if "warp_speed" in node_data:
		warp_speed = node_data.warp_speed
	if "turn" in node_data:
		turn = node_data.turn


func calculate_warp():
	var closest: WarpMonument = null
	#var closest_distance=0
	for w: WarpMonument in warp_detector.warp_monuments.values():
		var distance = w.position.distance_to(position)
		if !closest or distance < closest.position.distance_to(position):
			closest = w
			#closest_distance=distance
	if closest:
		warp_speed = closest.warp_speed
	else:
		warp_speed = 1
