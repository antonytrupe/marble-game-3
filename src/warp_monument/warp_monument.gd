class_name WarpMonument
extends Node3D


@export var age: float = Time.get_unix_time_from_system()
@export var warp_speed: int = 1:
	set = _set_warp_speed
@export var radius: int = 1:
	set = _set_radius

var bodies = {}

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
@onready var scanner_shape: CollisionShape3D = %ScannerShape


func _ready():
	age = Time.get_unix_time_from_system()


func _set_warp_speed(value):
	if value != warp_speed:
		warp_speed = value
		for body in bodies.values():
			body.calculate_warp()
		if warp_slider:
			warp_slider.value = value


func _set_radius(value):
	if value != radius:
		radius = value
		_update_radius()
		if radius_slider:
			radius_slider.value = value


func _update_radius():
	if sphere:
		sphere.mesh.radius = radius
		sphere.mesh.height = radius * 2
	if scanner_shape:
		scanner_shape.shape.radius = radius


func _process(delta: float) -> void:
	age += delta * warp_speed

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

	#seconds hand
	var seconds = int(age) % (MarbleAge.SECONDS_IN_MINUTE)
	var sec_radians = seconds / float(MarbleAge.SECONDS_IN_MINUTE) * PI * 2 + PI
	second_hand.rotation = Vector3(0, sec_radians, 0)

	#minutes hand
	var minutes = int(age) % (MarbleAge.SECONDS_IN_HOUR) / float(MarbleAge.MINUTES_IN_HOUR)
	var min_radians = minutes / (60.0) * PI * 2 + PI
	minute_hand.rotation = Vector3(0, min_radians, 0)

	#hours hand
	var hours = int(age) % int(MarbleAge.SECONDS_IN_DAY / 2.0) / float(MarbleAge.SECONDS_IN_HOUR)
	var hours_radians = hours / int(MarbleAge.HOURS_IN_DAY / 2.0) * PI * 2 + PI
	hour_hand.rotation = Vector3(0, hours_radians, 0)

	label_3d.text = "%02d:%02d:%02d" % [hours, minutes, seconds]

	#day of month
	@warning_ignore("integer_division")
	var day_of_month: int = int(age) % (MarbleAge.SECONDS_IN_MONTH) / (MarbleAge.SECONDS_IN_DAY) + 1
	day_of_month_label.text = str(day_of_month)

	var day_of_week = (day_of_month - 1) % MarbleAge.DAYS_IN_WEEK

	@warning_ignore("integer_division")
	var week_of_month = (day_of_month - 1) / MarbleAge.DAYS_IN_WEEK

	@warning_ignore("integer_division")
	day.position = Vector3(day_of_week / MarbleAge.DAYS_IN_WEEK, -week_of_month / MarbleAge.WEEKS_IN_MONTH, 0)

	#month of year
	@warning_ignore("integer_division")
	var month_of_year: int = int(age) % (MarbleAge.SECONDS_IN_HOUR * MarbleAge.HOURS_IN_DAY * MarbleAge.DAYS_IN_MONTH * MarbleAge.MONTHS_IN_YEAR) / (MarbleAge.SECONDS_IN_MONTH)
	month_of_year_label.text = MarbleAge.MONTHS[month_of_year]


func _on_warp_slider_value_changed(value: float) -> void:
	#print('_on_warp_slider_value_changed')
	warp_speed = int(value)


func _on_radius_slider_value_changed(value: float) -> void:
	radius = int(value)


func _on_scanner_body_entered(body: Node3D) -> void:
	#print('_on_scanner_body_entered %s:%s %s' % [body.get_class(), body.name, name])
	if "warp_detector" in body:
		#print('gg %s' % body.name)
		body.warp_detector.warp_monuments[self.name] = self
		bodies[body.name] = body
		body.calculate_warp()
		#body.warp_speed = warp_speed


func _on_scanner_body_exited(body: Node3D) -> void:
	#print('_on_scanner_body_exited %s:%s' % [body.get_class(), body.name])
	if "warp_detector" in body or bodies.has(body.name):
		#print('ff %s' % body.name)
		bodies.erase(body.name)
		# print('removed:%s %s' % [removed, body.name])
		# print(bodies)
		body.warp_detector.warp_monuments.erase(self.name)
		body.calculate_warp()


func get_data() -> Dictionary:
	return {
		"name": name,
		"warp_speed": warp_speed,
		"radius": radius,
		"transform": var_to_str(transform),
	}


func load_node(node_data):
	#transform = str_to_var(node_data["transform"])
	if "age" in node_data:
		age = node_data.age
	if "warp_speed" in node_data:
		warp_speed = node_data.warp_speed
	if "radius" in node_data:
		radius = node_data.radius
