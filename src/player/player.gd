class_name Player
extends Resource

## eg Steam
#var id_service:String
## eg Steam:steam_id
var name: String
var characters: Array = []
## from multiplayer_peer
var peer_id: int
var current_character_id: String
var steam_name

## for serializing
func get_data() -> Dictionary:
	return {"name": name, "characters": characters, "current_character_id": current_character_id}
