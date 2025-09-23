class_name World
extends Node3D


const CHARACTER_SCENE = preload("res://character/character.tscn")


@onready var characters=%Characters

func _ready() -> void:
	Persistance.load_character.connect(_load_character)


func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		print('world quit')
		get_tree().get_nodes_in_group("persist").all(
			func(c):
				Persistance.persist.emit("MarbleCharacter",c)
		)


func _load_character(character_name,data:Dictionary):
	var c:MarbleCharacter = CHARACTER_SCENE.instantiate()
	c.name = character_name
	if data.has("player_id"):
		c.player_id=data.player_id
	if data.has("warp_speed"):
		c.warp_speed=data.warp_speed
	if data.has("position"):
		c.position=Vector3(data.position.x,data.position.y,data.position.z)
	characters.add_child(c,true)
