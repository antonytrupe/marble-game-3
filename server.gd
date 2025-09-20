class_name Server
extends Node

@onready var ui=%UI
@onready var world:World=$/root/Game/World

const CHARACTER_SCENE = preload("res://character.tscn")


func _ready():
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)


func hide():
	ui.visible=false


func start(port):
	var peer = ENetMultiplayerPeer.new()
	var r=peer.create_server(port)
	multiplayer.multiplayer_peer = peer
	get_viewport().get_window().title += " - " + "SERVER"
	#get_tree().set_multiplayer(peer,self.get_path())
	Steam.setRichPresence("connect","steam://connect/"+str(19216811)+":"+str(port))

	match r:
		OK:
			debug.debug.emit('OK')
		ERR_ALREADY_IN_USE:
			debug.debug.emit('ERR_ALREADY_IN_USE')
		ERR_CANT_CREATE:
			debug.debug.emit('ERR_CANT_CREATE')

	debug.debug.emit("Hosting on port: %s" % port)

	_spawn_character(multiplayer.get_unique_id())
	return r

@rpc("any_peer","call_local")
func chat(message):
	debug.debug.emit(message)


@rpc("any_peer")
func command(message):
	debug.debug.emit(message)


func _on_peer_connected(id):
	debug.debug.emit("Peer connected with ID: %s" % id)
	if multiplayer.is_server():
		_spawn_character(id)


func _on_peer_disconnected(id):
	debug.debug.emit("Peer disconnected with ID: %s" % id)
	var player_node = world.characters.get_node(str(id))
	if player_node:
		player_node.queue_free()

func _spawn_character(id):
	debug.debug.emit("spawn_character: %s" % id)

	#var players_node = get_node("Players")
	var c = CHARACTER_SCENE.instantiate()
	c.name = str(id)
	world.characters.add_child(c)
