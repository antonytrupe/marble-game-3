class_name WarpDetector
extends Area3D

@export var nearby_bodies: Dictionary = {}
@onready var character: MarbleCharacter = owner

func _on_body_entered(body: Node3D) -> void:
	#print(body.name)
	nearby_bodies.set(body.name, body)


func _on_body_exited(body: Node3D) -> void:
	#print(body.name)
	nearby_bodies.erase(body.name)
