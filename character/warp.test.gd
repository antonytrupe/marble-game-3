# GdUnit generated TestSuite
class_name WarpTest
extends GdUnitTestSuite
@warning_ignore('unused_parameter')
@warning_ignore('return_value_discarded')

# TestSuite generated from
const __source: String = 'res://character/character.gd'


var instance:MarbleCharacter
var other:MarbleCharacter

func before_test() -> void:

	instance=scene_runner("res://character/character.tscn").find_child("MarbleCharacter")
	other=scene_runner("res://character/character.tscn").find_child("MarbleCharacter")


func after_test() -> void:
	instance.queue_free()
	other.queue_free()


func test_when_both_are_warp_1():
	assert_int(instance.get_max_warp(other)).is_equal(1)
	assert_int(other.get_max_warp(instance)).is_equal(1)


func test_when_both_are_warp_2():
	instance.warp_speed=2
	other.warp_speed=2
	assert_int(instance.get_max_warp(other)).is_equal(2)
	assert_int(other.get_max_warp(instance)).is_equal(2)


func test_when_warp_1_and_warp_2_far_apart():
	#instance.warp_speed=1
	other.position=Vector3(300,0,0)
	other.warp_speed=2
	assert_int(instance.get_max_warp(other)).is_equal(1)
	assert_int(other.get_max_warp(instance)).is_equal(2)


func test_when_warp_1_and_warp_2_overlapping():
	instance.warp_speed=1
	other.warp_speed=2
	assert_int(instance.get_max_warp(other)).is_equal(1)
	assert_int(other.get_max_warp(instance)).is_equal(1)
