class_name WarpMonument
extends Node3D

# Statically typed visibility thresholds
const VISIBILITY_THRESHOLD_SECONDS: int = 120
const VISIBILITY_THRESHOLD_MINUTES: int = 6000
const VISIBILITY_THRESHOLD_HOURS: int = 60000
const HOURS_IN_CLOCK_FACE: float = 12.0

static var scene: Resource = preload("res://src/warp_monument/warp_monument.tscn")

@export var age: MarbleAge = MarbleAge.new()
@export var warp_speed: int = 1: set = _set_warp_speed
@export var radius: int = 1: set = _set_radius

@export var bodies: Dictionary = {}

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

func _ready() -> void:
	_on_synchronized()

## --- Persistence & Data ---

func get_data() -> Dictionary:
	return {
		"name": name,
		"parent": str(get_parent().get_path()) if get_parent() else "",
		"scene_file_path": get_scene_file_path(),
		"warp_speed": warp_speed,
		"radius": radius,
		"transform": var_to_str(transform),
		"age": age.age
	}

func load_pre_ready(data: Dictionary) -> void:
	if data.has("transform"):
		transform = str_to_var(data.transform)

func load_post_ready(data: Dictionary) -> void:
	if "age" in data: age.age = data.age
	if "warp_speed" in data: warp_speed = data.warp_speed
	if "radius" in data: radius = data.radius
	_on_synchronized()

## --- Networking & Synchronization ---

func _on_synchronized() -> void:
	if not is_node_ready(): return

	sphere.mesh.radius = radius
	sphere.mesh.height = radius * 2
	scanner_shape.shape.radius = radius

	radius_slider.value = radius
	warp_slider.value = warp_speed

	for body: Node in bodies.values():
		if body.has_method("calculate_warp"):
			body.calculate_warp()

@rpc("any_peer", "call_local", "reliable")
func request_server_update(new_warp: int, new_radius: int) -> void:
	if not multiplayer.is_server(): return
	warp_speed = new_warp
	radius = new_radius

func _on_warp_slider_value_changed(value: float) -> void:
	_handle_input_update(int(value), radius)

func _on_radius_slider_value_changed(value: float) -> void:
	_handle_input_update(warp_speed, int(value))

func _handle_input_update(w: int, r: int) -> void:
	if multiplayer.is_server():
		warp_speed = w
		radius = r
	else:
		request_server_update.rpc_id(1, w, r)

## --- Authoritative Setters ---

func _set_warp_speed(v: int) -> void:
	warp_speed = v
	if is_node_ready(): _on_synchronized()

func _set_radius(v: int) -> void:
	radius = v
	if is_node_ready(): _on_synchronized()

## --- Processing & Clock Logic ---

func _process(delta: float) -> void:
	age.age += delta * warp_speed
	_update_clock_visuals()

func _update_clock_visuals() -> void:
	# Hand Visibility
	second_hand.visible = warp_speed <= VISIBILITY_THRESHOLD_SECONDS
	minute_hand.visible = warp_speed <= VISIBILITY_THRESHOLD_MINUTES
	hour_hand.visible = warp_speed <= VISIBILITY_THRESHOLD_HOURS

	# Rotations using TAU and direct MarbleAge constants
	second_hand.rotation.y = (fmod(age.age, float(MarbleAge.SECONDS_IN_MINUTE)) / MarbleAge.SECONDS_IN_MINUTE) * TAU + PI
	minute_hand.rotation.y = (fmod(age.age / MarbleAge.SECONDS_IN_MINUTE, float(MarbleAge.MINUTES_IN_HOUR)) / MarbleAge.MINUTES_IN_HOUR) * TAU + PI
	hour_hand.rotation.y = (fmod(age.age / MarbleAge.SECONDS_IN_HOUR, HOURS_IN_CLOCK_FACE) / HOURS_IN_CLOCK_FACE) * TAU + PI

	# Label Formatting
	label_3d.text = "%02d:%02d:%02d" % [
		int(age.age / MarbleAge.SECONDS_IN_HOUR) % int(HOURS_IN_CLOCK_FACE),
		int(age.age / MarbleAge.SECONDS_IN_MINUTE) % MarbleAge.MINUTES_IN_HOUR,
		int(age.age) % MarbleAge.SECONDS_IN_MINUTE
	]

	day_of_month_label.text = str(age.get_day_of_month())
	month_of_year_label.text = MarbleAge.MONTHS[int(age.age / MarbleAge.SECONDS_IN_MONTH) % MarbleAge.MONTHS.size()]

	day.position = Vector3(
		age.get_day_of_week() / float(MarbleAge.DAYS_IN_WEEK),
		- age.get_week_of_month() / float(MarbleAge.WEEKS_IN_MONTH),
		0
	)

## --- Collision logic (Server Only) ---

func _on_scanner_body_entered(body: Node3D) -> void:
	if not multiplayer.is_server(): return
	if body.has_method("calculate_warp"):
		bodies[body.name] = body
		if "warp_detector" in body:
			body.warp_detector.warp_monuments[name] = self
		body.calculate_warp()

func _on_scanner_body_exited(body: Node3D) -> void:
	if not multiplayer.is_server(): return
	if bodies.erase(body.name):
		if "warp_detector" in body:
			body.warp_detector.warp_monuments.erase(name)
		body.calculate_warp()
