class_name Player
extends Resource


#var id_service:String
var name:String
var characters:Array=[]
var peer_id:int
var current_character_id:String

func get_data()->Dictionary:
	return {
		"name":name,
		"characters":characters,
		"current_character_id":current_character_id
	}
