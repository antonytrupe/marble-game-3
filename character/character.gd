class_name MarbleCharacter
extends CharacterBody3D


@onready var label:Label3D=$Label3D
@onready var camera_pivot=%CameraPivot
@onready var camera=%Camera3D

var player_id:String

var warp_speed=1:
	set=_set_warp_speed

func _ready():
	label.text="warp speed:"+str(warp_speed)


func get_data()->Dictionary:
	return {
		"name":name,
		"player_id":player_id,
		"warp_speed":warp_speed,
		"position":{"x":position.x,
					"y":position.y,
					"z":position.z},
	}


func _set_warp_speed(w):
	warp_speed=w
	if label:
		label.text="warp speed:"+str(warp_speed)
