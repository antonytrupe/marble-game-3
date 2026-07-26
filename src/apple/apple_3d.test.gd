# GdUnit4 Test Suite
class_name Apple3DTest
extends GdUnitTestSuite

# Use explicit types for clarity
#const Apple3D: GDScript = preload("res://src/apple/apple_3d.gd")
# DOUBLE CHECK THIS PATH - it must be exactly where your .tscn file is
const SCENE_PATH: String = "res://src/apple/apple_3d.tscn"

var _runner: GdUnitSceneRunner

func before_test() -> void:
	_runner = scene_runner(SCENE_PATH)
	# Fail early with a clear message if the runner couldn't load the scene
	if _runner == null:
		assert_bool(false).is_true().append_failure_message("failed to load scene")

func test_initial_state() -> void:
	var apple: Apple3D = _runner.scene() as Apple3D
	assert_bool(apple.freeze).is_false()
	assert_bool(apple.is_on_floor()).is_false()

func test_fall_deferred_state() -> void:
	var apple: Apple3D = _runner.scene() as Apple3D
	apple.freeze = true

	apple.fall()

	# RigidBody3D changes via set_deferred require a physics frame
	_runner.simulate_frames(1)

	assert_bool(apple.freeze).is_true()
	assert_int(apple.freeze_mode).is_equal(RigidBody3D.FREEZE_MODE_STATIC)

func test_serialization_data() -> void:
	var apple: Apple3D = _runner.scene() as Apple3D
	apple.name = "TestApple"

	var data: Dictionary = apple.get_data()

	assert_dict(data).contains_key_value("name", "TestApple")
	assert_dict(data).contains_keys(["transform"])

func test_physics_freeze_on_floor() -> void:
	var apple: Apple3D = _runner.scene() as Apple3D

	# Manually setup "stopped on floor" state
	apple._is_on_floor = true
	apple.linear_velocity = Vector3.ZERO
	apple.angular_velocity = Vector3.ZERO
	apple.freeze = false

	_runner.simulate_frames(1)

	assert_bool(apple.freeze).is_false()
