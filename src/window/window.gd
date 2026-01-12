class_name MarbleWindow
extends Control

enum MODE {NONE,TOP_LEFT,TOP,TOP_RIGHT,RIGHT,BOTTOM_RIGHT,BOTTOM,BOTTOM_LEFT,LEFT}

#signal drag_ended(value_changed: bool)
#signal drag_started()

var drag_mode: MODE = MODE.NONE

func _input(event: InputEvent):
	# Stop dragging when the mouse button is released anywhere
	if drag_mode!=MODE.NONE and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			drag_mode = MODE.NONE
			#drag_ended.emit()

	# Update position while dragging
	if event is InputEventMouseMotion:
		match drag_mode:
			MODE.NONE:
				pass
			MODE.TOP_LEFT:
				#update_position_to_mouse()
				#print(event.relative)
				position+=event.relative
				size-=event.relative
			MODE.TOP:
				position+=event.relative
			MODE.TOP_RIGHT:
				position.y+=event.relative.y
				size.x+=event.relative.x
				size.y-=event.relative.y
			MODE.RIGHT:
				size.x+=event.relative.x
			MODE.BOTTOM_RIGHT:
				size.x+=event.relative.x
				size.y+=event.relative.y
			MODE.BOTTOM:
				size.y+=event.relative.y
			MODE.BOTTOM_LEFT:
				size.y+=event.relative.y
				position.x+=event.relative.x
				size.x-=event.relative.x
			MODE.LEFT:
				position.x+=event.relative.x
				size.x-=event.relative.x
			_:
				print('missing a mode')


func _on_top_left_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		drag_mode = MODE.TOP_LEFT


func _on_top_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		drag_mode = MODE.TOP

func _on_top_right_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		drag_mode = MODE.TOP_RIGHT

func _on_right_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		drag_mode = MODE.RIGHT


func _on_bottom_right_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		drag_mode = MODE.BOTTOM_RIGHT


func _on_bottom_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		drag_mode = MODE.BOTTOM


func _on_bottom_left_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		drag_mode = MODE.BOTTOM_LEFT


func _on_left_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		drag_mode = MODE.LEFT
