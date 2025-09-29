class_name MarbleCharacter
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

const STRINGS = {
	MODE.CROUCH: "CROUCH",
	MODE.WALK: "WALK",
	MODE.HUSTLE: "HUSTLE",
	MODE.RUN: "RUN",
}

const SPEED_MULTIPLIER = 1.0 / 24.0

@export var mode: MODE = MODE.WALK  #:
#set = _set_mode

@export var speed = 30.0

var warp_speed = 1:
	set = _set_warp_speed

var player_id: String

@onready var label: Label3D = $Label3D
@onready var camera_pivot = %CameraPivot
@onready var camera = %Camera3D
@onready var client = $/root/Game/Client


func is_server() -> bool:
	return multiplayer.is_server()


func _physics_process(_delta: float) -> void:
	var input_dir: Vector2 = Input.get_vector("left", "right", "forward", "backward")
	if client.current_character and client.current_character.name == name:
		if is_server():
			server_move(input_dir)
		else:
			server_move.rpc_id(1, input_dir)

	move_and_slide()


@rpc("any_peer")
func server_move(d: Vector2):
	if !is_server():
		return
	#print(d)
	var direction = (transform.basis * Vector3(d.x, 0, d.y)).normalized()

	#m*SPEED_MULTIPLIER*speed
	if direction:
		velocity.x = direction.x * mode * SPEED_MULTIPLIER * speed * min(warp_speed, 20)
		velocity.z = direction.z * mode * SPEED_MULTIPLIER * speed * min(warp_speed, 20)
	else:
		velocity.x = move_toward(
			velocity.x, 0, mode * SPEED_MULTIPLIER * speed * min(warp_speed, 20)
		)
		velocity.z = move_toward(
			velocity.z, 0, mode * SPEED_MULTIPLIER * speed * min(warp_speed, 20)
		)
	#if !is_zero_approx(velocity.x) or !is_zero_approx(velocity.z):
	#set_action({"move": mode})
	#play_animation.rpc("walking")
	#if mode in [MODE.HUSTLE, MODE.RUN]:
	#set_action({"action": STRINGS[mode]})
	#else:
	#TODO animation state machine so that walk and crouch can play at the same time
	#play_animation.rpc("RESET")


func _unhandled_input(event) -> void:
	print("_unhandled_input")
	print(event)


@rpc("any_peer")
func turn(value: Vector2):
	if !is_server():
		return
	#print(value)
	rotate_y(-value.x * .005)
	#print(value.x)
	_rotate_camera(value)


func _rotate_camera(value: Vector2):
	camera_pivot.rotate_x(-value.y * .005)
	camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, -PI / 2, PI / 2)


func _ready():
	label.text = "warp speed:" + str(warp_speed)


func serialize_transform3d() -> Dictionary:
	var data = {}
	data["origin"] = JSON.stringify(transform.origin)  # Convert Vector3 to array [x, y, z]
	data["basis_x"] = JSON.stringify(transform.basis.x)  # Convert Basis vectors to arrays
	data["basis_y"] = JSON.stringify(transform.basis.y)
	data["basis_z"] = JSON.stringify(transform.basis.z)
	return data


func deserialize_transform3d(data: Dictionary) -> Transform3D:
	var origin = Vector3(data["origin"][0], data["origin"][1], data["origin"][2])
	var basis_x = Vector3(data["basis_x"][0], data["basis_x"][1], data["basis_x"][2])
	var basis_y = Vector3(data["basis_y"][0], data["basis_y"][1], data["basis_y"][2])
	var basis_z = Vector3(data["basis_z"][0], data["basis_z"][1], data["basis_z"][2])
	var b = Basis(basis_x, basis_y, basis_z)
	return Transform3D(b, origin)


func get_data() -> Dictionary:
	return {
		"name": name,
		"player_id": player_id,
		"warp_speed": warp_speed,
		"position": {"x": position.x, "y": position.y, "z": position.z},
		#"transform":serialize_transform3d(),
	}


func _set_warp_speed(w):
	warp_speed = w
	if label:
		label.text = "warp speed:" + str(warp_speed)
