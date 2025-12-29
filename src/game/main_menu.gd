class_name MainMenu
extends Node

const PORT = 9999
@onready var server: Server = %Server
@onready var client: Client = %Client
@onready var main_menu: Control = %MainMenu
@onready var join_friends_container:= %JoinFriendsContainer

func debug(...args: Array):
	Debug.debug.emit(args)


func _on_new_game_button_pressed() -> void:
	#debug.debug.emit('_on_new_game_button_pressed')
	if not server.start():
		main_menu.visible = false
		client.visible = true


func get_friends_in_game():
	var friends_playing_this_game = []
	# k_EFriendFlagImmediate = 0x01
	var friend_count = Steam.getFriendCount(Steam.FRIEND_FLAG_IMMEDIATE)
	var app_id=Steam.getAppID()
	debug("app_id:",app_id)
	for i in range(0, friend_count):
		var steam_id = Steam.getFriendByIndex(i, Steam.FRIEND_FLAG_IMMEDIATE)
		#debug("steam_id:",steam_id)
		var game_info = Steam.getFriendGamePlayed(steam_id)
		# Check if they are playing a game
		if game_info.has("id"):
			#debug("game_info[id]:",game_info["id"])

			#var app_id = game_info["id"]
			# Optional: Check if they are playing YOUR specific game
			if game_info["id"]==app_id:
				var friend_name = Steam.getFriendPersonaName(steam_id)
				friends_playing_this_game.append(
					{"name": friend_name,
					 "id": steam_id,
					 "lobby_id": game_info.get("lobby", 0) # Get lobby ID if available
})

	#debug(friends_playing_this_game)
	return friends_playing_this_game


func _on_show_friends_button_pressed() -> void:
	var friends=get_friends_in_game()
	# clear the join buttons
	for child in join_friends_container.get_children():
		child.queue_free()

	for friend in friends:
		# 1. Create the button instance
		var my_button = Button.new()

		# 2. Set properties (Text, Size, Position)
		my_button.text = "Join %s" % friend.name
		#my_button.position = Vector2(100, 100)
		#my_button.custom_minimum_size = Vector2(200, 50)

		# 3. Connect the "pressed" signal to a function
		my_button.pressed.connect(_on_join_friend_button_pressed.bind(friend))

		# 4. Add it to the current node
		join_friends_container.add_child(my_button)
	#debug.debug.emit('_on_join_game_button_pressed')
	#if not client.start("localhost", PORT):
		#main_menu.visible = false
		#client.visible = true


func _on_join_friend_button_pressed(friend:Dictionary):
	debug(friend)
	var lobby_id=int(friend.lobby_id)
	client.join_lobby(lobby_id)
	main_menu.visible = false
	client.visible = true

func _on_load_game_button_pressed() -> void:
	Debug.debug.emit("_on_load_game_button_pressed")
	#TODO


func _on_quit_button_pressed() -> void:
	get_tree().quit(0)
