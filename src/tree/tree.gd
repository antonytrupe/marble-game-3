class_name MarbleTree
extends StaticBody3D


const APPLE_SCENE: Resource = preload("res://src/apple/apple_3d.tscn")
static var scene: Resource = preload("res://src/tree/tree.tscn")

@export var maturity: int = MarbleAge.SECONDS_IN_YEAR * 8
@export var warp_speed: float = 1
@export_range(0, 1) var chop_progress: float = 0
@export var chop_stage: int = 0:
	set = _set_chop_stage

var turn: int = 0
var apples: Array = []

@onready var meshes: Array[MeshInstance3D] = [
	%TrunkMesh0, %TrunkMesh1, %TrunkMesh2, %TrunkMesh3, %TrunkMesh4, %TrunkMesh5,
	%TrunkMesh6, %TrunkMesh7, %TrunkMesh8, %TrunkMesh9, %TrunkMesh10,
	]
@onready var age: MarbleAge = %MarbleAge
@onready var warp_detector: WarpDetector = $WarpDetectorArea3D
@onready var label_3d: Label3D = $Label3D
@onready var flora: Node = $/root/Game/World/Flora
@onready var left_leaves: MeshInstance3D = %LeftLeaves
@onready var front_leaves: MeshInstance3D = %FrontLeaves
@onready var right_leaves: MeshInstance3D = %RightLeaves
@onready var back_leaves: MeshInstance3D = %BackLeaves
@onready var trunk_collision: CollisionShape3D = %TrunkCollision
@onready var server: Server = $/root/Game/Server
@onready var world: World = $/root/Game/World
@onready var growth_timer: Timer = $GrowthTimer


func _ready() -> void:
	# The growth timer handles age updates on the server to avoid running logic every frame.
	if is_server():
		growth_timer.timeout.connect(_on_growth_timer_timeout)
		# Stagger the first timer tick by a random amount up to its wait_time.
		# This prevents all trees from updating on the exact same frame, spreading the load.
		growth_timer.start(randf_range(0.0, growth_timer.wait_time))
	update_visuals()


func update_visuals() -> void:
	var r: float = float(age.age) / float(maturity)
	var s: float = clampf(r, .01, 1.0)
	# WARNING: Scaling a physics body is not ideal for performance.
	# This forces a rebuild of the physics shape. This should be called infrequently.
	# For better performance, consider using different-sized models instead of scaling.
	var new_scale := Vector3(s, s, s)
	if not scale.is_equal_approx(new_scale):
		scale = new_scale
	label_3d.text = "Age:%.f\nWarp:%.f\nScale:%.2f" % [age.age, warp_speed, scale.x]


func _on_growth_timer_timeout() -> void:
	# This function only runs on the server, as connected in _ready().
	age.age += growth_timer.wait_time * warp_speed
	update_visuals()
	_check_for_turn_updates()


func _start_turn(_turns: Array) -> void:
	#print('starting turn %.f'%turn)
	#if the tree mature, then it can grow apples
	if age.age > maturity:
		#apples start growing in March
		if age.get_month() == 0:
			var i: int = randi_range(1, 3200)
			if i == 1:
				#pass
				_add_apple()


func _check_for_turn_updates() -> void:
	@warning_ignore("narrowing_conversion")
	var new_turn: int = age.age / MarbleAge.SECONDS_IN_TURN + 1
	if new_turn > self.turn:
		_start_turn(range(self.turn + 1, new_turn + 1))
		self.turn = new_turn


func _set_chop_stage(v: int) -> void:
	if is_node_ready():
		meshes[chop_stage].visible = false
	chop_stage = v
	if chop_stage < meshes.size() and is_node_ready():
		meshes[chop_stage].visible = true


func chop(_hand: MarbleCharacter.INTERACT, _o: Array) -> Array:
	#print('tree chop')
	# The number of chops depends on the size of the tree.
	var min_chops: float = 1.0
	var max_chops: float = 40.0
	var total_chops: float = lerp(min_chops, max_chops, scale.x)
	chop_progress += 1.0 / total_chops

	chop_progress = clampf(chop_progress, 0.0, 1.0)
	chop_stage = floori(chop_progress * (meshes.size() - 0))
	#if chop_stage < meshes.size():
		#chop_stage += 1

	if chop_stage >= meshes.size():
		#spawn stump and log
		server.spawn_stump(position, scale.x)
		server.spawn_log(position + Vector3(0, 1, 0) * scale.x, scale.x)
		#l.log_scale=scale.x

		for apple: Apple3D in apples:
			apple.fall()
		queue_free()
		Persistance.delete.emit(self )
	return []


func get_object_verbs(subject_verbs: Array[String]) -> Array[Callable]:
	var verbs: Array[Callable] = []
	if subject_verbs.has("chop"):
		verbs.append(chop)
	return verbs


func _add_apple() -> void:
	#print("add apple")
	var x: float = randf_range(-1.0, 1.0)
	var y: float = randf_range(-1.0, 1.0)
	var z: float = randf_range(-1.0, 1.0)
	var p: Vector3 = Vector3(x, y, z).normalized()

	var apple: Apple3D = APPLE_SCENE.instantiate()
	apple.name = apple.name + "%010d" % randi()
	apple.tree = self
	match randi_range(0, 3):
		0:
			p.x = - abs(p.x)
			apple.position = left_leaves.global_position + p * left_leaves.mesh.radius
		1:
			p.x = abs(p.x)
			apple.position = right_leaves.global_position + p * right_leaves.mesh.radius
		2:
			p.z = - abs(p.z)
			apple.position = front_leaves.global_position + p * front_leaves.mesh.radius
		3:
			p.z = abs(p.z)
			apple.position = back_leaves.global_position + p * back_leaves.mesh.radius
	flora.add_child(apple)
	apples.append(apple)


func is_server() -> bool:
	return multiplayer.is_server()


func get_data() -> Dictionary:
	var data: Dictionary = {
		"name": name,
		"parent": str(get_parent().get_path()) if get_parent() else "",
		"scene_file_path": get_scene_file_path(),
		"transform": var_to_str(transform),
		"age": age.age,
		"turn": turn,
		"warp_speed": warp_speed,
		"chop_stage": chop_stage,
		"apples": apples.map(func(a: Apple3D) -> String: return a.name)
	}
	return data


func load_pre_ready(data: Dictionary) -> void:
	if "transform" in data:
		transform = str_to_var(data.transform)


func load_post_ready(data: Dictionary) -> void:
	if "age" in data:
		age.age = data.age
		update_visuals()
	if "warp_speed" in data:
		warp_speed = data.warp_speed
	if "turn" in data:
		turn = data.turn
	if "chop_stage" in data:
		chop_stage = data.chop_stage
	if "apples" in data and data.apples.size() > 0:
		for a_name: String in apples:
			var apple: Apple3D = world.find_child(a_name, true, false)
			if apple: apples.append(apple)
			else:
				var f: Callable = func(apple: Node) -> void:
					if apple.name == a_name:
						apples.append(apple)
				world.items.child_entered_tree.connect(f)


func calculate_warp() -> void:
	var closest: WarpMonument = null
	#var closest_distance=0
	for w: WarpMonument in warp_detector.warp_monuments.values():
		var distance: float = w.position.distance_to(position)
		if !closest or distance < closest.position.distance_to(position):
			closest = w
			#closest_distance=distance
	if closest:
		warp_speed = closest.warp_speed
	else:
		warp_speed = 1
