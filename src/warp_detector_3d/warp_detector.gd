class_name WarpDetector
extends Area3D

#@export var nearby_bodies: Dictionary = {}
#@export var body: Node3D = owner
var warp_monuments: Dictionary = {}

func _on_body_entered(_b: Node3D) -> void:
	pass
	#print(body.name)
	#nearby_bodies.set(b.name, b)


func _on_body_exited(_b: Node3D) -> void:
	pass
	#print(body.name)
	#nearby_bodies.erase(b.name)
