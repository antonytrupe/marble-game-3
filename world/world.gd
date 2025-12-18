class_name World
extends Node3D

@onready var characters = %Characters


func _ready() -> void:
	pass


func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		print("world quit")
