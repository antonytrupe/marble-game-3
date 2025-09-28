class_name Client
extends Control

@onready var server:Server = $/root/Game/Server
@onready var world:World = $/root/Game/World

@onready var ui=%UI
@onready var chat_text_edit: TextEdit = %ChatInput

@export var current_character:MarbleCharacter

func d(...args: Array):
	Debug.debug.emit(args)

func _ready() -> void:
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.server_disconnected.connect(_server_disconnected)


func is_server() -> bool:
	return multiplayer.is_server()

func _input(event: InputEvent) -> void:
	if current_character:
		#print("_input")
		#print(event)
		if event is InputEventMouseMotion:
			#print(2)
			#print(event)
			if event is InputEventMouseMotion:
				if (
					Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
					or Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE)
				):
					Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
					if is_server():
						current_character.turn(event.relative)
					else:
						current_character.turn.rpc_id(1, event.relative)
				else:
					Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			if (
				Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
				or Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE)
			):
				print("camera move")
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

				current_character.rotate_y(-event.relative.x * .005)
				#print(value.x)
				#rotate_camera(event.relative.x* .005)
				current_character.camera_pivot.rotate_x(-event.relative.y * .005)
				current_character.camera_pivot.rotation.x = clamp(current_character.camera_pivot.rotation.x, -PI / 2, PI / 2)

			else:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _unhandled_input(event) -> void:
	#print("_unhandled_input")
	#print(event)
	if current_character:
		#print(1)
		#print(event)
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

@rpc()
func set_current_character(character_id):
	print('set_current_character',character_id)
	current_character=world.characters.get_node(character_id)
	current_character.camera.current=true


func start(address, port):
	Debug.debug.emit("Attempting to connect to: %s:%s" % [address, port])
	var peer = ENetMultiplayerPeer.new()
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
	var steam_id = Steam.getSteamID()
	#return "steam:"+str(steam_id)
	server.set_client_player_id.rpc_id(1,"steam:"+str(steam_id))


func _server_disconnected():
	Debug.debug.emit("_server_disconnected")
	ui.visible=true
