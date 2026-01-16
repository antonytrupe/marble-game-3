#@tool
class_name Apple
extends RigidBody3D

#apples take 150 days to mature
##days
@export var maturity: int = MarbleAge.SECONDS_IN_DAY * 150
@export var warp_speed: float = 1
@onready var age: MarbleAge = $MarbleAge

var turn = 0

@onready var warp_detector: WarpDetector = $WarpDetectorArea3D
@onready var flora = $/root/Game/World/Flora

func _process(_delta: float) -> void:
	pass
	#var r = float(age.age) / float(maturity)
	#var s = clampf(r, .1, 1.0)
	#scale = Vector3(s, s, s)

#delta is in seconds
func _physics_process(delta: float):
	if is_server():
		age.age += delta * warp_speed
	@warning_ignore("narrowing_conversion")
	var new_turn: int = age.age / MarbleAge.SECONDS_IN_TURN + 1
	for i in range(self.turn, new_turn):
		_start_turn(i)
	self.turn = new_turn
	#_fall()



func _fall():
	if freeze and age.age > maturity:
		print('apple fall')
		# pass
#		turn on physics and let it drop to the ground
		freeze = false
		freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
		# reparent(flora)

func is_server() -> bool:
	return multiplayer.is_server()


func _start_turn(_turn):
	#print('starting turn %.f'%turn)
	pass

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
