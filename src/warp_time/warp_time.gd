@tool
class_name WarpTime
extends Node3D

const MONTHS = [
	"March", # 1
	"April", # 2
	"May", #
	"June", #
	"July", #
	"August", # 6
	"September", # 7
	"October", # 8
	"November", # 9
	"December" # 10
	]

@export var age: float = Time.get_unix_time_from_system()
@export var warp_speed: int = 1

var max_distance = 2
var is_dragging: bool = false


@onready var hour_hand: Node3D = %HourHand
@onready var second_hand: Node3D = %SecondHand
@onready var minute_hand: Node3D = %MinuteHand
@onready var day: Node3D = %Day
@onready var day_of_month_label: Label3D = $Calendar/Node3D/Day/DayOfMonth
@onready var month_of_year_label: Label3D = $Calendar/Node3D2/MonthOfYearLabel
@onready var label_3d: Label3D = %Label3D
@onready var ball: StaticBody3D = %Ball


func _ready():
	age = Time.get_unix_time_from_system()
	#warp_speed = 1


func _input(event: InputEvent):
	#print("_input")
	# Stop dragging when the mouse button is released anywhere
	if is_dragging and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			is_dragging = false
			print("stop dragging")
			#freeze = true # Re-freeze when dropped

	# Update position while dragging
	if is_dragging and event is InputEventMouseMotion:
		print("drag")
		update_position_to_mouse()


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
		# Apply the drag ONLY to the X axis and clamp within limits
		ball.position.y = clamp(local_pos.y, 0.0, max_distance)


func _on_input_event(_camera, event, _position, _normal, _shape_idx):
	# Start dragging when the handle itself is clicked
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_dragging = true
			print('start drag')
			#freeze = false # Unfreeze to allow movement via script

func _process(delta: float) -> void:
	if warp_speed > 120:
		second_hand.visible = false
	else:
		second_hand.visible = true

	if warp_speed > 6000:
		minute_hand.visible = false
	else:
		minute_hand.visible = true

	if warp_speed > 60000:
		hour_hand.visible = false
	else:
		hour_hand.visible = true

	age += delta * warp_speed

	#seconds hand
	var seconds = int(age) % (60)
	var sec_radians = seconds / 60.0 * PI * 2 + PI
	second_hand.rotation = Vector3(0, sec_radians, 0)

	#minutes hand
	var minutes = int(age) % (60 * 60) / (60.0)
	var min_radians = minutes / (60.0) * PI * 2 + PI
	minute_hand.rotation = Vector3(0, min_radians, 0)

	#hours hand
	var hours = int(age) % (60 * 60 * 12) / (60.0 * 60)
	var hours_radians = hours / (12.0) * PI * 2 + PI
	hour_hand.rotation = Vector3(0, hours_radians, 0)


	label_3d.text = "%02d:%02d:%02d" % [hours, minutes, seconds]
	#day of month
	@warning_ignore("integer_division")
	var day_of_month: int = int(age) % (60 * 60 * 24 * 28) / (60 * 60 * 24) + 1
	day_of_month_label.text = str(day_of_month)

	var day_of_week = (day_of_month - 1) % 7

	@warning_ignore("integer_division")
	var week_of_month = (day_of_month - 1) / 7

	day.position = Vector3(day_of_week / 7.0, -week_of_month / 4.0, 0)

	#month of year
	@warning_ignore("integer_division")
	var month_of_year: int = int(age) % (60 * 60 * 24 * 28 * 10) / (60 * 60 * 24 * 28)
	month_of_year_label.text = MONTHS[month_of_year]
