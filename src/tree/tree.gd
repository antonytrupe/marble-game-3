class_name MarbleTree
extends RigidBody3D


const APPLE_SCENE: Resource = preload("res://src/apple/apple_3d.tscn")
static var scene: Resource = preload("res://src/tree/tree.tscn")

@export var maturity: int = MarbleAge.SECONDS_IN_YEAR * 8
@export var warp_speed: float = 1
@export var chop_stage: int = 0:
	set = _set_chop_stage

var turn: int = 0

@onready var meshes: Array[MeshInstance3D] = [
	%TrunkMesh1, %TrunkMesh2, %TrunkMesh3, %TrunkMesh4,
	%TrunkMesh6, %TrunkMesh7, %TrunkMesh8, %TrunkMesh9, %TrunkMesh10,
	]
@onready var age: MarbleAge = $Age
@onready var warp_detector: WarpDetector = $WarpDetectorArea3D
@onready var label_3d: Label3D = $Label3D
@onready var flora: Node = $/root/Game/World/Flora
@onready var left_leaves: MeshInstance3D = %LeftLeaves
@onready var trunk_collision: CollisionShape3D = %TrunkCollision
@onready var server: Server = $/root/Game/Server


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	#print('tool')
	#age.age += _delta * warp_speed
	var r: float = float(age.age) / float(maturity)
	var s: float = clampf(r, .01, 1.0)
	scale = Vector3(s, s, s)
	label_3d.text = "Age:%.f\nWarp:%.f\nScale:%.2f" % [age.age, warp_speed, scale.x]


#delta is in seconds
func _physics_process(delta: float) -> void:
	if is_server():
		age.age += delta * warp_speed
		@warning_ignore("narrowing_conversion")
		var new_turn: int = age.age / MarbleAge.SECONDS_IN_TURN + 1
		_start_turn(range(self.turn + 1, new_turn + 1))
		self.turn = new_turn


func _start_turn(_turns: Array) -> void:
	#print('starting turn %.f'%turn)
	#if the tree mature, then it can grow apples
	if age.age > maturity:
		#apples start growing in March
		if age.get_month() == 0:
			var i: int = randi_range(1, 800)
			if i == 1:
				#pass
				_add_apple()


func _set_chop_stage(v: int) -> void:
	if is_node_ready():
		meshes[chop_stage].visible = false
	chop_stage = v
	if chop_stage < meshes.size() and is_node_ready():
		meshes[chop_stage].visible = true


func chop(_hand: MarbleCharacter.INTERACT, _o: Array) -> Array:
	print('tree chop')
	if chop_stage < meshes.size():
		chop_stage += 1

		if chop_stage == meshes.size():
			#spawn stump and log
			server.spawn_stump(position)
			var l: MarbleLog = server.spawn_log(position + Vector3(0, 1, 0))
			l.freeze = false
			l.apply_torque_impulse(Vector3(1, 0, 0))
			queue_free()
			Persistance.delete.emit(self )
	return []


func get_object_verbs(action: String = "chop") -> Array[Action]:
	match action:
		'chop':
			return [Action.new('chop', chop)]
		_:
			return []


func _add_apple() -> void:
	#print("add apple")
	var x: float = - abs(randfn(0, 1))
	var y: float = randfn(0, 1)
	var z: float = randfn(0, 1)
	var l: float = sqrt(x * x + y * y + z * z)
	var apple: Apple3D = APPLE_SCENE.instantiate()
	apple.name = apple.name + "%010d" % randi()
	apple.position = left_leaves.global_position + Vector3(x / l, y / l, z / l) * 3
	flora.add_child(apple)


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
	}
	return data


func load_pre_ready(data: Dictionary) -> void:
	if "transform" in data:
		transform = str_to_var(data.transform)


func load_post_ready(data: Dictionary) -> void:
	if "age" in data:
		age.age = data.age
	if "warp_speed" in data:
		warp_speed = data.warp_speed
	if "turn" in data:
		turn = data.turn
	if "chop_stage" in data:
		chop_stage = data.chop_stage


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
