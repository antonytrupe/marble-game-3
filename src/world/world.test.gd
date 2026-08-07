# GdUnit generated TestSuite
#class_name WorldTest
extends GdUnitTestSuite
@warning_ignore('unused_parameter')
@warning_ignore('return_value_discarded')

# TestSuite generated from
const __source: String = 'res://src/world/world.gd'


func test_get_ground_y() -> void:
	# Verify get_ground_y returns the floor collision height
	var world_scene: PackedScene = preload("res://src/world/world.tscn")
	var world: World = auto_free(world_scene.instantiate())
	add_child(world)
	# Need to wait a physics frame for the space state to be available
	await await_millis(100)
	var y: float = world.get_ground_y(0.0, 0.0)
	# The world scene has a floor collision shape at y=-6
	assert_float(y).is_equal_approx(23.139923,.00001)
