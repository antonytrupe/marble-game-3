class_name Client
extends Control

@onready var server:Server = $/root/Game/Server
@onready var world:World = $/root/Game/World

@onready var ui=%UI
@onready var chat_text_edit: TextEdit = %ChatInput

@export var current_character:MarbleCharacter

func d(...args: Array):
	Debug.debug.emit(args)


func _steam_signals():
	Steam.lobby_joined.connect(_on_lobby_joined)


func _ready() -> void:
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.server_disconnected.connect(_server_disconnected)
	_steam_signals()

#var lobby_id: int = 0


func make_p2p_handshake() -> void:
	pass
	#print("Sending P2P handshake to the lobby")

	#send_p2p_packet(0, {"message": "handshake", "from": steam_id})


func join_lobby(this_lobby_id: int) -> void:
	d("Attempting to join lobby %s" % this_lobby_id)

	# Make the lobby join request to Steam
	Steam.joinLobby(this_lobby_id)




	#main_menu.visible = false
	#client.visible = true
	ui.visible=true


func _on_lobby_joined(lobby_id: int, _permissions: int, _locked: bool, _response: int) -> void:
	d("_on_lobby_joined")
	if Steam.getLobbyOwner(lobby_id) == Steam.getSteamID():
		# We're probably hosting so we can ignore this
		d('this is us')
		return

	# But if we're joining
	var peer := SteamMultiplayerPeer.new()
	peer.debug_level = SteamMultiplayerPeer.DEBUG_LEVEL_PEER # <- optional, adds info to log
	peer.connect_to_lobby(lobby_id)
	multiplayer.multiplayer_peer = peer


func is_server() -> bool:
	return multiplayer.is_server()

func _input(event: InputEvent) -> void:
	if current_character:
		if event is InputEventMouseMotion:
			if (
				Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
				or Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE)
			):
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
				if is_server():
					current_character.server_turn(event.relative)
				else:
					current_character.server_turn.rpc_id(1, event.relative)
			else:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _unhandled_input(event) -> void:
	if current_character:
		if event is InputEventMouseButton:
			if(Input.is_mouse_button_pressed(MOUSE_BUTTON_WHEEL_UP )):
				var scroll_amount = -event.factor if event.factor else -1.0
				var direction=current_character.camera_pivot.transform.basis.z
				current_character.camera_pivot.position += direction * scroll_amount * .1

			if(Input.is_mouse_button_pressed(MOUSE_BUTTON_WHEEL_DOWN )):
				var scroll_amount = event.factor if event.factor else 1.0
				var direction=current_character.camera_pivot.transform.basis.z
				current_character.camera_pivot.position += direction * scroll_amount * .1



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


#this is for the server to tell this client who it's character is
@rpc()
func set_current_character(character_id):
	d('set_current_character:',character_id)
	current_character=world.characters.get_node(character_id)
	#to get the warp ui to update
	TimeWarp.warp_change.emit(current_character.warp_speed)
	TimeWarp.warp_change.connect(set_current_character_warp_speed)
	current_character.camera.current=true


func set_current_character_warp_speed(value):
	#current_character.warp_speed=value
	if is_server():
		current_character.server_warp(value)
	else:
		current_character.server_warp.rpc_id(1, value)


func start(address, port):
	Debug.debug.emit("Attempting to connect to: %s:%s" % [address, port])
	var peer = SteamMultiplayerPeer.new()
	var r=peer.create_client(address, port)
	multiplayer.multiplayer_peer=peer
	#get_tree().set_multiplayer(peer,get_path())

	match r:
		OK:
			Debug.debug.emit('OK')
		ERR_ALREADY_IN_USE:
			Debug.debug.emit('ERR_ALREADY_IN_USE')
		ERR_CANT_CREATE:
			Debug.debug.emit('ERR_CANT_CREATE')


	ui.visible=true


func _on_connected_to_server():
	Debug.debug.emit("_on_connected_to_server")
	# var steam_id = Steam.getSteamID()
	#return "steam:"+str(steam_id)
	#server.set_client_player_id.rpc_id(1,"steam:"+str(steam_id))


func _server_disconnected():
	d("_server_disconnected")
	ui.visible=true
