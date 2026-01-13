class_name Server
extends Node

const CHARACTER_SCENE = preload("res://src/character/character.tscn")
const PLAYER_SCENE = preload("res://src/player/player.gd")
const STONE_SCENE = preload("res://src/stone/stone.tscn")
const ACORN_SCENE = preload("res://src/acorn/acorn.tscn")
const BUSH_SCENE = preload("res://src/bush/bush.tscn")
const TREE_SCENE = preload("res://src/tree/tree.tscn")
const MOB_SCENE = preload("res://src/monster/monster.tscn")
const WARP_MONUMENT_SCENE = preload("res://src/warp_monument/warp_monument.tscn")

## key is unique id
## e.g. Steam:steam_id.
## Any player that has logged in will have an entry here
@export var players: Dictionary = {}
## key is peer_id from @MultiplayerPeer. only currently connected players are in this dictionary
@export var connected_players: Dictionary = {}

@onready var ui = %UI
@onready var world: World = $/root/Game/World
@onready var client: Client = $/root/Game/Client


var lobby_id = 0

func _steam_signals():
	Steam.lobby_created.connect(_on_lobby_created)
	# just for information
	#Steam.join_requested.connect(_on_lobby_join_requested)


func _multiplayer_signals():
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)


func _persistance_signals():
	Persistance.load_player.connect(_load_player)
	Persistance.load_character.connect(_load_character)
	Persistance.load_warp_monument.connect(_load_warp_monument)
	Persistance.load_tree.connect(_load_tree)
	Persistance.load_finished.connect(_load_finished)


func _load_finished():
	world.underworld_raiser(world.characters.get_children())
	world.underworld_raiser(world.warp_monuments.get_children())
	world.visible = true


func _load_tree(object_name, data: Dictionary):
	var t: MarbleTree = TREE_SCENE.instantiate()
	t.name = object_name

	t.ready.connect(t.load_node.bind(data))

	if data.has("transform"):
		t.transform = str_to_var(data.transform)
	world.flora.add_child(t)


func _load_warp_monument(object_name, data: Dictionary):
	var w: WarpMonument = WARP_MONUMENT_SCENE.instantiate()
	w.name = object_name

	w.ready.connect(w.load_node.bind(data))

	if data.has("transform"):
		w.transform = str_to_var(data.transform)
	world.warp_monuments.add_child(w)


func _load_character(character_name, data: Dictionary):
	var c: MarbleCharacter = CHARACTER_SCENE.instantiate()
	c.name = character_name

	c.ready.connect(c.load_node.bind(data))

	if data.has("transform"):
		c.transform = str_to_var(data.transform)
	world.characters.add_child(c)


func _persist():
	players.keys().all(
		func(player_id):
			Persistance.persist.emit("Player", players[player_id])
			return true
	)

	world.characters.get_children().all(
		func(character):
			Persistance.persist.emit("MarbleCharacter", character)
			return true
	)

	world.warp_monuments.get_children().all(
		func(w):
			Persistance.persist.emit("WarpMonument", w)
			return true
	)

	world.flora.get_children().all(
		func(w):
			Persistance.persist.emit("MarbleTree", w)
			return true
	)


func quit():
	world.visible = false
	print("server quit")
	Steam.leaveLobby(lobby_id)
	_persist()


func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		quit()


func hide():
	ui.visible = false


func debug(...args: Array):
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


func start():
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
func chat(message):
	debug(message)
	#find the character that sent
	var peer_id = multiplayer.get_remote_sender_id()
	var steam_id = multiplayer.multiplayer_peer.get_steam_id_for_peer_id(peer_id)


	#debug('steam_id:%s' % steam_id)
	var player: Player = players['Steam:%s'%steam_id]
	#debug('p.current_character_id:%s' % p.current_character_id)
	var c_name = str(player.current_character_id)
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


func command(cmd: String, _player: Player, character: MarbleCharacter):
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
			var target = character.get_target()
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
			var count = 10
			if parts.size() >= 2:
				count = int(parts[1])
			character._wander(count)
		"action":
			#todo create the action
			var count = 1
			var frequency = 1
			if parts.size() >= 2:
				count = int(parts[1])
				if parts.size() >= 3:
					frequency = int(parts[2])
			character.add_action(count, frequency)
		"spawn", "/spawn":
			match parts[1]:
				"monument", "warp":
					_spawn_warp_monument(character.position)
				"mob", "monster":
					var count = 1
					if parts.size() >= 3:
						count = int(parts[2])
					_spawn_mob(count, character.position)
				"stone", "stones", "rocks", "rock":
					var count = 1
					if parts.size() >= 3:
						count = int(parts[2])
					_spawn_stones(count, character.position)

				"acorn", "acorns":
					var count = 1
					if parts.size() >= 3:
						count = int(parts[2])
					count = clampi(count, 1, 100)
					_spawn_acorns(count, character.position)

				"bush", "bushes":
					var count = 1
					if parts.size() >= 3:
						count = int(parts[2])
					_spawn_bushes(count, character.position)

				"tree", "trees":
					var count = 1
					if parts.size() >= 3:
						count = int(parts[2])
					_spawn_trees(count, character.position)


func _get_random_vector(radius: float, center: Vector3) -> Vector3:
	#var rng = RandomNumberGenerator.new()
	var r = radius * sqrt(randf())
	var theta = randf() * 2 * PI
	var x = center.x + r * cos(theta)
	var z = center.z + r * sin(theta)
	var y = world.get_ground_y(x, z)
	return Vector3(x, y, z)


func _spawn_warp_monument(center: Vector3):
	var m: WarpMonument = WARP_MONUMENT_SCENE.instantiate()
	m.name = m.name + "%010d" % randi()
	#var chunk = chunks.get_chunk(center)
	var y = randf_range(0, PI)
	#print("y:", y) # Debug

	m.rotation.y = y
	var p: Vector3 = _get_random_vector(10, center)

	m.position = p
	world.warp_monuments.add_child(m)


func _spawn_acorns(count: int, center: Vector3):
	count = clampi(count, 1, 100)
	for i in count:
		var acorn = ACORN_SCENE.instantiate()
		acorn.name = acorn.name + "%010d" % randi()
		acorn.global_position = _get_random_vector(10, center)
		#var chunk = chunks.get_chunk(acorn.global_position)
		world.flora.add_child(acorn)


func _spawn_bushes(count: int, center: Vector3):
	count = clampi(count, 1, 100)
	for i in count:
		var bush = BUSH_SCENE.instantiate()
		bush.name = bush.name + "%010d" % randi()
		bush.position = _get_random_vector(10, center)
		#var chunk = chunks.get_chunk(bush.global_position)
		world.flora.add_child(bush)


func _spawn_trees(count: int, center: Vector3):
	count = clampi(count, 1, 100)
	for i in count:
		var tree = TREE_SCENE.instantiate()
		tree.name = tree.name + "%010d" % randi()
		#TODO do this more righter
		tree.position = _get_random_vector(10, center)
		#var chunk = chunks.get_chunk(tree.global_position)
		world.flora.add_child(tree)


func _spawn_stones(quantity: int, p: Vector3):
	print('_spawn_stones')
	quantity = clampi(quantity, 1, 100)
	for i in quantity:
		var stone = STONE_SCENE.instantiate()
		stone.name = stone.name + "%010d" % randi()
		stone.position = _get_random_vector(10, p)
		#var chunk: Chunk = chunks.get_chunk(stone.global_position)
		world.terra.add_child(stone)


func _spawn_mob(count: int, center: Vector3):
	for i in count:
		var mob = MOB_SCENE.instantiate()
		mob.name = mob.name + "%010d" % randi()
		#var chunk = chunks.get_chunk(center)
		var y = randf_range(0, PI)
		#print("y:", y) # Debug

		mob.rotation.y = y
		mob.position = _get_random_vector(10, center)
		world.fauna.add_child(mob)

		#print("After rotation:", mob.rotation.y) # Debug


func _load_player(player_name, data: Dictionary):
	var p = PLAYER_SCENE.new()
	p.name = player_name

	if data.has("current_character_id"):
		p.current_character_id = data.current_character_id
	if data.has("characters"):
		p.characters = data.characters

	players[player_name] = p

## peer_id from multiplayer_peer
## player_id Steam:steam_id
func _create_player(peer_id, player_id) -> Player:
	var p = PLAYER_SCENE.new()
	p.peer_id = peer_id
	p.name = player_id
	var c = _create_character()
	c.player_id = player_id
	p.characters.append(c.name)
	p.current_character_id = c.name
	#c.set_multiplayer_authority(peer_id)
	Persistance.persist.emit("Player", p)

	players[player_id] = p
	connected_players[peer_id] = p

	return p


## peer_id from multiplayer_pee, 1 for host
func _on_peer_connected(peer_id = 1):
	#debug("Peer connected with ID: %s" % peer_id)
	var steam_id: int
	var friend_name: String
	if multiplayer.has_multiplayer_peer():
		steam_id = (multiplayer.multiplayer_peer as SteamMultiplayerPeer).get_steam_id_for_peer_id(peer_id)
		#debug("steam id: %s" % steam_id)
		friend_name = Steam.getFriendPersonaName(steam_id)
		#debug("friend_name: %s" % friend_name)

	var player_id = "Steam:" + str(steam_id)
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

func _on_peer_disconnected(peer_id):
	#debug("Peer disconnected with ID: %s" % peer_id)
	var p: Player = connected_players[peer_id]
	var c: MarbleCharacter = world.characters.get_node(p.current_character_id)
	#"clear" the player_name of the character
	c.player_name = "(%s)" % c.player_name
	Persistance.persist.emit("MarbleCharacter", c)
	c._update_label()

	connected_players.erase(peer_id)


func _create_character():
	#debug("_create_character")
	var c: MarbleCharacter = CHARACTER_SCENE.instantiate()
	c.name = str(randi())
	c.position = Vector3(randf_range(-100, 100), 0, randf_range(-100, 100))
	world.characters.add_child(c)
	Persistance.persist.emit("MarbleCharacter", c)
	return c
