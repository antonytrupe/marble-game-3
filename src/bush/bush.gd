class_name MarbleBush
extends Node3D


static var scene: Resource = preload("res://src/bush/bush.tscn")


#8 years
@export var maturity: int = MarbleAge.SECONDS_IN_YEAR * 8

@export var berries: int = 9:
	set(value):
		berries = value
		setup()


##milliseconds
#@export var age: float = 0
@export var warp_speed: float = 1

var turn: int = 0

@onready var world: World = $/root/Game/World
@onready var age: MarbleAge = %MarbleAge
@onready var warp_detector: WarpDetector = $WarpDetectorArea3D

#var rng = RandomNumberGenerator.new()

@onready var b: Array = [
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
@onready var label_3d: Label3D = $Label3D


func get_actions() -> Array:
	return ["pick_berry"]


#delta is in seconds
func _physics_process(delta: float) -> void:
	if is_server():
		age.age += delta * warp_speed
		@warning_ignore("narrowing_conversion")
		var new_turn: int = age.age / MarbleAge.SECONDS_IN_TURN + 1
		_start_turn(range(self.turn + 1, new_turn + 1))
		self.turn = new_turn

func _start_turn(_turns: Array) -> void:
	pass

func is_server() -> bool:
	return multiplayer.is_server()


func get_data() -> Dictionary:
	return {
		"name": name,
		"parent": str(get_parent().get_path()) if get_parent() else "",
		"scene_file_path": get_scene_file_path(),
		"transform": var_to_str(transform),
		"age": age,
		"berries": berries,
		"warp_speed": warp_speed,
	}


func load_pre_ready(data: Dictionary) -> void:
	if "transform" in data:
		transform = str_to_var(data.transform)


func load_post_ready(data: Dictionary) -> void:
	if "age" in data:
		age.age = data.age
	if "berries" in data:
		berries = data.berries
	if "warp_speed" in data:
		warp_speed = data.warp_speed


func pick_berry() -> Dictionary:
	if berries:
		b[berries - 1].hide()
		berries = berries - 1
		#print(GlobalRandom.Items.berry)
		var a: Dictionary = {berry = {}}
		a.berry.quantity = 1
		#print(a)
		return a
	# else:
	return {}


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	setup()


func setup() -> void:
	for i: int in range(0, 9):
		if i < berries and b:
			b[i].show()
		else:
			if b:
				b[i].hide()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	#print('tool')
	#age.age += _delta * warp_speed
	var r: float = float(age.age) / float(maturity)
	var s: float = clampf(r, .01, 1.0)
	#TODO don't scale the whole scene
	#scaling collisionbody is no good
	scale = Vector3(s, s, s)
	label_3d.text = "Age:%.f\nWarp:%.f\nScale:%.2f" % [age.age, warp_speed, scale.x]


	#if multiplayer.is_server():
		#age += _delta * 1000 * warp_speed
		#if berries < 9:
			#if randi_range(0, 1000) <= 1:
				#print("spawn a berry")
				#berries = berries + 1


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
