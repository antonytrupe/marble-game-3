class_name Apple3D
extends RigidBody3D

static var scene: Resource = preload("res://src/apple/apple_3d.tscn")


#apples take 150 days to mature
##days
@export var maturity: int = MarbleAge.SECONDS_IN_DAY * 1
@export var longevity: int = MarbleAge.SECONDS_IN_DAY * 5
#@export var warp_speed: float = 1

var turn: int = 0
var tree: MarbleTree
var _is_on_floor: bool = false

@onready var collision_shape_3d: CollisionShape3D = %CollisionShape3D
@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D
@onready var highlight_mesh_instance_3d: MeshInstance3D = %HighlightMeshInstance3D
#@onready var age: MarbleAge = $Age
@onready var warp_detector: WarpDetector = $WarpDetectorArea3D
@onready var flora: Node = $/root/Game/World/Flora
@onready var item: MarbleItem = $MarbleItem
@onready var world: World = $/root/Game/World

func _ready() -> void:
	sleeping_state_changed.connect(_on_sleeping_state_changed)
	contact_monitor = false
	max_contacts_reported = 0
	#timer.wait_time=MarbleAge.SECONDS_IN_TURN/warp_speed
	#timer.start()
	#timer.stop()
	await get_tree().physics_frame
	if not is_on_floor() and not tree and is_server():
		fall()


func _on_sleeping_state_changed() -> void:
	# When the apple stops moving, the physics engine puts it to sleep.
	# We can use this to freeze it and stop further physics calculations for it.
	if sleeping:
		freeze = true
		contact_monitor = false
		max_contacts_reported = 0


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
	set_deferred("contact_monitor", true)
	set_deferred("max_contacts_reported", 4)


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
	if freeze:
		return
	_is_on_floor = false

	for i: int in range(state.get_contact_count()):
		# Local normal points from the collider toward this RigidBody
		var normal: Vector3 = state.get_contact_local_normal(i)

		# In 3D, a normal pointing UP (Vector3.UP) indicates a floor.
		# Use a dot product to allow for slopes (e.g., > 0.7 for ~45 degrees).
		if normal.dot(Vector3.UP) > 0.7:
			_is_on_floor = true
			break

#region interactions
func get_subject_verbs() -> Array[Callable]:
	return []


func get_object_verbs(subject_verbs: Array[String]) -> Array[Callable]:
	var verbs: Array[Callable] = []
	if subject_verbs.has("pick_up"):
		verbs.append(pick_up)
	return verbs

func pick_up(_hand: MarbleCharacter.INTERACT, _o: Array) -> Array:
	return [ self ]
	
#endregion

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

#region persistance
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
#endregion
