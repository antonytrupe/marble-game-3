class_name Server
extends Node

const CHARACTER_SCENE = preload("res://character/character.tscn")
const PLAYER_SCENE = preload("res://player/player.gd")

## key is unique id
## e.g. Steam:steam_id.
## Any player that has logged in will have an entry here
@export var players: Dictionary = {}
## key is peer_id from @MultiplayerPeer. only currently connected players are in this dictionary
@export var connected_players: Dictionary = {}

@onready var ui = %UI
@onready var world: World = $/root/Game/World
@onready var client: Client = $/root/Game/Client


func _steam_signals():
	Steam.lobby_created.connect(_on_lobby_created)
	# just for information
	Steam.join_requested.connect(_on_lobby_join_requested)


#just for info
func _on_lobby_join_requested(this_lobby_id: int, friend_steam_id: int) -> void:
	# Get the lobby owner's name
	var friend_name: String = Steam.getFriendPersonaName(friend_steam_id)

	debug("%s joined lobby %s..." % friend_name, this_lobby_id)
	var id := Steam.getLobbyOwner(this_lobby_id)
	debug("lobby owner %s" % id)


func _multiplayer_signals():
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)


func _persistance_signals():
	Persistance.load_player.connect(_load_player)
	Persistance.load_character.connect(_load_character)


func _load_character(character_name, data: Dictionary):
	var c: MarbleCharacter = CHARACTER_SCENE.instantiate()
	c.name = character_name
	world.characters.add_child(c, true)
	if data.has("player_id"):
		c.player_id = data.player_id
	if data.has("player_name"):
		c.player_id = data.player_name
	if data.has("warp_speed"):
		c.warp_speed = data.warp_speed
	if data.has("position"):
		c.position = str_to_var(data.position)
	if data.has("transform"):
		c.transform =  str_to_var(data.transform)
	if data.has("rotation"):
		c.rotation = str_to_var(data.rotation)


func _ready():
	_multiplayer_signals()
	_persistance_signals()
	_steam_signals()


func quit():
	print("server quit")
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


func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		quit()


func hide():
	ui.visible = false


func debug(...args: Array):
	Debug.debug.emit(args)


func _on_lobby_created(result: int, lobby_id: int) -> void:
	if result == Steam.RESULT_OK:
		var peer: SteamMultiplayerPeer = SteamMultiplayerPeer.new()
		peer.host_with_lobby(lobby_id)

		multiplayer.multiplayer_peer = peer
		# Set the lobby ID
		debug("Created a lobby: %s" % lobby_id)

		# Set this lobby as joinable, just in case, though this should be done by default
		Steam.setLobbyJoinable(lobby_id, true)

		# Allow P2P connections to fallback to being relayed through Steam if needed
		var set_relay: bool = Steam.allowP2PPacketRelay(true)
		print("Allowing Steam to be relay backup: %s" % set_relay)

		Steam.setRichPresence("connect", str(lobby_id))

		#set up the host player
		_on_peer_connected(multiplayer.get_unique_id())


func start():
	# load everything from persistance
	Persistance.load.emit()

	get_viewport().get_window().title += " - " + "SERVER"

	var lobby_members_max: int = 4
	#fires _on_lobby_created
	Steam.createLobby(Steam.LobbyType.LOBBY_TYPE_PUBLIC, lobby_members_max)


@rpc("any_peer", "call_local")
func chat(message):
	debug(message)


@rpc("any_peer")
func command(message):
	debug(message)


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
	c.set_multiplayer_authority(peer_id)
	Persistance.persist.emit("Player", p)

	players[player_id] = p
	connected_players[peer_id] = p

	return p


## peer_id from multiplayer_pee, 1 for host
func _on_peer_connected(peer_id = 1):
	debug("Peer connected with ID: %s" % peer_id)

	var steam_id:int
	var friend_name:String
	if multiplayer.has_multiplayer_peer():
		steam_id = (multiplayer.multiplayer_peer as SteamMultiplayerPeer).get_steam_id_for_peer_id(peer_id)
		debug("steam id: %s" % steam_id)
		friend_name = Steam.getFriendPersonaName(steam_id)
		debug("friend_name: %s" % friend_name)

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
	var c:MarbleCharacter=world.characters.get_node(p.current_character_id)
	c.player_name=friend_name
	c._update_label()

func _on_peer_disconnected(peer_id):
	debug("Peer disconnected with ID: %s" % peer_id)
	connected_players.erase(peer_id)

	#TODO clear the player_name of the character
	#var c:MarbleCharacter=world.characters.get_node(p.current_character_id)
	#c.player_name=""


func _create_character():
	debug("_create_character")

	var c: MarbleCharacter = CHARACTER_SCENE.instantiate()
	c.name = str(randi())
	c.position = Vector3(randf_range(-100, 100), 0, randf_range(-100, 100))
	world.characters.add_child(c, true)
	Persistance.persist.emit("MarbleCharacter", c)
	return c
