class_name MarbleTree
extends StaticBody3D

#50 years
@export var maturity: int = int(60 * 60 * 24 * 360 * (50.0))

##milliseconds
@export var age: float = 0
@export var warp_speed: float = 1

#@onready var world = $/root/Game/World
#@onready var ageLabel = %AgeLabel
@onready var warp_detector: WarpDetector = $WarpDetectorArea3D
@onready var label_3d: Label3D = $Label3D


func get_data():
	var save_dict = {
		"transform": var_to_str(transform),
		"age": age,
		"warp_speed": warp_speed,
	}
	return save_dict


func load_node(node_data):
	transform = str_to_var(node_data["transform"])
	if "age" in node_data:
		age = node_data.age
	if "warp_speed" in node_data:
		warp_speed = node_data.warp_speed


func calculate_warp():
	var closest: WarpMonument = null
	#var closest_distance=0
	for w: WarpMonument in warp_detector.warp_monuments.values():
		var distance = w.position.distance_to(position)
		if !closest or distance < closest.position.distance_to(position):
			closest = w
			#closest_distance=distance
	if closest:
		#TODO scale the warp within a bubble, maybe
		#*(1-(closest_distance/closest.radius))
		warp_speed = closest.warp_speed
	else:
		warp_speed = 1


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	var r = float(age) / float(maturity)
	#print(r)
	var s = clampf(r, .001, 1.0)
	#print(s)
	scale = Vector3(s, s, s)
	label_3d.text = "Age:%.f\nWarp:%.f\nScale:%.2f" % [age, warp_speed, scale.x]


#delta is in seconds
func _physics_process(delta: float):
	if is_server():
		age = age + delta * warp_speed


func is_server() -> bool:
	return multiplayer.is_server()
