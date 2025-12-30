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
const JUMP_VELOCITY = 5.0

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var mode: MODE = MODE.WALK # :
#set = _set_mode

var speed = 30.0

## current actual warp speed
@export var warp_speed = 1:
	set = _set_warp_speed
##target warp speed
var target_warp_speed = 1
##allowed maximum warp speed
var max_warp_speed = 5000
##allowed minimum warp speed
var min_warp_speed = 1

var player_id: String
@export var player_name: String

@onready var label: Label3D = $Label3D
@onready var camera_pivot = %CameraPivot
@onready var camera = %Camera3D
@onready var chat_bubbles = %ChatBubbles
@onready var client = $/root/Game/Client
@onready var warp_detector = %WarpDetectorCollisionShape3D

func is_server() -> bool:
	return multiplayer.is_server()


func update_neighbors_warp():
	pass


func get_max_warp(other: MarbleCharacter) -> int:
	var d = global_transform.origin.distance_to(other.global_transform.origin)
	print(d)

	return 1


@rpc("any_peer")
func server_jump():
	if !is_server():
		return
	velocity.y = JUMP_VELOCITY * warp_speed


#this the function that runs on all the peers that only the server can call
@rpc("authority", "call_local", "reliable", 1)
func chat_bubble(message: String):
	var bubble: Bubble = load("res://src/chat_bubble/ChatBubble.tscn").instantiate()
	bubble.text = message
	chat_bubbles.add_child(bubble)


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta * warp_speed * warp_speed



	move_and_slide()
	update_neighbors_warp()


@rpc("any_peer")
func server_move(d: Vector2):
	if !is_server():
		return
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


@rpc("any_peer")
func server_warp(value: int):
	if !is_server():
		return
	warp_speed = value
	Persistance.persist.emit("MarbleCharacter", self)


func _set_warp_speed(w):
	warp_speed = w
	_update_label()

	#if warp_detector:
		#(warp_detector.shape as SphereShape3D).radius=w*30


@rpc("any_peer")
func server_turn(value: Vector2):
	if !is_server():
		return
	rotate_y(-value.x * .005)
	_rotate_camera(value)


@rpc("any_peer")
func server_camera_zoom(scroll_amount):
	if !is_server():
		return
	var direction = camera_pivot.transform.basis.z
	camera_pivot.position += direction * scroll_amount * .1


func _rotate_camera(value: Vector2):
	camera_pivot.rotate_x(-value.y * .005)
	camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, -PI / 2, PI / 2)


func _ready():
	_update_label()
	#(warp_detector.shape as SphereShape3D).radius=warp_speed*30


func serialize_transform3d() -> Dictionary:
	var data = {}
	data["origin"] = JSON.stringify(transform.origin) # Convert Vector3 to array [x, y, z]
	data["basis_x"] = JSON.stringify(transform.basis.x) # Convert Basis vectors to arrays
	data["basis_y"] = JSON.stringify(transform.basis.y)
	data["basis_z"] = JSON.stringify(transform.basis.z)
	return data


func get_data() -> Dictionary:
	return {
		"name": name,
		"player_id": player_id,
		"player_name": player_name,
		"warp_speed": warp_speed,
		"position": var_to_str(position),
		"transform": var_to_str(transform),
	}

func _update_label():
	if label:
		label.text = "%s (x%s)" % [player_name, str(warp_speed)]
