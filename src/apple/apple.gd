#@tool
class_name Apple
extends RigidBody3D

#apples take 150 days to mature
##days
@export var maturity: int = MarbleAge.SECONDS_IN_DAY * 1
@export var longevity: int = MarbleAge.SECONDS_IN_DAY * 5
@export var warp_speed: float = 1

var turn = 0
var _is_on_floor = false

@onready var collision_shape_3d: CollisionShape3D = %CollisionShape3D
@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D
@onready var highlight_mesh_instance_3d: MeshInstance3D = %HighlightMeshInstance3D
@onready var age: MarbleAge = $MarbleAge
@onready var warp_detector: WarpDetector = $WarpDetectorArea3D
@onready var flora = $/root/Game/World/Flora

func _ready():
	pass
	#timer.wait_time=MarbleAge.SECONDS_IN_TURN/warp_speed
	#timer.start()
	#timer.stop()


func _process(delta: float) -> void:
	pass
	if is_server():
		age.age += delta * warp_speed


func _physics_process(_delta: float) -> void:
	if is_server():
		#put it back to sleep when its done falling/rolling
		if is_on_floor() and not freeze and linear_velocity.distance_squared_to(Vector3(0, 0, 0)) < .0001:
			print('freezing')
			set_deferred("freeze", true)
			set_deferred("sleeping", true)

		@warning_ignore("narrowing_conversion")
		var new_turn: int = age.age / MarbleAge.SECONDS_IN_TURN + 1
		_start_turn(range(self.turn + 1, new_turn + 1))
		self.turn = new_turn

		if age.age > longevity:
			set_deferred("freeze", true)
			set_deferred("sleeping", true)
			queue_free()

		#var r = float(age.age) / float(maturity)
		#var s = clampf(r, .1, 1.0)
		#_set_scale( Vector3(s, s, s))


func _set_scale(s):
	#TODO this doesn't work
	collision_shape_3d.scale = s
	mesh_instance_3d.scale = s
	warp_detector.scale = s
	highlight_mesh_instance_3d.scale = s


func _fall():
	set_deferred("freeze", false)
	set_deferred("sleeping", false)
	set_deferred("freeze_mode", RigidBody3D.FREEZE_MODE_KINEMATIC)


func is_server() -> bool:
	return multiplayer.is_server()


func _start_turn(_turns):
	#print("apple._start_turn")
	#
	if not is_on_floor() and age.age > maturity:
		#print('apple fall')
		_fall()


func is_on_floor() -> bool:
	return _is_on_floor


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	#print('_integrate_forces')
	_is_on_floor = false

	for i in range(state.get_contact_count()):
		# Local normal points from the collider toward this RigidBody
		var normal = state.get_contact_local_normal(i)

		# In 3D, a normal pointing UP (Vector3.UP) indicates a floor.
		# Use a dot product to allow for slopes (e.g., > 0.7 for ~45 degrees).
		if normal.dot(Vector3.UP) > 0.7:
			_is_on_floor = true
			print('is on floor')
			break


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
