class_name Apple3D
extends RigidBody3D

static var scene: Resource = preload("res://src/apple/apple_3d.tscn")


#apples take 150 days to mature
##days
@export var maturity: int = MarbleAge.SECONDS_IN_DAY * 1
@export var longevity: int = MarbleAge.SECONDS_IN_DAY * 5
#@export var warp_speed: float = 1

var turn: int = 0
var _is_on_floor: bool = false
var tree: MarbleTree

@onready var collision_shape_3d: CollisionShape3D = %CollisionShape3D
@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D
@onready var highlight_mesh_instance_3d: MeshInstance3D = %HighlightMeshInstance3D
#@onready var age: MarbleAge = $Age
@onready var warp_detector: WarpDetector = $WarpDetectorArea3D
@onready var flora: Node = $/root/Game/World/Flora
@onready var item: MarbleItem = $MarbleItem
@onready var world: World = $/root/Game/World

func _ready() -> void:
	#timer.wait_time=MarbleAge.SECONDS_IN_TURN/warp_speed
	#timer.start()
	#timer.stop()
	await get_tree().physics_frame
	if not is_on_floor() and not tree and is_server():
		fall()


func _physics_process(_delta: float) -> void:
	if not freeze and is_on_floor() and linear_velocity.length() < 0.01 and angular_velocity.length() < 0.01:
		freeze = true
	#if is_server():
		#pass
		#put it back to sleep when its done falling/rolling
		#if is_on_floor() and not freeze and linear_velocity.distance_squared_to(Vector3(0, 0, 0)) < 1:
			#print('freezing')
			#set_deferred("freeze", true)
			#set_deferred("sleeping", true)
			#freeze_mode=RigidBody3D.FREEZE_MODE_STATIC
#
		#@warning_ignore("narrowing_conversion")
		#var new_turn: int = item.age.age / MarbleAge.SECONDS_IN_TURN + 1
		#_start_turn(range(self.turn + 1, new_turn + 1))
		#self.turn = new_turn

		#if item.age.age > longevity:
			#set_deferred("freeze", true)
			#set_deferred("sleeping", true)
			#queue_free()

		#var r = float(age.age) / float(maturity)
		#var s = clampf(r, .1, 1.0)
		#_set_scale( Vector3(s, s, s))


func pick_up(_hand: MarbleCharacter.INTERACT, _o: Array[Object]) -> Array:
	return [ self ]


func _set_scale(s: Vector3) -> void:
	#TODO this doesn't work
	collision_shape_3d.scale = s
	mesh_instance_3d.scale = s
	warp_detector.scale = s
	highlight_mesh_instance_3d.scale = s


func fall() -> void:
	set_deferred("freeze", false)
	set_deferred("sleeping", false)
	set_deferred("freeze_mode", RigidBody3D.FREEZE_MODE_KINEMATIC)


func is_server() -> bool:
	return multiplayer.is_server()


func _start_turn(_turns: Array) -> void:
	#print("apple._start_turn")
	#
	if not is_on_floor() and item.age.age > maturity:
		#print('apple fall')
		fall()


func is_on_floor() -> bool:
	return _is_on_floor


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	#print('_integrate_forces')
	_is_on_floor = false

	for i: int in range(state.get_contact_count()):
		# Local normal points from the collider toward this RigidBody
		var normal: Vector3 = state.get_contact_local_normal(i)

		# In 3D, a normal pointing UP (Vector3.UP) indicates a floor.
		# Use a dot product to allow for slopes (e.g., > 0.7 for ~45 degrees).
		if normal.dot(Vector3.UP) > 0.7:
			_is_on_floor = true
			print('is on floor')
			break


func get_subject_verbs() -> Array[Action]:
	return []


func get_object_verbs(action: String = "pick_up") -> Array[Action]:
	match action:
		'pick_up':
			return [Action.new('pick_up', pick_up)]
		_:
			return []


func calculate_warp() -> void:
	var closest: WarpMonument = null
	#var closest_distance=0
	for w: WarpMonument in warp_detector.warp_monuments.values():
		var distance: float = w.position.distance_to(position)
		if !closest or distance < closest.position.distance_to(position):
			closest = w
			#closest_distance=distance
	if closest:
		item.warp_speed = closest.warp_speed
	else:
		item.warp_speed = 1


func get_data() -> Dictionary:
	var save_dict: Dictionary = {
		"name": name,
		"parent": str(get_parent().get_path()) if get_parent() else "",
		"scene_file_path": get_scene_file_path(),
		"transform": var_to_str(transform),
		"age": item.age.age,
		"turn": turn,
		"warp_speed": item.warp_speed,
		"tree": str(tree.name) if tree else ""
	}
	return save_dict


func load_pre_ready(data: Dictionary) -> void:
	if "transform" in data:
		transform = str_to_var(data.transform)


func load_post_ready(data: Dictionary) -> void:
	if "age" in data:
		item.age.age = data.age
	if "warp_speed" in data:
		item.warp_speed = data.warp_speed
	if "turn" in data:
		turn = data.turn
	if "tree" in data and data.tree:
		var t: MarbleTree = world.find_child(data.tree, true, false)
		if t: tree = t
		else:
			var f: Callable
			f = func(child: Node) -> void:
				if child.name == data.tree:
					tree = child
					#world.flora.child_entered_tree.disconnect(f)
			world.flora.child_entered_tree.connect(f)
