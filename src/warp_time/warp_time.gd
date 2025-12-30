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


@onready var hour_hand: Node3D = %HourHand
@onready var second_hand: Node3D = %SecondHand
@onready var minute_hand: Node3D = %MinuteHand
@onready var day: Node3D = %Day
@onready var day_of_month_label: Label3D = $Calendar/Node3D/Day/DayOfMonth
@onready var month_of_year_label: Label3D = $Calendar/Node3D2/MonthOfYearLabel


func _ready():
	age = Time.get_unix_time_from_system()
	warp_speed = 1


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
	var sec_radians = seconds / 60.0 * PI * 2
	second_hand.rotation = Vector3(0, sec_radians, 0)

	#minutes hand
	var minutes = int(age) % (60 * 60) / (60.0)
	var min_radians = minutes / (60.0) * PI * 2
	minute_hand.rotation = Vector3(0, min_radians, 0)

	#hours hand
	var hours = int(age) % (60 * 60 * 12) / (60.0 * 60)
	var hours_radians = hours / (12.0) * PI * 2
	hour_hand.rotation = Vector3(0, hours_radians, 0)

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
