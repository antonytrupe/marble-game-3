class_name Bubble
extends Node3D

@export var text: String
var start: int
@onready var parent: Node3D = get_parent_node_3d()
@onready var label: Label3D = $Label3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	start = Time.get_ticks_msec()
	#parent=get_parent_node_3d()
	label.text = text


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	var now: int = Time.get_ticks_msec()
	var y: float = (now - start) / 10000.0
	position.y = y
	if now - start > 12000:
		queue_free()
