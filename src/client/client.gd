class_name Client
extends Control

signal current_character_updated(character: MarbleCharacter)

@onready var server: Server = $/root/Game/Server
@onready var world: World = $/root/Game/World
@onready var main_menu: MarbleWindow = $/root/Game/MainMenu
@onready var chat_text_edit: TextEdit = %ChatInput
@onready var chat_window: MarbleWindow = %ChatWindow
@onready var actions: ActionsWindow = %MarbleActionsWindow
@onready var crosshairs: ColorRect = %CrossHairs

var current_character: MarbleCharacter

var lobby_id: int

func debug(...args: Array) -> void:
	Debug.debug.emit(args)


func _steam_signals() -> void:
	Steam.lobby_joined.connect(_on_lobby_joined)


func _ready() -> void:
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.server_disconnected.connect(_server_disconnected)
	_steam_signals()


@warning_ignore("shadowed_variable")
func join_lobby(lobby_id: int) -> void:
	#debug("Attempting to join lobby %s" % lobby_id)
	# Make the lobby join request to Steam
	Steam.joinLobby(lobby_id)
	#ui.visible=true


@warning_ignore("shadowed_variable")
func _on_lobby_joined(lobby_id: int, _permissions: int, _locked: bool, _response: int) -> void:
	#debug("_on_lobby_joined")
	if Steam.getLobbyOwner(lobby_id) == Steam.getSteamID():
		# We're probably hosting so we can ignore this
		#debug('this is us')
		return


	# But if we're joining
	var peer: SteamMultiplayerPeer = SteamMultiplayerPeer.new()
	peer.debug_level = SteamMultiplayerPeer.DEBUG_LEVEL_PEER # <- optional, adds info to log
	peer.connect_to_lobby(lobby_id)
	multiplayer.multiplayer_peer = peer
	self.lobby_id = lobby_id


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
					#current_character.server_turn(event.relative)
			else:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _unhandled_input(event: InputEvent) -> void:
	if current_character:
		#only if we're not typing
		if !chat_window.visible:
			#interact
			if Input.is_action_just_pressed("interact_right"):
				if is_server():
					current_character.interact(MarbleCharacter.INTERACT.RIGHT)
				else:
					current_character.interact.rpc_id(1, MarbleCharacter.INTERACT.RIGHT)
			if Input.is_action_just_pressed("interact_left"):
				if is_server():
					current_character.interact(MarbleCharacter.INTERACT.LEFT)
				else:
					current_character.interact.rpc_id(1, MarbleCharacter.INTERACT.LEFT)

			# Jump
			if Input.is_action_just_pressed("jump") or \
			current_character.flying and Input.is_action_pressed("jump"):
				if is_server():
					current_character.server_jump()
				else:
					current_character.server_jump.rpc_id(1)
					#current_character.server_jump()

			#fly
			if Input.is_action_pressed("fly"):
				if is_server():
					current_character.server_fly()
				else:
					current_character.server_fly.rpc_id(1)
					#current_character.server_fly()

			#moving
			var input_dir: Vector2 = Input.get_vector("left", "right", "forward", "backward")
			if is_server():
				current_character.server_move(input_dir)
			else:
				current_character.server_move.rpc_id(1, input_dir)
				#current_character.server_move(input_dir)


			#rotate left hand inventory
			if Input.is_key_pressed(KEY_ALT):
				if event is InputEventMouseButton:
					print(event.factor)
					var scroll_amount: float = 0
					if (Input.is_mouse_button_pressed(MOUSE_BUTTON_WHEEL_UP)):
						scroll_amount = - event.factor if event.factor else -1.0
					elif (Input.is_mouse_button_pressed(MOUSE_BUTTON_WHEEL_DOWN)):
						scroll_amount = event.factor if event.factor else 1.0
					#spin
					current_character.inventory_right_marker.rotate_object_local(
						Vector3.UP,
						scroll_amount * 0.1)

				if event is InputEventMouseMotion:
					#side to side
					current_character.inventory_right_marker.rotate(
						#current_character.transform.basis.z,
						Vector3.FORWARD,
						event.relative.x * 0.005)
					#front to back
					current_character.inventory_right_marker.rotate(
						#current_character.global_transform.basis.x,
						Vector3.RIGHT,
						event.relative.y * 0.005)

			#rotate right hand inventory
			elif Input.is_key_pressed(KEY_CTRL):
				if event is InputEventMouseButton:
					print(event.factor)
					var scroll_amount: float = 0
					if (Input.is_mouse_button_pressed(MOUSE_BUTTON_WHEEL_UP)):
						scroll_amount = - event.factor if event.factor else -1.0
					elif (Input.is_mouse_button_pressed(MOUSE_BUTTON_WHEEL_DOWN)):
						scroll_amount = event.factor if event.factor else 1.0
					#spin
					current_character.inventory_left_marker.rotate_object_local(
						Vector3.UP,
						scroll_amount * 0.1)

				if event is InputEventMouseMotion:
					#side to side
					current_character.inventory_left_marker.rotate(
						#current_character.transform.basis.z,
						Vector3.FORWARD,
						event.relative.x * 0.005)
					#front to back
					current_character.inventory_left_marker.rotate(
						#current_character.global_transform.basis.x,
						Vector3.RIGHT,
						event.relative.y * 0.005)

			else:
				#handle moving the camera forward
				if (Input.is_mouse_button_pressed(MOUSE_BUTTON_WHEEL_UP)):
					var scroll_amount: float = - event.factor if event.factor else -1.0
					if is_server():
						current_character.server_camera_zoom(scroll_amount)
					else:
						current_character.server_camera_zoom.rpc_id(1, scroll_amount)
						#current_character.server_camera_zoom(scroll_amount)

				#handle moving the camera backwards
				if (Input.is_mouse_button_pressed(MOUSE_BUTTON_WHEEL_DOWN)):
					var scroll_amount: float = event.factor if event.factor else 1.0
					if is_server():
						current_character.server_camera_zoom(scroll_amount)
					else:
						current_character.server_camera_zoom.rpc_id(1, scroll_amount)
						#current_character.server_camera_zoom(scroll_amount)


	if Input.is_action_just_pressed("escape"):
		#show the menu
		main_menu.visible = !main_menu.visible
		crosshairs.visible = !crosshairs.visible

	if Input.is_action_just_pressed("command"):
		chat_window.visible = !chat_window.visible
		#chat_mode = !chat_mode

		if chat_window.visible:
			chat_text_edit.grab_focus()
			chat_text_edit.text = "/"
			chat_text_edit.set_caret_column(1)
		else:
			chat_text_edit.release_focus()

	if Input.is_action_just_pressed("chat"):
		chat_window.visible = !chat_window.visible
		#chat_mode = !chat_mode
		if chat_window.visible:
			chat_text_edit.grab_focus()
		else:
			chat_text_edit.release_focus()
			server.chat.rpc_id(1, chat_text_edit.text)
			chat_text_edit.text = ""


#this is for the server to tell this client who it's character is
@rpc()
func set_current_character(character_id: String) -> void:
	#debug('set_current_character:', character_id)
	current_character = world.characters.get_node(character_id)
	current_character.camera.current = true
	current_character_updated.emit(current_character)


func _on_connected_to_server() -> void:
	main_menu.visible = false
	visible = true
	world.visible = true

	#debug("_on_connected_to_server")
	# var steam_id = Steam.getSteamID()
	#return "steam:"+str(steam_id)
	#server.set_client_player_id.rpc_id(1,"steam:"+str(steam_id))


func _server_disconnected() -> void:
	#debug("_server_disconnected")
	Steam.leaveLobby(lobby_id)
	main_menu.visible = true
	visible = false
	world.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
