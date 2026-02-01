class_name Player
extends Node

static var scene: Resource = preload("res://src/player/player.tscn")

## eg Steam:steam_id
#var name: String
var characters: Array = []
## from multiplayer_peer
var peer_id: int
var current_character_id: String
var steam_name: String

@onready var server: Server = $/root/Game/Server


## for serializing
func get_data() -> Dictionary:
	return {
		"name": name,
		"parent": str(get_parent().get_path()) if get_parent() else "",
		"scene_file_path": get_scene_file_path(),
		"characters": characters,
		"current_character_id": current_character_id}


#don't reference @onready vars
func load_pre_ready(data: Dictionary) -> void:
	if "characters" in data:
		characters = data.characters
	if "current_character_id" in data:
		current_character_id = data.current_character_id

#can reference @onready vars now
func load_post_ready(_data: Dictionary) -> void:
	pass
