extends StaticBody3D

@export var root :Node3D


func pick_berry()->Dictionary:
	return root.pick_berry()
