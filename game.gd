extends Node

func d(...args: Array):
	debug.debug.emit(args)


func _ready():

	if Steam.isSteamRunning():
		debug.debug.emit("steam is running")
	else:
		debug.debug.emit("steam is not running")

	var steam_id = Steam.getSteamID()
	d("steam_id:", steam_id)
	var steam_persona_name = Steam.getFriendPersonaName(steam_id)
	d("steam_persona_name:", steam_persona_name)

	Steam.setRichPresence("steam_display", "steam_display value")
	Steam.setRichPresence("status", "status value")
	var args=Steam.getLaunchCommandLine()
