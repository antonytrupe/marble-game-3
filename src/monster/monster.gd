class_name Monster
extends CharacterBody3D
const SPEED_MULTIPLIER: float = 1.0 / 24.0

@export var speed: float = 30.0
@export var movement_range: float = 60.0

var turn: int
var warp_speed: int
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var age: MarbleAge = $MarbleAge
@onready var world: World = $/root/Game/World

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D

func _ready() -> void:
	# Crucial: Navigation data often isn't ready on frame 1
	# Wait for the first physics frame before picking a target
	await get_tree().physics_frame
	set_new_random_target()

func _physics_process(delta: float) -> void:
	# 1. Apply Gravity first
	if not is_on_floor():
		print('not on floor!')
		velocity.y -= gravity * delta
	else:
		velocity.y = 0 # Keeps velocity from building up while grounded

	var next_path_pos: Vector3 = nav_agent.get_next_path_position()

	# 2. Handle Navigation
	if not nav_agent.is_navigation_finished():
		#print("position:",position)
		#print("target_position:",nav_agent.target_position)
#
		#print("next_path_pos:",next_path_pos)
		#print("global_position:",global_position)
		var direction: Vector3 = global_position.direction_to(next_path_pos)
		direction.y=0
		direction=direction.normalized()

		#print("direction:",direction)
		# Only update horizontal velocity so you don't "fly" or cancel gravity
		var move_speed: float = SPEED_MULTIPLIER * speed

		velocity.x = direction.x * move_speed
		#velocity.y = direction.y * move_speed
		velocity.z = direction.z * move_speed

		#print("velocity:",velocity)
		# Rotate to face movement
		if is_on_floor() and velocity.length() > 0.1:
			var floor_normal = get_floor_normal()
			var target_forward = velocity.normalized()

			# Build a transform that aligns with the slope normal
			# This keeps the "Up" vector perpendicular to the ground
			var target_basis = Basis()
			target_basis.y = floor_normal
			target_basis.x = target_forward.cross(floor_normal).normalized()
			target_basis.z = target_basis.x.cross(target_basis.y).normalized()

			# Smoothly interpolate to avoid "shaking" on uneven Jolt colliders
			global_basis = global_basis.slerp(target_basis, 10.0 * delta)
	else:
		# Stop moving horizontally if reached target
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	# 3. Move
	move_and_slide()

func set_new_random_target() -> void:
	#print('picking a new target')
	# Create a random target within the movement range
	var x:float = randf_range(-movement_range, movement_range)
	var z:float = randf_range(-movement_range, movement_range)
	var y:float = 0
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


#can reference @onready vars now
func load_post_ready(node_data: Dictionary) -> void:
	#transform = str_to_var(node_data["transform"])
	if "transform" in node_data:
		transform = str_to_var(node_data.transform)
	if "age" in node_data:
		age.age = node_data.age


func save_node() -> Dictionary:
	var save_dict: Dictionary = {
		transform = var_to_str(transform),
	}
	return save_dict
