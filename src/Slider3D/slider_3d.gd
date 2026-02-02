class_name Slider3D
extends Node3D

signal drag_ended(value_changed: bool)
signal drag_started()
#signal changed() #emitted with min/max/custom_values changes
signal value_changed(value: float)

@export var custom_values: Array[int] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10,
								]
@export var show_label: bool = false

@export var value: float = 1.0:
	set = _set_value

var is_dragging: bool = false
var max_distance: float = 2.0
@onready var slider_ball: StaticBody3D = %SliderBall
@onready var label_3d: Label3D = %Label3D


func _ready() -> void:
	update_position_to_value()
	label_3d.visible = show_label

func _set_value(v: float) -> void:
	#print('slider3d._set_value: %s' % v)
	if v != value:
		value = v
		label_3d.text = str(value)
		value_changed.emit(value)
		update_position_to_value()

func _input(event: InputEvent) -> void:
	# Stop dragging when the mouse button is released anywhere
	if is_dragging and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			is_dragging = false
			drag_ended.emit()

	# Update position while dragging
	if is_dragging and event is InputEventMouseMotion:
		update_position_to_mouse()


func update_position_to_value() -> void:
	#print(slider_ball)
	if slider_ball:
		for i: int in range(0, custom_values.size() - 1):
			if value >= custom_values[i]:
				#TODO just make sure its between values, don't jump to lower tick
				var y: float = i / float(custom_values.size()) * max_distance
				slider_ball.position.y = y
			else:
				break


func update_position_to_mouse() -> void:
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var camera: Camera3D = get_viewport().get_camera_3d()

	# Project a ray into the 3D world
	var origin: Vector3 = camera.project_ray_origin(mouse_pos)
	var direction: Vector3 = camera.project_ray_normal(mouse_pos)

	# Create a plane aligned with the slider's movement axis
	var slider_plane: Plane = Plane(global_transform.basis.z, global_position)
	var world_intersect: Vector3 = slider_plane.intersects_ray(origin, direction)

	if world_intersect != null:
		var local_pos: Vector3 = to_local(world_intersect)
		# Apply the drag ONLY to the Y axis and clamp within limits
		#print("local_pos.y:%s" % [local_pos.y])

		var new_y: float = clamp(local_pos.y, 0.0, max_distance)
		var old_y: float = slider_ball.position.y
		#print("old_y:%s, new_y:%s" % [old_y,new_y])
		slider_ball.position.y = new_y
		if new_y != old_y:
			update_value(new_y)


func update_value(y: float) -> void:
	@warning_ignore("narrowing_conversion")
	var i: int = y / max_distance * (custom_values.size() - 1)
	value = custom_values[i]


func _on_slider_ball_input_event(_camera: Node, event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	# Start dragging when the handle itself is clicked
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_dragging = true
			drag_started.emit()
