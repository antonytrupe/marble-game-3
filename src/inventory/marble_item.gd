class_name MarbleItem
extends Node

@export var mass: float = 1.0
@export var volume: float = 1.0
#@export var scene_2d: String
#@export var scene_3d: String
@export var warp_speed: float = 1.0
@onready var age: MarbleAge = %MarbleAge


func _process(delta: float) -> void:
	if is_server():
		age.age += delta * warp_speed


func is_server() -> bool:
	return multiplayer.is_server()
