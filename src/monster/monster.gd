class_name Monster
extends CharacterBody3D

enum MODE {
	##half the walk distance
	##usually 15ft/round
	CROUCH = 1,
	##single move action
	##usually 30ft/round
	WALK = 2,
	##this is the double move action
	##usually 60ft/round
	HUSTLE = 4,
	##not used?
	RUN = 6,
}
const SPEED_MULTIPLIER: float = 1.0 / 24.0

static var scene: Resource = preload("res://src/monster/monster.tscn")


@export var speed: float = 30.0
@export var movement_range: float = 60.0

@export var turn: int = 0:
	set = _set_turn
@export var warp_speed: int = 1:
	set = _set_warp_speed
@export var mode: MODE = MODE.WALK # :
@export var maturity: int = MarbleAge.SECONDS_IN_MINUTE * 2

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var age: MarbleAge = $MarbleAge
@onready var world: World = $/root/Game/World
@onready var label: Label3D = %Label3D
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var warp_detector: WarpDetector = $WarpDetectorArea3D

func _ready() -> void:
	# Crucial: Navigation data often isn't ready on frame 1
	# Wait for the first physics frame before picking a target
	await get_tree().physics_frame
	set_new_random_target()


func calculate_warp() -> void:
	var closest: WarpMonument = null
	var closest_dist_sq: float = INF
	for key: Variant in warp_detector.warp_monuments:
		var w: WarpMonument = warp_detector.warp_monuments[key]
		var dist_sq: float = w.position.distance_squared_to(position)
		if dist_sq < closest_dist_sq:
			closest = w
			closest_dist_sq = dist_sq

	var new_warp_speed: int = 1
	if closest:
		#TODO scale the warp within a bubble, maybe
		#*(1-(closest_distance/closest.radius))
		new_warp_speed = closest.warp_speed

	if warp_speed != new_warp_speed:
		warp_speed = new_warp_speed


func _process(_delta: float) -> void:
	var r: float = float(age.age) / float(maturity)
	var s: float = clampf(r, 0.1, 1.0)

	# 1. Scale the Visual Mesh
	$MeshInstance3D.scale = Vector3.ONE * s

	# 2. Resize the Shape Properties (Not Scale)
	var shape: Shape3D = $CollisionShape3D.shape
	if shape is CapsuleShape3D or shape is CylinderShape3D:
		shape.radius = 0.25 * s
		shape.height = 1.0 * s
	elif shape is BoxShape3D:
		# Box size is the full dimension (x, y, z)
		shape.size = Vector3(0.5, 1.0, 0.5) * s

	# 3. Align to Ground
	# Since shapes are centered, move the Y position to half the current height
	var current_height: float = 1.0 * s
	var offset: float = current_height / 2.0

	$MeshInstance3D.position.y = offset
	$CollisionShape3D.position.y = offset


func _physics_process(delta: float) -> void:
	age.age = age.age + delta * warp_speed
	#@warning_ignore("narrowing_conversion")
	var new_turn: int = int(age.age / MarbleAge.SECONDS_IN_TURN) + 1
	if new_turn > turn:
		#print('new turn')
		_start_turn(range(self.turn + 1, new_turn + 1))
		self.turn = new_turn

	# 1. Apply Gravity first
	if not is_on_floor():
		#print('not on floor!')
		#var w_speed: float = warp_speed
		velocity.y -= gravity * delta * (warp_speed * warp_speed)
	else:
		velocity.y = 0 # Keeps velocity from building up while grounded

	var next_path_pos: Vector3 = nav_agent.get_next_path_position()

	# 2. Handle Navigation
	if not nav_agent.is_navigation_finished():
		var direction: Vector3 = global_position.direction_to(next_path_pos)
		direction.y = 0
		direction = direction.normalized()

		# Only update horizontal velocity so you don't "fly" or cancel gravity
		var move_speed: float = SPEED_MULTIPLIER * speed * warp_speed * mode

		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed

		# Rotate to face movement
		if is_on_floor() and velocity.length() > 0.1:
			var floor_normal: Vector3 = get_floor_normal()
			var target_forward: Vector3 = velocity.normalized()

			# Build a transform that aligns with the slope normal
			# This keeps the "Up" vector perpendicular to the ground
			var target_basis: Basis = Basis()
			target_basis.y = floor_normal
			target_basis.x = target_forward.cross(floor_normal).normalized()
			target_basis.z = target_basis.x.cross(target_basis.y).normalized()
			target_basis = target_basis.orthonormalized()
			# Smoothly interpolate to avoid "shaking" on uneven Jolt colliders
			global_basis = global_basis.slerp(target_basis, 10.0 * delta).orthonormalized()
	else:
		# Stop moving horizontally if reached target
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	# 3. Move
	move_and_slide()


func _set_turn(value: int) -> void:
	if label and value != turn:
		_update_label()
	turn = value


func _set_warp_speed(w: int) -> void:
	warp_speed = w
	_update_label()


func _start_turn(_turns: Array) -> void:
	#print('starting turn %.f'%turn)
	pass


func _update_label() -> void:
	if not is_node_ready():
		return
	var r: float = float(age.age) / float(maturity)
	var s: float = clampf(r, 0.1, 1.0)
	if label:
		label.text = "(x%.f)\n turn %.f\n%.2f" % [warp_speed, turn, s]


func set_new_random_target() -> void:
	#print('picking a new target')
	# Create a random target within the movement range
	var x: float = randf_range(-movement_range, movement_range)
	var z: float = randf_range(-movement_range, movement_range)
	var y: float = world.get_ground_y(x, z)
	var random_pos: Vector3 = Vector3(x, y, z)
	# Apply to the agent
	nav_agent.target_position = global_position + random_pos
	#print('new target:', nav_agent.target_position)


# Connect your Timer's "timeout" signal to this function
func _on_timer_timeout() -> void:
	#if nav_agent.is_navigation_finished():
		set_new_random_target()


func get_data() -> Dictionary:
	return {
		"name": name,
		#"warp_speed": warp_speed,
		"age": age.age,
		#"turn": turn,
		"transform": var_to_str(transform),
		#"left_inventory": left_inventory.name if left_inventory else StringName(""),
		#"right_inventory": right_inventory.name if right_inventory else StringName(""),
	}


#don't reference @onready vars
func load_pre_ready(node_data: Dictionary) -> void:
	if "turn" in node_data:
		turn = node_data.turn
	if "warp_speed" in node_data:
		warp_speed = node_data.warp_speed


#can reference @onready vars
func load_post_ready(node_data: Dictionary) -> void:
	if "transform" in node_data:
		transform = str_to_var(node_data.transform)
	if "age" in node_data:
		age.age = node_data.age


func save_node() -> Dictionary:
	var save_dict: Dictionary = {
		transform = var_to_str(transform),
	}
	return save_dict
