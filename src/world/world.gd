class_name World
extends Node3D

@onready var characters = %Characters
@onready var flora: Node3D = %Flora
@onready var fauna: Node3D = %Fauna
@onready var terra = %Terra


func _ready() -> void:
	pass


func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		print("world quit")
