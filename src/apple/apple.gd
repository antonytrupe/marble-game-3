#@tool
class_name Apple
extends Node3D

#apples take 150 days to mature
##days
@export var maturity: int = int(60 * 60 * 24 * (150))
@export var age: MarbleAge = MarbleAge.new()
@export var warp_speed: float = 1

var turn = 0

@onready var warp_detector: WarpDetector = $WarpDetectorArea3D

func _process(_delta: float) -> void:
	pass
	#var r = float(age.age) / float(maturity)
	#var s = clampf(r, .1, 1.0)
	#scale = Vector3(s, s, s)

#delta is in seconds
func _physics_process(delta: float):
	if is_server():
		age.age += delta * warp_speed
	var _turn: int = age.age / 6 + 1
	for i in range(self.turn, _turn):
		_start_turn(i)
	self.turn = _turn


func is_server() -> bool:
	return multiplayer.is_server()


func _start_turn(_turn):
	#print('starting turn %.f'%turn)
	pass
