class_name Client
extends Node

@onready var server:Server = $/root/Game/Server
@onready var ui=%UI
@onready var chat_text_edit: TextEdit = %ChatInput

func d(...args: Array):
	debug.debug.emit(args)

func _ready() -> void:
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.server_disconnected.connect(_server_disconnected)




func _unhandled_input(_event: InputEvent) -> void:

	if Input.is_action_just_pressed("command"):
		chat_text_edit.visible = !chat_text_edit.visible
		#chat_mode = !chat_mode

		if chat_text_edit.visible:
			chat_text_edit.grab_focus()
			chat_text_edit.text = "/"
			chat_text_edit.set_caret_column(1)
		else:
			chat_text_edit.release_focus()

	if Input.is_action_just_pressed("chat"):
		chat_text_edit.visible = !chat_text_edit.visible
		#chat_mode = !chat_mode
		if chat_text_edit.visible:
			chat_text_edit.grab_focus()
		else:
			chat_text_edit.release_focus()
			#if multiplayer.is_server():
				#print('is_server')
			#print(multiplayer)
			server.chat.rpc_id(1,chat_text_edit.text)
			#else:
				#print('not is_server')
				#server.chat.rpc_id(1, chat_text_edit.text)
			chat_text_edit.text = ""


func start(address, port):
	debug.debug.emit("Attempting to connect to: %s:%s" % [address, port])
	var peer = ENetMultiplayerPeer.new()
	var r=peer.create_client(address, port)
	multiplayer.multiplayer_peer=peer
	#get_tree().set_multiplayer(peer,get_path())

	match r:
		OK:
			debug.debug.emit('OK')
		ERR_ALREADY_IN_USE:
			debug.debug.emit('ERR_ALREADY_IN_USE')
		ERR_CANT_CREATE:
			debug.debug.emit('ERR_CANT_CREATE')


	ui.visible=true


func _on_connected_to_server():
	debug.debug.emit("_on_connected_to_server")


func _server_disconnected():
	debug.debug.emit("_server_disconnected")
	ui.visible=true
