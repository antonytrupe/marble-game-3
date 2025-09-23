extends Node
@onready var server:Server=%Server
@onready var client:Client=%Client
@onready var ui:Control=%UI

const PORT=9999


func _on_new_game_button_pressed() -> void:
	#debug.debug.emit('_on_new_game_button_pressed')
	if not server.start(PORT):
		ui.visible=false
	#server.set_player_id("")
	client._on_connected_to_server()
	#client.start("localhost",PORT)

func _on_join_game_button_pressed() -> void:
	#debug.debug.emit('_on_join_game_button_pressed')
	if not client.start("localhost",PORT):
		ui.visible=false


func _on_load_game_button_pressed() -> void:
	Debug.debug.emit('_on_load_game_button_pressed')
	#TODO

func _on_quit_button_pressed() -> void:
	get_tree().quit(0)
