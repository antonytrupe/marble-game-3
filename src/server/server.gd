class_name Server
extends Node

## key is scene_file_path
var scenes: Dictionary[String, Resource] = {}

## key is unique id
## e.g. Steam:steam_id.
## Any player that has ever logged in will have an entry here
#@export var players: Dictionary = {}
## key is peer_id from @MultiplayerPeer. only currently connected players are in this dictionary
@export var connected_players: Dictionary = {}

@onready var ui: Control = %UI
@onready var world: World = $/root/Game/World
@onready var client: Client = $/root/Game/Client
@onready var players: Node = %Players


var lobby_id: int = 0
var use_steam: bool = true


func _steam_signals() -> void:
	if not use_steam:
		return
	Steam.lobby_created.connect(_on_lobby_created)
	# just for information
	#Steam.join_requested.connect(_on_lobby_join_requested)


func _multiplayer_signals() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)


func _persistance_signals() -> void:
	Persistance.load_object.connect(_load_object)
	Persistance.load_finished.connect(_load_finished)


func _load_finished() -> void:
	world.underworld_raiser(world.characters.get_children())
	world.underworld_raiser(world.fauna.get_children())
	world.underworld_raiser(world.warp_monuments.get_children())
	world.visible = true


func _get_resource_(p_scene_file_path: String) -> Resource:
	if not scenes.has(p_scene_file_path):
		scenes[p_scene_file_path] = load(p_scene_file_path)
	return scenes[p_scene_file_path]


func _load_object(object_name: String, data: Dictionary) -> void:
	#var t:Node
	var t: Node = get_node_or_null(data.parent + "/" + data.name)
	if not t:
		if data.has("scene_file_path"):
			t = _get_resource_(data.scene_file_path).instantiate()
		#elif data.has("script"):
			#t = _get_resource(data.script).new()
		t.name = object_name.validate_node_name()

	if t.has_signal("ready") and t.has_method("load_post_ready"):
		t.ready.connect(t.load_post_ready.bind(data))

	if t.has_method("load_pre_ready"):
		t.load_pre_ready(data)

	if !t.get_parent():
		get_node_or_null(data.parent).add_child(t)


func _persist() -> void:
	print('persisting')
	debug('persisting')

	#Persistance.persist.emit(self)

	get_tree().get_nodes_in_group('persist').all(
		func(n: Node) -> bool:
			Persistance.persist.emit(n)
			return true
	)


func quit() -> void:
	world.visible = false
	print("server quit")
	if use_steam:
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
	use_steam = Steam.isSteamRunning()
	_multiplayer_signals()
	_persistance_signals()
	_steam_signals()
	# load everything from persistance

	#world.visible = true
	Persistance.load_game.emit()

	get_viewport().get_window().title += " - " + "SERVER"

	if use_steam:
		var lobby_members_max: int = 4
		#fires _on_lobby_created
		Steam.createLobby(Steam.LobbyType.LOBBY_TYPE_PUBLIC, lobby_members_max)
	else:
		print("Starting server without Steam (using ENet)")
		var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
		peer.create_server(9999)
		multiplayer.multiplayer_peer = peer
		_on_peer_connected(multiplayer.get_unique_id())


@rpc("any_peer", "call_local")
func chat(message: String) -> void:
	debug(message)
	#find the character that sent
	var peer_id: int = multiplayer.get_remote_sender_id()
	var player: Player
	if use_steam:
		var steam_id: int = (multiplayer.multiplayer_peer as SteamMultiplayerPeer).get_steam_id_for_peer_id(peer_id)
		#debug('steam_id:%s' % steam_id)
		player = players.get_node('Steam_%s' % steam_id)
	else:
		player = connected_players.get(peer_id)
	#debug('p.current_character_id:%s' % p.current_character_id)
	var c_name: String = str(player.current_character_id)
	var character: MarbleCharacter = world.characters.get_node(c_name)
	if message.begins_with("/"):
		command(message, player, character)
	else:
		character.chat_bubble.rpc(message)


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
			debug("%.f %.f %.f" % [character.position.x, character.position.y, character.position.z])
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
		"spawn", "/spawn":
			_spawn(character, parts)


func _spawn(character: MarbleCharacter, parts: Array) -> void:
	if parts.size() < 2: # must have at least /spawn <item>
		return

	var count: int = 1
	if parts.size() >= 3 and parts[2].is_valid_int():
		count = int(parts[2])

	var maturity_ratio: float = 0.0
	if parts.size() >= 4 and parts[3].is_valid_float():
		maturity_ratio = float(parts[3])

	var spawn_map: Dictionary = {
		"saw": _spawn_saws, "saws": _spawn_saws,
		"board": _spawn_boards, "boards": _spawn_boards,
		"log": _spawn_logs, "logs": _spawn_logs,
		"axe": _spawn_axe,
		"mob": _spawn_mob, "monster": _spawn_mob, "mobs": _spawn_mob, "monsters": _spawn_mob,
		"stone": _spawn_stones, "stones": _spawn_stones, "rock": _spawn_stones, "rocks": _spawn_stones,
		"acorn": _spawn_acorns, "acorns": _spawn_acorns,
		"bush": _spawn_bushes, "bushes": _spawn_bushes,
		"apple": _spawn_apples, "apples": _spawn_apples,
		"spring": func(_count: int, _center: Vector3) -> void: _spawn_spring(character),
		"character": func(c: int, p: Vector3) -> void: _spawn_characters(c, p),
		"char": func(c: int, p: Vector3) -> void: _spawn_characters(c, p),
		"characters": func(c: int, p: Vector3) -> void: _spawn_characters(c, p),
	}

	var spawn_type: String = parts[1]
	match spawn_type:
		"tree", "trees":
			_spawn_trees(count, character.position, maturity_ratio, character)
		"cant", "cants":
			_spawn_cants(character.position)
		"monument", "warp":
			_spawn_warp_monument(character.position)
		_:
			if spawn_map.has(spawn_type):
				spawn_map[spawn_type].call(count, character.position)


func _get_random_vector(radius: float, center: Vector3) -> Vector3:
	#var rng = RandomNumberGenerator.new()
	var r: float = radius * sqrt(randf())
	var theta: float = randf() * 2 * PI
	var x: float = center.x + r * cos(theta)
	var z: float = center.z + r * sin(theta)
	var y: float = world.get_ground_y(x, z)
	return Vector3(x, y, z)


func _spawn_warp_monument(center: Vector3) -> void:
	var m: WarpMonument = WarpMonument.scene.instantiate()
	#WARP_MONUMENT_SCENE.instantiate()
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
		var acorn: Acorn = Acorn.scene.instantiate()
		acorn.name = acorn.name + "%010d" % randi()
		acorn.global_position = _get_random_vector(10, center)
		#var chunk = chunks.get_chunk(acorn.global_position)
		world.flora.add_child(acorn)


func _spawn_bushes(count: int, center: Vector3) -> void:
	count = clampi(count, 1, 100)
	for i: int in count:
		var bush: MarbleBush = MarbleBush.scene.instantiate()
		bush.name = bush.name + "%010d" % randi()
		bush.position = _get_random_vector(10, center)
		#var chunk = chunks.get_chunk(bush.global_position)
		world.flora.add_child(bush)


func _spawn_axe(count: int, center: Vector3) -> void:
	count = clampi(count, 1, 100)
	for i: int in count:
		var axe: Axe = Axe.scene.instantiate()
		axe.name = axe.name + "%010d" % randi()
		axe.position = _get_random_vector(1, center)

		axe.ready.connect(axe.load_post_ready.bind({}))
		#var chunk = chunks.get_chunk(tree.global_position)
		world.items.add_child(axe)


func _spawn_trees(count: int, center: Vector3, maturity_ratio: float = 0.0, character: MarbleCharacter = null) -> void:
	count = clampi(count, 1, 100)
	var max_maturity_ratio: float = 1.0 if maturity_ratio <= 0.0 else maturity_ratio
	var random_maturity_ratio: float = randf() * max_maturity_ratio

	var existing_trees: Array[MarbleTree] = []
	for node in world.flora.get_children():
		if node is MarbleTree:
			existing_trees.append(node)

	for i: int in count:
		var pos: Vector3
		if count == 1 and character != null:
			var forward: Vector3 = -character.transform.basis.z.normalized()
			pos = center + (forward * 4.0)
			pos.y = world.get_ground_y(pos.x, pos.z)
		else:
			pos = _get_random_vector(10 + count, center)

		for attempt in 50:
			var too_close: bool = false
			for tree_node in existing_trees:
				if pos.distance_to(tree_node.position) < 5.0:
					too_close = true
					break
			if not too_close:
				break
			pos = _get_random_vector(10 + count, center)

		var tree: MarbleTree = MarbleTree.scene.instantiate()
		tree.name = tree.name + "%010d" % randi()
		#TODO do this more righter
		tree.position = pos

		
		tree.ready.connect(tree.load_post_ready.bind({
			"age": tree.maturity * random_maturity_ratio,
			"turn": (tree.maturity * random_maturity_ratio) / MarbleAge.SECONDS_IN_TURN
		}))


		#var chunk = chunks.get_chunk(tree.global_position)
		world.flora.add_child(tree)
		existing_trees.append(tree)


func spawn_log(p_position: Vector3, p_scale: float) -> MarbleLog:
	var l: MarbleLog = MarbleLog.scene.instantiate()
	l.name = l.name + "%010d" % randi()
	l.position = p_position
	l.log_scale = p_scale

	l.ready.connect(l.load_post_ready.bind({}))
	#var chunk = chunks.get_chunk(tree.global_position)
	world.flora.add_child(l)

	l.freeze = false
	l.apply_torque_impulse(Vector3(1, 0, 0))
	return l


func spawn_stump(p_position: Vector3, maturity_ratio: float = 1.0) -> void:
	var stump: Stump = Stump.scene.instantiate()
	stump.name = stump.name + "%010d" % randi()
	stump.position = p_position
	stump.stump_scale = maturity_ratio
	#stump.ready.connect(func() -> void:
		#stump.age.age = stump.maturity * maturity_ratio
		#)
	#var chunk = chunks.get_chunk(tree.global_position)
	world.flora.add_child(stump)


func spawn_cant(p_transform: Transform3D, _p_scale: float) -> Cant:
	var c: Cant = Cant.scene.instantiate()
	c.name = c.name + "%010d" % randi()
	c.transform = p_transform
	#c.log_scale = p_scale

	#c.ready.connect(c.load_post_ready.bind({}))
	#var chunk = chunks.get_chunk(tree.global_position)
	world.flora.add_child(c)

	c.freeze = false
	return c


func _spawn_cants(p_position: Vector3) -> Cant:
	var b: Cant = Cant.scene.instantiate()
	b.name = b.name + "%010d" % randi()
	b.position = p_position
	#c.log_scale = p_scale

	#c.ready.connect(c.load_post_ready.bind({}))
	#var chunk = chunks.get_chunk(tree.global_position)
	world.flora.add_child(b)

	b.freeze = false
	return b


func _spawn_boards(p_position: Vector3, count: int) -> void:
	count = clampi(count, 1, 100)
	for i: int in count:
		var b: Board = Board.scene.instantiate()
		b.name = b.name + "%010d" % randi()
		b.position = _get_random_vector(2 + count, p_position)
		#c.log_scale = p_scale

		#c.ready.connect(c.load_post_ready.bind({}))
		#var chunk = chunks.get_chunk(tree.global_position)
		world.flora.add_child(b)

		b.freeze = false


func spawn_board(p_transform: Transform3D, _p_scale: float) -> Board:
	var b: Board = Board.scene.instantiate()
	b.name = b.name + "%010d" % randi()
	b.transform = p_transform
	#c.log_scale = p_scale

	#c.ready.connect(c.load_post_ready.bind({}))
	#var chunk = chunks.get_chunk(tree.global_position)
	world.flora.add_child(b)

	b.freeze = false
	return b


func _spawn_apples(count: int, center: Vector3) -> void:
	count = clampi(count, 1, 10000)
	for i: int in count:
		var apple: Apple3D = Apple3D.scene.instantiate()
		apple.name = apple.name + "%010d" % randi()
		apple.position = _get_random_vector(10, center)
		#var chunk = chunks.get_chunk(tree.global_position)
		world.flora.add_child(apple)


func _spawn_saws(count: int, center: Vector3) -> void:
	count = clampi(count, 1, 100)
	for i: int in count:
		var l: Saw = Saw.scene.instantiate()
		l.name = l.name + "%010d" % randi()
		l.position = _get_random_vector(10, center)
		#var chunk = chunks.get_chunk(tree.global_position)
		world.items.add_child(l)


func _spawn_logs(count: int, center: Vector3) -> void:
	count = clampi(count, 1, 100)
	for i: int in count:
		var l: MarbleLog = MarbleLog.scene.instantiate()
		l.name = l.name + "%010d" % randi()
		l.position = _get_random_vector(10, center)
		#var chunk = chunks.get_chunk(tree.global_position)
		world.flora.add_child(l)


func _spawn_stones(quantity: int, p: Vector3) -> void:
	print('_spawn_stones')
	quantity = clampi(quantity, 1, 100)
	for i: int in quantity:
		var stone: Stone = Stone.scene.instantiate()
		stone.name = stone.name + "%010d" % randi()
		stone.position = _get_random_vector(10, p)
		#var chunk: Chunk = chunks.get_chunk(stone.global_position)
		world.terra.add_child(stone)


func _spawn_spring(character: MarbleCharacter) -> void:
	var spring: Spring = Spring.scene.instantiate()
	spring.name = spring.name + "%010d" % randi()

	var forward: Vector3 = -character.global_transform.basis.z.normalized()
	var spawn_position: Vector3 = character.global_position + (forward * 4.0)
	spawn_position.y = world.get_ground_y(spawn_position.x, spawn_position.z)
	spring.position = spawn_position
	world.terra.add_child(spring)
	Persistance.persist.emit.call_deferred(spring)


func _spawn_mob(count: int, center: Vector3) -> void:
	for i: int in count:
		var mob: Monster = Monster.scene.instantiate()
		mob.name = mob.name + "%010d" % randi()
		#var chunk = chunks.get_chunk(center)
		var y: float = randf_range(0, PI)
		#print("y:", y) # Debug

		mob.rotation.y = y
		mob.position = _get_random_vector(10, center)
		world.fauna.add_child(mob)


## peer_id from multiplayer_peer
## player_id Steam:steam_id
func _create_player(peer_id: int, player_id: String) -> Player:
	var p: Player = Player.scene.instantiate()
	p.peer_id = peer_id
	p.name = player_id
	var c: MarbleCharacter = _create_character()
	c.player_id = player_id
	p.characters.append(c.name)
	p.current_character_id = c.name
	#c.set_multiplayer_authority(peer_id)


	players.add_child(p)
	connected_players[peer_id] = p
	Persistance.persist.emit.call_deferred(p)

	return p


## peer_id from multiplayer_peer, 1 for host
func _on_peer_connected(peer_id: int = 1) -> void:
	#debug("Peer connected with ID: %s" % peer_id)
	var steam_id: int = 0
	var friend_name: String = ""
	if use_steam and multiplayer.has_multiplayer_peer():
		steam_id = (multiplayer.multiplayer_peer as SteamMultiplayerPeer).get_steam_id_for_peer_id(peer_id)
		#debug("steam id: %s" % steam_id)
		friend_name = Steam.getFriendPersonaName(steam_id)
		#debug("friend_name: %s" % friend_name)

	var player_id: String
	if use_steam:
		player_id = "Steam_" + str(steam_id)
	else:
		player_id = "ENet_" + str(peer_id)
		friend_name = "Player_" + str(peer_id)
	# see if the player exists already
	var p: Player
	if players.has_node(player_id):
		#Debug.info.emit("found player")
		p = players.get_node(player_id)
	else:
		#Debug.info.emit("did not find player")
		p = _create_player(peer_id, player_id)
		#players.add_child( p)

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


func _spawn_characters(count: int, center: Vector3) -> void:
	count = maxi(count, 1)
	for i: int in count:
		var c: MarbleCharacter = _create_character()
		c.position = _get_random_vector(10, center)


func _create_character() -> MarbleCharacter:
	#debug("_create_character")
	var c: MarbleCharacter = MarbleCharacter.scene.instantiate()
	c.name = str(randi())
	var rand_x: float = randf_range(-100, 100)
	var rand_z: float = randf_range(-100, 100)
	c.position = Vector3(rand_x, world.get_ground_y(rand_x, rand_z), rand_z)
	var faction_types: Array = FactionStatic.COLORS.keys().filter(
		func(t: FactionStatic.Type) -> bool: return t != FactionStatic.Type.NONE
	)
	var random_faction: FactionStatic.Type = faction_types.pick_random()
	c.rotation.y = randf_range(0, TAU)
	world.characters.add_child(c)
	# c.faction.faction = random_faction
	c.faction._init_default_relations(random_faction)
	c._apply_color()
	Persistance.persist.emit(c)
	return c


func get_data() -> Dictionary:
	return {
		"name": name,
		"parent": str(get_parent().get_path()) if get_parent() else "",
		#"scene_file_path":get_scene_file_path(),
		#"players": var_to_str(players),
	}


#don't reference @onready vars
func load_pre_ready(_data: Dictionary) -> void:
	pass
	#if "players" in node_data:
		#players = str_to_var(node_data.players)


#can reference @onready vars now
func load_post_ready(_data: Dictionary) -> void:
	pass
