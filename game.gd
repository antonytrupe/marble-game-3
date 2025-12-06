class_name Game
extends Node

#PlayTest app id: 4041750

#live app id: 4041660

@onready var client:Client=%Client
@onready var main_menu=%MainMenu

func _steam_signals():
	pass
	# Steam.lobby_chat_update.connect(_on_lobby_chat_update)
	#Steam.lobby_created.connect(_on_lobby_created)
	#Steam.lobby_data_update.connect(_on_lobby_data_update)
	#Steam.lobby_invite.connect(_on_lobby_invite)
	#Steam.lobby_joined.connect(_on_lobby_joined)
	# Steam.lobby_match_list.connect(_on_lobby_match_list)
	#Steam.join_requested.connect(_on_lobby_join_requested)
	# Steam.lobby_message.connect(_on_lobby_message)
	# Steam.persona_state_change.connect(_on_persona_change)
	# Steam.setRichPresence("connect", "#connect_test")


func d(...args: Array):
	Debug.debug.emit(args)


func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		print("game quit")
		get_tree().quit()  # default behavior


func _ready():
	if Steam.isSteamRunning():
		Debug.debug.emit("steam is running")
	else:
		Debug.debug.emit("steam is not running")


	var file_path = "res://build_number.txt" # The path to your file in the Godot project
	var file_content = read_text_file(file_path)

	if file_content != "":
		d( "Build Version: " + file_content)


	#var steam_id = Steam.getSteamID()
	#d("steam_id:", steam_id)
	#var steam_persona_name = Steam.getFriendPersonaName(steam_id)
	#d("steam_persona_name:", steam_persona_name)

	Steam.setRichPresence("steam_display", "#steam_display_test")
	Steam.setRichPresence("status", "#status_test")
	#Steam.setRichPresence("connect", "#connect_test")
	#var connect_lobby = Steam.getLaunchQueryParam("+connect_lobby")
	#var steam_command_line=Steam.getLaunchCommandLine()
	#d('steam_command_line',steam_command_line)

	#d('connect_lobby',connect_lobby)


	var command_args: Array = OS.get_cmdline_args()
	d('command_args',command_args)
	if(command_args.size()>=2 && command_args[0]=='+connect_lobby'):
		var lobby_id=int(command_args[1])
		# d('key',command_args[0])
		# d('value',command_args[1])
		client.join_lobby(lobby_id)
		main_menu.visible = false
		client.visible = true


func _process(_delta: float):
	Steam.run_callbacks()


func read_text_file(path):
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		# Check for errors opening the file
		print("Failed to open file: ", path, " Error code: ", FileAccess.get_open_error())
		return ""

	var content = file.get_as_text()
	file.close()
	return content.strip_edges() # Use strip_edges() to remove any extra newlines or whitespace
