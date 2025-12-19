class_name TimeWarpUI
extends Control

@export var custom_values: Array[int] = [1, 2, 3, 4, 6, 8, 10, 12, 16, 20, 100, 500, 3000]
@onready var label = $VBoxContainer/Label
@onready var h_slider: HSlider = %HSlider

func _ready():
	label.text = str(custom_values[0])
	TimeWarp.warp_change.connect(_c)

func _c(c:int):
	#Debug.debug.emit(c)
	h_slider.value=custom_values.find(c)


func _on_h_slider_value_changed(value: int) -> void:
	label.text = str(custom_values[value])
	TimeWarp.warp_change.emit(custom_values[value])
