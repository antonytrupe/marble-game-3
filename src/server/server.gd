class_name Server
extends Node

const CHARACTER_SCENE: Resource = preload("res://src/character/character.tscn")
const PLAYER_SCENE: Resource = preload("res://src/player/player.gd")
const STONE_SCENE: Resource = preload("res://src/stone/stone.tscn")
const ACORN_SCENE: Resource = preload("res://src/acorn/acorn.tscn")
const BUSH_SCENE: Resource = preload("res://src/bush/bush.tscn")
const TREE_SCENE: Resource = preload("res://src/tree/tree.tscn")
const APPLE_SCENE: Resource = preload("res://src/apple/apple_3d.tscn")
const AXE_SCENE: Resource = preload("res://src/axe/axe.tscn")
const MOB_SCENE: Resource = preload("res://src/monster/monster.tscn")
const WARP_MONUMENT_SCENE: Resource = preload("res://src/warp_monument/warp_monument.tscn")

## key is unique id
## e.g. Steam:steam_id.
## Any player that has logged in will have an entry here
@export var players: Dictionary = {}
## key is peer_id from @MultiplayerPeer. only currently connected players are in this dictionary
@export var connected_players: Dictionary = {}

@onready var ui: Control = %UI
@onready var world: World = $/root/Game/World
@onready var client: Client = $/root/Game/Client


var lobby_id: int = 0

func _steam_signals() -> void:
	Steam.lobby_created.connect(_on_lobby_created)
	# just for information
	#Steam.join_requested.connect(_on_lobby_join_requested)


func _multiplayer_signals() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)


func _persistance_signals() -> void:
	Persistance.load_player.connect(_load_player)
	Persistance.load_character.connect(_load_character)
	Persistance.load_warp_monument.connect(_load_warp_monument)
	Persistance.load_tree.connect(_load_tree)
	Persistance.load_apple.connect(_load_apple)
	Persistance.load_finished.connect(_load_finished)


func _load_finished() -> void:
	var chars: Array = world.characters.get_children()
	#var mc:Array = chars.map(func(c: Node) -> Node3D:
		#var cc: Node3D = c.get_node("Character")
		#return cc
		#)
	world.underworld_raiser(chars)
	world.underworld_raiser(world.warp_monuments.get_children())
	world.visible = true


func _load_tree(object_name: String, data: Dictionary) -> void:
	var t: MarbleTree = TREE_SCENE.instantiate()
	t.name = object_name.validate_node_name()

	t.ready.connect(t.load_node.bind(data))

	if data.has("transform"):
		t.transform = str_to_var(data.transform)
	world.flora.add_child(t)


func _load_apple(object_name: String, data: Dictionary) -> void:
	var t: Apple3D = APPLE_SCENE.instantiate()
	t.name = object_name.validate_node_name()

	t.ready.connect(t.load_node.bind(data))

	if data.has("transform"):
		t.transform = str_to_var(data.transform)
	world.flora.add_child(t)


func _load_warp_monument(object_name: String, data: Dictionary) -> void:
	var w: WarpMonument = WARP_MONUMENT_SCENE.instantiate()
	w.name = object_name.validate_node_name()

	w.ready.connect(w.load_post_ready.bind(data))
	w.load_pre_ready(data)

	world.warp_monuments.add_child(w)


func _load_character(character_name: String, data: Dictionary) -> void:
	var c: MarbleCharacter = CHARACTER_SCENE.instantiate()
	c.name = character_name.validate_node_name()

	c.load_pre_ready(data)
	c.ready.connect(c.load_post_ready.bind(data))

	world.characters.add_child(c)


func _persist() -> void:
	print('persisting')
	debug('persisting')
	players.keys().all(
		func(player_id: String) -> bool:
			Persistance.persist.emit(players[player_id])
			return true
	)

	world.characters.get_children().all(
		func(character: MarbleCharacter) -> bool:
			Persistance.persist.emit(character)
			return true
	)

	world.warp_monuments.get_children().all(
		func(w: WarpMonument) -> bool:
			Persistance.persist.emit(w)
			return true
	)

	world.flora.get_children().all(
		func(f: Node3D) -> bool:
			Persistance.persist.emit(f)
			return true
	)

	world.fauna.get_children().all(
		func(f: Node3D) -> bool:
			Persistance.persist.emit(f)
			return true
	)


func quit() -> void:
	world.visible = false
	print("server quit")
	Steam.leaveLobby(lobby_id)
	_persist()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		quit()


func hide() -> void:
	ui.visible = false


func debug(...args: Array) -> void:
	Debug.debug.emit(args)


@warning_ignore("shadowed_variable")
func _on_lobby_created(result: int, lobby_id: int) -> void:
	self.lobby_id = lobby_id
	if result == Steam.RESULT_OK:
		var peer: SteamMultiplayerPeer = SteamMultiplayerPeer.new()
		peer.host_with_lobby(lobby_id)

		multiplayer.multiplayer_peer = peer
		# Set the lobby ID
		#debug("Created a lobby: %s" % lobby_id)

		# Set this lobby as joinable, just in case, though this should be done by default
		Steam.setLobbyJoinable(lobby_id, true)

		# Allow P2P connections to fallback to being relayed through Steam if needed
		var set_relay: bool = Steam.allowP2PPacketRelay(true)
		print("Allowing Steam to be relay backup: %s" % set_relay)

		Steam.setRichPresence("connect", str(lobby_id))

		#set up the host player
		_on_peer_connected(multiplayer.get_unique_id())


func start() -> void:
	_multiplayer_signals()
	_persistance_signals()
	_steam_signals()
	# load everything from persistance

	#world.visible = true
	Persistance.load.emit()

	get_viewport().get_window().title += " - " + "SERVER"

	var lobby_members_max: int = 4
	#fires _on_lobby_created
	Steam.createLobby(Steam.LobbyType.LOBBY_TYPE_PUBLIC, lobby_members_max)


@rpc("any_peer", "call_local")
func chat(message: String) -> void:
	debug(message)
	#find the character that sent
	var peer_id: int = multiplayer.get_remote_sender_id()
	var steam_id: int = multiplayer.multiplayer_peer.get_steam_id_for_peer_id(peer_id)


	#debug('steam_id:%s' % steam_id)
	var player: Player = players['Steam:%s'%steam_id]
	#debug('p.current_character_id:%s' % p.current_character_id)
	var c_name: String = str(player.current_character_id)
	var character: MarbleCharacter = world.characters.get_node(c_name)
	if message.begins_with("/"):
		command(message, player, character)
	else:
		character.chat_bubble.rpc(message)


#this is the function that runs on the server that any peer can call
#@rpc("any_peer", "call_remote", "reliable", 1)
#func server_chat(message: String):
	#if message.begins_with("/"):
		#game.command(message, self)
	#else:
		#client_chat.rpc(message)


func command(cmd: String, _player: Player, character: MarbleCharacter) -> void:
	print(cmd)
	if !multiplayer.is_server():
		print("not server")
		return
	var parts: PackedStringArray = cmd.replace("/", "").split(" ")
	match parts[0]:
		"persist":
			_persist()
		"loc", "pos", "position", "location":
			pass
			print("%.f %.f %.f" % [character.position.x, character.position.y, character.position.z])
		"s", "switch":
			print("switch")
			var target: Object = character.get_target()
			if target:
				print(target.name)
				print(target)
				#Signals.CurrentPlayer.emit(target)
			else:
				print("no target")
		"teleport", "tele":
			if parts.size() >= 4:
				character.position = Vector3(float(parts[1]), float(parts[2]), float(parts[3]))
		"wander":
			var count: int = 10
			if parts.size() >= 2:
				count = int(parts[1])
			character._wander(count)
		"action":
			#todo create the action
			var count: int = 1
			var frequency: int = 1
			if parts.size() >= 2:
				count = int(parts[1])
				if parts.size() >= 3:
					frequency = int(parts[2])
			character.add_action(count, frequency)
		"spawn", "/spawn":
			match parts[1]:
				"axe":
					_spawn_axe(1,character.position)
				"monument", "warp":
					_spawn_warp_monument(character.position)
				"mob", "monster":
					var count: int = 1
					if parts.size() >= 3:
						count = int(parts[2])
					_spawn_mob(count, character.position)
				"stone", "stones", "rocks", "rock":
					var count: int = 1
					if parts.size() >= 3:
						count = int(parts[2])
					_spawn_stones(count, character.position)

				"acorn", "acorns":
					var count: int = 1
					if parts.size() >= 3:
						count = int(parts[2])
					count = clampi(count, 1, 100)
					_spawn_acorns(count, character.position)

				"bush", "bushes":
					var count: int = 1
					if parts.size() >= 3:
						count = int(parts[2])
					_spawn_bushes(count, character.position)

				"tree", "trees":
					var count: int = 1
					if parts.size() >= 3:
						count = int(parts[2])
					var maturity_ratio: float = 0.0
					if parts.size() >= 4:
						maturity_ratio = float(parts[3])
					_spawn_trees(count, character.position, maturity_ratio)

				"apple", "apples":
					var count: int = 1
					if parts.size() >= 3:
						count = int(parts[2])
					_spawn_apples(count, character.position)


func _get_random_vector(radius: float, center: Vector3) -> Vector3:
	#var rng = RandomNumberGenerator.new()
	var r: float = radius * sqrt(randf())
	var theta: float = randf() * 2 * PI
	var x: float = center.x + r * cos(theta)
	var z: float = center.z + r * sin(theta)
	var y: float = world.get_ground_y(x, z)
	return Vector3(x, y, z)


func _spawn_warp_monument(center: Vector3) -> void:
	var m: WarpMonument = WARP_MONUMENT_SCENE.instantiate()
	m.name = m.name + "%010d" % randi()
	#var chunk = chunks.get_chunk(center)
	var y: float = randf_range(0, PI)
	#print("y:", y) # Debug

	m.rotation.y = y
	var p: Vector3 = _get_random_vector(10, center)

	m.position = p
	world.warp_monuments.add_child(m)


func _spawn_acorns(count: int, center: Vector3) -> void:
	count = clampi(count, 1, 100)
	for i: int in count:
		var acorn: Acorn = ACORN_SCENE.instantiate()
		acorn.name = acorn.name + "%010d" % randi()
		acorn.global_position = _get_random_vector(10, center)
		#var chunk = chunks.get_chunk(acorn.global_position)
		world.flora.add_child(acorn)


func _spawn_bushes(count: int, center: Vector3) -> void:
	count = clampi(count, 1, 100)
	for i: int in count:
		var bush: MarbleBush = BUSH_SCENE.instantiate()
		bush.name = bush.name + "%010d" % randi()
		bush.position = _get_random_vector(10, center)
		#var chunk = chunks.get_chunk(bush.global_position)
		world.flora.add_child(bush)


func _spawn_axe(count: int, center: Vector3) -> void:
	count = clampi(count, 1, 100)
	for i: int in count:
		var axe: Axe = AXE_SCENE.instantiate()
		axe.name = axe.name + "%010d" % randi()
		#TODO do this more righter
		axe.position = _get_random_vector(10 + count, center)

		#axe.ready.connect(axe.load_post_ready.bind(data))
		#var chunk = chunks.get_chunk(tree.global_position)
		world.flora.add_child(axe)


func _spawn_trees(count: int, center: Vector3, maturity_ratio: float = 0.0) -> void:
	count = clampi(count, 1, 100)
	for i: int in count:
		var tree: MarbleTree = TREE_SCENE.instantiate()
		tree.name = tree.name + "%010d" % randi()
		#TODO do this more righter
		tree.position = _get_random_vector(10 + count, center)

		tree.ready.connect(func() -> void:
			tree.age.age = tree.maturity * maturity_ratio
			)
		#var chunk = chunks.get_chunk(tree.global_position)
		world.flora.add_child(tree)


func _spawn_apples(count: int, center: Vector3) -> void:
	count = clampi(count, 1, 100)
	for i: int in count:
		var apple: Apple3D = APPLE_SCENE.instantiate()
		apple.name = apple.name + "%010d" % randi()
		#TODO do this more righter
		apple.position = _get_random_vector(10, center)
		apple.position.y = 15
		#var chunk = chunks.get_chunk(tree.global_position)
		world.flora.add_child(apple)


func _spawn_stones(quantity: int, p: Vector3) -> void:
	print('_spawn_stones')
	quantity = clampi(quantity, 1, 100)
	for i: int in quantity:
		var stone: Stone = STONE_SCENE.instantiate()
		stone.name = stone.name + "%010d" % randi()
		stone.position = _get_random_vector(10, p)
		#var chunk: Chunk = chunks.get_chunk(stone.global_position)
		world.terra.add_child(stone)


func _spawn_mob(count: int, center: Vector3) -> void:
	for i: int in count:
		var mob: Monster = MOB_SCENE.instantiate()
		mob.name = mob.name + "%010d" % randi()
		#var chunk = chunks.get_chunk(center)
		var y: float = randf_range(0, PI)
		#print("y:", y) # Debug

		mob.rotation.y = y
		mob.position = _get_random_vector(10, center)
		world.fauna.add_child(mob)

		#print("After rotation:", mob.rotation.y) # Debug


func _load_player(player_name: String, data: Dictionary) -> void:
	var p: Player = PLAYER_SCENE.new()
	p.name = player_name

	if data.has("current_character_id"):
		p.current_character_id = data.current_character_id
	if data.has("characters"):
		p.characters = data.characters

	players[player_name] = p

## peer_id from multiplayer_peer
## player_id Steam:steam_id
func _create_player(peer_id: int, player_id: String) -> Player:
	var p: Player = PLAYER_SCENE.new()
	p.peer_id = peer_id
	p.name = player_id
	var c: MarbleCharacter = _create_character()
	c.player_id = player_id
	p.characters.append(c.name)
	p.current_character_id = c.name
	#c.set_multiplayer_authority(peer_id)
	Persistance.persist.emit(p)

	players[player_id] = p
	connected_players[peer_id] = p

	return p


## peer_id from multiplayer_peer, 1 for host
func _on_peer_connected(peer_id: int = 1) -> void:
	#debug("Peer connected with ID: %s" % peer_id)
	var steam_id: int
	var friend_name: String
	if multiplayer.has_multiplayer_peer():
		steam_id = (multiplayer.multiplayer_peer as SteamMultiplayerPeer).get_steam_id_for_peer_id(peer_id)
		#debug("steam id: %s" % steam_id)
		friend_name = Steam.getFriendPersonaName(steam_id)
		#debug("friend_name: %s" % friend_name)

	var player_id: String = "Steam:" + str(steam_id)
	# see if the player exists already
	var p: Player
	if players.has(player_id):
		#Debug.info.emit("found player")
		p = players[player_id]
	else:
		#Debug.info.emit("did not find player")
		p = _create_player(peer_id, player_id)
		players[player_id] = p

	connected_players[peer_id] = p
	if peer_id == 1:
		client.set_current_character(p.current_character_id)
	else:
		client.set_current_character.rpc_id(peer_id, p.current_character_id)

	#set the player_name of the character
	var c: MarbleCharacter = world.characters.get_node(p.current_character_id)
	c.player_name = friend_name
	c._update_label()

func _on_peer_disconnected(peer_id: int) -> void:
	#debug("Peer disconnected with ID: %s" % peer_id)
	var p: Player = connected_players[peer_id]
	var c: MarbleCharacter = world.characters.get_node(p.current_character_id)
	#"clear" the player_name of the character
	c.player_name = "(%s)" % c.player_name
	Persistance.persist.emit(c)
	c._update_label()

	connected_players.erase(peer_id)


func _create_character() -> MarbleCharacter:
	#debug("_create_character")
	var c: MarbleCharacter = CHARACTER_SCENE.instantiate()
	c.name = str(randi())
	c.position = Vector3(randf_range(-100, 100), 20, randf_range(-100, 100))
	world.characters.add_child(c)
	Persistance.persist.emit(c)
	return c
