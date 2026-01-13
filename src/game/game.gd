class_name Game
extends Node

#PlayTest app id: 4041750
#live app id: 4041660

@onready var client: Client = %Client
@onready var main_menu = %MainMenu


func debug(...args: Array):
	Debug.debug.emit(args)


func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		print("game quit")
		get_tree().quit() # default behavior


func _ready():
	if Steam.isSteamRunning():
		debug("steam is running")
	else:
		debug("steam is not running")

	var build_number_path = "res://build_number.txt" # The path to your file in the Godot project
	var build_number = read_text_file(build_number_path)

	if build_number != "":
		debug("Build Version: " + build_number)


	var commit_number_path = "res://commit_number.txt" # The path to your file in the Godot project
	var commit_number = read_text_file(commit_number_path)

	if commit_number != "":
		debug("Commit Number: " + commit_number)

	var command_args: Array = OS.get_cmdline_args()
	if (command_args.size() >= 2 && command_args[0] == '+connect_lobby'):
		var lobby_id = int(command_args[1])
		client.join_lobby(lobby_id)
		main_menu.visible = false
		client.visible = true


func _process(_delta: float):
	Steam.run_callbacks()


func read_text_file(path):
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		# Check for errors opening the file
		debug("Failed to open file: ", path, " Error code: ", FileAccess.get_open_error())
		return ""

	var content = file.get_as_text()
	file.close()
	return content.strip_edges() # Use strip_edges() to remove any extra newlines or whitespace
