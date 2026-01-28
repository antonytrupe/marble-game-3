class_name WarpMonument
extends Node3D


@export var age: MarbleAge = MarbleAge.new()
@export var warp_speed: int = 1:
	set = _set_warp_speed
@export var radius: int = 1:
	set = _set_radius

var bodies: Dictionary = {}

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


@rpc("any_peer", "call_local")
func server_set_warp(value: int) -> void:
	if not is_server():
		return
	if warp_speed == value:
		return
	warp_speed = value


@rpc("any_peer", "call_local")
func server_set_radius(value: int) -> void:
	if not is_server():
		return
	if radius == value:
		return
	radius = value


func _on_multiplayer_synchronizer_synchronized() -> void:
	_update_radius_mesh()
	_update_bodies()
	_update_warp_slider()
	_update_radius_slider()


func _ready() -> void:
	_update_radius_mesh()
	_update_bodies()
	_update_warp_slider()
	_update_radius_slider()


## setter
func _set_warp_speed(value: int) -> void:
	if value != warp_speed:
		warp_speed = value
		_update_bodies()
		_update_warp_slider()


func _update_warp_slider() -> void:
	if not is_node_ready():
		return
	warp_slider.value = warp_speed


func _update_bodies() -> void:
	for body: Node in bodies.values():
		body.calculate_warp()


## setter
func _set_radius(value: int) -> void:
	if value != radius:
		radius = value
		_update_radius_mesh()
		_update_radius_slider()


func _update_radius_slider() -> void:
	if not is_node_ready():
		return
	radius_slider.value = radius


## update the bubble and scanner
func _update_radius_mesh() -> void:
	if not is_node_ready():
		return
	sphere.mesh.radius = radius
	sphere.mesh.height = radius * 2
	scanner_shape.shape.radius = radius


func _process(delta: float) -> void:
	age.age += delta * warp_speed

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
	var seconds: int = int(age.age) % (MarbleAge.SECONDS_IN_MINUTE)
	var sec_radians: float = seconds / float(MarbleAge.SECONDS_IN_MINUTE) * PI * 2 + PI
	second_hand.rotation = Vector3(0, sec_radians, 0)

	#minutes hand
	@warning_ignore("narrowing_conversion")
	var minutes: int = int(age.age) % (MarbleAge.SECONDS_IN_HOUR) / float(MarbleAge.MINUTES_IN_HOUR)
	var min_radians: float = minutes / (60.0) * PI * 2 + PI
	minute_hand.rotation = Vector3(0, min_radians, 0)

	#hours hand
	@warning_ignore("narrowing_conversion")
	var hours: int = int(age.age) % int(MarbleAge.SECONDS_IN_DAY / 2.0) / float(MarbleAge.SECONDS_IN_HOUR)
	@warning_ignore("integer_division")
	var hours_radians: float = hours / int(MarbleAge.HOURS_IN_DAY / 2.0) * PI * 2 + PI
	hour_hand.rotation = Vector3(0, hours_radians, 0)

	label_3d.text = "%02d:%02d:%02d" % [hours, minutes, seconds]

	#day of month
	var day_of_month: int = age.get_day_of_month()
	day_of_month_label.text = str(day_of_month)

	var day_of_week: int = age.get_day_of_week()

	var week_of_month: int = age.get_week_of_month()

	day.position = Vector3(day_of_week / float(MarbleAge.DAYS_IN_WEEK), -week_of_month / float(MarbleAge.WEEKS_IN_MONTH), 0)

	#month of year
	@warning_ignore("integer_division")
	var month_of_year: int = int(age.age) % (MarbleAge.SECONDS_IN_YEAR) / (MarbleAge.SECONDS_IN_MONTH)
	month_of_year_label.text = MarbleAge.MONTHS[month_of_year]


func is_server() -> bool:
	return multiplayer.is_server()


func _on_warp_slider_value_changed(value: float) -> void:
	#print('_on_warp_slider_value_changed')
	warp_speed = int(value)
	#TODO make sure this is updated everywhere
	if not is_server():
		server_set_warp.rpc_id(1, value)


func _on_radius_slider_value_changed(value: float) -> void:
	radius = int(value)
	if not is_server():
		server_set_radius.rpc_id(1, value)


@rpc("any_peer", "call_local")
func update_radius(value: float) -> void:
	radius = int(value)


func _on_scanner_body_entered(body: Node3D) -> void:
	#print('_on_scanner_body_entered %s:%s %s' % [body.get_class(), body.name, name])
	if not is_server():
		return
	if "warp_detector" in body:
		#print('gg %s' % body.name)
		body.warp_detector.warp_monuments[self.name] = self
		bodies[body.name] = body
		body.calculate_warp()
		#body.warp_speed = warp_speed


func _on_scanner_body_exited(body: Node3D) -> void:
	if not is_server():
		return
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
		"age": age.age
	}


func load_pre_ready(data: Dictionary) -> void:
	if data.has("transform"):
		transform = str_to_var(data.transform)


func load_post_ready(data: Dictionary) -> void:
	#transform = str_to_var(node_data["transform"])
	if "age" in data:
		age.age = data.age
	if "warp_speed" in data:
		warp_speed = data.warp_speed
	if "radius" in data:
		radius = data.radius
