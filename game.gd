class_name Game
extends Node

#PlayTest app id: 4041750

#live app id: 4041660

#global test app id: 480

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
	var connect_lobby = Steam.getLaunchQueryParam("+connect_lobby")
	var steam_command_line=Steam.getLaunchCommandLine()
	d('steam_command_line',steam_command_line)

	d('connect_lobby',connect_lobby)

	var command_args: Array = OS.get_cmdline_args()
	d('command_args',command_args)
	if(command_args.size()>=2 && command_args[0]=='+connect'):
		d('key',command_args[0])
		d('value',command_args[1])
		Steam.joinLobby(int(command_args[1]))


	# There are arguments to process
	if connect_lobby:

		# At this point, you'll probably want to change scenes
		# Something like a loading into lobby screen
		d("Command line lobby ID: %s" % connect_lobby)
		Steam.joinLobby(int(connect_lobby))


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
