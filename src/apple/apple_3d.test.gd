class_name TestApple3D
extends GdUnitTestSuite

const SCENE_PATH: String = "res://src/apple/apple_3d.tscn"
var _runner: GdUnitSceneRunner
var _mock_game_root: Node

func before_test() -> void:
	# 1. Build the absolute tree path expected by the Apple3D @onready variables
	_mock_game_root = Node.new()
	_mock_game_root.name = "Game"

	var mock_world = World.new()
	mock_world.name = "World"

	# Add children that World expects as unique names
	var characters = Node.new()
	characters.name = "Characters"
	mock_world.add_child(characters)
	characters.owner = mock_world
	characters.unique_name_in_owner = true

	var flora = Node.new()
	flora.name = "Flora"
	mock_world.add_child(flora)
	flora.owner = mock_world
	flora.unique_name_in_owner = true

	var fauna = Node.new()
	fauna.name = "Fauna"
	mock_world.add_child(fauna)
	fauna.owner = mock_world
	fauna.unique_name_in_owner = true

	var terra = Node.new()
	terra.name = "Terra"
	mock_world.add_child(terra)
	terra.owner = mock_world
	terra.unique_name_in_owner = true

	var warp_monuments = Node.new()
	warp_monuments.name = "WarpMonuments"
	mock_world.add_child(warp_monuments)
	warp_monuments.owner = mock_world
	warp_monuments.unique_name_in_owner = true

	var items = Node3D.new()
	items.name = "Items"
	mock_world.add_child(items)

	# 2. Attach them to the engine root so $/root/Game/World exists
	var root = Engine.get_main_loop().root
	root.add_child(_mock_game_root)
	_mock_game_root.add_child(mock_world)

	# 3. Now initialize the runner safely without crash loops
	_runner = scene_runner(SCENE_PATH)
	if _runner == null:
		assert_bool(false).is_true().append_failure_message("failed to load scene")

func after_test() -> void:
	# Clean up the tree after every test to keep memory isolated
	if is_instance_valid(_mock_game_root):
		_mock_game_root.free()

func test_initial_state() -> void:
	var apple: Apple3D = _runner.scene() as Apple3D
	assert_bool(apple.freeze).is_false()
	assert_bool(apple.is_on_floor()).is_false()

func test_fall_deferred_state() -> void:
	var apple: Apple3D = _runner.scene() as Apple3D
	apple.freeze = true

	apple.fall()

	# Advance 2 frames to process set_deferred changes and physics steps
	_runner.simulate_frames(2)

	# FIX: your fall() function sets freeze to false, and freeze_mode to KINEMATIC
	assert_bool(apple.freeze).is_false()
	assert_int(apple.freeze_mode).is_equal(RigidBody3D.FREEZE_MODE_KINEMATIC)


func test_collision_and_sleeping_state() -> void:
	var apple: Apple3D = _runner.scene() as Apple3D

	# 1. Create a physical floor for the apple to fall onto
	var floor_body = StaticBody3D.new()
	var floor_shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()

	box_shape.size = Vector3(10, 1, 10)
	floor_shape.shape = box_shape
	floor_body.add_child(floor_shape)

	# Position the floor directly below the apple
	floor_body.position = Vector3(0, -2, 0)

	# Add the floor to the running scene runner tree so physics processes it
	_runner.scene().get_parent().add_child(floor_body)

	# 2. Configure the apple to actively watch for physics contacts
	apple.fall()

	# 3. Simulate frames to let the apple fall, collide, and come to a rest.
	# Physics engines can take a moment to settle into a "sleeping" state.
	# We simulate roughly 2-3 seconds of game time (120-180 frames).
	await _runner.simulate_frames(180)

	# 4. Verify that the apple's internal physics slept and triggered your script's logic
	assert_bool(apple.sleeping).is_true()
	assert_bool(apple.freeze).is_true()  # Verified: _on_sleeping_state_changed() set freeze to true
	assert_bool(apple.is_on_floor()).is_true() # Verified: _integrate_forces set _is_on_floor

	# Clean up the runtime floor node
	floor_body.queue_free()


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
