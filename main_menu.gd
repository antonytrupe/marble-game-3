class_name MainMenu
extends Node

const PORT = 9999
#var lobby_id: int = 0
@onready var server: Server = %Server
@onready var client: Client = %Client
@onready var main_menu: Control = %MainMenu


func _on_new_game_button_pressed() -> void:
	#debug.debug.emit('_on_new_game_button_pressed')
	if not server.start():
		main_menu.visible = false
		var steam_id = Steam.getSteamID()
		#return "steam:"+str(steam_id)
		#server.set_client_player_id("server:steam:" + str(steam_id))

		client.visible = true


func _on_join_game_button_pressed() -> void:
	#debug.debug.emit('_on_join_game_button_pressed')
	if not client.start("localhost", PORT):
		main_menu.visible = false
		client.visible = true


func _on_load_game_button_pressed() -> void:
	Debug.debug.emit("_on_load_game_button_pressed")
	#TODO


func _on_quit_button_pressed() -> void:
	get_tree().quit(0)
