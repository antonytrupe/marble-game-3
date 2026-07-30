class_name MarbleCharacter
extends CharacterBody3D

#region static, enums, and consts
static var scene: Resource = preload("res://src/character/character.tscn")

enum INTERACT {RIGHT, LEFT}

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

const STRINGS: Dictionary[MODE, String] = {
	MODE.CROUCH: "CROUCH",
	MODE.WALK: "WALK",
	MODE.HUSTLE: "HUSTLE",
	MODE.RUN: "RUN",
}

const SPEED_MULTIPLIER: float = 1.0 / 24.0
const JUMP_VELOCITY: float = 5.0
const MAX_CONTROLLED_WARP: int = 10

#endregion

#region turn actions flags
#@export var move_action: bool = true
@export var standard_action: bool = true
@export var item_interaction: bool = true
@export var free_action: bool = true
#endregion

#region exports
## current actual warp speed
@export var warp_speed: int = 1:
	set = _set_warp_speed
@export var player_name: String
@export var flying: bool = false
@export var turn: int = 0:
	set = _set_turn
@export var color: Color = Color(0.7, 0.7, 0.7, 1):
	set = _set_color
#endregion

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

var mode: MODE = MODE.WALK # :

var speed: float = 30.0

##target warp speed
#var target_warp_speed: int = 1
##allowed maximum warp speed
#var max_warp_speed: int = 5000
##allowed minimum warp speed
#var min_warp_speed: int = 1

var player_id: String

var right_inventory: Node3D
var left_inventory: Node3D
var actions: Array[Action]
var faction: Faction.Type = Faction.Type.NONE

#region onready variables
@onready var label: Label3D = %Label3D
@onready var camera_pivot: Node3D = %CameraPivot
@onready var camera: Camera3D = %Camera3D
@onready var chat_bubbles: Node3D = %ChatBubbles
@onready var client: Client = $/root/Game/Client
@onready var world: World = $/root/Game/World
@onready var warp_detector: WarpDetector = %WarpDetector
@onready var age: MarbleAge = %Age
@onready var raycast: RayCast3D = %RayCast3D
@onready var inventory_right_marker: Generic6DOFJoint3D = %InventoryRightMarker
@onready var inventory_left_marker: Generic6DOFJoint3D = %InventoryLeftMarker
@onready var character: MarbleCharacter = $"."
@onready var body_mesh: MeshInstance3D = %BodyMesh
#endregion


func debug(...args: Array) -> void:
	Debug.debug.emit(args)


#@rpc("call_local","authority")
func action_add(action: Action) -> void:
	var last_action: Action
	if not actions.is_empty():
		last_action = actions.back()
	if last_action and last_action.equals(action):
		last_action.count += 1
		last_action.repeat = true
	else:
		actions.append(action)
	client.actions.update_actions()


#@rpc("any_peer","call_local")
func action_remove(index: int = 0) -> void:
	actions.remove_at(index)
	client.actions.update_actions()


func action_repeat(index: int, toggled_on: bool) -> void:
	actions[index].repeat = toggled_on
	if not actions[index].repeat:
		actions[index].forever = false


func action_reorder(from: int, to: int) -> void:
	var item: Action = actions.pop_at(from)
	actions.insert(to, item)
	client.actions.update_actions()


func action_forever(index: int, toggled_on: bool) -> void:
	actions[index].forever = toggled_on


func action_count_changed(index: int, count: int) -> void:
	actions[index].count = count


func _ready() -> void:
	_apply_color()
	_update_label()


func _physics_process(delta: float) -> void:
	#if is_server():
	age.age = age.age + delta * warp_speed
	#@warning_ignore("narrowing_conversion")
	var new_turn: int = int(age.age / MarbleAge.SECONDS_IN_TURN) + 1
	if new_turn > turn:
		_start_turn(range(self.turn + 1, new_turn + 1))
		self.turn = new_turn


	if not character.is_on_floor():
		if not flying:
			var w_speed: float = min(warp_speed, MAX_CONTROLLED_WARP)
			character.velocity.y -= gravity * delta * (w_speed * w_speed)
		#not on floor and flying
		else:
			character.velocity.y = 0

	_apply_faction_movement(delta)

	character.move_and_slide()


func is_server() -> bool:
	return multiplayer.is_server()


func get_target() -> Object:
	var entity: Object = raycast.get_collider()
	return entity


##verbs the character can do
func get_subject_verbs() -> Array[Callable]:
	return [pick_up]


##verbs that can be done to the character
func get_object_verbs(_subject_verbs: Array[String]) -> Array[Callable]:
	return []


func pick_up(hand: INTERACT, entities: Array, collision_point: Vector3) -> bool:
	#TODO pickup multiple things at once?!
	for entity: Object in entities:
		if entity is PhysicsBody3D:
			if entity is RigidBody3D:
				entity.freeze = false

			if hand == INTERACT.RIGHT:
				right_inventory = entity
				# Move the object so the point of collision is at the hand marker, preserving object rotation
				right_inventory.global_position += inventory_right_marker.global_position - collision_point
				inventory_right_marker.node_b = right_inventory.get_path()
				raycast.add_exception(right_inventory)
			else:
				left_inventory = entity
				# Move the object so the point of collision is at the hand marker, and align rotation with hand
				var local_collision_point: Vector3 = left_inventory.to_local(collision_point)
				var target_transform := inventory_left_marker.global_transform
				var world_offset: Vector3 = target_transform.basis * local_collision_point
				target_transform.origin = inventory_left_marker.global_position - world_offset
				left_inventory.global_transform = target_transform
				inventory_left_marker.node_b = left_inventory.get_path()
				raycast.add_exception(left_inventory)

			return true
	return false

## client calls this. it does not run locally
@rpc("any_peer")
func interact(hand: INTERACT = INTERACT.RIGHT) -> void:
	if !is_server():
		return

	# Perform the raycast once at the start of interaction.
	raycast.force_raycast_update()

	var did_action: bool = false
	# 1. Check for interaction targets first
	if raycast.is_colliding():
		var collision_point := raycast.get_collision_point()
		var object: Object = get_target()

		if object.has_method("get_object_verbs"):
			var subject: Object = self

			if hand == INTERACT.RIGHT:
				if right_inventory and right_inventory.has_method("get_subject_verbs"):
					subject = right_inventory
			elif hand == INTERACT.LEFT:
				if left_inventory and left_inventory.has_method("get_subject_verbs"):
					subject = left_inventory
			if subject.has_method("get_subject_verbs"):
				var subject_verbs: Array[Callable] = subject.get_subject_verbs()

				var object_verbs: Array = object.get_object_verbs(Array(subject_verbs.map(
					func(c: Callable) -> String:
						return c.get_method()
				), TYPE_STRING, "", null))

				did_action = object_verbs.any(func(object_verb: Callable) -> bool:
					#print(object_verb.get_method())
					return subject_verbs.any(func(subject_verb: Callable) -> bool:						#print(subject_verb.get_method())
						if object_verb.get_method() == subject_verb.get_method():
							if subject_verb.get_method() == "pick_up":
								# Directly call pick_up with collision info, bypassing action queue for this specific case
								pick_up(hand, [object], collision_point)
								standard_action = false
							else:
								action_add(Action.new(hand, subject, subject_verb, object_verb, object))
								do_actions()
							return true
						return false
					))
	#print(did_action)

	if not did_action:
		_handle_drop(hand)


func _handle_drop(hand: INTERACT) -> void:
	if hand == INTERACT.RIGHT and right_inventory:
		if right_inventory is RigidBody3D:
			right_inventory.freeze = false
			#remove_collision_exception_with(right_inventory)
		raycast.remove_exception(right_inventory)
		right_inventory = null
		inventory_right_marker.node_b = NodePath()
		inventory_right_marker.set_param_x(Generic6DOFJoint3D.PARAM_ANGULAR_SPRING_EQUILIBRIUM_POINT, 0)
		inventory_right_marker.set_param_y(Generic6DOFJoint3D.PARAM_ANGULAR_SPRING_EQUILIBRIUM_POINT, 0)
		inventory_right_marker.set_param_z(Generic6DOFJoint3D.PARAM_ANGULAR_SPRING_EQUILIBRIUM_POINT, 0)

	elif hand == INTERACT.LEFT and left_inventory:
		if left_inventory is RigidBody3D:
			left_inventory.freeze = false
			#remove_collision_exception_with(left_inventory)
		raycast.remove_exception(left_inventory)
		left_inventory = null
		inventory_left_marker.node_b = NodePath()
		inventory_left_marker.set_param_x(Generic6DOFJoint3D.PARAM_ANGULAR_SPRING_EQUILIBRIUM_POINT, 0)
		inventory_left_marker.set_param_y(Generic6DOFJoint3D.PARAM_ANGULAR_SPRING_EQUILIBRIUM_POINT, 0)
		inventory_left_marker.set_param_z(Generic6DOFJoint3D.PARAM_ANGULAR_SPRING_EQUILIBRIUM_POINT, 0)


func _set_turn(value: int) -> void:
	if label and value != turn:
		_update_label()
	turn = value


func calculate_warp() -> void:
	var closest: WarpMonument = null
	var closest_dist_sq: float = INF
	for key: Variant in warp_detector.warp_monuments:
		var w: WarpMonument = warp_detector.warp_monuments[key]
		var dist_sq: float = w.position.distance_squared_to(character.position)
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


@rpc("any_peer", "call_local")
func server_jump() -> void:
	#if !is_server():
		#return
	if character.is_on_floor() and warp_speed <= MAX_CONTROLLED_WARP:
		character.velocity.y = JUMP_VELOCITY * min(warp_speed, MAX_CONTROLLED_WARP)
	elif flying:
		character.velocity.y = JUMP_VELOCITY * min(warp_speed, MAX_CONTROLLED_WARP)


@rpc("any_peer", "call_local")
func server_fly() -> void:
	#if !is_server():
		#return
	#stop flying
	if flying:
		flying = false
		return

	if not character.is_on_floor() and warp_speed <= MAX_CONTROLLED_WARP:
		if not flying:
			flying = true

		#velocity.y = JUMP_VELOCITY * warp_speed


#this the function that runs on all the peers that only the server can call
@rpc("authority", "call_local", "reliable", 1)
func chat_bubble(message: String) -> void:
	var bubble: Bubble = load("res://src/chat_bubble/ChatBubble.tscn").instantiate()
	bubble.text = message
	chat_bubbles.add_child(bubble)


#TODO make this take multiple turns
func _start_turn(_turns: Array) -> void:
	#print('starting turn %.f'%turn)
	self.standard_action = true
	do_actions()


#this is called on the server
func do_actions() -> void:
	if actions.size() > 0 and standard_action:
		var a: Action = actions[0]
		print(a.subject_verb.get_method())
		a.do.call()

		if not a.forever:
			a.count -= 1


		if a.count <= 0:
			action_remove(0)

		client.actions.update_actions()
		#debug('chop')
		standard_action = false


@rpc("any_peer", "call_local")
func server_set_mode(new_mode: int) -> void:
	if new_mode in [MODE.WALK, MODE.HUSTLE, MODE.CROUCH, MODE.RUN]:
		mode = new_mode as MODE


@rpc("any_peer", "call_local")
func server_move(d: Vector2) -> void:
	#if !is_server():
		#return
	var direction: Vector3 = (character.transform.basis.x * d.x + character.transform.basis.z * d.y).normalized()
	var min_warp_speed: int = min(warp_speed, MAX_CONTROLLED_WARP)
	var move_speed: float = mode * SPEED_MULTIPLIER * speed * min_warp_speed

	if direction:
		character.velocity.x = direction.x * move_speed
		character.velocity.z = direction.z * move_speed
	else:
		character.velocity.x = move_toward(character.velocity.x, 0, move_speed)
		character.velocity.z = move_toward(character.velocity.z, 0, move_speed)
	#if !is_zero_approx(velocity.x) or !is_zero_approx(velocity.z):
	#set_action({"move": mode})
	#play_animation.rpc("walking")
	#if mode in [MODE.HUSTLE, MODE.RUN]:
	#set_action({"action": STRINGS[mode]})
	#else:
	#TODO animation state machine so that walk and crouch can play at the same time
	#play_animation.rpc("RESET")


@rpc("any_peer")
func server_warp(value: int) -> void:
	if !is_server():
		return
	warp_speed = value
	Persistance.persist.emit("MarbleCharacter", self )


func _set_warp_speed(w: int) -> void:
	warp_speed = w
	_update_label()


@rpc("any_peer", "call_local")
func server_turn(value: Vector2) -> void:
	#if !is_server():
		#return
	character.rotate_y(-value.x * .005)
	_rotate_camera(value)


@rpc("any_peer", "call_local")
func server_camera_zoom(scroll_amount: float) -> void:
	#if !is_server():
		#return
	var direction: Vector3 = camera.transform.basis.z
	camera.position += direction * scroll_amount * .1
	camera.position.z = max(camera.position.z, 0)


func _rotate_camera(value: Vector2) -> void:
	camera_pivot.rotate_x(-value.y * .005)
	camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, -PI / 2, PI / 2)

#region persistance functions
func get_data() -> Dictionary:
	return {
		"name": name,
		"parent": str(get_parent().get_path()) if get_parent() else "",
		"scene_file_path": get_scene_file_path(),
		"player_id": player_id,
		"player_name": player_name,
		"warp_speed": warp_speed,
		"age": age.age,
		"turn": turn,
		"transform": var_to_str(character.transform),
		"color": var_to_str(color),
		"left_inventory": left_inventory.name if left_inventory else StringName(""),
		"right_inventory": right_inventory.name if right_inventory else StringName(""),
	}


#don't reference @onready vars
func load_pre_ready(data: Dictionary) -> void:
	if "transform" in data:
		transform = str_to_var(data.transform)
	if "color" in data:
		color = str_to_var(data.color)
	if "player_id" in data:
		player_id = data.player_id


#can reference @onready vars now
func load_post_ready(data: Dictionary) -> void:
	if "age" in data:
		age.age = data.age

	if "left_inventory" in data and data.left_inventory:
		var f: Callable = func(child: Node) -> void:
			if child.name == data.left_inventory:
				left_inventory = child
				#add_collision_exception_with(left_inventory)
				raycast.add_exception(left_inventory)
				inventory_left_marker.node_b = left_inventory.get_path()
				#world.items.child_entered_tree.disconnect(f)

		var l: Node = world.find_child(data.left_inventory, true, false)

		if l: f.call(l)
		else: world.items.child_entered_tree.connect(f)

	if "right_inventory" in data and data.right_inventory:
		var f: Callable = func(child: Node) -> void:
			if child.name == data.right_inventory:
				right_inventory = child
				#add_collision_exception_with(right_inventory)
				raycast.add_exception(right_inventory)
				inventory_right_marker.node_b = right_inventory.get_path()
				#world.items.child_entered_tree.disconnect(f)

		var r: Node = world.find_child(data.right_inventory, true, false)

		if r: f.call(r)
		else: world.items.child_entered_tree.connect(f)
#endregion

func _is_player_controlled() -> bool:
	return player_id != "" and player_id != null


func _apply_faction_movement(delta: float) -> void:
	FactionMovement.apply(self, delta)


func _set_color(value: Color) -> void:
	color = value
	faction = Faction.from_color(color)
	_apply_color()
	_update_label()


func _apply_color() -> void:
	if body_mesh:
		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.albedo_color = color
		body_mesh.material_override = material


func get_faction_name() -> String:
	return Faction.get_faction_name(faction)


func _update_label() -> void:
	if label:
		label.text = "%s [%s] (x%.f)\n turn %.f" % [player_name, get_faction_name(), warp_speed, turn]
