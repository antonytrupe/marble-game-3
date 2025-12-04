class_name Game
extends Node

#PlayTest app id: 4041750

#live app id: 4041660

#global test app id: 480

func d(...args: Array):
	Debug.debug.emit(args)

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		print('game quit')
		get_tree().quit() # default behavior


func _ready():

	if Steam.isSteamRunning():
		Debug.debug.emit("steam is running")
	else:
		Debug.debug.emit("steam is not running")

	#var steam_id = Steam.getSteamID()
	#d("steam_id:", steam_id)
	#var steam_persona_name = Steam.getFriendPersonaName(steam_id)
	#d("steam_persona_name:", steam_persona_name)

	Steam.setRichPresence("steam_display", "#steam_display_test")
	Steam.setRichPresence("status", "#status_test")
	#Steam.setRichPresence("connect", "#connect_test")
	var _args=Steam.getLaunchCommandLine()


func _process(_delta: float):
	Steam.run_callbacks()
