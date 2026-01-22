class_name MarbleCharacter
extends CharacterBody3D

signal inventory_updated

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
const MAX_CONTROLLED_WARP = 10
## current actual warp speed
@export var warp_speed = 1:
	set = _set_warp_speed
@export var player_name: String

@export var inventory: Inventory = Inventory.new()
	#set = _set_inventory
@export var current_turn_actions = {"move": null, "action": null}:
	set = _set_action

var turn: int = 0:
	set = _set_turn

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var mode: MODE = MODE.WALK # :
#set = _set_mode

var speed = 30.0

@export var flying: bool = false

#var warp_monuments = {}

##target warp speed
var target_warp_speed = 1
##allowed maximum warp speed
var max_warp_speed = 5000
##allowed minimum warp speed
var min_warp_speed = 1

var player_id: String

@onready var label: Label3D = $Label3D
@onready var camera_pivot = %CameraPivot
@onready var camera = %Camera3D
@onready var chat_bubbles = %ChatBubbles
@onready var client = $/root/Game/Client
@onready var warp_detector: WarpDetector = $WarpDetector
@onready var age: MarbleAge = $Age
@onready var raycast: RayCast3D = %RayCast3D

func _set_inventory(value):
	inventory = value
	inventory_updated.emit(inventory)


#setter, don't call directly
func _set_action(value):
	current_turn_actions = value
	#Signals.Actions.emit(player_id, current_turn_actions)


func is_server() -> bool:
	return multiplayer.is_server()


func get_target():
	var entity = raycast.get_collider()
	return entity


@rpc("any_peer")
func interact():
	if !is_server():
		return

	#if trading:
		#cancel_trade()
		#return
	if raycast.is_colliding():
		var entity = get_target()

		if entity.has_method("start_trade"):
			pass
			#start_trade(entity)
			#entity.start_trade(self)

		if entity.has_method("pick_berry"):
			pass
			#var action = "pick_berry"
			## make actions.action always a string
			#if current_turn_actions.action != null and current_turn_actions.action != action:
				#return
			#var loot = entity.pick_berry()
			#_add_to_inventory(loot)
			#set_action({"action": "pick_berry"})

		if entity.has_method("pick_up"):
			var action = "pick_up"
			# make actions.action always a string
			#if current_turn_actions.action != null and current_turn_actions.action != action:
				#return
			var loot = entity.pick_up()
			_add_to_inventory.rpc(loot)
			set_action({"action": action})


# use reset_actions to clear this and skip internal logic
func set_action(value: Dictionary):
	if value.has("action") and value.action:
		current_turn_actions.action = value.action
	# only update move if we went faster
	if (
		value.has("move")
		and (current_turn_actions.move == null or value.move > current_turn_actions.move)
	):
		current_turn_actions.move = value.move

@rpc("call_remote")
func _add_to_inventory(loot: Array[MarbleItem]):
	if !is_server():
		return
	for item in loot:
		inventory.items[item.name] = item


func _set_turn(value):
	if label and value != turn:
		_update_label()
	turn = value

func calculate_warp():
	var closest: WarpMonument = null
	#var closest_distance=0
	for w: WarpMonument in warp_detector.warp_monuments.values():
		var distance = w.position.distance_to(position)
		if !closest or distance < closest.position.distance_to(position):
			closest = w
			#closest_distance=distance
	if closest:
		#TODO scale the warp within a bubble, maybe
		#*(1-(closest_distance/closest.radius))
		warp_speed = closest.warp_speed
	else:
		warp_speed = 1


@rpc("any_peer")
func server_jump():
	if !is_server():
		return
	if is_on_floor() and warp_speed <= MAX_CONTROLLED_WARP:
		velocity.y = JUMP_VELOCITY * min(warp_speed, MAX_CONTROLLED_WARP)
	elif flying:
		velocity.y = JUMP_VELOCITY * min(warp_speed, MAX_CONTROLLED_WARP)

@rpc("any_peer")
func server_fly():
	if !is_server():
		return
	#stop flying
	if flying:
		flying = false
		return

	if not is_on_floor() and warp_speed <= MAX_CONTROLLED_WARP:
		if not flying:
			flying = true

		#velocity.y = JUMP_VELOCITY * warp_speed


#this the function that runs on all the peers that only the server can call
@rpc("authority", "call_local", "reliable", 1)
func chat_bubble(message: String):
	var bubble: Bubble = load("res://src/chat_bubble/ChatBubble.tscn").instantiate()
	bubble.text = message
	chat_bubbles.add_child(bubble)


func _start_turn(_turns):
	#print('starting turn %.f'%turn)
	pass


func _physics_process(delta: float) -> void:
	if is_server():
		age.age = age.age + delta * warp_speed
		@warning_ignore("narrowing_conversion")
		var new_turn: int = age.age / MarbleAge.SECONDS_IN_TURN + 1
		_start_turn(range(self.turn + 1, new_turn + 1))
		self.turn = new_turn
	# Add the gravity.
	if not is_on_floor():
		if not flying:
			velocity.y -= gravity * delta * min(warp_speed, MAX_CONTROLLED_WARP) * min(warp_speed, MAX_CONTROLLED_WARP)
		#not on floor and flying
		else:
			velocity.y = 0
	move_and_slide()


@rpc("any_peer")
func server_move(d: Vector2):
	if !is_server():
		return
	var direction = (transform.basis * Vector3(d.x, 0, d.y)).normalized()

	#m*SPEED_MULTIPLIER*speed
	if direction:
		velocity.x = direction.x * mode * SPEED_MULTIPLIER * speed * min(warp_speed, MAX_CONTROLLED_WARP)
		velocity.z = direction.z * mode * SPEED_MULTIPLIER * speed * min(warp_speed, MAX_CONTROLLED_WARP)
	else:
		velocity.x = move_toward(
			velocity.x, 0, mode * SPEED_MULTIPLIER * speed * min(warp_speed, MAX_CONTROLLED_WARP)
		)
		velocity.z = move_toward(
			velocity.z, 0, mode * SPEED_MULTIPLIER * speed * min(warp_speed, MAX_CONTROLLED_WARP)
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


func get_data() -> Dictionary:
	return {
		"name": name,
		"player_id": player_id,
		"player_name": player_name,
		"warp_speed": warp_speed,
		"age": age,
		"turn": turn,
		"transform": var_to_str(transform),
		"inventory": var_to_str(inventory.items)
	}


func load_node(node_data):
	#transform = str_to_var(node_data["transform"])
	#if "transform" in node_data:
		#transform = str_to_var(node_data.transform)
	if "player_id" in node_data:
		player_id = node_data.player_id
	if "player_name" in node_data:
		player_name = node_data.player_name
	if "warp_speed" in node_data:
		warp_speed = node_data.warp_speed
	if "age" in node_data:
		age.age = node_data.age
	if "turn" in node_data:
		turn = node_data.turn
	if "inventory" in node_data:
		inventory.items = str_to_var(node_data.inventory)


func _update_label():
	if label:
		label.text = "%s (x%.f)\n turn %.f" % [player_name, warp_speed, turn]
