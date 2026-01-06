#@tool
class_name Slider3D
extends Node3D

@export var CUSTOM_VALUES: Array[int] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10,
								]
@export var show_label: bool = false
signal drag_ended(value_changed: bool)
signal drag_started()
#signal changed() #emitted with min/max/custom_values changes
signal value_changed(value: float)

var is_dragging: bool = false
var max_distance = 2.0
@onready var slider_ball: StaticBody3D = %SliderBall
@onready var label_3d: Label3D = %Label3D


@export var value: float = 1.0:
	set = _set_value


func _ready():
	update_position_to_value()
	label_3d.visible = show_label

func _set_value(v):
	#print('slider3d._set_value: %s' % v)
	if v != value:
		value = v
		label_3d.text = str(value)
		value_changed.emit(value)
		update_position_to_value()

func _input(event: InputEvent):
	# Stop dragging when the mouse button is released anywhere
	if is_dragging and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			is_dragging = false
			drag_ended.emit()

	# Update position while dragging
	if is_dragging and event is InputEventMouseMotion:
		update_position_to_mouse()


func update_position_to_value():
	#print(slider_ball)
	if slider_ball:
		for i in range(0, CUSTOM_VALUES.size() - 1):
			if value >= CUSTOM_VALUES[i]:
				#TODO just make sure its between values, don't jump to lower tick
				var y = i / float(CUSTOM_VALUES.size()) * max_distance
				slider_ball.position.y = y
			else:
				break


func update_position_to_mouse():
	var mouse_pos = get_viewport().get_mouse_position()
	var camera = get_viewport().get_camera_3d()

	# Project a ray into the 3D world
	var origin = camera.project_ray_origin(mouse_pos)
	var direction = camera.project_ray_normal(mouse_pos)

	# Create a plane aligned with the slider's movement axis
	var slider_plane = Plane(global_transform.basis.z, global_position)
	var world_intersect = slider_plane.intersects_ray(origin, direction)

	if world_intersect != null:
		var local_pos = to_local(world_intersect)
		# Apply the drag ONLY to the Y axis and clamp within limits
		#print("local_pos.y:%s" % [local_pos.y])

		var new_y = clamp(local_pos.y, 0.0, max_distance)
		var old_y = slider_ball.position.y
		#print("old_y:%s, new_y:%s" % [old_y,new_y])
		slider_ball.position.y = new_y
		if new_y != old_y:
			update_value(new_y)


func update_value(y: float):
	var i: int = y / max_distance * (CUSTOM_VALUES.size() - 1)
	value = CUSTOM_VALUES[i]


func _on_slider_ball_input_event(_camera, event, _position, _normal, _shape_idx):
	# Start dragging when the handle itself is clicked
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_dragging = true
			drag_started.emit()
