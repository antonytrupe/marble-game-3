@tool
class_name WarpTime
extends Node3D

#[1, 2, 3, 4, 6, 8, 10, 12, 16, 20, 60,
								#300, 600, 1800, 3600,
								#86400, 604800, 2419200, 24192000,
								#]

#const RADIUS_CUSTOM_VALUES: Array[int] = [1, 2, 3, 5, 10, 20, 60,
								#300, 600,
								#]
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
@export var warp_speed: int = 1:
	set = _set_warp_speed
@export var radius: int = 1:
	set = _set_radius


@onready var hour_hand: Node3D = %HourHand
@onready var second_hand: Node3D = %SecondHand
@onready var minute_hand: Node3D = %MinuteHand
@onready var day: Node3D = %Day
@onready var day_of_month_label: Label3D = $Calendar/Node3D/Day/DayOfMonth
@onready var month_of_year_label: Label3D = $Calendar/Node3D2/MonthOfYearLabel
@onready var label_3d: Label3D = %Label3D
@onready var warp_slider: Slider3D = $WarpSlider
@onready var radius_slider: Slider3D = $RadiusSlider
@onready var sphere: MeshInstance3D = %Sphere


func _ready():
	age = Time.get_unix_time_from_system()


func _set_warp_speed(value):
	if value != warp_speed:
		warp_speed = value
		if warp_slider:
			warp_slider.value = value


func _set_radius(value):
	if value != radius:
		radius = value
		_update_radius()
		if radius_slider:
			radius_slider.value = value


func _update_radius():
	sphere.mesh.radius = radius
	sphere.mesh.height = radius * 2


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


func _on_warp_slider_value_changed(value: float) -> void:
	warp_speed = int(value)


func _on_radius_slider_value_changed(value: float) -> void:
	radius = int(value)
