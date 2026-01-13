class_name MarbleTree
extends StaticBody3D

const APPLE_SCENE = preload("res://src/apple/apple.tscn")

@export var maturity: int = int(60 * 60 * 24 * 360 * (8))
@export var age: MarbleAge = MarbleAge.new()
@export var warp_speed: float = 1
var turn = 0
@onready var warp_detector: WarpDetector = $WarpDetectorArea3D
@onready var label_3d: Label3D = $Label3D


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	var r = float(age.age) / float(maturity)
	var s = clampf(r, .001, 1.0)
	scale = Vector3(s, s, s)
	label_3d.text = "Age:%.f\nWarp:%.f\nScale:%.2f" % [age.age, warp_speed, scale.x]


#delta is in seconds
func _physics_process(delta: float):
	if is_server():
		age.age += delta * warp_speed
	var _turn: int = age.age / 6 + 1
	for i in range(self.turn, _turn):
		_start_turn(i)
	self.turn = _turn


func _start_turn(_turn):
	#print('starting turn %.f'%turn)
	#if the tree mature, then it can grow apples
	if age.age > maturity:
		#apples start growing in March
		if age.get_month() == 0:
			var i = randi_range(1, 200)
			if i == 1:
				print("add apple")
				_add_apple()


func _add_apple():
	var x = randf()
	var y = randf()
	var z = randf()
	var l = sqrt(x * x + y * y + z * z)
	var apple: Apple = APPLE_SCENE.instantiate()
	apple.position = Vector3(x / l, y / l, z / l)

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
