extends Node3D


func get_actions():
	return ['pick_up','plant']

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass  # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _physics_process(_delta: float) -> void:
	pass
	#if not is_on_floor():
	#velocity.y -= gravity * delta
