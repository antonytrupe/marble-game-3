class_name Server
extends Node

@onready var ui=%UI
@onready var world:World=$/root/Game/World
@onready var client:Client=$/root/Game/Client
@export var players:Players

const CHARACTER_SCENE = preload("res://character/character.tscn")
const PLAYER_SCENE = preload("res://player/player.gd")


func _ready():
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	Persistance.load_player.connect(_load_player)
	#Persistance.load_character.connect(_load_character)

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		print('server quit')
		players.players.keys().all(
			func(player_id):
				Persistance.persist.emit("Player",players.players[player_id])
				return true
		)

func hide():
	ui.visible=false


func start(port):
	Persistance.start.emit()
	var peer = ENetMultiplayerPeer.new()
	var r=peer.create_server(port)
	multiplayer.multiplayer_peer = peer
	get_viewport().get_window().title += " - " + "SERVER"
	#get_tree().set_multiplayer(peer,self.get_path())
	Steam.setRichPresence("connect","steam://connect/"+str(19216811)+":"+str(port))

	match r:
		OK:
			Debug.debug.emit('OK')
		ERR_ALREADY_IN_USE:
			Debug.debug.emit('ERR_ALREADY_IN_USE')
		ERR_CANT_CREATE:
			Debug.debug.emit('ERR_CANT_CREATE')

	Debug.debug.emit("Hosting on port: %s" % port)

	#_spawn_character(multiplayer.get_unique_id())
	_on_peer_connected(multiplayer.get_unique_id())
	#set_player_id(multiplayer.get_unique_id())
	return r

@rpc("any_peer","call_local")
func chat(message):
	Debug.debug.emit(message)


@rpc("any_peer")
func command(message):
	Debug.debug.emit(message)


func _load_character(character_id,data:Dictionary):
	Debug.debug.emit('_load_character:'+character_id)
	var c:MarbleCharacter=CHARACTER_SCENE.instantiate()
	c.name=character_id
	if data.has("player_id"):
		c.player_id=data.player_id

	if data.has("position"):
		c.position=Vector3(data.position.x,data.position.y,data.position.z)

	world.characters.add_child(c)


func _load_player(player_name,data:Dictionary):
	var p=PLAYER_SCENE.new()
	p.name=player_name

	if data.has("current_character_id"):
		p.current_character_id=data.current_character_id
	if data.has("characters"):
		p.characters=data.characters
	players.players[player_name]=p


func _create_player(peer_id,player_id)->Player:
	var p=PLAYER_SCENE.new()
	p.peer_id=peer_id
	p.name=player_id
	var c=_create_character()
	c.player_id=player_id
	p.characters.append(c.name)
	p.current_character_id=c.name
	Persistance.persist.emit("Player",p)
	return p

@rpc("call_local")
func set_client_player_id(player_id):
	var peer_id:int = multiplayer.get_remote_sender_id()
	peer_id=peer_id if peer_id!=0 else 1
	var p:Player
	if players.players.has(player_id):
		#Debug.info.emit("found player")
		p=players.players[player_id]
	else:
		#Debug.info.emit("did not find player")
		p=_create_player(peer_id,player_id)
		players.players[player_id]=p

	players.connectedPlayers[peer_id]=p
	client.set_current_character.rpc_id(1,p.current_character_id)


func _on_peer_connected(peer_id):
	Debug.debug.emit("Peer connected with ID: %s" % peer_id)

	#if multiplayer.is_server():
		##client.get_id.rpc_id(peer_id)
		##debug.debug.emit(client_id)
		#var p=players.get_child(peer_id)
		#if not p:
			#p=PLAYER_SCENE.new()
			#p.peer_id=peer_id

		#_spawn_character(id)


func _on_peer_disconnected(id):
	Debug.debug.emit("Peer disconnected with ID: %s" % id)
	#var player_node = players.get_node(str(id))
	#if player_node:
		#player_node.queue_free()

func _create_character():
	Debug.debug.emit("_create_character")

	#var players_node = get_node("Players")
	var c:MarbleCharacter = CHARACTER_SCENE.instantiate()
	c.name = str(randi())
	c.position=Vector3(randf_range(-100,100),0,randf_range(-100,100))
	world.characters.add_child(c,true)
	Persistance.persist.emit("MarbleCharacter",c)
	return c
